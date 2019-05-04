scriptencoding utf-8

let g:neomake_error_sign = {
  \ 'text':   '✗',
  \ 'texthl': 'NeomakeErrorSign',
\ }
let g:neomake_warning_sign = {
  \ 'text':   '∆',
  \ 'texthl': 'NeomakeWarningSign',
\ }
let g:neomake_info_sign = {
  \ 'text':   '▸',
  \ 'texthl': 'NeomakeInfoSign',
\ }
let g:neomake_message_sign = {
  \ 'text':   '▪︎',
  \ 'texthl': 'NeomakeMessageSign',
\ }

let g:neomake_ruby_mri_exe = $HOME . '/.anyenv/envs/rbenv/shims/ruby'

function! s:neomake(ileave) abort
  if a:ileave
    if !get(b:, 'neomake_run_ileave', 0)
      return
    endif
    let b:neomake_run_ileave = 0
  elseif 'n' !=# mode()
    return
  endif

  if !filereadable(expand('%:p'))
    return
  endif

  Neomake
endfunction

function! vimrc#plugin#neomake#init() abort
  autocmd vimrc User AutoSavePost call <SID>neomake(0)
  autocmd vimrc BufEnter,BufWritePost * call <SID>neomake(0)
  autocmd vimrc InsertEnter * let b:neomake_run_ileave = 0
  autocmd vimrc InsertLeave * let b:neomake_run_ileave = 1
  autocmd vimrc CursorHold * call <SID>neomake(1)

  if g:colors_name ==# 'candle'
    autocmd vimrc BufWinEnter,WinEnter *
     \ call candle#highlight('NeomakeErrorSign', 'red', '', '') |
     \ call candle#highlight('NeomakeWarningSign', 'yellow', '', '') |
     \ call candle#highlight('NeomakeInfoSign', 'blue', '', '') |
     \ call candle#highlight('NeomakeMessageSign', 'green', '', '')
  endif
endfunction
