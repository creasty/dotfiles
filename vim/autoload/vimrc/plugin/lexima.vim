function! vimrc#plugin#lexima#init() abort
endfunction

let g:lexima_map_escape = ''

let s:opfmt_precedence = [
  \ ['||'],
  \ ['&&'],
  \ ['==', '!=', '<', '<=', '>', '>='],
  \ ['+', '-', '|', '^'],
  \ ['*', '/', '%', '<<', '>>', '&', '&^'],
\ ]

let s:opfmt_triggers = [
  \ '*/%<>&' . '+-|^' . '=',
  \ '~' . '?!:',
  \ '$#@\.,' . "'`",
\ ]

let s:opfmt_triggers_all = join(s:opfmt_triggers, '')

function! s:skip_syntactical_context(line, col) abort
  for l:syn in synstack(a:line, a:col)
    let l:name = synIDattr(synIDtrans(l:syn), 'name')
    if l:name =~? '\vreg(ular)?ex|htmltag|jsxelement|string'
      return v:true
    endif
  endfor

  return v:false
endfunction

function! s:skip_last_style(text, i, op) abort
  if a:i == 0
    return v:false
  endif

  if a:text[a:i - 1] ==# a:op
    return v:false
  endif

  let l:pos = strridx(a:text, a:op, a:i - 1)
  if l:pos <= 0
    return v:false
  endif

  let l:left = a:text[l:pos - 1]
  if l:left ==# a:op " repeating
    return v:false
  endif

  return (l:left !=# ' ')
endfunction

function! s:find_chunk_around(text, i) abort
  let l:len = len(a:text)
  let l:range = [a:i, a:i]

  " Left
  let l:space = 0
  let l:i = a:i - 1
  while 0 <= l:i
    let l:c = a:text[l:i]

    if l:space == 2
      break
    endif

    if l:c ==# ' '
      let l:space += 1
    elseif stridx(s:opfmt_triggers_all, l:c) == -1
      break
    endif

    let l:range[0] = l:i
    let l:i -= 1
  endwhile

  " Right
  " let l:space = 0
  let l:i = a:i + 1
  while l:i <= l:len - 1
    let l:c = a:text[l:i]

    if l:space == 2
      break
    endif

    if l:c ==# ' '
      let l:space += 1
    elseif stridx(s:opfmt_triggers_all, l:c) == -1
      break
    endif

    let l:range[1] = l:i
    let l:i += 1
  endwhile

  echomsg [l:range, a:text[l:range[0] : l:range[1]]]
endfunction

function! vimrc#plugin#lexima#opfmt(op) abort
  let l:line = line('.')
  let l:col = col('.')
  let l:text = getline(l:line)

  let l:text = l:text[0 : l:col - 1] . a:op . l:text[l:col :]

  if s:skip_syntactical_context(l:line, l:col)
    return a:op
  endif
  if s:skip_last_style(l:text, l:col, a:op)
    return a:op
  endif

  call s:find_chunk_around(l:text, l:col)

  return a:op
  " return ' ' . a:op . ' '
endfunction

for s:op in split(join(s:opfmt_triggers, ''), '\zs')
  let s:op_char = s:op
  let s:op_char = substitute(s:op_char, '|', '<Bar>', '')
  let s:op_char = substitute(s:op_char, '<', '<lt>', '')
  let s:op_char = substitute(s:op_char, '\', '<Bslash>', '')

  call lexima#add_rule({ 'char': s:op_char, 'input': '<C-r>=vimrc#plugin#lexima#opfmt("' . escape(s:op, '"') . '")<CR>' })
endfor
unlet s:op
unlet s:op_char


"  Comma
"-----------------------------------------------
call lexima#add_rule({ 'char': ',', 'input': "<C-r>=smartchr#loop(', ', ',')<CR>" })

"  Angle brackets
"-----------------------------------------------
call lexima#add_rule({ 'char': '<lt>', 'input_after': '>', 'filetype': ['html', 'eruby', 'slim', 'php', 'xml'] })
call lexima#add_rule({ 'char': '<lt>', 'at': '\\\%#' })
call lexima#add_rule({ 'char': '>', 'at': '[^>]\%#>', 'leave': 1 })
call lexima#add_rule({ 'char': '<BS>', 'at': '<\%#>', 'delete': 1 })
call lexima#add_rule({ 'char': '>', 'at': '< \%#', 'input': '<BS>', 'input_after': '>' })
call lexima#add_rule({ 'char': '<CR>', 'at': '<\%#>', 'input_after': '<CR>' })
call lexima#add_rule({ 'char': '<CR>', 'at': '<\%#$', 'input_after': '<CR>>', 'except': '\C\v^(\s*)\S.*%#\n%(%(\s*|\1\s.+)\n)*\1>' })

"  Arrows
"-----------------------------------------------
" indent on return
call lexima#add_rule({
  \ 'char':  '<CR>',
  \ 'at':    '\(<[-=]\|[-=]>\)\%#',
  \ 'input': '<CR><Tab>',
\ })
call lexima#add_rule({
  \ 'char':  '<CR>',
  \ 'at':    '\(<[-=]\|[-=]>\) \%#',
  \ 'input': '<BS><CR><Tab>',
