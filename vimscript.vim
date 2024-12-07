" Custom VimScript configuration

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
" Variosu editing stuff

" Removes trailing spaces
function! TrimWhiteSpace() abort
  %s/\s\+$//e
endfunction

command! TrimWhiteSpace call TrimWhiteSpace()
