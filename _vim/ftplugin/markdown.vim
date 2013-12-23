
inoremap <buffer> <expr> = <SID>title_line('=')
inoremap <buffer> <expr> - <SID>title_line('-')

function! s:title_line(char)
  let l = line('.') - 1
  let c = col('.')
  let char = a:char

  if l && c == 1
    let size = strwidth(getline(l))

    while size > 1
      let char = char . a:char
      let size -= 1
    endwhile
  endif

  return char
endfunction

