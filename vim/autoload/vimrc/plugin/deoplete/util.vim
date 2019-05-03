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

  let l:args = map(l:args, {i, a -> ''}) " TODO: support named arguments
  let l:args = join(l:args, ', ') " FIXME: hardcoded delimiter

  call setline('.', l:line . l:args . ')')
  call feedkeys("\<Tab>") " Jump to the first placeholder
endfunction

function! s:parse_funcs(text, filetype) abort
  if a:text ==# ''
    return []
  endif

  let text = a:text

  " Function pointer pattern.
  " Example: int32_t get(void *const, const size_t)
  let text = substitute(text, '\s*(\*)\s*', '', 'g')
  let text = substitute(text, '^(\(.*\))$', '\1', '')
  let text = substitute(text, '\s\+\ze(', '', '')

  " Template arguments pattern.
  let text = substitute(text, '<\zs[^>]*\ze>', '...', 'g')

  let quote_i = -1
  let stack = []
  let open_stack = []
  let comma = 0

  " Matching pairs will count as a single argument entry so that commas can be
  " skipped within them.  The open depth is tracked in each open stack item.
  " Parenthesis is an exception since it's used for functions and can have a
  " depth of 1.
  let pairs = '({[)}]'
  let l = len(text) - 1
  let i = -1

  " Note: single quote does not check
  let check_quotes = ['"', '`']

  while i < l
    let i += 1
    let c = text[i]

    if i > 0 && text[i - 1] ==# '\'
      continue
    endif

    if quote_i != -1
      " For languages that allow '''' ?
      " if c == "'" && text[i - 1] == c && i - quote_i > 1
      "   continue
      " endif
      if c == text[quote_i]
        let quote_i = -1
      endif
      continue
    endif

    if quote_i == -1 && index(check_quotes, c) >= 0
      " backtick (`) is not used alone in languages that I know of.
      let quote_i = i
      continue
    endif

    let prev = len(open_stack) ? open_stack[-1] : {'opens': [0, 0, 0]}
    let opened = prev.opens[0] + prev.opens[1] + prev.opens[2]

    let p = stridx(pairs, c)
    if p != -1
      let ci = p % 3
      if p == 3 && opened == 1 && prev.opens[0] == 1
        " Closing the function parenthesis
        if !empty(open_stack)
          let item = remove(open_stack, -1)
          let item.end = i - 1
          let item.pos = -1
          let item.opens[0] -= 1
          if comma <= i
            call add(item.args, text[comma :i - 1])
          endif
          let comma = item.i
        endif
      elseif p == 0
        " Opening parenthesis
        let func_i = match(text[:i - 1], '\S', comma)
        let func_name = matchstr(substitute(text[func_i :i - 1],
              \ '<[^>]*>', '', 'g'), '\k\+$')

        if func_i != -1 && func_i < i - 1 && func_name !=# ''
          let ppos = 0
          if !empty(open_stack)
            let ppos = open_stack[-1].pos
          endif

          if func_name !=# ''
            " Opening parenthesis that's preceded by a non-empty string.
            call add(stack, {
                  \ 'name': func_name,
                  \ 'i': func_i,
                  \ 'start': i + 1,
                  \ 'end': -1,
                  \ 'pos': 0,
                  \ 'ppos': ppos,
                  \ 'args': [],
                  \ 'opens': [1, 0, 0]
                  \ })
            call add(open_stack, stack[-1])

            " Function opening parenthesis marks the beginning of arguments.
            " let comma = i + 1
            let comma = i + 1
          endif
        else
          let prev.opens[0] += 1
        endif
      else
        let prev.opens[ci] += p > 2 ? -1 : 1
      endif
    elseif opened == 1 && prev.opens[0] == 1 && c ==# ','
      " Not nested in a pair.
      if !empty(open_stack) && comma <= i
        let open_stack[-1].pos += 1
        call add(open_stack[-1].args, text[comma :i - 1])
      endif
      let comma = i + 1
    endif
  endwhile

  if !empty(open_stack)
    let item = open_stack[-1]
    call add(item.args, text[comma :l])
    let item.pos += 1
  endif

  if a:filetype ==# 'python'
    for item in open_stack
      call filter(item.args, "v:val !=# 'self'")
    endfor
  endif

  if !empty(stack) && stack[-1].opens[0] == 0
    let item = stack[-1]
    let item.trailing = matchstr(text, '\s*\zs\p*', item.end + 2)
  endif

  return stack
endfunction
