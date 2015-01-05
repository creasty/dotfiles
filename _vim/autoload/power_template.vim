let s:save_cpo = &cpo
set cpo&vim


"=== Load
"==============================================================================================
function! power_template#load(...)
  let name = get(a:000, 0, 0)
  let lnum = get(a:000, 1, 0)

  let tmpl = empty(name) ?
    \ template#by_filetype(name)
    \ : template#by_intelligent(expand('%:p'))

  if empty(tmpl)
    return
  endif

  let empty_buffer = line('$') == 1 && strlen(getline(1)) == 0

  call cursor(lnum, 1)
  silent keepalt :.-1 read `=tmpl`

  if empty_buffer
    silent $ delete _
  endif

  doautocmd User PowerTemplatePostLoad
endfunction


"=== Search
"==============================================================================================
function! template#search(path)
  if empty(a:path)
    return ''
  endif

  " matching from tail
  let target = s:reverse(s:to_slash_path(a:path))

  let longest = ['', 0]  " ['template file name', match length]

  for i in split(globpath(g:power_template_dir, 'intelligent/**'), "\n")
    let i = s:to_slash_path(i)

    if isdirectory(i) || i !~ g:template_free_pattern
      continue
    endif

    " Make a path such as the following.
    " From: 'template_dir/a_$_file.vim' (FREE is a free path.)
    " To:   '^\Vmiv.elif_\(\.\{-}\)_a\%[/rid_etalpmet]'
    " TODO: cache?
    let l = map(split(i, '$'), 's:reverse(escape(v:val, "\\"))')
    let [head, rest] = matchlist(l[0], '\v(.{-})(/.*)')[1:2]
    let l[0] = head . '\%[' . substitute(rest, '[][]', '[\0]', 'g') . ']'
    let matched = matchlist(target, '^\V' . join(reverse(l), '\(\.\{-}\)'))
    let len = len(matched) ?
      \ strlen(matched[0]) - strlen(join(matched[1:], ''))
      \ : 0

    if longest[1] < len
      let longest = [i, len]
    endif
  endfor

  return longest[0]
endfunction


"=== Misc
"==============================================================================================
"  Return the reversed string
"-----------------------------------------------
function! s:reverse(str)
  return join(reverse(split(a:str, '\zs')), '')
endfunction

"  Unify path separator to a slash
"-----------------------------------------------
function! s:to_slash_path(path)
  if has('win16') || has('win32') || has('win64')
    return substitute(a:path, '\\', '/', 'g')
  endif
  return a:path
endfunction


let &cpo = s:save_cpo
