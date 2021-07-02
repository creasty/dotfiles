function! quote_toggler#toggle() abort
  let l:line = getline('.')
  let l:pos = col('.') - 1
  let l:max = len(l:line) - 1

  let l:outmost = s:find_outmost_quote(l:line, l:pos)
  if type(l:outmost) != v:t_dict
    return v:false
  endif

  let l:q_opp = l:outmost.quote ==# '"' ? "'" : '"'

  " left
  let l:buf = ''
  if 0 <= l:outmost.start - 1
    let l:buf .= l:line[0 : l:outmost.start - 1]
  endif

  " inside
  let l:buf .= l:q_opp
  if l:outmost.start < l:outmost.end - 1 && l:outmost.start + 1 < l:outmost.end
    let l:_buf = l:line[l:outmost.start + 1 : l:outmost.end - 1]
    let l:_buf = substitute(l:_buf, '\\' . l:q_opp, l:q_opp, 'g')
    let l:_buf = substitute(l:_buf, l:q_opp, '\\' . l:q_opp, 'g')
    let l:_buf = substitute(l:_buf, '\\' . l:outmost.quote, l:outmost.quote, 'g')
    let l:buf .= l:_buf
  endif
  let l:buf .= l:q_opp

  " right
  if l:outmost.end + 1 <= l:max
    let l:buf .= l:line[l:outmost.end + 1 : l:max]
  endif

  call setline('.', l:buf)
  return v:true
endfunction

function! s:find_quotes(line, pos, dir) abort
  let l:max = len(a:line) - 1
  let l:quotes = []

  " collect quotes
  let l:i = a:pos
  while a:dir > 0 ? l:i <= l:max : l:i >= 0
    let l:c = a:line[l:i]
    let l:check_escape = a:dir > 0 ? a:pos < l:i : l:i > 0
    let l:c1 = l:check_escape ? a:line[l:i - 1] : ''

    if (l:c ==# "'" || l:c ==# '"') && l:c1 !=# '\'
      call add(l:quotes, [l:c, l:i])
    endif

    let l:i += a:dir
  endwhile

  let l:count = len(l:quotes)

  " squash complete pairs
  if l:count >= 3
    let l:last = ''
    let l:lastpos = 0

    let l:i = l:count - 1
    while l:i >= 0
      if l:last ==# ''
        let l:last = l:quotes[l:i][0]
      elseif l:last ==# l:quotes[l:i][0]
        let l:lastpos = l:i
        let l:last = ''
      endif

      let l:i -= 1
    endwhile

    let l:quotes = l:quotes[0 : l:lastpos - 1]
    let l:count = len(l:quotes)
  endif

  return {
    \ 'quotes': l:quotes,
    \ 'count': l:count,
  \ }
endfunction

function! s:find_outmost_quote(line, pos) abort
  let l:before = s:find_quotes(a:line, a:pos, -1)
  let l:after = s:find_quotes(a:line, a:pos, +1)

  " search for the most outer pair
  let l:b = l:before.count - 1
  while l:b >= 0
    let l:a = l:after.count - 1
    while l:a >= 0
      let l:bq = l:before.quotes[l:b][0]
      let l:aq = l:after.quotes[l:a][0]
      if l:bq == l:aq
        return {
          \ 'quote': l:bq,
          \ 'start': l:before.quotes[l:b][1],
          \ 'end': l:after.quotes[l:a][1],
        \ }
      endif
      let l:a -= 1
    endwhile
    let l:b -= 1
  endwhile

  return v:null
endfunction
