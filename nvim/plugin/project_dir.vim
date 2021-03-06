if exists('g:loaded_project_dir') || v:version < 702
  finish
endif
let g:loaded_project_dir = 1

let s:save_cpo = &cpoptions
set cpoptions&vim

if exists('+autochdir')
  set noautochdir
endif

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

function! s:get_root_directory() abort
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

function! s:can_change_directory() abort
  if match(expand('%:p'), '^\w\+://.*') != -1
    return v:false
  endif
  if !empty(&buftype)
    return v:false
  endif
  if get(g:, 'project_dir_only_home', v:true) && getcwd() !=# $HOME
    return v:false
  endif
  return v:true
endfunction

function! s:change_directory(dir) abort
  let l:edir = fnameescape(a:dir)

  exec 'setlocal path-=' . l:edir
  let b:current_root_directory = a:dir
  exec 'setlocal path+=' . l:edir

  exec 'lcd ' . l:edir
endfunction

function! s:change_to_root_directory() abort
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

augroup project_dir
  autocmd!
  autocmd BufRead,BufEnter,WinEnter,TabEnter *
    \ call <SID>change_to_root_directory()
augroup END

let &cpoptions = s:save_cpo
unlet s:save_cpo
