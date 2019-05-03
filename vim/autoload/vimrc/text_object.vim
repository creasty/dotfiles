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
  let c = nr2char(getchar())
  let d = ''

  if c ==# "p" || c ==# "(" || c ==# ")"
    let c = "("
  elseif c ==# "b" || c ==# "{" || c ==# "}"
    let c = "{"
  elseif c ==# "r" || c ==# "[" || c ==# "]"
    let c = "["
  elseif c ==# 's' || c ==# "'"
    let c = "'"
  elseif c ==# 'd' || c ==# '"'
    let c = '"'
  else
    return
  endif

  " Find the next opening-whatever.
  execute "normal! " . a:dir . c . "\<cr>"

  if a:motion ==# 'a'
    " If we're doing an 'around' method, we just need to select around it
    " and we can bail out to Vim.
    execute "normal! va" . c
  else
    " Otherwise we're looking at an 'inside' motion.  Unfortunately these
    " get tricky when you're dealing with an empty set of delimiters because
    " Vim does the wrong thing when you say vi(.

    let open = ''
    let close = ''

    if c ==# "("
      let open = "("
      let close = ")"
    elseif c ==# "{"
      let open = "{"
      let close = "}"
    elseif c ==# "["
      let open = "\\["
      let close = "\\]"
    elseif c ==# "'"
      let open = "'"
      let close = "'"
    elseif c ==# '"'
      let open = '"'
      let close = '"'
    endif

    " We'll start at the current delimiter.
    let start_pos = getpos('.')
    let start_l = start_pos[1]
    let start_c = start_pos[2]

    " Then we'll find it's matching end delimiter.
    if c ==# "'" || c ==# '"'
      " searchpairpos() doesn't work for quotes, because fuck me.
      let end_pos = searchpos(open)
    else
      let end_pos = searchpairpos(open, '', close)
    endif

    let end_l = end_pos[0]
    let end_c = end_pos[1]

    call setpos('.', start_pos)

    if start_l == end_l && start_c == (end_c - 1)
      " We're in an empty set of delimiters.  We'll append an "x"
      " character and select that so most Vim commands will do something
      " sane.  v is gonna be weird, and so is y.  Oh well.
      execute "normal! ax\<esc>\<left>"
      execute "normal! vi" . c
    elseif start_l == end_l && start_c == (end_c - 2)
      " We're on a set of delimiters that contain a single, non-newline
      " character.  We can just select that and we're done.
      execute "normal! vi" . c
    else
      " Otherwise these delimiters contain something.  But we're still not
      " sure Vim's gonna work, because if they contain nothing but
      " newlines Vim still does the wrong thing.  So we'll manually select
      " the guts ourselves.
      let whichwrap = &whichwrap
      set whichwrap+=h,l

      execute "normal! va" . c . "hol"

      let &whichwrap = whichwrap
    endif
  endif
endfunction

"=== Number text-object
"==============================================================================================
" margin-top: 200px; -> dam -> margin-top: px;
" ^                                       ^
" TODO: Handle floats.
function! vimrc#text_object#number(whole) abort
  let num = '\v[0-9]'

  " If the current char isn't a number, walk forward.
  while getline('.')[col('.') - 1] !~# num
    normal! l
  endwhile

  " Now that we're on a number, start selecting it.
  normal! v

  " If the char after the cursor is a number, select it.
  while getline('.')[col('.')] =~# num
    normal! l
  endwhile

  " If we want an entire word, flip the select point and walk.
  if a:whole
    normal! o

    while col('.') > 1 && getline('.')[col('.') - 2] =~# num
      normal! h
    endwhile
  endif
endfunction