\ })

"  C-l
"-----------------------------------------------
call lexima#add_rule({ 'char': '<C-l>', 'input': '' })

" transpose charactors before/after cursor
call lexima#add_rule({
  \ 'char':     '<C-l>',
  \ 'at':       '\w\%#\w',
  \ 'input':    '<Esc>"0ylxa<C-r>0<Left>',
  \ 'priority': 10,
\ })

" delete spaces around
call lexima#add_rule({
  \ 'char':  '<C-l>',
  \ 'at':    '\S [+\-\*/%?&|<>=]\+ \%#',
  \ 'input': '<Esc>bh"_xf<Space>"_cl',
\ })
call lexima#add_rule({
  \ 'char':  '<C-l>',
  \ 'at':    '\S [+\-\*/%?&|<>=]\+\%#',
  \ 'input': '<Space><Esc>bh"_xf<Space>"_cl',
\ })
call lexima#add_rule({
  \ 'char':  '<C-l>',
  \ 'at':    '\S[+\-\*/%?&|<>=]\+ \%#',
  \ 'input': '<BS>',
\ })

" nesting
for s:pa in ['()', '[]', '{}']
  call lexima#add_rule({
    \ 'char':     '<C-l>',
    \ 'at':       escape(s:pa[1], '[]') . '\%#',
    \ 'input':    '<Esc>%i' . s:pa[0] . '<Esc><Right>%a' . s:pa[1],
    \ 'priority': 10,
  \ })
  call lexima#add_rule({
    \ 'char':     '<C-l>',
    \ 'at':       '\%#' . escape(s:pa[1], '[]'),
    \ 'input':    '<Esc><Right>%i' . s:pa[0] . '<Esc><Right>%i' . s:pa[1],
    \ 'priority': 10,
  \ })
endfor
unlet s:pa

" tag close
call lexima#add_rule({
  \ 'char':  '<C-l>',
  \ 'at':    '<[a-zA-Z0-9_-]\+[^>]*>\%#',
  \ 'input': '<Esc>F<<Right>"xyiwf>a</><Esc><Left>"xpF<i',
\ })

" go channel
call lexima#add_rule({
  \ 'char':     '<C-l>',
  \ 'at':       '\(chan\|<-chan\|chan<-\)\%#',
  \ 'input':    "<C-r>=smartchr#loop('chan', '<-chan', 'chan<-')<CR>",
  \ 'filetype': ['go'],
\ })

"  Ruby
"-----------------------------------------------
" lambda
call lexima#add_rule({
  \ 'char':        '(',
  \ 'at':          '?->\%#',
  \ 'input':       '(',
  \ 'input_after': ')',
  \ 'filetype':    ['ruby', 'ruby.rspec'],
