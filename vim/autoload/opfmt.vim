"  Patterns
"-----------------------------------------------
function! s:create_dict(items) abort
  let l:dict = {}
  for l:item in a:items
    let l:dict[l:item] = 1
  endfor
  return l:dict
endfunction

let s:triggers = [
  \ '*', '/', '%', '<', '>', '&', '+', '-', '|', '^', '=',
  \ '~', '?', '!',
  \ '$', '#', '@', "\\",
\ ]
let s:non_triggers = [
  \ ':', '.', ',', "'", '`',
\ ]
let s:all_operators = s:create_dict(s:triggers + s:non_triggers)

let s:eq_patterns = s:create_dict([
  \ '*=', '/=', '%=', '<=', '>=', '+=', '-=', '|=', '&=', '^=',
  \ '?=', '||=', '&&=', '<<=', '>>=', '&^=',
  \ '==', '===',
  \ '!=', '!==', '\=',
  \ '=~', '!~',
  \ '==#', '!=#', '=~#', '!~#', '==?', '!=?', '=~?', '!~?', '.=',
  \ '=>',
  \ ':=',
\ ])
let s:sep_0_patterns = s:create_dict([
  \ '++',
  \ '--',
\ ])
let s:sep_0_transformations = {
  \ '+++': ['++', 3],
  \ '---': ['--', 3],
\ }
let s:sep_3_patterns = s:create_dict([
  \ '*', '/', '%', '<', '>', '&',
  \ '+', '-', '|', '^',
  \ '!!', '??', '\\',
  \ '=', '~',
  \ ':=',
\ ])

