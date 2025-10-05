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
  call ReloadEnvironment()
  let l:display = system('echo $WAYLAND_DISPLAY')
  let l:ssh_custom_callback = system('echo $SSH_CUSTOM_CALLBACK')
  let l:helper = $HOME."/.vim_runtime/bin/set-all-clipboard.py"

  if !has('nvim') || !filereadable(l:helper) || (l:display ==# '' && l:ssh_custom_callback ==# '')
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

" =============================================================================
" Various editing stuff

func! EditLocalVimrc()
  exec ":edit .git/vimrc_local.vim"
endfun

command! -bar EditLocalVimrc call EditLocalVimrc()

function! CondLinuxCodingStyle()
  if &ft == "cpp" || &ft == 'c'
    LinuxCodingStyle
  endif
endfunction

command! CondLinuxCodingStyle call CondLinuxCodingStyle()


" Mark '.orig' file buffers as read-only on open
augroup MarkOrigReadonly
  autocmd!
  autocmd BufRead *.orig setlocal readonly
augroup END


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


  Indent4Spaces
  setl formatlistpat+=\\\|^\\s*\\*\\s*
  setl comments=fb:>,fb:*,fb:+,fb:-
  setl formatoptions-=q
  setl conceallevel=3

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

function! MyVimEditInsertDateLine() abort
  return strftime("# At %Y-%m-%d %H:%M:%S\n")
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

function! MyMarkdownVisualModeExitOnce()
  if mode() =~# '\vV|v'
    let b:cursor_moves += 1
    if b:cursor_moves >= 10
      return
    endif
    call feedkeys("\<Esc>\<Esc>")
    augroup MyMarkdownVisualModeExitOnce
      autocmd!
    augroup END
  endif
endfunction

function! MyMarkdownSetupVisualModeExitOnce()
  let b:cursor_moves = 0
  let l:pos = getpos("'<")
  call cursor(l:pos[1], l:pos[2])
  augroup MyMarkdownVisualModeExitOnce
    autocmd!
    autocmd CursorMoved * call MyMarkdownVisualModeExitOnce()
    autocmd CursorMovedI * call MyMarkdownVisualModeExitOnce()
  augroup END
endfunction

function! MyMarkdownBulletMetrics(start_line, dir, start_indent)
  " Get the current line and its indentation level
  let l:current_line = a:start_line
  let l:current_indent = indent(l:current_line)
  if a:start_indent != -1 && l:current_indent != a:start_indent
    " Not a sibling node
    return [-1, 0, 0]
  endif
  let l:last_line = line('$')

  " Initialize the end line to the current line
  let l:end_line = l:current_line

  if a:dir == 1
    " Find the last line with equal or greater indentation
    while l:end_line < l:last_line && indent(l:end_line + 1) > current_indent
      let l:end_line += 1
    endwhile
    return [l:current_indent, l:current_line, l:end_line]
  else
    " Find the first line with equal or greater indentation
    while l:end_line > 1 && indent(l:end_line - 1) > current_indent
      let l:end_line -= 1
    endwhile
    let l:end_line -= 1
    let l:current_line -= 1
    if l:end_line == l:current_line && indent(l:end_line) < current_indent
      return [-1, 0, 0]
    endif
    return [l:current_indent, l:end_line, l:current_line]
  fi
endfunction

function! MyMarkdownSelectWholeBullet()
  " Check if in visual mode; use '< if so, otherwise use the current line
  let l:start_line = mode() =~# 'V' ? getpos("'<")[1] : line('.')

  let [l:current_indent, l:current_line, l:end_line] = MyMarkdownBulletMetrics(l:start_line, 1, -1)
  if l:current_indent == -1
    return [l:current_indent, l:current_line, l:end_line]
  endif

  " Set the visual selection marks '< and '>
  call setpos("'<", [0, l:current_line, 1, 0])
  call setpos("'>", [0, l:end_line, 1, 0])

  execute "normal! V"
  execute "normal! gv"
  return [l:current_indent, l:current_line, l:end_line]
endfunction

function! MyMarkdownDragUp() range
  let l:orig_pos = getpos(".")
  let [l:current_indent, l:current_line, l:end_line] = MyMarkdownSelectWholeBullet()
  if l:current_indent == -1
    return
  endif

  let [l:prev_indent, l:prev_start_line, l:prev_end_line] = MyMarkdownBulletMetrics(l:current_line, -1, l:current_indent)
  if l:prev_indent == -1
    call cursor(l:orig_pos[1], l:orig_pos[2])
    return
  endif
  if getline(l:prev_start_line) == ""
    call cursor(l:orig_pos[1], l:orig_pos[2])
    return
  endif

  for l:i in range(1, l:prev_end_line - l:prev_start_line + 1)
    execute "normal \<Plug>MoveBlockUp"
  endfor
  call MyMarkdownSetupVisualModeExitOnce()
endfunction

function! MyMarkdownDragDown() range
  let l:orig_pos = getpos(".")
  let [l:current_indent, l:current_line, l:end_line] = MyMarkdownSelectWholeBullet()
  if l:current_indent == -1
    return
  endif

  let [l:next_indent, l:next_start_line, l:next_end_line] = MyMarkdownBulletMetrics(l:end_line + 1, 1, l:current_indent)
  if l:next_indent == -1
    call cursor(l:orig_pos[1], l:orig_pos[2])
    return
  endif
  if getline(l:next_start_line) == ""
    call cursor(l:orig_pos[1], l:orig_pos[2])
    return
  endif

  for l:i in range(1, l:next_end_line - l:next_start_line + 1)
    execute "normal \<Plug>MoveBlockDown"
  endfor
  call MyMarkdownSetupVisualModeExitOnce()
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

  " Setup key bindings using Lua command
  SetupKnotBindings
endfunction

command! InKnotBuffer call InKnotBuffer()

" =============================================================================
" FZF Spell suggestions
" From: https://www.codementor.io/@coreyja/coreyja-vim-spelling-suggestions-with-fzf-p6ce3zb9a

function! FzfSpellSink(word)
  exe 'normal! "_ciw'.a:word
endfunction

function! FzfSpell()
  let suggestions = spellsuggest(expand("<cword>"))
  return fzf#run({
    \ 'source': suggestions, 
    \ 'sink': function("FzfSpellSink"), 
    \ 'down': 10,
    \ 'options': '--bind=esc:cancel'
    \ })
endfunction

" =============================================================================
" Environment reload with cooldown

let g:last_reload_time = 0

function! ReloadEnvironment() abort
  if $TMUX ==# ''
    return
  endif

  let l:current_time = localtime()
  if l:current_time - g:last_reload_time < 60
    return
  endif
  let g:last_reload_time = l:current_time

  silent let l:env = system('tmux show-environment')
  for l:line in split(l:env, '\n')
    if l:line =~# '\V\^-\(\.\*\)'
      " Only possible with 8.0.1832 [ https://github.com/vim/vim/issues/1116 ]
      silent! execute 'unlet $'.strpart(l:line, 1)
    else
      let [l:name, l:value] = split(l:line, '=')
      execute 'let $'.l:name." = \"".escape(l:value, '\\/.*$^~[]')."\""
    endif
  endfor
endfunction
