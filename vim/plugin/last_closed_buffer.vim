if exists('g:loaded_last_closed_buffer') || v:version < 702
  finish
endif
let g:loaded_last_closed_buffer = 1

let s:save_cpo = &cpoptions
set cpoptions&vim

let g:lcb_max_restore_count = 5

let g:lcb_current = 0
let g:lcb_leaved  = 0
let g:lcb_closed  = []

function! s:lcb_remember_on_enter() abort
  let g:lcb_current = bufnr('')

  if g:lcb_leaved > 0 && !bufloaded(g:lcb_leaved)
    let g:lcb_closed = ([g:lcb_leaved] + g:lcb_closed)[0 : g:lcb_max_restore_count - 1]
  endif
endfunction

function! s:lcb_remember_on_leave() abort
  if g:lcb_current > 0 && !empty(bufname(g:lcb_current))
    let g:lcb_leaved = g:lcb_current
  endif
endfunction

function! s:lcb_restore() abort
  let l:nr = get(g:lcb_closed, 0, 0)
  let g:lcb_closed = g:lcb_closed[1:]

  if l:nr > 0 && bufexists(l:nr)
    exec 'buffer' l:nr
  endif
endfunction

augroup last_closed_buffer
  autocmd!
  autocmd vimrc BufEnter * call <SID>lcb_remember_on_enter()
  autocmd vimrc BufLeave * call <SID>lcb_remember_on_leave()
augroup END

nnoremap <silent> <Plug>(lcb-restore) :call <SID>lcb_restore()<CR>

let &cpoptions = s:save_cpo
unlet s:save_cpo
