let g:switch_custom_definitions = [
  \ {
    \ ':\(\w\+\)': '''\1''',
  \ },
  \ {
    \ '\<\(\w\+\): \(\s*\)': '''\1'' \2=> ',
    \ '''\(\w\+\)'' \(\s*\)=> ': '\1: \2',
  \ },
  \ {
    \ '\<public\>': 'protected',
    \ '\<protected\>': 'private',
    \ '\<private\>': 'public',
  \ },
  \ {
    \ '\<\(it\|describe\|context\|senario\)\>': 'x\1',
    \ '\<x\(it\|describe\|context\|senario\)\>': '\1',
  \ },
  \ {
    \ '\<and\>': 'or',
    \ '\<or\>': 'and',
  \ },
  \ {
    \ '\<if\>': 'unless',
    \ '\<unless\>': 'if',
  \ },
  \ {
    \ '\<true\>': 'false',
    \ '\<false\>': 'true',
  \ },
  \ {
    \ '\<TRUE\>': 'FALSE',
    \ '\<FALSE\>': 'TRUE',
  \ },
  \ {
    \ '\<on\>': 'off',
    \ '\<off\>': 'on',
  \ },
  \ {
    \ '\<ON\>': 'OFF',
    \ '\<OFF\>': 'ON',
  \ },
  \ {
    \ '\<yes\>': 'no',
    \ '\<no\>': 'yes',
  \ },
  \ {
    \ '\<YES\>': 'NO',
    \ '\<NO\>': 'YES',
  \ },
\ ]

function! s:switch() abort
  let l:line = getline('.')
  let l:pos = col('.') - 1
  let l:max = len(l:line) - 1

  let l:before = []
  let l:after = []

  let l:i = l:pos
  while l:i >= 0
    let l:c = l:line[l:i]
    let l:c1 = l:i > 0 ? l:line[l:i - 1] : ''

    if (l:c ==# "'" || l:c ==# '"') && l:c1 !=# '\'
        call add(l:before, [l:c, l:i])
    endif

    let l:i -= 1
  endwhile

  let l:i = l:pos
  while l:i <= l:max
    let l:c = l:line[l:i]
    let l:c1 = l:pos < l:i ? l:line[l:i - 1] : ''

    if (l:c ==# "'" || l:c ==# '"') && l:c1 !=# '\'
        call add(l:after, [l:c, l:i])
    endif

    let l:i += 1
  endwhile

  let l:b = len(l:before) - 1
  let l:a = len(l:after) - 1

  " echomsg '[' join(l:before, ', ') '], [' join(l:after, ', ') ']'

  while l:b >= 0
    while l:a >= 0
      " echomsg l:before[l:b][0] l:after[l:a][0]

      let l:q = l:before[l:b][0]
      if l:q == l:after[l:a][0]
        let [l:start_pos, l:end_pos] = [l:before[l:b][1], l:after[l:a][1]]
        let l:q_opp = l:q ==# '"' ? "'" : '"'

        let l:buf = ''
        if 0 <= l:start_pos - 1
          let l:buf .= l:line[0 : l:start_pos - 1]
        endif
        let l:buf .= l:q_opp
        if l:start_pos < l:end_pos - 1 && l:start_pos + 1 < l:end_pos
          let l:_buf = l:line[l:start_pos + 1 : l:end_pos - 1]
          let l:_buf = substitute(l:_buf, '\\' . l:q_opp, l:q_opp, 'g')
          let l:_buf = substitute(l:_buf, l:q_opp, '\\' . l:q_opp, 'g')
          let l:_buf = substitute(l:_buf, '\\' . l:q, l:q, 'g')
          let l:buf .= l:_buf
        endif
        let l:buf .= l:q_opp
        if l:end_pos + 1 <= l:max
          let l:buf .= l:line[l:end_pos + 1 : l:max]
        endif

        call setline('.', l:buf)
        return
      endif
      let l:a -= 1
    endwhile
    let l:b -= 1
  endwhile

  :Switch
endfunction

nnoremap <silent> - :call <SID>switch()<CR>
