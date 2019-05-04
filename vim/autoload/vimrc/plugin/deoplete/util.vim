function! vimrc#plugin#deoplete#util#on_completion() abort
  let l:completed_item = get(v:, 'completed_item', {})
  if empty(l:completed_item)
    let l:completed_item = get(v:event, 'completed_item', {})
  endif

  let l:info = get(l:completed_item, 'info', '')
  if empty(l:info)
    let l:info = get(l:completed_item, 'abbr', '')
  endif
  if empty(l:info)
    return
  endif

  echomsg l:info

  let l:word = get(l:completed_item, 'word', '')
  if l:word =~# '^.\+('
    call s:complete_signature(l:info)
  endif
endfunction

function! s:complete_signature(info) abort
  let l:line = getline(line('.'))
  let l:pos = getpos('.')

  " Cursor should be at EOL
  if len(l:line) >= l:pos[2]
    return
  endif

  let l:signature = s:parse_funcs(a:info, &filetype)
  if empty(l:signature)
    call setline('.', l:line . ')')
    return
  endif

  let l:args = l:signature[0]['args']
  if empty(l:args[0])
    call feedkeys(')', 'n')
    return
  endif

  let l:args = map(l:args, {i, a -> '{{+' . trim(l:a) . '+}}'}) " TODO: support named arguments
  let l:args = join(l:args, ', ') " FIXME: hardcoded delimiter

  call setline('.', l:line . l:args . ')')
  call feedkeys("\<Tab>") " Jump to the first placeholder
endfunction

function! s:parse_funcs(text, filetype) abort
  if a:text ==# ''
    return []
  endif

  let l:text = a:text

  " Function pointer pattern.
  " Example: int32_t get(void *const, const size_t)
  let l:text = substitute(l:text, '\s*(\*)\s*', '', 'g')
  let l:text = substitute(l:text, '^(\(.*\))$', '\1', '')
  let l:text = substitute(l:text, '\s\+\ze(', '', '')

  " Template arguments pattern.
  let l:text = substitute(l:text, '<\zs[^>]*\ze>', '...', 'g')

  let l:quote_i = -1
  let l:stack = []
  let l:open_stack = []
  let l:comma = 0

  " Matching pairs will count as a single argument entry so that commas can be
  " skipped within them.  The open depth is tracked in each open stack item.
  " Parenthesis is an exception since it's used for functions and can have a
  " depth of 1.
  let l:pairs = '({[)}]'
  let l:last = len(l:text) - 1
  let l:i = -1

  " Note: single quote does not check
  let l:check_quotes = ['"', '`']

  while l:i < l:last
    let l:i += 1
    let l:c = l:text[l:i]

    if l:i > 0 && l:text[l:i - 1] ==# '\'
      continue
    endif

    if l:quote_i != -1
      " For languages that allow '''' ?
      " if l:c == "'" && l:text[l:i - 1] == l:c && l:i - l:quote_i > 1
      "   continue
      " endif
      if l:c == l:text[l:quote_i]
        let l:quote_i = -1
      endif
      continue
    endif

    if l:quote_i == -1 && index(l:check_quotes, l:c) >= 0
      " backtick (`) is not used alone in languages that I know of.
      let l:quote_i = l:i
      continue
    endif

    let l:prev = len(l:open_stack) ? l:open_stack[-1] : {'opens': [0, 0, 0]}
    let l:opened = l:prev.opens[0] + l:prev.opens[1] + l:prev.opens[2]

    let l:p = stridx(l:pairs, l:c)
    if l:p != -1
      let ci = l:p % 3
      if l:p == 3 && l:opened == 1 && l:prev.opens[0] == 1
        " Closing the function parenthesis
        if !empty(l:open_stack)
          let l:item = remove(l:open_stack, -1)
          let l:item.end = l:i - 1
          let l:item.pos = -1
          let l:item.opens[0] -= 1
          if l:comma <= l:i
            call add(l:item.args, l:text[l:comma : l:i - 1])
          endif
          let l:comma = l:item.i
        endif
      elseif l:p == 0
        " Opening parenthesis
        let l:func_i = match(l:text[: l:i - 1], '\S', l:comma)
        let l:func_name = matchstr(substitute(l:text[l:func_i : l:i - 1], '<[^>]*>', '', 'g'), '\k\+$')

        if l:func_i != -1 && l:func_i < l:i - 1 && l:func_name !=# ''
          let l:ppos = 0
          if !empty(l:open_stack)
            let l:ppos = l:open_stack[-1].pos
          endif

          if l:func_name !=# ''
            " Opening parenthesis that's preceded by a non-empty string.
            call add(l:stack, {
              \ 'name': l:func_name,
              \ 'i': l:func_i,
              \ 'start': l:i + 1,
              \ 'end': -1,
              \ 'pos': 0,
              \ 'ppos': l:ppos,
              \ 'args': [],
              \ 'opens': [1, 0, 0]
            \ })
            call add(l:open_stack, l:stack[-1])

            " Function opening parenthesis marks the beginning of arguments.
            " let l:comma = l:i + 1
            let l:comma = l:i + 1
          endif
        else
          let l:prev.opens[0] += 1
        endif
      else
        let l:prev.opens[ci] += l:p > 2 ? -1 : 1
      endif
    elseif l:opened == 1 && l:prev.opens[0] == 1 && l:c ==# ','
      " Not nested in a pair.
      if !empty(l:open_stack) && l:comma <= l:i
        let l:open_stack[-1].pos += 1
        call add(l:open_stack[-1].args, l:text[l:comma : l:i - 1])
      endif
      let l:comma = l:i + 1
    endif
  endwhile

  if !empty(l:open_stack)
    let l:item = l:open_stack[-1]
    call add(l:item.args, l:text[l:comma : l:last])
    let l:item.pos += 1
  endif

  if a:filetype ==# 'python'
    for l:item in l:open_stack
      call filter(l:item.args, "v:val !=# 'self'")
    endfor
  endif

  if !empty(l:stack) && l:stack[-1].opens[0] == 0
    let l:item = l:stack[-1]
    let l:item.trailing = matchstr(l:text, '\s*\zs\p*', l:item.end + 2)
  endif

  return l:stack
endfunction
