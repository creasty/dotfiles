let g:easy_align_delimiters = {
  \ '=': {
    \ 'pattern':       '===\|<=>\|=\~[#?]\?\|=>\|[:+/*!%^=><&|.-?]*=[#?]\?'
    \                  . '\|[-=]>\|<[-=]',
    \ 'left_margin':   1,
    \ 'right_margin':  1,
    \ 'stick_to_left': 0,
  \ },
  \ ';': {
    \ 'pattern':       ':',
    \ 'left_margin':   0,
    \ 'right_margin':  1,
    \ 'stick_to_left': 1
  \ },
\ }

vnoremap <silent> L :EasyAlign<cr>
