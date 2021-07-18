function! s:homepage_for_url(url) abort
  let l:domain_pattern = 'github\.com'
  let l:domains = get(g:, 'github_enterprise_urls', get(g:, 'fugitive_github_domains', []))

  for l:domain in l:domains
    let l:domain_pattern .= '\|' . escape(split(substitute(l:domain, '/$', '', ''), '://')[-1], '.')
  endfor

  let l:base = matchstr(a:url, '^\%(https\=://\%([^@/:]*@\)\=\|git://\|git@\|ssh://git@\|org-\d\+@\|ssh://org-\d\+@\)\=\zs\('.l:domain_pattern.'\)[/:].\{-\}\ze\%(\.git\)\=/\=$')
  if index(l:domains, 'http://' . matchstr(l:base, '^[^:/]*')) >= 0
    return 'http://' . tr(l:base, ':', '/')
  elseif !empty(l:base)
    return 'https://' . tr(l:base, ':', '/')
  endif

  return ''
endfunction

function! user#plugin#fugitive#browse_handler(...) abort
  if a:0 == 1 || type(a:1) == type({})
    let l:opts = a:1
    let l:root = s:homepage_for_url(get(l:opts, 'remote', ''))
  else
    return ''
  endif

  if empty(l:root)
    return ''
  endif

  let l:path = substitute(l:opts.path, '^/', '', '')
  if l:path =~# '^\.git/refs/heads/'
    return l:root . '/commits/' . l:path[16:-1]
  elseif l:path =~# '^\.git/refs/tags/'
    return l:root . '/releases/tag/' . l:path[15:-1]
  elseif l:path =~# '^\.git/refs/remotes/[^/]\+/.'
    return l:root . '/commits/' . matchstr(l:path, 'remotes/[^/]\+/\zs.*')
  elseif l:path =~# '^\.git/\%(config$\|hooks\>\)'
    return l:root . '/admin'
  elseif l:path =~# '^\.git\>'
    return l:root
  endif

  if l:opts.commit =~# '^\d\=$'
    return ''
  else
    let l:commit = l:opts.commit
  endif

  if get(l:opts, 'type', '') ==# 'tree' || l:opts.path =~# '/$'
    let l:url = substitute(l:root . '/tree/' . l:commit . '/' . l:path, '/$', '', 'g')
  elseif get(l:opts, 'type', '') ==# 'blob' || l:opts.path =~# '[^/]$'
    let l:escaped_commit = substitute(l:commit, '#', '%23', 'g')
    let l:url = l:root . '/blob/' . l:escaped_commit . '/' . l:path
    if get(l:opts, 'line2') > 0 && get(l:opts, 'line1') == l:opts.line2
      let l:url .= '#L' . l:opts.line1
    elseif get(l:opts, 'line1') > 0 && get(l:opts, 'line2') > 0
      let l:url .= '#L' . l:opts.line1 . '-L' . l:opts.line2
    endif
  else
    let l:url = l:root . '/commit/' . l:commit
  endif

  return l:url
endfunction
