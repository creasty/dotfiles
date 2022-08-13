let s:max_history_count = 10
let s:last_bufnr = 0
let s:histories = []

function! s:on_enter() abort
  if s:last_bufnr == 0
    return
  endif
  if !empty(&buftype)
    return
  endif

  let l:info = get(getbufinfo(s:last_bufnr), 0, {})
  if empty(l:info)
    return
  endif
  if l:info.hidden || !l:info.loaded
    let s:histories = ([s:last_bufnr] + s:histories)[0 : s:max_history_count - 1]
  endif
endfunction

function! s:on_leave() abort
  if !empty(bufname()) && empty(&buftype)
    let s:last_bufnr = bufnr('')
  endif
endfunction

function! s:restore() abort
  let l:nr = get(s:histories, 0, 0)
  let s:histories = s:histories[1:]

  if l:nr > 0 && bufexists(l:nr)
    exec 'buffer' l:nr
  endif
endfunction

augroup plugin_restore_buffer
  autocmd!
  autocmd BufEnter * call <SID>on_enter()
  autocmd BufLeave * call <SID>on_leave()
augroup END

nnoremap <silent> <Plug>(restore-buffer) <Cmd>call <SID>restore()<CR>

if !get(g:, 'restore_buffer_disable_default_mappings', v:false)
  nmap <C-w>r <Plug>(restore-buffer)
  nmap <C-w><C-r> <Plug>(restore-buffer)
endif
