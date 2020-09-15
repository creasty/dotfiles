" clean up hidden buffers
function! vimrc#util#clean_buffers() abort
  redir => l:bufs
    silent buffers
  redir END

  for l:ibuf in split(l:bufs, "\n")
    let l:t = matchlist(l:ibuf, '\v^\s*(\d+)([^"]*)')
    if l:t[2] !~# '[#a+]'
      exec 'bdelete' l:t[1]
    endif
  endfor
endfunction

" create directories if not exist
function! vimrc#util#mkdir(dir) abort
  if !isdirectory(a:dir)
    call mkdir(iconv(a:dir, &encoding, &termencoding), 'p')
  endif
endfunction

" delete current file
function! vimrc#util#delete_file(file) abort
  let l:file = fnameescape(a:file)
  if empty(l:file)
    return
  endif

  let l:trash_dir = $HOME . '/.Trash'
  if isdirectory(l:trash_dir)
    call job_start(['mv', l:file, l:trash_dir])
  else
    call delete(l:file)
  endif
endfunction

" chmod
function! vimrc#util#chmod(file, mode) abort
  let l:file = fnameescape(a:file)
  if empty(l:file)
    return
  endif

  call job_start(['chmod', a:mode, l:file])
endfunction

" rename
function! vimrc#util#rename_file(file) abort
  let l:bufnr = bufnr('%')
  let l:old_path = expand('%:p')
  let l:new_path = fnamemodify(expand(a:file), ':p')

  if l:new_path ==# l:old_path || l:new_path ==# ''
    return
  endif

  if !filereadable(l:old_path)
    exec 'write' fnameescape(l:new_path)
    return
  endif

  if &modified
    noautocmd w
  endif

  let l:case_changed = (tolower(l:new_path) ==# tolower(l:old_path))
  let l:extension_changed = fnamemodify(tolower(l:new_path), ':e') !=# fnamemodify(tolower(l:old_path), ':e')

  if l:case_changed && filereadable(l:new_path)
    " Confirm to overwrite
    " call vimrc#util#delete_file(l:new_path)
    exec 'echomsg' 'Destination already exists:' l:new_path
    return
  endif

  call s:rename_file(l:old_path, l:new_path)

  let l:view = winsaveview()
  if l:case_changed
    exec l:bufnr . 'bwipeout!'
    exec 'keepalt' 'edit' fnameescape(l:new_path)
  else
    exec 'keepalt' 'edit' fnameescape(l:new_path)
    exec l:bufnr . 'bwipeout!'
  endif
  call winrestview(l:view)

  if l:extension_changed
    filetype detect
  endif
endfunction

function! s:rename_file(old, new) abort
  " https://github.com/facebook/watchman
  " @see https://man7.org/linux/man-pages/man2/rename.2.html
py3 << EOF
import os
old_path, new_path = vim.eval("a:old"), vim.eval("a:new")
os.rename(old_path, new_path)
EOF
endfunction

" edit a next file in the same directory
function! vimrc#util#next_file(direction) abort
  let l:path = expand('%:p')
  let l:directory = fnamemodify(l:path, ':h')

  let l:paths = split(globpath(l:directory, '*'), "\n")
  let l:files = filter(l:paths, '!isdirectory(v:val)')
  let l:n = len(l:files)
  let l:idx = index(l:files, l:path)

  if l:idx >= 0
    exec 'edit' fnameescape(l:files[(l:idx + a:direction) % l:n])
  endif
endfunction
