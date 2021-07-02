" Original: https://github.com/vim-scripts/keepcase.vim

" m: match pattern
" r: replace pattern
" s: substitute pattern
let s:patterns = [
  \ {
    \ 'm': '^\u\l\+$',
    \ 'r': '^\(.\)\(.\+\)$',
    \ 's': '\u\1\L\2',
  \ },
  \ {
    \ 'm': '^\u\+$',
    \ 'r': '^.\+$',
    \ 's': '\U&',
  \ },
  \ {
    \ 'm': '^\l\+$',
    \ 'r': '^.\+$',
    \ 's': '\L&',
  \ },
  \ {
    \ 'm': '^\u.\+$',
    \ 'r': '^.\+$',
    \ 's': '\u&',
  \ },
  \ {
    \ 'm': '^\l.\+$',
    \ 'r': '^.\+$',
    \ 's': '\l&',
  \ },
\ ]

function! match_case#keep_case(oldword, newword) abort
  for l:pattern in s:patterns
    if a:oldword =~# l:pattern.m
      return substitute(a:newword, l:pattern.r, l:pattern.s, '')
    endif
  endfor
  return a:newword
endfunction

function! match_case#substitute(input) range
  let l:sep = a:input[0]
  let l:args = split(a:input, l:sep)

  " Main keepcase
  let l:args[1] = '\=match_case#keep_case(submatch(0), ' . "'" . l:args[1] . "')"
  " Take care of back-references
  let l:args[1] = substitute(l:args[1], '\\\(\d\+\)', "'.submatch(\\1).'", 'g')

  let l:cmd = a:firstline . ',' . a:lastline . 's' . l:sep . join(l:args, l:sep)
  execute l:cmd
endfunction
