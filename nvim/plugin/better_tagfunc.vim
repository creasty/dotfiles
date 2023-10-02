if exists('g:loaded_better_tagfunc_vim')
  finish
endif

let g:loaded_better_tagfunc_vim = 1

function! BetterTagfunc(pattern, flags, info) abort
  let l:pattern = a:pattern
  let l:bufname = get(a:info, 'buf_ffname', expand('%:p'))
  let l:ft = getbufvar(l:bufname, '&filetype')

  if a:flags ==# 'c'
    let l:pattern = '\<' . l:pattern . '\>'
  endif

  let l:Cmp = funcref('s:item_cmp', [l:bufname, l:ft])

  let l:result = taglist(l:pattern, l:bufname)
  call sort(l:result, { a, b -> l:Cmp(a) - l:Cmp(b) })
  return l:result
endfunction

function! s:item_cmp(bufname, ft, item) abort
  if a:item.filename ==# a:bufname
    return -3
  endif
  if a:item.language ==# a:ft
    return -2
  endif
  if !a:item.static
    return -1
  endif
  return 0
endfunction

set tagfunc=BetterTagfunc
