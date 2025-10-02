" Git utility functions for rvim configuration

" =============================================================================
" Git commit functions

function EndCommitMessageEdit()
  if len(getbufinfo({'buflisted':1})) == 1
    wq!
  else
    w | bd
  endif
endfunction

function! MyGitCommitHook() abort
  setlocal spell
  startinsert
endfunction

function! MyGitAddAllAmend() abort
  Git commit -a --amend
endfunction

function! MyGitPush() abort
  Git push
endfunction

" =============================================================================
" Git rebase functions

function! MyGitRebaseTodoHook(...) abort
  " Cursor positioning is now handled by the autocmd in init.lua
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

" =============================================================================
" Git diff functions

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

function GFilesWithPreview()
  call fzf#vim#gitfiles('', {'options': [
        \ '--sync',
        \ '--query', expand('%h'),
        \ '--bind', 'result:transform:
           \  if [[ -n $FZF_QUERY ]]; then ;
           \      echo "track-current+clear-query" ;
           \  else ;
           \      echo "untrack-current+offset-middle+unbind(result)" ;
           \  fi',
        \ '--preview', 'bat -p --color always {}'],
        \ 'window': { 'width': 0.9, 'height': 0.9 }})
endfunction
" =============================================================================
" Git autocommands

augroup GitCommitAutocmds
  autocmd!
  autocmd! FileType gitcommit call MyGitCommitHook()
augroup END
