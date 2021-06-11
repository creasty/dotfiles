function! vimrc#plugin#switch#lazy_init() abort
  let g:switch_custom_definitions = [
    \ switch#Words(['public', 'protected', 'private']),
    \ switch#Words(['and', 'or']),
    \ switch#Words(['if', 'unless']),
    \ switch#NormalizedCaseWords(['true', 'false']),
    \ switch#NormalizedCaseWords(['on', 'off']),
    \ switch#NormalizedCaseWords(['yes', 'no']),
  \ ]

  " 1. snake_case -> camelCase
  " 2. camelCase -> PascalCase
  " 3. PascalCase -> snake_case
  let g:switch_custom_definitions += [
    \ {
    \   '\<[a-z0-9]\+_\k\+\>': {
    \     '_\(.\)': '\u\1',
    \   },
    \   '\<[a-z0-9]\+[A-Z]\k\+\>': {
    \     '\<\([a-z]\)': '\u\1',
    \   },
    \   '\<[A-Z0-9][a-z0-9]\+[A-Z]\k\+\>': {
    \     '\<\([A-Z]\)': '\l\1',
    \     '\([a-z]\)\([A-Z]\)': '\L\1_\2',
    \   },
    \ },
  \ ]
endfunction
