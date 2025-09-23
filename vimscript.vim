" Custom VimScript configuration

" =============================================================================
" Gg

function! MyGitRoot() abort
  let l:dir = systemlist('git rev-parse --show-toplevel')
  if len(l:dir) != 0
    return l:dir[0]
  endif
  let l:dir = systemlist('git rev-parse --git-dir')
  if len(l:dir) != 0
     return fnamemodify(l:dir[0], ":p:h:h")
  else
endfunction

function! MyGitGrep(arg) abort
  let s:string = shellescape(a:arg)
  let l:recursive = ""
  if get(g:, 'gg_recursive', 1)
     let l:recursive = "--recurse-submodules"
  endif
  call fzf#vim#grep('git grep '.l:recursive.' --line-number --color '.s:string.' 2>/dev/null', 0,
      \ { 'dir': MyGitRoot() },
      \ 0)
  call histadd(':', 'Gg '.a:arg)
endfunction

function! MyGitGrepToggleRecursive() abort
  if get(g:, 'gg_recursive', 1)
    let g:gg_recursive = 0
    echom "GitGrep: Non recursive by default"
  else
    let g:gg_recursive = 1
    echom "GitGrep: Recursive by default"
  endif
endfunction

command! -nargs=+ Gg call MyGitGrep(<q-args>)
command! GgToggleRecursive call MyGitGrepToggleRecursive()

nnoremap <F9> :Gg <c-r>=expand("<cword>")<CR><CR>
nnoremap <C-F9> :Gg <c-r>=""<CR>
nnoremap <tab><F9> :Rg <c-r>=expand("<cword>")<CR><CR>
nnoremap <tab><C-F9> :Rg <c-r>=""<CR>

" =============================================================================
" Yanking to system clipboard various stuff

function! s:BackgroundSetClip_JobEnd(job_id, exit_code, event_type) abort
  let l:clip_job_end_time = reltimefloat(reltime())
  let l:duration = l:clip_job_end_time - s:clip_jobstart_time
  if a:exit_code != 0
    echo '<ERROR copying to system clipboard: '.string(a:exit_code).'>'
  else
    if l:duration > 0.2
      echo '<copied to system clipboard (jobid='.string(a:job_id).')>'
    endif
  endif
endfunction

function! SetSystemClipboard(string) abort
  let l:display = system('echo $DISPLAY')
  let l:helper = '$HOME/.vim_runtime/bin/set-all-clipboard.py'
  if !has('nvim') || !exists(l:helper) || l:display ==# ''
    return
  endif

  " Send it to the background, because it may take some time due to a remote tmux session.
  let l:id = jobstart(l:helper, {'on_exit': function('s:BackgroundSetClip_JobEnd')})
  let s:clip_jobstart_time = reltimefloat(reltime())
  call chansend(l:id, a:string)
  call chanclose(l:id, 'stdin')
endfunction

function! YankCurrentFilename() abort
  call SetSystemClipboard(expand("%"))
endfunction

function! YankCurrentDirAbs() abort
  call SetSystemClipboard(expand("%:p:h"))
endfunction

noremap <silent> <leader>yf :call YankCurrentFilename()<CR>
noremap <silent> <leader>yd :call YankCurrentDirAbs()<CR>

