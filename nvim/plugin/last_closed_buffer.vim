if exists('g:loaded_last_closed_buffer') || v:version < 702
  finish
endif
let g:loaded_last_closed_buffer = 1

let s:save_cpo = &cpoptions
set cpoptions&vim

let g:lcb_max_restore_count = 5
let g:lcb_leaved = 0
let g:lcb_closed = []

function! s:on_enter() abort
  if g:lcb_leaved == 0
    return
  endif
  if !empty(&buftype)
    return
  endif

  let l:info = get(getbufinfo(g:lcb_leaved), 0, {})
  if empty(&info)
    return
  endif
  if l:info.hidden || !l:info.loaded
    let g:lcb_closed = ([g:lcb_leaved] + g:lcb_closed)[0 : g:lcb_max_restore_count - 1]
  endif
endfunction

function! s:on_leave() abort
  if !empty(bufname()) && empty(&buftype)
    let g:lcb_leaved = bufnr('')
  endif
endfunction

function! s:restore() abort
  let l:nr = get(g:lcb_closed, 0, 0)
  let g:lcb_closed = g:lcb_closed[1:]

  if l:nr > 0 && bufexists(l:nr)
    exec 'buffer' l:nr
  endif
endfunction

augroup last_closed_buffer
  autocmd!
  autocmd BufEnter * call <SID>on_enter()
  autocmd BufLeave * call <SID>on_leave()
augroup END

nnoremap <silent> <Plug>(lcb-restore) <Cmd>call <SID>restore()<CR>

if !get(g:, 'last_closed_buffer_no_mappings', v:false)
  nmap <C-w>r <Plug>(lcb-restore)
  nmap <C-w><C-r> <Plug>(lcb-restore)
endif

let &cpoptions = s:save_cpo
unlet s:save_cpo
