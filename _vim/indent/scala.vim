" Vim indent file
" Language:   Scala (http://scala-lang.org/)
" Maintainer: Yuki Iwanaga

if exists('b:did_indent')
  finish
endif
let b:did_indent = 1

setlocal indentexpr=GetMyScalaIndent()
setlocal indentkeys=0{,0},0),!^F,<>>,<CR>
setlocal autoindent shiftwidth=2 tabstop=2 softtabstop=2 expandtab

if exists('*GetMyScalaIndent')
  finish
endif

function! CountParens(line)
  let line = substitute(a:line, '"\(.\|\\"\)*"', '', 'g')
  let open = substitute(line, '[^(]', '', 'g')
  let close = substitute(line, '[^)]', '', 'g')
  return strlen(open) - strlen(close)
endfunction

function! GetMyScalaIndent()
  let lnum = prevnonblank(v:lnum - 1)

  if lnum == 0
    return 0
  endif

  let ind = indent(lnum)
  let prevline = getline(lnum)
  let thisline = getline(v:lnum)

  " html literals
  if prevline !~# '/>\s*$' && prevline =~# '^\s*<[a-zA-Z][^>]*>\s*$'
    return ind + &shiftwidth
  endif

  " blocks
  if prevline =~# '^\s*\<\(\(else\s\+\)\?if\|for\|while\)\>.*[)]\s*$'
    \ || prevline =~# '^\s*\<\(va[lr]\|def\)\>.*[=]\s*$'
    \ || prevline =~# '^\s*\<else\>\s*$'
    \ || prevline =~# '{\s*$'
    let ind = ind + &shiftwidth
  endif

  " parentheses
  let c = CountParens(prevline)
  if c > 0
    let ind = ind + &shiftwidth
  elseif c < 0
    let ind = ind - &shiftwidth
  endif

  " deindent after if, for, while and val, var, def without block
  let pprevline = getline(prevnonblank(lnum - 1))
  if pprevline =~# '^\s*\<\(\(else\s\+\)\?if\|for\|while\)\>.*[)]\s*$'
    \ || pprevline =~# '^\s*\<\(va[lr]\|def\)\>.*[=]\s*$'
    \ || pprevline =~# '^\s*\<else\>\s*$'
    let ind = ind - &shiftwidth
  endif

  " deindent on '}' or html
  if thisline =~# '^\s*[})]' || thisline =~# '^\s*</[a-zA-Z][^>]*>'
    let ind = ind - &shiftwidth
  endif

  return ind
endfunction
