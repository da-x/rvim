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
" Git utilities (functions moved to gitutils.vim)
source <sfile>:h/gitutils.vim


" =============================================================================
" Search replace

" Select the current cursor word and search it in the buffer, without
" moving, unlike '*' and '#' which move. If there is a selection, it is
" used instead.
vmap <A-t> *``
imap <A-t> <C-c>*``
nmap <A-t> *``

" Delimiter rotation for substitute commands
let g:substitute_delimiters = ['/', '#', '|', '@', '!']
let g:substitute_delimiter_index = 0

function! RotateSubstituteDelimiter() abort
  let g:substitute_delimiter_index = (g:substitute_delimiter_index + 1) % len(g:substitute_delimiters)
  let l:delim = g:substitute_delimiters[g:substitute_delimiter_index]
  echo 'Substitute delimiter: ' . l:delim
endfunction

function! GetSubstituteDelimiter() abort
  return g:substitute_delimiters[g:substitute_delimiter_index]
endfunction

nnoremap <A-d> :call RotateSubstituteDelimiter()<CR>

function! InsertSelectionMatch() abort
  " Finds the first match of the current search pattern (@/) and returns it
  " as escaped text for use in substitute commands. This enables pre-filling
  " replacement fields with the actual matched text for editing.
  "
  " Returns: Escaped string containing the matched text, or the original
  "          search pattern if no match found or match spans multiple lines
  let l:save_pos = getpos('.')
  let l:search_mark = @/
  let l:res = l:search_mark
  let [l:lnum, l:col] = searchpos(@/, 'cw')

  if l:lnum !=# 0
    let [l:lnum_end, l:col_end] = searchpos(@/, 'ce')
    if l:lnum ==# l:lnum_end
      let l:res = escape(strpart(getline(l:lnum), l:col - 1, l:col_end - l:col + 1), ' /&')
    else
      " Not supported yet
    endif
  endif

  call setpos('.', l:save_pos)
  return l:res
endfunction

" Search and replace using the current search mark, either in a selection or
" the entire buffer, and take the closest match as the replacement text to
" edit.
nnoremap <A-r> :%s<C-r>=GetSubstituteDelimiter()<CR><C-r>=@/<CR><C-r>=GetSubstituteDelimiter()<CR><C-r>=InsertSelectionMatch()<CR><C-r>=GetSubstituteDelimiter()<CR>g<left><left>
vnoremap <A-r> :s<C-r>=GetSubstituteDelimiter()<CR><C-r>=@/<CR><C-r>=GetSubstituteDelimiter()<CR><C-r>=InsertSelectionMatch()<CR><C-r>=GetSubstituteDelimiter()<CR>g<left><left>

" Same as above, but write a new string for replacement.
nnoremap <A-n> :%s<C-r>=GetSubstituteDelimiter()<CR><C-r>=@/<CR><C-r>=GetSubstituteDelimiter()<CR><C-r>=GetSubstituteDelimiter()<CR>g<left><left>
vnoremap <A-n> :s<C-r>=GetSubstituteDelimiter()<CR><C-r>=@/<CR><C-r>=GetSubstituteDelimiter()<CR><C-r>=GetSubstituteDelimiter()<CR>g<left><left>

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
