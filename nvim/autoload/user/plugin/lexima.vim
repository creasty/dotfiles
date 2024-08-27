let s:js_filetypes = ['javascript', 'typescript', 'javascriptreact', 'typescriptreact']

function! user#plugin#lexima#init() abort
  doautocmd User PluginLeximaPostInit
endfunction

function! user#plugin#lexima#loop(...) abort
  let l:literals = a:000 + [a:000[0]]

  for l:i in range(len(l:literals) - 1, 1, -1)
    let l:l1 = l:literals[l:i]
    let l:l2 = l:literals[l:i - 1]

    if search('\V' . escape(l:l2, '\') . '\%#', 'bcn')
      return (pumvisible() ? "\<C-e>" : '')
        \ . repeat("\<BS>", strchars(l:l2))
        \ . l:l1
    endif
  endfor

  return l:literals[0]
endfunction

"  CR
"-----------------------------------------------
" indent on after =>
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

" JavaScript: arrow function brackets
call lexima#add_rule({
  \ 'char':     '<CR>',
  \ 'at':       '=>\%#',
  \ 'input':    '<Space>{}<Left><CR>',
  \ 'filetype': s:js_filetypes,
\ })
call lexima#add_rule({
  \ 'char':     '<CR>',
  \ 'at':       '=> \%#',
  \ 'input':    '{}<Left><CR>',
  \ 'filetype': s:js_filetypes,
\ })

"  C-l
"-----------------------------------------------
call lexima#add_rule({ 'char': '<C-l>', 'input': '' })

" tag close
call lexima#add_rule({
  \ 'char':          '<C-l>',
  \ 'at':            '<\([a-zA-Z0-9_.-]\+\)[^>/]*>\%#',
  \ 'input':         '',
  \ 'input_after':   '</\1>',
  \ 'with_submatch': 1,
\ })
call lexima#add_rule({
  \ 'char':  '<C-l>',
  \ 'at':    '<\([a-zA-Z0-9_.-]\+\)[^>]*>\%#</\1>',
  \ 'input': '<Esc>cf> />',
\ })
call lexima#add_rule({
  \ 'char':          '<C-l>',
  \ 'at':            '<\([a-zA-Z0-9_.-]\+\) />\%#',
  \ 'input':         '<BS><BS><BS>>',
  \ 'input_after':   '</\1>',
  \ 'with_submatch': 1,
\ })

" Golang: channel
call lexima#add_rule({
  \ 'char':     '<C-l>',
  \ 'at':       '\(chan\|<-chan\|chan<-\)\%#',
  \ 'input':    "<C-r>=user#plugin#lexima#loop('chan', '<-chan', 'chan<-')<CR>",
  \ 'filetype': ['go'],
\ })

"  Angle brackets
"-----------------------------------------------
call lexima#add_rule({ 'char': '<lt>', 'input_after': '>', 'filetype': ['html', 'eruby', 'xml', 'markdown'] })
call lexima#add_rule({ 'char': '<lt>', 'at': '\\\%#' })
call lexima#add_rule({ 'char': '>', 'at': '[^>]\%#>', 'leave': 1 })
call lexima#add_rule({ 'char': '<BS>', 'at': '<\%#>', 'delete': 1 })
call lexima#add_rule({ 'char': '>', 'at': '< \%#', 'input': '<BS>', 'input_after': '>' })
call lexima#add_rule({ 'char': '>', 'at': '< \%#\S', 'input': '<BS>', 'input_after': '><Space>' })
call lexima#add_rule({ 'char': '<CR>', 'at': '<\%#>', 'input_after': '<CR>' })
call lexima#add_rule({ 'char': '<CR>', 'at': '<\%#$', 'input_after': '<CR>>', 'except': '\C\v^(\s*)\S.*%#\n%(%(\s*|\1\s.+)\n)*\1>' })
call lexima#add_rule({ 'char': '<Space>', 'at': '<\%#>', 'leave': 1 })
call lexima#add_rule({ 'char': '<Space>', 'at': ' <\%#>', 'delete': 1, 'input': '><Space>' })

"  Ruby: block params
"-----------------------------------------------
call lexima#add_rule({
  \ 'char':        '<Bar>',
  \ 'at':          '\({\|do\)\s*\%#',
  \ 'input':       '<Bar>',
  \ 'input_after': '<Bar>',
  \ 'filetype':    ['ruby', 'ruby.rspec'],
