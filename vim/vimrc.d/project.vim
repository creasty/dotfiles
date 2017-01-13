if g:env.support.autochdir
  set noautochdir
endif

let b:current_root_directory = '.'

let s:root_patterns = [
  \ '.git',
  \ '.git/',
  \ 'Rakefile',
  \ 'Gemfile',
  \ 'package.json',
  \ '.vimprojectroot',
  \ '*.xcodeproj',
  \ 'build.sbt',
\ ]

function! s:get_root_directory()
  let l:dir_current_file = fnameescape(expand('%:p:h'))

  for l:pattern in s:root_patterns
    if stridx(l:pattern, '/') != -1
      let l:match = finddir(l:pattern, l:dir_current_file . ';')

      if !empty(l:match)
        return fnamemodify(l:match, ':p:h:h')
      endif
    else
      let l:match = findfile(l:pattern, l:dir_current_file . ';')

      if !empty(l:match)
        return fnamemodify(l:match, ':p:h')
      endif
    endif
  endfor

  return ''
endfunction

function! s:can_change_directory()
  return match(expand('%:p'), '^\w\+://.*') == -1 && empty(&buftype)
endfunction

function! s:change_directory(dir)
  let l:edir = fnameescape(a:dir)

  exec 'setlocal path-=' . l:edir
  let b:current_root_directory = a:dir
  exec 'setlocal path+=' . l:edir

  exec 'lcd ' . l:edir
endfunction

function! s:change_to_root_directory()
  if !s:can_change_directory()
    return
  endif

  let l:dir = s:get_root_directory()

  if empty(l:dir)
    " change directory for non project files
    " let dir = expand('%:p:h')
    return
  endif

  call s:change_directory(l:dir)
endfunction

autocmd vimrc BufRead,BufEnter,WinEnter,TabEnter *
  \ call <SID>change_to_root_directory()