augroup AutoSetSystemClipboard
  autocmd!
  autocmd TextYankPost * call SetSystemClipboard(@")
augroup END

" =============================================================================
" Git 


function EndCommitMessageEdit()
  if len(getbufinfo({'buflisted':1})) == 1
    wq!
  else
    w | bd
  endif
endfunction

function! MyGitCommitHook() abort
  setlocal spell

  " Quick save commit message and return
  nnoremap <buffer> <C-g><CR> :w \| bd<CR>
  imap <buffer> <C-g><CR> <C-c><C-g><CR>

  " In Neovim, M-PageUp=C-CR
  nnoremap <buffer> <M-T-PageUp> :call EndCommitMessageEdit()<CR>
  imap <buffer> <M-T-PageUp> <C-c>:call EndCommitMessageEdit()<CR>
  startinsert
endfunction

function! MyGitAddAllAmend() abort
  Git commit -a --amend
endfunction

function! MyGitRebaseTodoHook(...) abort
  call setpos('.', [0, 1, 1, 0])
  nnoremap <buffer> p 0ciwpick<ESC><Down>0
  nnoremap <buffer> r 0ciwreword<ESC><Down>0
  nnoremap <buffer> e 0ciwedit<ESC><Down>0
  nnoremap <buffer> s 0ciwsquash<ESC><Down>0
  nnoremap <buffer> f 0ciwfixup<ESC><Down>0
  nnoremap <buffer> x 0ciwexec<ESC><Down>0
  nnoremap <buffer> d 0ciwdrop<ESC><Down>0
  nnoremap <buffer> k 0ciwdrop<ESC><Down>0
  nmap <buffer> <C-Up> <M-k>
  nmap <buffer> <C-Down> <M-j>
  nmap <buffer> <M-PageUp> <M-k>
  nmap <buffer> <M-PageDown> <M-j>
endfunction

augroup GitRebaseTodoRebinding autocmd!
  autocmd! BufRead git-rebase-todo call MyGitRebaseTodoHook()
augroup END

function! s:rebase_interactive_sink(single_item)
  echomsg a:single_item
  if len(a:single_item) >= 2
    let l:line = a:single_item[1]
    " Extract commit hash from git log --oneline format: "hash message"
    let l:parts = split(l:line, ' ')
    if len(l:parts) > 0
      let l:commit_hash = l:parts[0]
      execute "Git rebase -i " l:commit_hash
    else
      echo "Could not parse commit hash"
    endif
  else
    echo "No commit selected"
  endif
endfunction

function! MyFZFChooseRebaseInteractive()
  " Show only commits in current branch
  let l:branch = system('git branch --show-current 2>/dev/null || git rev-parse --abbrev-ref HEAD 2>/dev/null')
  let l:branch = substitute(l:branch, '\n', '', 'g')
  
  if empty(l:branch)
    echo "Not in a git repository or no commits"
    return
  endif
  
  " Use git log for current branch only
  let l:git_cmd = 'git log --oneline --decorate --color=always ' . shellescape(l:branch)
  
  call fzf#vim#commits({
  \  'source': l:git_cmd,
  \  'sink*': function('s:rebase_interactive_sink'),
  \})
endfunction

let s:my_fzf_git_diff_hunk_program = expand('<sfile>:p:h')."/bin/fzf-git-diff-hunk-preview"

