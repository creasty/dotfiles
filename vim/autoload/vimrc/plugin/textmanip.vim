let g:textmanip_enable_mappings = 0

let g:textmanip_hooks = {}

function! g:textmanip_hooks.finish(tm) abort
  let l:tm = a:tm
  let l:helper = textmanip#helper#get()
  if l:tm.linewise
    " if filetype is `html` automatically indent
    if &filetype ==# 'html'
      call l:helper.indent(l:tm)
    endif
  else
    " When blockwise move/duplicate, remove trailing white space.
    " To use this feature without feeling counterintuitive,
    " I recommend you to ':set virtualedit=block',
    call l:helper.remove_trailing_WS(l:tm)
  endif
endfunction

function! vimrc#plugin#textmanip#init() abort
  " move selection
  xmap <C-j> <Plug>(textmanip-move-down)
  xmap <C-k> <Plug>(textmanip-move-up)
  xmap <C-h> <Plug>(textmanip-move-left)
  xmap <C-l> <Plug>(textmanip-move-right)

  " duplicate line
  xmap <Space><C-j> <Plug>(textmanip-duplicate-down)
  xmap <Space><C-k> <Plug>(textmanip-duplicate-up)
  xmap <Space><C-h> <Plug>(textmanip-duplicate-left)
  xmap <Space><C-l> <Plug>(textmanip-duplicate-right)
endfunction
