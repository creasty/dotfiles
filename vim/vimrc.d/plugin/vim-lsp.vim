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

function! s:activate_lsp_mode() abort
  nnoremap <buffer> <silent> <C-]> :LspDefinition<CR>
endfunction

if executable('gopls')
  autocmd vimrc User lsp_setup call lsp#register_server({
    \ 'name': 'gopls',
    \ 'cmd': {server_info->[&shell, &shellcmdflag, 'gopls -mode stdio']},
    \ 'whitelist': ['go'],
  \ })
  autocmd vimrc FileType go call s:activate_lsp_mode()
endif

if executable('typescript-language-server')
  autocmd vimrc User lsp_setup call lsp#register_server({
    \ 'name': 'typescript-language-server',
    \ 'cmd': {server_info->[&shell, &shellcmdflag, 'typescript-language-server --stdio']},
    \ 'root_uri': {server_info->lsp#utils#path_to_uri(lsp#utils#find_nearest_parent_file_directory(lsp#utils#get_buffer_path(), 'tsconfig.json'))},
    \ 'whitelist': ['typescript', 'typescript.tsx'],
  \ })
  autocmd vimrc User lsp_setup call lsp#register_server({
    \ 'name': 'javascript support using typescript-language-server',
    \ 'cmd': {server_info->[&shell, &shellcmdflag, 'typescript-language-server --stdio']},
    \ 'root_uri': {server_info->lsp#utils#path_to_uri(lsp#utils#find_nearest_parent_file_directory(lsp#utils#get_buffer_path(), 'package.json'))},
    \ 'whitelist': ['javascript', 'javascript.jsx'],
    \ })
  autocmd vimrc FileType typescript,typescript.tsx,javascript,javascript.jsx call s:activate_lsp_mode()
endif

if executable('solargraph')
  autocmd vimrc User lsp_setup call lsp#register_server({
    \ 'name': 'solargraph',
    \ 'cmd': {server_info->[&shell, &shellcmdflag, 'solargraph stdio']},
    \ 'initialization_options': {'diagnostics': 'true'},
    \ 'whitelist': ['ruby'],
  \ })
  autocmd vimrc FileType ruby,ruby.rspec call s:activate_lsp_mode()
endif

if executable('pyls')
  autocmd vimrc User lsp_setup call lsp#register_server({
    \ 'name': 'pyls',
    \ 'cmd': {server_info->['pyls']},
    \ 'whitelist': ['python'],
  \ })
  autocmd vimrc FileType python call s:activate_lsp_mode()
endif
