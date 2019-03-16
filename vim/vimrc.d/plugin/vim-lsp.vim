" let g:lsp_log_verbose = 1
" let g:lsp_log_file = expand('~/vim-lsp.log')

let g:lsp_diagnostics_enabled = 0 " TODO

let g:lsp_signs_error = {'text': '✗'}
let g:lsp_signs_warning = {'text': '∆'}
let g:lsp_signs_hint = {'text': '▸'}

hi clear LspErrorText
hi clear LspWarningText
hi clear LspInformationText

if dein#tap('candle.vim')
  call candle#highlight('LspErrorText', 'red', '', '')
  call candle#highlight('LspWarningText', 'yellow', '', '')
  call candle#highlight('LspInformationText', 'blue', '', '')
endif

if executable('gopls')
  autocmd vimrc User lsp_setup call lsp#register_server({
    \ 'name': 'gopls',
    \ 'cmd': {server_info->[&shell, &shellcmdflag, 'gopls -mode stdio']},
    \ 'whitelist': ['go']
  \ })
  autocmd vimrc FileType go
    \ nnoremap <buffer> <silent> <C-]> :LspDefinition<CR>
endif
