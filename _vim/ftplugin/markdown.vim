
inoremap <buffer> <expr> = <SID>title_line('=')
inoremap <buffer> <expr> - <SID>title_line('-')

function! s:title_line(char)
  let l = line('.') - 1
  let c = col('.')
  let text = getline(l)
  let char = a:char

  if l && c == 1 && text !~ '^[-=]\s'
    let size = strwidth(text)

    while size > 1
      let char = char . a:char
      let size -= 1
    endwhile
  endif

  return char
endfunction

