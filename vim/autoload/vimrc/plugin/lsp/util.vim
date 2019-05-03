"  Hover
"-----------------------------------------------
function! vimrc#plugin#lsp#util#hover_under_cursor() abort
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

function! vimrc#plugin#lsp#util#server_status_changed(delay) abort
  if a:delay == 1
    call timer_start(500, function('s:server_status_changed'))
  else
    call s:server_status_changed()
  endif
endfunction


"  Diagnostics
"-----------------------------------------------
let s:severity_enum = {
  \ 1: 'E',
  \ 2: 'W',
  \ 3: 'I',
  \ 4: 'H',
\ }

function! vimrc#plugin#lsp#util#handle_diagnostics(server_name, data) abort
  if lsp#client#is_error(a:data['response'])
    return
  endif

  let l:uri = a:data['response']['params']['uri']
  let l:diagnostics = a:data['response']['params']['diagnostics']

  let l:path = lsp#utils#uri_to_path(l:uri)
  let l:bufnr = bufnr(l:path)

  if l:bufnr < 0
    return
  endif

  let l:count = {}
  for l:item in items(s:severity_enum)
    let l:count[l:item[1]] = 0
  endfor

  for l:item in l:diagnostics
    if has_key(l:item, 'severity') && !empty(l:item['severity'])
      let l:count[s:severity_enum[l:item['severity']]] += 1
    endif
  endfor

  call setbufvar(l:bufnr, 'vim_lsp_diagnostics', l:count)
endfunction


"  Helpers
"-----------------------------------------------
function! vimrc#plugin#lsp#util#find_root_uri(file) abort
  return lsp#utils#path_to_uri(lsp#utils#find_nearest_parent_file_directory(lsp#utils#get_buffer_path(), a:file))
endfunction