function! MyFZFDiffHunks(cmd,...) abort
  let l:screen = get(a:, 1, 'half')
  let l:matches = []
  let l:filename = ''
  let l:filename_color = "\x1b[38;2;155;255;155m"
  let l:white = "\x1b[38;2;255;255;255m"
  let l:lnum_color = "\x1b[38;2;77;127;77m"
  let l:grey = "\x1b[38;2;255;255;155m"

  let l:hunknum = 1
  let l:found_change_start = 0
  for l:line in systemlist("git diff " . a:cmd . " | grep -E '^(diff|@@)' -A 4")
    let l:m = matchlist(l:line, '\V\^diff --git a/\(\.\*\) b/\(\.\*\)')
    if len(l:m) != 0
      let l:filename = l:m[2]
      let l:hunknum = 1
      continue
    endif
    let l:m = matchlist(l:line, '\V\^@@ -\[^ ]\+ +\(\[0-9]\+\)\[ ,]\[^@]\*@@\(\.\*\)')
    if len(l:m) != 0
      let l:found_change_start = 0
      let l:line_num = l:m[1]
      let l:title = l:m[2]
      call add(l:matches, [l:hunknum, l:filename, l:line_num, l:title])
      let l:hunknum += 1
      continue
    endif
    if l:found_change_start == 0
      let l:m = matchlist(l:line, '\V\^\[+-]')
      if len(l:m) != 0
        let l:found_change_start = 1
      else
        if len(l:matches) >= 1
          let l:matches[len(l:matches) - 1][2] += 1
        endif
      endif
    endif
  endfor

  let l:i = 0
  while l:i < len(l:matches)
    let [l:hunknum, l:filename, l:line_num, l:title] = l:matches[l:i]
    let l:matches[i] =
        \ printf("%3d " . l:filename_color . "%s"
        \ . l:white. ":" . l:lnum_color. "%d"
        \ . l:white. " %s",
        \ l:hunknum,
        \ l:filename,
        \ l:line_num,
        \ l:title)
    let l:i = l:i + 1
  endwhile

  if len(l:matches) == 0
    if l:screen == 'full'
      execute "normal! :x\<CR>"
    endif
    return
  endif

  let l:options = [
      \"--ansi", "-e", "--no-sort", "--tac",
      \"--preview-window", "down:70%:noborder",
      \"--preview", s:my_fzf_git_diff_hunk_program." '".a:cmd."' {}"
      \]

  if l:screen == 'full'
    let l:down = "100%"
  else
    let l:down = "50%"
  endif

  let l:opts = {}
  function! l:opts.sink(single)
    if len(a:single) == 1
      let l:m = matchlist(a:single[0], '\V\^ \*\(\[0-9]\*\) \(\[^:]\*\):\(\[0-9]\*\)')
      if len(l:m) != 0
        execute "edit" l:m[2]
        call setpos(".", [0, str2nr(l:m[3]), 0, 0])
      endif
    endif
  endfunction

  let l:v = fzf#run(fzf#wrap({
              \ 'source': l:matches,
              \ 'down': l:down,
              \ 'sink*': remove(opts, 'sink'),
              \ 'options': l:options,
              \ }))
endfunction

" History of the current buffer's file
nnoremap <C-g>L     :BCommits<CR>
nnoremap <C-g>AA    :call MyGitAddAllAmend()<CR>

" Various diff ways
nnoremap <C-g>d     :call MyFZFDiffHunks('')<CR>
nnoremap <C-g><C-d> :call MyFZFDiffHunks('')<CR>
nnoremap <C-g>D     :call MyFZFDiffHunks('HEAD')<CR>
nnoremap <C-g>C     :call MyFZFDiffHunks('--cached')<CR>
nnoremap <C-g>j     :call MyFZFDiffHunks('HEAD~1')<CR>
nnoremap <C-g><C-j> :call MyFZFDiffHunks('HEAD~1')<CR>
nnoremap <C-g>i     :call MyFZFChooseRebaseInteractive()<CR>

augroup GitCommitAutocmds
  autocmd!
  autocmd! FileType gitcommit call MyGitCommitHook()
augroup END

" =============================================================================
" Various editing stuff

func! EditLocalVimrc()
  exec ":edit .git/vimrc_local.vim"
endfun

command! -bar EditLocalVimrc call EditLocalVimrc()

" Mark '.orig' file buffers as read-only on open
augroup MarkOrigReadonly
  autocmd!
  autocmd BufRead *.orig setlocal readonly
augroup END

nmap <leader>el :EditLocalVimrc<CR>
nnoremap <leader>ea :e! ~/.config/alacritty/alacritty.yml<CR>
nnoremap <leader>ee :e! ~/.config/rvim/init.lua<CR>
nnoremap <leader>eg :e! ~/.files/gitconfig<CR>
nnoremap <leader>et :e! ~/.tmux.conf<CR>
nnoremap <leader>ez :e! ~/.zsh/zshrc.sh<CR>
nnoremap <leader>e_ :e! ~/.vim_runtime/project-specific.vim<CR>
nnoremap <leader>ef :ToggleFileExplorer<CR>

