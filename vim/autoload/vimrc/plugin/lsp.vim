scriptencoding utf-8

let g:lsp_diagnostics_enabled = 1
let g:lsp_diagnostics_echo_cursor = 1
let g:lsp_diagnostics_echo_delay = 300
let g:lsp_use_event_queue = 1

let g:lsp_signs_error = {'text': '✗'}
let g:lsp_signs_warning = {'text': '∆'}
let g:lsp_signs_information = {'text': '▸'}
let g:lsp_signs_hint = {'text': '▪︎'}

function! vimrc#plugin#lsp#init() abort
  hi clear LspErrorText
  hi clear LspWarningText
  hi clear LspInformationText
  hi clear LspHintText

  if g:colors_name ==# 'candle'
    autocmd vimrc BufWinEnter,WinEnter *
      \ call candle#highlight('LspErrorText', 'red', '', '') |
      \ call candle#highlight('LspWarningText', 'yellow', '', '') |
      \ call candle#highlight('LspInformationText', 'blue', '', '') |
      \ call candle#highlight('LspHintText', 'green', '', '')
  endif

  " server status
  autocmd vimrc User lsp_setup call vimrc#plugin#lsp#util#server_status_changed(1)
  autocmd vimrc FileType * call vimrc#plugin#lsp#util#server_status_changed(1)
  autocmd vimrc User lsp_server_init,lsp_server_exit call vimrc#plugin#lsp#util#server_status_changed(0)
endfunction


"  Notification
"-----------------------------------------------
function! s:on_notification(server_name, data) abort
  let l:response = a:data['response']

  if lsp#client#is_server_instantiated_notification(a:data)
    if has_key(l:response, 'method')
      if l:response['method'] ==# 'textDocument/publishDiagnostics'
        call vimrc#plugin#lsp#util#handle_diagnostics(a:server_name, a:data)
      endif
    endif
  endif
endfunction
call lsp#register_notifications('vimrc:on_notification', function('s:on_notification'))


"  Mode
"-----------------------------------------------
command! LspLogEnable
  \ let g:lsp_log_verbose = 1
  \| let g:lsp_log_file = expand('~/vim-lsp.log')

command! LspLogDisable
  \ let g:lsp_log_verbose = 0
  \| let g:lsp_log_file = ''

nnoremap gd :LspDefinition<CR>
nnoremap gh :LspHover<CR>
nnoremap gs :call vimrc#plugin#lsp#util#hover_under_cursor()<CR>


"  Servers
"-----------------------------------------------
" Installation:
"   go get -u golang.org/x/tools/cmd/gopls
"   go get -u github.com/sourcegraph/go-langserver
if executable('go-langserver')
  " TODO: replace with 'gopls -mode stdio'
  autocmd vimrc User lsp_setup call lsp#register_server({
    \ 'name': 'go-langserver',
    \ 'cmd': {server_info -> [&shell, &shellcmdflag, 'go-langserver -gocodecompletion']},
    \ 'whitelist': ['go'],
  \ })
endif

" Installation:
"   rustup update
"   rustup component add rls rust-analysis rust-src
if executable('rls')
  autocmd vimrc User lsp_setup call lsp#register_server({
    \ 'name': 'rls',
    \ 'cmd': {server_info -> [&shell, &shellcmdflag, 'rustup run stable rls']},
    \ 'whitelist': ['rust'],
  \ })
endif

" Installation:
"   gem install solargraph
"
" TODO: Bundler
" if executable('solargraph')
"   autocmd vimrc User lsp_setup call lsp#register_server({
"     \ 'name': 'solargraph',
"     \ 'cmd': {server_info -> [&shell, &shellcmdflag, 'solargraph stdio']},
"     \ 'initialization_options': {'diagnostics': 'true'},
"     \ 'whitelist': ['ruby', 'ruby.rspec'],
"   \ })
" endif

" Installation:
"   pip install python-language-server
if executable('pyls')
  autocmd vimrc User lsp_setup call lsp#register_server({
    \ 'name': 'pyls',
    \ 'cmd': {server_info -> [&shell, &shellcmdflag, 'pyls']},
    \ 'whitelist': ['python'],
  \ })
endif

" Installation:
"   https://github.com/MaskRay/ccls/wiki
if executable('ccls')
  autocmd vimrc User lsp_setup call lsp#register_server({
    \ 'name': 'ccls',
    \ 'cmd': {server_info -> [&shell, &shellcmdflag, 'ccls']},
    \ 'root_uri': {server_info -> vimrc#plugin#lsp#util#find_root_uri('compile_commands.json')},
    \ 'initialization_options': {},
    \ 'whitelist': ['c', 'cpp', 'objc', 'objcpp', 'cc'],
  \ })
endif

" Installation:
"   npm install -g typescript typescript-language-server
"   npm install -g typescript-styled-plugin
if executable('typescript-language-server')
  autocmd vimrc User lsp_setup call lsp#register_server({
    \ 'name': 'typescript-language-server',
    \ 'cmd': {server_info -> [&shell, &shellcmdflag, 'typescript-language-server --stdio']},
    \ 'root_uri': {server_info -> vimrc#plugin#lsp#util#find_root_uri('tsconfig.json')},
    \ 'whitelist': ['typescript', 'typescript.tsx'],
  \ })

  autocmd vimrc User lsp_setup call lsp#register_server({
    \ 'name': 'typescript-language-server/javascript',
    \ 'cmd': {server_info -> [&shell, &shellcmdflag, 'typescript-language-server --stdio']},
    \ 'root_uri': {server_info -> vimrc#plugin#lsp#util#find_root_uri('package.json')},
    \ 'whitelist': ['javascript', 'javascript.jsx'],
  \ })
endif

" Installation:
"   npm install -g vscode-css-languageserver-bin
if executable('css-languageserver')
  autocmd vimrc User lsp_setup call lsp#register_server({
    \ 'name': 'css-languageserver',
    \ 'cmd': {server_info -> [&shell, &shellcmdflag, 'css-languageserver --stdio']},
    \ 'whitelist': ['css', 'sass', 'scss'],
  \ })
endif
