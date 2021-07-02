function! s:foldexpr_markdown(lnum)
  let l1 = getline(a:lnum)

  if l1 =~ '^\s*$'
    " ignore empty lines
    return '='
  endif

  let l2 = getline(a:lnum+1)

  if  l2 =~ '^==\+\s*'
    " next line is underlined (level 1)
    return '>1'
  elseif l2 =~ '^--\+\s*'
    " next line is underlined (level 2)
    return '>2'
  elseif l1 =~ '^#'
    " current line starts with hashes
    return '>'.matchend(l1, '^#\+')
  elseif a:lnum == 1
    " fold any 'preamble'
    return '>1'
  else
    " keep previous foldlevel
    return '='
  endif
endfunction

setlocal foldexpr=s:foldexpr_markdown(v:lnum)
setlocal foldmethod=expr
