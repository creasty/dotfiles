" let g:lsp_log_verbose = 1
" let g:lsp_log_file = expand('~/vim-lsp.log')

let g:lsp_diagnostics_enabled = 1 " TODO

let g:lsp_signs_error = {'text': '✗'}
let g:lsp_signs_warning = {'text': '∆'}
let g:lsp_signs_information = {'text': '▸'}
let g:lsp_signs_hint = {'text': '▸'}

hi clear LspErrorText
hi clear LspWarningText
hi clear LspInformationText

if dein#tap('candle.vim')
  call candle#highlight('LspErrorText', 'red', '', '')
  call candle#highlight('LspWarningText', 'yellow', '', '')
  call candle#highlight('LspInformationText', 'blue', '', '')
endif

"  Hover
"-----------------------------------------------
function! s:get_servers() abort
  let l:servers = filter(lsp#get_whitelisted_servers(), 'lsp#capabilities#has_hover_provider(v:val)')

  if len(l:servers) == 0
    call lsp#utils#error('Retrieving hover not supported for '. &filetype)
  endif

  return l:servers
endfunction

function! s:hover_under_cursor() abort
  let l:servers = s:get_servers()
  if len(l:servers) == 0
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
    for l:entry in a:data
      call s:echo_hover_result(l:entry)
    endfor
  elseif type(a:data) == type('')
    echomsg a:data
  elseif type(a:data) == type({})
    echomsg a:data.value
  endif
endfunction


"  Mode
"-----------------------------------------------
nnoremap gd :LspDefinition<CR>
nnoremap gh :call <SID>hover_under_cursor()<CR>


"  Servers
"-----------------------------------------------
if executable('go-langserver')
  " TODO: replace with 'gopls -mode stdio'
  autocmd vimrc User lsp_setup call lsp#register_server({
    \ 'name': 'go-langserver',
    \ 'cmd': {server_info->[&shell, &shellcmdflag, 'go-langserver -gocodecompletion']},
    \ 'whitelist': ['go'],
  \ })
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
endif

if executable('solargraph')
  autocmd vimrc User lsp_setup call lsp#register_server({
    \ 'name': 'solargraph',
    \ 'cmd': {server_info->[&shell, &shellcmdflag, 'solargraph stdio']},
    \ 'initialization_options': {'diagnostics': 'true'},
    \ 'whitelist': ['ruby', 'ruby.rspec'],
  \ })
endif

if executable('pyls')
  autocmd vimrc User lsp_setup call lsp#register_server({
    \ 'name': 'pyls',
    \ 'cmd': {server_info->[&shell, &shellcmdflag, 'pyls']},
    \ 'whitelist': ['python'],
  \ })
endif

if executable('ccls')
  autocmd vimrc User lsp_setup call lsp#register_server({
    \ 'name': 'ccls',
    \ 'cmd': {server_info->['ccls']},
    \ 'root_uri': {server_info->lsp#utils#path_to_uri(lsp#utils#find_nearest_parent_file_directory(lsp#utils#get_buffer_path(), 'compile_commands.json'))},
    \ 'initialization_options': {},
    \ 'whitelist': ['c', 'cpp', 'objc', 'objcpp', 'cc'],
  \ })
endif