" Removes trailing spaces
function! TrimWhiteSpace() abort
  %s/\s\+$//e
endfunction

command! TrimWhiteSpace call TrimWhiteSpace()

func! Indent4Spaces(...)
  setlocal expandtab

  setlocal shiftwidth=4
  setlocal softtabstop=4
  setlocal nosmarttab
endfun

command! Indent4Spaces call Indent4Spaces()

" =============================================================================
" Eat

function! SaveAllAndEatRedo() abort
  wa!
  call EatRedo()
endfunction

noremap <silent> <F8>                 :call EatNext()<CR>
noremap <silent> <M-F8>               :call SaveAllAndEatRedo()<CR>
noremap <silent> <C-F8>               :call EatFirst()<CR>
noremap <silent> <leader>o<Insert>    :call EatScan()<CR>
noremap <silent> <leader>o<Home>      :call EatFirst()<CR>
noremap <silent> <leader>ol           :call EatScan()<CR>
noremap <silent> <leader>oo           :call SaveAllAndEatRedo()<CR>
noremap <silent> <leader>o<Backspace> :call EatPrev()<CR>
noremap <silent> <leader>o<Return>    :call EatNext()<CR>
noremap <silent> <leader>o<space>     :call EatFirst()<CR>
noremap <silent> <leader>o[           :call EatPrev()<CR>
noremap <silent> <leader>o]           :call EatNext()<CR>

" =============================================================================
" Markdown

let g:vim_markdown_no_default_key_mappings = 1
let g:vim_markdown_folding_disabled = 1
let g:vim_markdown_no_extensions_in_markdown = 1
let g:vim_markdown_auto_insert_bullets = 0
let g:vim_markdown_new_list_item_indent = 0
let g:vim_markdown_follow_anchor = 1
let g:vim_markdown_spell_title = 0

function! MyFixupMarkdownLink(text)
  let l:text = a:text
  let l:matchurl = matchlist(a:text, '\V\^\(\.\*\).md')
  if l:matchurl != []
    let l:text = l:matchurl[1]
  endif
  return knot#ConvertIdLink(expand(l:text))
endfunction