\ })
call lexima#add_rule({
  \ 'char':     '<Bar>',
  \ 'at':       '\({\|do\)\s*|[^|]*\%#|',
  \ 'leave':    1,
  \ 'filetype': ['ruby', 'ruby.rspec'],
\ })

"  Doc
"-----------------------------------------------
call lexima#add_rule({
  \ 'char':  '/',
  \ 'at':    '\*\s\%#',
  \ 'input': '<BS>/',
\ })

"  Commands
"-----------------------------------------------
" Visual selection range '<,'>
call lexima#add_rule({
  \ 'char':  "'",
  \ 'at':    '^\%#',
  \ 'input': "'<,'>",
  \ 'mode':  ':',
\ })

" :w!! -- sudo write
call lexima#add_rule({
  \ 'char':  '!',
  \ 'at':    '^w!\%#',
  \ 'input': "\<C-u>w !sudo tee % > /dev/null",
  \ 'mode':  ':',
\ })

" :ee -- edit relative
call lexima#add_rule({
  \ 'char':  'e',
  \ 'at':    '^e\%#',
  \ 'input': " \<C-r>=fnameescape(expand('%:p:h')) . '/' \<CR>",
  \ 'mode':  ':',
\ })

" :ef -- edit file
call lexima#add_rule({
  \ 'char':  'f',
  \ 'at':    '^e\%#',
  \ 'input': " \<C-r>=fnameescape(expand('%:p'))\<CR>",
  \ 'mode':  ':',
\ })

" directory shortcuts
" :eh -- home
" :eg -- github
" :ev -- vim runtime
let s:directories = {
  \ 'h': '~',
  \ 'g': '~/go/src/github.com',
  \ 'v': $VIMRUNTIME,
\ }
for [s:shortcut, s:directory] in items(s:directories)
  call lexima#add_rule({ 'char': s:shortcut, 'at': '^e\%#', 'input': ' ' . s:directory . '/' , 'mode': ':' })
endfor
unlet s:directories
unlet s:shortcut
unlet s:directory

" :er -- rename
call lexima#add_rule({
  \ 'char':  'r',
  \ 'at':    '^e\%#',
  \ 'input': "\<C-u>Rename \<C-r>=fnameescape(expand('%:p'))\<CR>",
  \ 'mode':  ':',
\ })

" substitute commands
for s:del in ['/', '~', '!', '@', '#', '%', ':']
  " :s -- Standard substitute
  call lexima#add_rule({
    \ 'char':        s:del,
    \ 'at':          '^\(%\|' . "'<,'>" . '\)\?s\%#',
    \ 'input':       s:del . '\v',
    \ 'input_after': s:del . s:del . 'g',
    \ 'mode':        ':',
  \ })

  " :sc -- Case sensitive substitute
  call lexima#add_rule({
    \ 'char':        s:del,
    \ 'at':          '^\(%\|' . "'<,'>" . '\)\?sc\%#',
    \ 'input':       '<BS>' . s:del . '\C\v',
    \ 'input_after': s:del . s:del . 'g',
    \ 'mode':        ':',
  \ })

  " :si -- Case insensitive substitute
  call lexima#add_rule({
    \ 'char':        s:del,
    \ 'at':          '^\(%\|' . "'<,'>" . '\)\?si\%#',
    \ 'input':       '<BS>' . s:del . '\c\v',
    \ 'input_after': s:del . s:del . 'g',
    \ 'mode':        ':',
  \ })

  " :sm -- Match-case substitute
  " Depends on keepcase.vim
  call lexima#add_rule({
    \ 'char':        s:del,
    \ 'at':          '^\(%\|' . "'<,'>" . '\)\?sm\%#',
    \ 'input':       '<BS><BS>SubstituteCase' . s:del . '\v\c',
    \ 'input_after': s:del . s:del . 'g',
    \ 'mode':        ':',
  \ })
endfor
unlet s:del

" auto escape chars in search commands
for s:del in ['/', '?']
  call lexima#add_rule({ 'char': s:del, 'at': '\\\%#', 'input': s:del, 'mode': s:del })
  call lexima#add_rule({ 'char': s:del, 'at': '\%#', 'input': '\' . s:del, 'mode': s:del })
endfor
unlet s:del
