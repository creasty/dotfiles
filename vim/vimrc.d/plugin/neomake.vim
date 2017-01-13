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
  \ 'text':   '▸',
  \ 'texthl': 'NeomakeMessageSign',
\ }

if dein#tap('candle.vim')
  call candle#highlight('NeomakeErrorSign', 'red', '', '')
  call candle#highlight('NeomakeWarningSign', 'yellow', '', '')
  call candle#highlight('NeomakeInfoSign', 'blue', '', '')
  call candle#highlight('NeomakeMessageSign', 'green', '', '')
endif

let g:neomake_ruby_mri_exe = $HOME . '/.anyenv/envs/rbenv/shims/ruby'

autocmd vimrc User AutoSavePost Neomake
autocmd vimrc BufEnter,BufReadPost,BufWritePost,InsertLeave * Neomake
