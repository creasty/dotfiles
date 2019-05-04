function! s:homepage_for_url(url) abort
  let l:domain_pattern = 'github\.com'
  let l:domains = get(g:, 'github_enterprise_urls', get(g:, 'fugitive_github_domains', []))
  call map(copy(l:domains), 'substitute(v:val, "/$", "", "")')

  for l:domain in l:domains
    let l:domain_pattern .= '\|' . escape(split(l:domain, '://')[-1], '.')
  endfor

  let l:base = matchstr(a:url, '^\%(https\=://\|git://\|git@\|ssh://git@\)\=\zs\(' . l:domain_pattern . '\)[/:].\{-\}\ze\%(\.git\)\=$')

  if index(l:domains, 'http://' . matchstr(l:base, '^[^:/]*')) >= 0
    return 'http://' . tr(l:base, ':', '/')
  elseif !empty(l:base)
    return 'https://' . tr(l:base, ':', '/')
  endif

  return ''
endfunction

function! vimrc#plugin#fugitive#browse_handler(opts, ...) abort
  if a:0 || type(a:opts) != type({})
    return ''
  endif

  let l:root = s:homepage_for_url(get(a:opts, 'remote'))
  if empty(l:root)
    return ''
  endif

  let l:path = substitute(a:opts.path, '^/', '', '')
  if l:path =~# '^\.git/refs/heads/'
    return l:root . '/commits/' . l:path[16:-1]
  elseif l:path =~# '^\.git/refs/tags/'
    return l:root . '/releases/tag/' . l:path[15:-1]
  elseif l:path =~# '^\.git/refs/remotes/[^/]\+/.'
    return l:root . '/commits/' . matchstr(l:path,'remotes/[^/]\+/\zs.*')
  elseif l:path =~# '^\.git/\%(config$\|hooks\>\)'
    return l:root . '/admin'
  elseif l:path =~# '^\.git\>'
    return l:root
  endif

  let l:commit = a:opts.commit
  if l:commit =~# '^\d\=$'
    return ''
  endif

  if get(a:opts, 'type', '') ==# 'tree' || a:opts.path =~# '/$'
    let l:url = substitute(l:root . '/tree/' . l:commit . '/' . l:path, '/$', '', 'g')
  elseif get(a:opts, 'type', '') ==# 'blob' || a:opts.path =~# '[^/]$'
    let l:escaped_commit = substitute(l:commit, '#', '%23', 'g')
    let l:url = l:root . '/blob/' . l:escaped_commit . '/' . l:path
    if get(a:opts, 'line2') && a:opts.line1 == a:opts.line2
      let l:url .= '#L' . a:opts.line1
    elseif get(a:opts, 'line2')
      let l:url .= '#L' . a:opts.line1 . '-L' . a:opts.line2
    endif
  else
    let l:url = l:root . '/commit/' . l:commit
  endif

  return l:url
endfunction

function! vimrc#plugin#fugitive#lazy_init() abort
  if !exists('g:fugitive_browse_handlers')
    let g:fugitive_browse_handlers = []
  endif

  call insert(g:fugitive_browse_handlers, function('vimrc#plugin#fugitive#browse_handler'))
endfunction