function! MyMarkdownSettings()
  setlocal spell
  let b:Markdown_LinkFilter = function('MyFixupMarkdownLink')
  let b:Markdown_PerFileBackgroundSaving = synIDattr(synIDtrans(hlID("Normal")), "bg", "gui")
  
  " Custom highlight overrides for markdown based on :Inspect output
  call nvim_set_hl(0, '@markup.raw.markdown_inline', {'fg': '#9e64ff', 'bg': '#1a1a1a'})

  map <buffer> <leader>e\ <A-e>d
  noremap <buffer> <silent> gq :call MyMarkdownGQ()<CR>
  imap <buffer> <A-e>d  <C-c><A-e>d

  noremap <buffer> <silent> <A-e><CR>      :call MyMarkdownInsertBullet()<CR>
  noremap <buffer> <silent> <C-CR>         :call MyMarkdownInsertBullet()<CR>
  noremap <buffer> <silent> <leader><Down> :call MyMarkdownInsertBullet()<CR>

  noremap <buffer> <silent> <A-e><Right> :call MyMarkdownInsertSubBullet()<CR>
  noremap <buffer> <silent> <leader><Right> :call MyMarkdownInsertSubBullet()<CR>
  nnoremap <buffer> <silent> <CR> <cmd>lua require('utils').open_markdown_link()<CR>
  noremap <buffer> <C-del> :call MyMarkdownToggleComposeMode()<CR>
  inoremap <buffer> <C-del> <C-c>:call MyMarkdownToggleComposeMode()<CR>
  vnoremap <buffer> <silent> <leader>` :call MyMarkdownCodeBlockSelection()<CR>

  inoremap <buffer> <A-e><Down>  Go<CR><CR><C-R>=MyVimEditInsertDateLine()<CR><CR>
  inoremap <buffer> <A-e><CR>  <C-c>i<C-R>=MyVimEditTimestamp()<CR>
  inoremap <buffer> <A-e>d      Go<CR><CR><C-R>=MyVimEditInsertDateLine()<CR><CR>
  noremap <buffer> <A-e>d  Go<C-R>=MyVimEditInsertDateLine()<CR><CR>
  noremap <buffer> <A-e><CR>  Go<C-R>=MyVimEditTimestamp()<CR>
  nnoremap <silent> <buffer> <A-k>  :call MyMarkdownDragUp()<CR>
  nnoremap <silent> <buffer> <A-j>  :call MyMarkdownDragDown()<CR>
  vnoremap <silent> <buffer> <A-k>  :call MyMarkdownDragUp()<CR>
  vnoremap <silent> <buffer> <A-j>  :call MyMarkdownDragDown()<CR>

  Indent4Spaces
  setl formatlistpat+=\\\|^\\s*\\*\\s*
  setl comments=fb:>,fb:*,fb:+,fb:-
  setl formatoptions-=q
  setl conceallevel=2

  syntax sync fromstart
endfunction

augroup MarkdownEditSettings
  autocmd!

  autocmd FileType markdown call MyMarkdownSettings()
augroup END

" =============================================================================
"
" Knots

function! MyVimEditTimestamp() abort
  return "__".strftime("%Y-%m-%d %H:%M:%S")."__: "
endfunction

function! MyStatuslineRelativePath() abort
  if !get(b:, 'knotIdResolved', v:false)
    let b:knotId = knot#currentFullID()
    let b:knotIdResolved = v:true
  endif
  if b:knotId == v:null
    return expand("%F")
  endif
  return "Knot: ".b:knotId
endfunction

function! MarkdownInsertTimestamp() abort
  if getline('$') == ""
    normal! G
  else
    normal! Go
  endif
  call setline(line('.'), MyVimEditTimestamp())
  normal! G$a
endfunction

function! InKnotBuffer()
  if &filetype !=# 'markdown'
      return
  endif

  call knot#InstallHooks()

  " Make the knots related to the current desktop one with a special background color
  if exists('b:Markdown_PerFileBackgroundSaving')
    if knot#currentFullID() != knot#currentDesktopKnotID()
      let l:color = "#150015"
      execute "highlight Normal guibg=".l:color
      execute "highlight EndOfBuffer guibg=".l:color
    endif
  endif

  let b:Markdown_LinkFilter = function('knot#ConvertIdLink')

  " Manipulation
  nmap <buffer> <C-n>m              :call knot#MoveCurrentInteractive()<CR>
  nmap <buffer> <C-n><Delete>       :call knot#DeleteCurrent()<CR>

  "" Open URLs from current knot
  nmap <silent> <buffer> <C-PageUp> :call knot#pickUrl()<CR>

  " Navigation
  "   C-h: Ctrl-Backspace
  nmap <buffer>     <C-h> :call knot#goToBacklinks()<CR>
  nmap <buffer>     <C-n><PageDown>  :call knot#Pick()<CR>
  nmap <buffer>     <F3>             :call knot#Pick()<CR>
  nmap <buffer>     <C-F1> :call knot#openReminder()<CR>

  " Insertions or extractions
  inoremap <buffer> <C-t>  <C-c>i<C-R>=MyVimEditTimestamp()<CR>
  noremap <buffer>  <C-t>  G:call MarkdownInsertTimestamp()<CR>A
  noremap <buffer>  <C-n>u :call knot#insertOpenedTabURL()<CR>
  noremap <buffer>  <C-n><Up>  i<C-R>=knot#DateLink()<CR>
  nnoremap <buffer> <leader>]  :call knot#InsertReminder()<CR>

  xnoremap <buffer> <C-n><Insert> :<c-u>
     \call knot#CarveCurrentInteractive()
     \<CR>
endfunction

command! InKnotBuffer call InKnotBuffer()