\ })
call lexima#add_rule({
  \ 'char':        '(',
  \ 'at':          '?-> \%#',
  \ 'input':       '<BS>(',
  \ 'input_after': ')',
  \ 'filetype':    ['ruby', 'ruby.rspec'],
\ })

"  Html
"-----------------------------------------------
" attributes
call lexima#add_rule({
  \ 'char':        '=',
  \ 'at':          '\w\+\%#',
  \ 'input':       '="',
  \ 'input_after': '"',
  \ 'syntax':      ['htmlArg'],
\ })

" entity
call lexima#add_rule({
  \ 'char':        '&',
  \ 'at':          '\%#',
  \ 'input':       '&',
  \ 'input_after': ';',
  \ 'filetype':    ['html', 'eruby', 'slim', 'php', 'xml'],
\ })

" comment
call lexima#add_rule({
  \ 'char':        '-',
  \ 'at':          '<\%#>',
  \ 'input':       '!-- ',
  \ 'input_after': ' --',
  \ 'filetype':    ['html', 'eruby', 'slim', 'php', 'xml'],
\ })

" server script
call lexima#add_rule({
  \ 'char':        '%',
  \ 'at':          '<\%#>',
  \ 'input':       '% ',
  \ 'input_after': ' %',
  \ 'filetype':    ['html', 'ejs', 'eruby'],
\ })
call lexima#add_rule({
  \ 'char':     '%',
  \ 'at':       '<%[=-]\? \%# %>',
  \ 'input':    "<C-r>=smartchr#loop('% ', '%= ', '%- ')<CR>",
  \ 'filetype': ['html', 'ejs', 'eruby'],
\ })

" program block
call lexima#add_rule({
  \ 'char':     '=',
  \ 'at':       '^\s*\([.#%]\(\w\|-\)\+\)*\%#',
  \ 'input':    '= ',
  \ 'filetype': ['haml', 'slim'],
\ })

"  Command mode
"-----------------------------------------------
" write a file as sudo :w!!
call lexima#add_rule({
  \ 'char':  '!',
  \ 'at':    '^w!\%#',
  \ 'input': "\<C-u>w !sudo tee % > /dev/null",
  \ 'mode':  ':',
\ })

" edit relative :ee
call lexima#add_rule({
  \ 'char':  'e',
  \ 'at':    '^e\%#',
  \ 'input': " \<C-r>=expand('%:p:h') . '/' \<CR>",
  \ 'mode':  ':',
\ })

" edit file :ef
call lexima#add_rule({
  \ 'char':  'f',
  \ 'at':    '^e\%#',
  \ 'input': " \<C-r>=expand('%:p')\<CR>",
  \ 'mode':  ':',
\ })

" directory shortcuts
let s:directories = {
  \ 'h': '~/',
  \ 'g': '~/go/src/github.com/',
\ }
for [s:shortcut, s:directory] in items(s:directories)
  call lexima#add_rule({
    \ 'char':  s:shortcut,
    \ 'at':    '^e\%#',
    \ 'input': ' ' . s:directory,
    \ 'mode':  ':',
  \ })
endfor
unlet s:directories
unlet s:shortcut
unlet s:directory

" edit buffer :eb
call lexima#add_rule({
  \ 'char':  'b',
  \ 'at':    '^e\%#',
  \ 'input': ' #',
  \ 'mode':  ':',
\ })

" rename :er
call lexima#add_rule({
  \ 'char':  'r',
  \ 'at':    '^e\%#',
  \ 'input': "\<C-u>Rename \<C-r>=expand('%:p') \<CR>",
  \ 'mode':  ':',
\ })

" font
call lexima#add_rule({
  \ 'char':  '<Space>',
  \ 'at':    '^font\%#',
  \ 'input': "\<C-u>Font ",
  \ 'mode':  ':',
\ })
