function! user#plugin#textmanip#init() abort
  let g:textmanip_enable_mappings = 0

  let g:textmanip_hooks = {}
  function! g:textmanip_hooks.finish(tm) abort
    let l:tm = a:tm
    let l:helper = textmanip#helper#get()
    if !l:tm.linewise
      call l:helper.remove_trailing_WS(l:tm)
    endif
  endfunction

  xnoremap <SID>(tm) <Nop>
  xnoremap <script> m <SID>(tm)
  xnoremap <script> <SID>(tm)m <SID>(tm)

  xmap <SID>(tm)j <Plug>(textmanip-move-down)<SID>(tm)
  xmap <SID>(tm)k <Plug>(textmanip-move-up)<SID>(tm)
  xmap <SID>(tm)h <Plug>(textmanip-move-left)<SID>(tm)
  xmap <SID>(tm)l <Plug>(textmanip-move-right)<SID>(tm)
  xmap <SID>(tm)J <Plug>(textmanip-duplicate-down)<SID>(tm)
  xmap <SID>(tm)K <Plug>(textmanip-duplicate-up)<SID>(tm)
  xmap <SID>(tm)H <Plug>(textmanip-duplicate-left)<SID>(tm)
  xmap <SID>(tm)L <Plug>(textmanip-duplicate-right)<SID>(tm)
endfunction
