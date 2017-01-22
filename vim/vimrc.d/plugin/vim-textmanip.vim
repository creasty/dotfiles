let g:textmanip_enable_mappings = 0

" move selection
vmap <C-j> <Plug>(textmanip-move-down)
vmap <C-k> <Plug>(textmanip-move-up)
vmap <C-h> <Plug>(textmanip-move-left)
vmap <C-l> <Plug>(textmanip-move-right)

" duplicate line
vmap <Space><C-j> <Plug>(textmanip-duplicate-down)
vmap <Space><C-k> <Plug>(textmanip-duplicate-up)
vmap <Space><C-h> <Plug>(textmanip-duplicate-left)
vmap <Space><C-l> <Plug>(textmanip-duplicate-right)

let g:textmanip_hooks = {}

function! g:textmanip_hooks.finish(tm)
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
