"=== Next/last text-object
"==============================================================================================
" dins  -- delete in next single quotes
"   foo = bar('spam')
"   C
"   foo = bar('')
"             C
" canp  -- change around next parens
"   foo = bar('spam')
"   C
"   foo = bar
"            C
" vind  -- select inside next double quotes
"   print "hello ", name
"    C
"   print "hello ", name
"          VVVVVV
function! vimrc#text_object#next(motion, dir) abort
  let l:c = nr2char(getchar())

  if l:c ==# 'p' || l:c ==# '(' || l:c ==# ')'
    let l:c = '('
  elseif l:c ==# 'b' || l:c ==# '{' || l:c ==# '}'
    let l:c = '{'
  elseif l:c ==# 'r' || l:c ==# '[' || l:c ==# ']'
    let l:c = '['
  elseif l:c ==# 's' || l:c ==# "'"
    let l:c = "'"
  elseif l:c ==# 'd' || l:c ==# '"'
    let l:c = '"'
  else
    return
  endif

  " Find the next opening-whatever.
  execute 'normal! ' . a:dir . l:c . "\<cr>"

  if a:motion ==# 'a'
    " If we're doing an 'around' method, we just need to select around it
    " and we can bail out to Vim.
    execute 'normal! va' . l:c
  else
    " Otherwise we're looking at an 'inside' motion.  Unfortunately these
    " get tricky when you're dealing with an empty set of delimiters because
    " Vim does the wrong thing when you say vi(.

    let l:open = ''
    let l:close = ''

    if l:c ==# '('
      let l:open = '('
      let l:close = ')'
    elseif l:c ==# '{'
      let l:open = '{'
      let l:close = '}'
    elseif l:c ==# '['
      let l:open = "\\["
      let l:close = "\\]"
    elseif l:c ==# "'"
      let l:open = "'"
      let l:close = "'"
    elseif l:c ==# '"'
      let l:open = '"'
      let l:close = '"'
    endif

    " We'll start at the current delimiter.
    let l:start_pos = getpos('.')
    let l:start_l = l:start_pos[1]
    let l:start_c = l:start_pos[2]

    " Then we'll find it's matching end delimiter.
    if l:c ==# "'" || l:c ==# '"'
      " searchpairpos() doesn't work for quotes, because fuck me.
      let l:end_pos = searchpos(l:open)
    else
      let l:end_pos = searchpairpos(l:open, '', l:close)
    endif

    let l:end_l = l:end_pos[0]
    let l:end_c = l:end_pos[1]

    call setpos('.', l:start_pos)

    if l:start_l == l:end_l && l:start_c == (l:end_c - 1)
      " We're in an empty set of delimiters.  We'll append an "x"
      " character and select that so most Vim commands will do something
      " sane.  v is gonna be weird, and so is y.  Oh well.
      execute "normal! ax\<esc>\<left>"
      execute 'normal! vi' . l:c
    elseif l:start_l == l:end_l && l:start_c == (l:end_c - 2)
      " We're on a set of delimiters that contain a single, non-newline
      " character.  We can just select that and we're done.
      execute 'normal! vi' . l:c
    else
      " Otherwise these delimiters contain something.  But we're still not
      " sure Vim's gonna work, because if they contain nothing but
      " newlines Vim still does the wrong thing.  So we'll manually select
      " the guts ourselves.
      let l:whichwrap = &whichwrap
      set whichwrap+=h,l

      execute 'normal! va' . l:c . 'hol'

      let &whichwrap = l:whichwrap
    endif
  endif
endfunction

"=== Number text-object
"==============================================================================================
" margin-top: 200px; -> dam -> margin-top: px;
" ^                                       ^
" TODO: Handle floats.
function! vimrc#text_object#number(whole) abort
  let l:num = '\v[0-9]'

  " If the current char isn't a number, walk forward.
  while getline('.')[col('.') - 1] !~# l:num
    normal! l
  endwhile

  " Now that we're on a number, start selecting it.
  normal! v

  " If the char after the cursor is a number, select it.
  while getline('.')[col('.')] =~# l:num
    normal! l
  endwhile

  " If we want an entire word, flip the select point and walk.
  if a:whole
    normal! o

    while col('.') > 1 && getline('.')[col('.') - 2] =~# l:num
      normal! h
    endwhile
  endif
endfunction
