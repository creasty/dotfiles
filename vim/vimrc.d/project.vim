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
  let dir_current_file = fnameescape(expand('%:p:h'))

  for pattern in s:root_patterns
    if stridx(pattern, '/') != -1
      let match = finddir(pattern, dir_current_file . ';')

      if !empty(match)
        return fnamemodify(match, ':p:h:h')
      endif
    else
      let match = findfile(pattern, dir_current_file . ';')

      if !empty(match)
        return fnamemodify(match, ':p:h')
      endif
    endif
  endfor

  return ''
endfunction

function! s:can_change_directory()
  return match(expand('%:p'), '^\w\+://.*') == -1 && empty(&buftype)
endfunction

function! s:change_directory(dir)
  let edir = fnameescape(a:dir)

  exec 'setlocal path-=' . edir
  let b:current_root_directory = a:dir
  exec 'setlocal path+=' . edir

  exec 'lcd ' . edir
endfunction

function! s:change_to_root_directory()
  if !s:can_change_directory()
    return
  endif

  let dir = s:get_root_directory()

  if empty(dir)
    " change directory for non project files
    " let dir = expand('%:p:h')
    return
  endif

  call s:change_directory(dir)
endfunction

autocmd vimrc BufRead,BufEnter,WinEnter,TabEnter *
  \ call <SID>change_to_root_directory()
