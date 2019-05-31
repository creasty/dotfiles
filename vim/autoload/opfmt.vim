let s:precedence = [
  \ ['||'],
  \ ['&&'],
  \ ['==', '!=', '<', '<=', '>', '>='],
  \ ['+', '-', '|', '^'],
  \ ['*', '/', '%', '<<', '>>', '&', '&^'],
\ ]

let g:opfmt#operators =
  \ '*/%<>&' . '+-|^' . '='
  \ . '~' . '?!:'
  \ . '$#@\.,' . "'`"

function! s:skip_by_syntax(line, col) abort
  for l:syn in synstack(a:line, a:col)
    let l:name = synIDattr(synIDtrans(l:syn), 'name')
    if l:name =~? '\vreg(ular)?ex|htmltag|jsxelement|string'
      return v:true
    endif
  endfor

  return v:false
endfunction

function! s:skip_by_last_style(text, i, op) abort
  if a:i == 0
    return v:false
  endif

  if a:text[a:i - 1] ==# a:op
    return v:false
  endif

  let l:pos = strridx(a:text, a:op, a:i - 1)
  if l:pos <= 0
    return v:false
  endif

  let l:left = a:text[l:pos - 1]
  if l:left ==# a:op " repeating
    return v:false
  endif

  return (l:left !=# ' ')
endfunction

function! s:find_range(text, i) abort
  let l:len = len(a:text)
  let l:range = [a:i, a:i]

  " Left
  let l:space = 0
  let l:i = a:i - 1
  while 0 <= l:i
    let l:c = a:text[l:i]

    if l:c ==# ' '
      let l:space += 1
    elseif stridx(g:opfmt#operators, l:c) == -1
      break
    endif

    let l:range[0] = l:i
    let l:i -= 1

    if l:space == 2
      break
    endif
  endwhile

  " Right
  let l:space = 0
  let l:i = a:i + 1
  while l:i <= l:len - 1
    let l:c = a:text[l:i]

    if l:c ==# ' '
      let l:space += 1
    elseif stridx(g:opfmt#operators, l:c) == -1
      break
    endif

    let l:range[1] = l:i
    let l:i += 1

    if l:space == 1
      break
    endif
  endwhile

  return [l:range, a:text[l:range[0] : l:range[1]]]
endfunction

function! s:format(before, operators, i) abort
  return [' ' . a:operators . ' ', 1]
endfunction

function! opfmt#format(op) abort
  let l:line = line('.')
  let l:col = col('.')

  if s:skip_by_syntax(l:line, l:col)
    return a:op
  endif

  let l:text = getline(l:line)
  let l:i = l:col - 1
  if l:i == 0
    let l:text = a:op . l:text
  else
    let l:text = l:text[0 : l:i - 1] . a:op . l:text[l:i :]
  endif

  if s:skip_by_last_style(l:text, l:i, a:op)
    return a:op
  endif

  let [l:range, l:operators] = s:find_range(l:text, l:i)
  echomsg l:range l:operators

  let l:before = l:range[0] > 0 ? l:text[0 : l:range[0] - 1] : ''
  let [l:new, l:move] = s:format(l:before, l:operators, l:i - l:range[0])
  let l:after = l:text[l:range[1] + 1 :]


  return ''
endfunction
