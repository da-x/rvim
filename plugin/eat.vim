if exists("g:loaded_eat")
  finish
endif
let g:loaded_eat = 1

function! s:replaceHomePrefix(input) abort
  let home = $HOME
  if a:input =~ '^' . escape(home, '\/')
    return substitute(a:input, '^' . escape(home, '\/'), '~', '')
  else
    return a:input
  endif
endfunction

function! EatBindCallback(eat_instances) abort
  let l:matches = []
  let l:cwd_color = "\x1b[38;2;127;127;127m"
  let l:command_color = "\x1b[38;2;255;255;155m"
  let l:white = "\x1b[38;2;255;255;255m"

  let l:i = 0
  while l:i < len(a:eat_instances)
    let l:x = a:eat_instances[l:i]
    let l:info = l:x[1]
    let l:dir = s:replaceHomePrefix(l:info['dir'])
    call add(l:matches, printf("%s ".l:cwd_color."%s".l:white." : ".l:command_color."%s", l:x[0], l:dir, l:info['command']))
    let l:i = l:i + 1
  endwhile

  echom "XS"

  let l:options = [
      \"-1",
      \"--ansi", "-e", "--no-sort", "--tac",
      \"--with-nth", "2..",
      \"--accept-nth", "1",
      \]

  let l:opts = {}
  function! l:opts.sink(single)
    call EatBind(a:single)
  endfunction

  call fzf#run(fzf#wrap({
              \ 'source': l:matches,
              \ 'down': '50%',
              \ 'options': l:options,
              \ 'sink': remove(l:opts, 'sink'),
              \}))
endfunction

" autocmd VimEnter * call s:DoSomething()
