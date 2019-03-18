let g:lsp_diagnostics_enabled = 1

let g:lsp_signs_error = {'text': '✗'}
let g:lsp_signs_warning = {'text': '∆'}
let g:lsp_signs_information = {'text': '▸'}
let g:lsp_signs_hint = {'text': '▸'}

hi clear LspErrorText
hi clear LspWarningText
hi clear LspInformationText

if exists('*candle#highlight')
  call candle#highlight('LspErrorText', 'red', '', '')
  call candle#highlight('LspWarningText', 'yellow', '', '')
  call candle#highlight('LspInformationText', 'blue', '', '')
endif

"  Hover
"-----------------------------------------------
function! s:hover_under_cursor() abort
  let l:servers = filter(lsp#get_whitelisted_servers(), 'lsp#capabilities#has_hover_provider(v:val)')
  if len(l:servers) == 0
    call lsp#utils#error('Retrieving hover not supported for '. &filetype)
    return
  endif

  for l:server in l:servers
    call lsp#send_request(l:server, {
      \ 'method': 'textDocument/hover',
      \ 'params': {
        \ 'textDocument': lsp#get_text_document_identifier(),
        \ 'position': lsp#get_position(),
      \ },
      \ 'on_notification': function('s:handle_hover', [l:server]),
    \ })
  endfor

  echo 'Retrieving hover ...'
endfunction

function! s:handle_hover(server, data) abort
  if lsp#client#is_error(a:data['response'])
    call lsp#utils#error('Failed to retrieve hover information for ' . a:server)
    return
  endif

  if !has_key(a:data['response'], 'result')
    return
  endif

  if !empty(a:data['response']['result']) && !empty(a:data['response']['result']['contents'])
    call s:echo_hover_result(a:data['response']['result']['contents'])
    return
  else
    call lsp#utils#error('No hover information found')
  endif
endfunction

function! s:echo_hover_result(data) abort
  if type(a:data) == type([])
    call s:echo_hover_result(a:data[0])
  elseif type(a:data) == type('')
    echomsg a:data
  elseif type(a:data) == type({})
    echomsg a:data.value
  endif
endfunction


"  Server status
"-----------------------------------------------
let s:server_status = {}

function! s:server_status_changed(...) abort
  let l:servers = lsp#get_whitelisted_servers()
  if empty(l:servers)
    return
  endif

  let l:info = []

  for l:server in l:servers
    let l:prev = get(s:server_status, l:server, '')
    let l:status = lsp#get_server_status(l:server)

    if l:prev !=# l:status
      let s:server_status[l:server] = l:status
      let l:info += [join([l:server, l:status], ': ')]
    endif
  endfor

  if empty(l:info)
    return
  endif

  echomsg '[vim-lsp]' join(l:info, ', ')
endfunction
function! s:server_status_changed_delay() abort
  call timer_start(500, function('s:server_status_changed'))
endfunction
autocmd vimrc User lsp_setup call <SID>server_status_changed_delay()
autocmd vimrc FileType * call <SID>server_status_changed_delay()
autocmd vimrc User lsp_server_init,lsp_server_exit call <SID>server_status_changed()


"  Notification
"-----------------------------------------------
function! s:on_notification(server_name, data) abort
  " TODO
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
nnoremap gs :call <SID>hover_under_cursor()<CR>


"  Servers
"-----------------------------------------------
function! LspGetRootUriForFile(file) abort
  return lsp#utils#path_to_uri(lsp#utils#find_nearest_parent_file_directory(lsp#utils#get_buffer_path(), a:file))
endfunction

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
"   npm install -g typescript typescript-language-server
if executable('typescript-language-server')
  autocmd vimrc User lsp_setup call lsp#register_server({
    \ 'name': 'typescript-language-server',
    \ 'cmd': {server_info -> [&shell, &shellcmdflag, 'typescript-language-server --stdio']},
    \ 'root_uri': {server_info -> LspGetRootUriForFile('tsconfig.json')},
    \ 'whitelist': ['typescript', 'typescript.tsx'],
  \ })

  autocmd vimrc User lsp_setup call lsp#register_server({
    \ 'name': 'typescript-language-server/javascript',
    \ 'cmd': {server_info -> [&shell, &shellcmdflag, 'typescript-language-server --stdio']},
    \ 'root_uri': {server_info -> LspGetRootUriForFile('package.json')},
    \ 'whitelist': ['javascript', 'javascript.jsx'],
  \ })
endif

" Installation:
"   gem install solargraph
"
" TODO: Bundler
if executable('solargraph')
  autocmd vimrc User lsp_setup call lsp#register_server({
    \ 'name': 'solargraph',
    \ 'cmd': {server_info -> [&shell, &shellcmdflag, 'solargraph stdio']},
    \ 'initialization_options': {'diagnostics': 'true'},
    \ 'whitelist': ['ruby', 'ruby.rspec'],
  \ })
endif

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
    \ 'root_uri': {server_info -> LspGetRootUriForFile('compile_commands.json')},
    \ 'initialization_options': {},
    \ 'whitelist': ['c', 'cpp', 'objc', 'objcpp', 'cc'],
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
