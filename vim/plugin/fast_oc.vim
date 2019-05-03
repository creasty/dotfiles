if exists('g:loaded_fast_oc') || v:version < 702
  finish
endif
let g:loaded_fast_oc = 1

let s:save_cpo = &cpoptions
set cpoptions&vim

function! s:insert_enter() abort
  set eventignore+=InsertLeave,InsertEnter
  return ''
endfunction

function! s:insert_leave() abort
  set eventignore-=InsertLeave,InsertEnter
  return ''
endfunction

inoremap <expr> <Plug>(insert-enter) <SID>insert_enter()
inoremap <expr> <Plug>(insert-leave) <SID>insert_leave()

let &cpoptions = s:save_cpo
unlet s:save_cpo
