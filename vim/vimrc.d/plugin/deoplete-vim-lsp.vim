if executable('gopls')
  autocmd vimrc User lsp_setup call lsp#register_server({
    \ 'name': 'gopls',
    \ 'cmd': {server_info->['gopls', '-mode', 'stdio']},
    \ 'whitelist': ['go']
  \ })
  autocmd vimrc FileType go
    \ nnoremap <buffer> <silent> <C-]> :LspDefinition<CR>
endif
