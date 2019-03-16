let g:lsp_auto_enable = 1
let g:lsp_log_verbose = 1
let g:lsp_log_file = expand('~/vim-lsp.log')

if executable('gopls')
  autocmd vimrc User lsp_setup call lsp#register_server({
    \ 'name': 'gopls',
    \ 'cmd': {server_info->[&shell, &shellcmdflag, 'gopls -mode stdio']},
    \ 'whitelist': ['go']
  \ })
  autocmd vimrc FileType go
    \ nnoremap <buffer> <silent> <C-]> :LspDefinition<CR>
endif