"  Skip functions
"-----------------------------------------------
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

  return (l:left !=# ' ' && !has_key(s:all_operators, l:left))
endfunction

function! s:skip_by_group_info(info) abort
  if a:info.cursor != a:info.num_groups - 1
    return v:true
  endif

  let l:group = a:info.groups[a:info.cursor]
  if a:info.cursor_pos != len(l:group) - 1
    return v:true
  endif

  return v:false
endfunction

function! s:skip_by_context(text, op, grouped) abort
  if a:text =~# '^\s*$'
    return v:true
  endif
  if a:text =~# '\v[(\[{,<]\s*$'
    return v:true
  endif

  if !a:grouped
    " Ruby: block args
    if a:op ==# '|' && a:text =~# '\v(do|\{)\s*\|[^|]+\s*$'
      return v:true
    elseif a:text =~# '\v(do|\{)\s*\|[^|]+\|\s*$'
      return v:true
    endif
  endif

  return v:false
endfunction

"  Analyzers
"-----------------------------------------------
function! s:insert_text_at(text, insertion, i) abort
  return (a:i == 0)
    \ ? (a:insertion . a:text)
    \ : (a:text[0 : a:i - 1] . a:insertion . a:text[a:i :])
endfunction

function! s:_find_range(text, len, start, end, max_space) abort
  if a:start == a:end
    return a:start
  endif

  let l:dir = (a:start < a:end ? +1 : -1)

  let l:space = 0
  let l:space_flag = v:false
  let l:idx = a:start
  let l:i = a:start + l:dir

  while 0 <= l:i && l:i < a:len
    let l:c = a:text[l:i]

    if l:space == a:max_space
      break
    elseif l:c ==# ' '
      if l:space_flag
        break " stop when two consecutive spaces found
      endif

      let l:space += 1
      let l:space_flag = v:true
    else
      let l:space_flag = v:false

      if !has_key(s:all_operators, l:c)
        break
      endif
    endif

    let l:idx = l:i
    let l:i += l:dir
  endwhile

  return l:idx
endfunction

function! s:find_range(text, i) abort
  let l:len = len(a:text)
  let l:left = s:_find_range(a:text, l:len, a:i, 0, 2)
  let l:right = s:_find_range(a:text, l:len, a:i, l:len, 1)

  return [[l:left, l:right], a:text[l:left : l:right]]
endfunction

function! s:parse_group(operators, i) abort
  let l:seeker = 'C'

  let l:text = s:insert_text_at(a:operators, l:seeker, a:i)
  let l:groups = split(l:text, ' ', v:true)

  let l:sep = 0
  if l:groups[0] ==# ''
    let l:sep += 1
    let l:groups = l:groups[1:]
  endif
  if l:groups[-1] ==# ''
    let l:sep += 2
    let l:groups = l:groups[0:-2]
  endif

  let l:len = len(l:groups)
  let l:i = 0
  while l:i < l:len
    let l:text = l:groups[l:i]
    let l:pos = stridx(l:text, l:seeker)
    if l:pos >= 0
      let l:groups[l:i] = substitute(l:text, l:seeker, '', '')
      break
    endif
    let l:i += 1
  endwhile

  return {
    \ 'groups':     l:groups,
    \ 'num_groups': l:len,
    \ 'sep':        l:sep,
    \ 'cursor':     l:i,
    \ 'cursor_pos': l:pos,
  \ }
endfunction

"  Formatter
"-----------------------------------------------
function! s:format(info) abort
  let l:sep = a:info.sep
  let l:text = join(a:info.groups, ' ')

  if a:info.num_groups == 1
    let l:g0 = a:info.groups[0]

    if has_key(s:sep_3_patterns, l:g0)
      let l:sep = 3
    elseif l:sep == 0 && has_key(s:sep_0_transformations, l:g0)
      let [l:text, l:sep] = s:sep_0_transformations[l:g0]
    endif
  elseif a:info.num_groups == 2
    let l:g0 = a:info.groups[0]
    let l:g1 = a:info.groups[1]
    let l:merged = l:g0 . l:g1

    if has_key(s:sep_0_patterns, l:merged)
      let l:text = l:merged
      let l:sep = 0
    elseif l:merged =~# '='
      if and(l:sep, 1) && has_key(s:eq_patterns, l:merged)
        let l:text = l:merged
        let l:sep = 3
      else
        let l:sep = or(l:sep, 2)
      endif
    elseif l:sep != 0
      let l:text = l:merged
      let l:sep = or(l:sep, 2)
    endif
  endif

  if and(l:sep, 1)
    let l:text = ' ' . l:text
  endif
  if and(l:sep, 2)
    let l:text = l:text . ' '
  endif
  return l:text
endfunction

function! opfmt#format(op) abort
  let l:line = line('.')
  let l:col = col('.')

  if s:skip_by_syntax(l:line, l:col)
    echomsg 'skip_by_syntax'
    return a:op
  endif

  let l:text = getline(l:line)
  let l:i = l:col - 1
  let l:text = s:insert_text_at(l:text, a:op, l:i)

  if l:i == 0 || s:skip_by_context(l:text[0 : l:i - 1], a:op, v:false)
    echomsg 'skip_by_context (cursor)'
    return a:op
  endif
  if s:skip_by_last_style(l:text, l:i, a:op)
    echomsg 'skip_by_last_style'
    return a:op
  endif

  let [l:range, l:operators] = s:find_range(l:text, l:i)
  echomsg [l:range, l:operators]

  if l:range[0] == 0 || s:skip_by_context(l:text[0 : l:range[0] - 1], a:op, v:true)
    echomsg 'skip_by_context (operator)'
    return a:op
  endif

  let l:group_info = s:parse_group(l:operators, l:i - l:range[0])
  echomsg l:group_info

  if s:skip_by_group_info(l:group_info)
    echomsg 'skip_by_group_info'
    return a:op
  endif

  let l:new = s:format(l:group_info)
  let l:new = repeat("\<BS>", l:i - l:range[0]) . repeat("\<Del>", l:range[1] - l:i) . l:new

  return l:new
endfunction

function! opfmt#triggers() abort
  return s:triggers
endfunction
