"  Disable lexima inside string literal
"-----------------------------------------------
function! vimrc#plugin#lexima#util#disable_inside_string(char) abort
  call lexima#add_rule({
    \ 'char':  a:char,
    \ 'at':    '^\([^"]*"[^"]*"\)*[^"]*"[^"]*\%#',
    \ 'input': a:char,
  \ })
  call lexima#add_rule({
    \ 'char':  a:char,
    \ 'at':    '^\([^'']*''[^'']*''\)*[^'']*''[^'']*\%#',
    \ 'input': a:char,
  \ })
  call lexima#add_rule({
    \ 'char':  a:char,
    \ 'at':    '\%#',
    \ 'input': a:char,
    \ 'syntax': ['String'],
  \ })
endfunction

function! vimrc#plugin#lexima#util#disable_inside_regexp(char) abort
  call lexima#add_rule({
    \ 'char':  a:char,
    \ 'at':    '\(...........\)\?/\S.*\%#.*\S/',
    \ 'input': a:char,
  \ })
endfunction

"  Expanders
"-----------------------------------------------
function! vimrc#plugin#lexima#util#expand_markdown_headering(char) abort
  let l:text = getline(line('.') - 1)

  if l:text =~# '^\(\t\|  \)*[-=]\s'
    return a:char . ' '
  else
    return repeat(a:char, strwidth(l:text))
  endif
endfunction

function! vimrc#plugin#lexima#util#expand_section(trigger, token, leader, line, width) abort
  let l:line = getline(line('.'))
  let l:m = matchlist(l:line, '^\(\s*\)' . a:trigger . '\s*\(.*\)')

  if empty(l:m)
    return
  endif

  let l:indent = get(l:m, 1, '')
  let l:text = get(l:m, 2, '')

  let l:cursor = '<vim:expand_section_header:cursor>'
  let l:lines = ['', '']

  let l:lines[0] = l:indent . a:token . a:leader . l:text . l:cursor
  let l:lines[1] = l:indent . a:token . repeat(a:line, a:width)

  call setline('.', l:lines[0])
  call append(line('.'), l:lines[1])

  if search(l:cursor)
    execute 'normal! "_da>'
  end
endfunction
