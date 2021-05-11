function! s:jobstart(cmd) abort
  if has('nvim')
    call jobstart(a:cmd)
  else
    call job_start(a:cmd)
  endif
endfunction

function! vimrc#util#change_font_size(size) abort
  exec 'set' 'guifont=Menlo:h' . a:size

  if $NVIM_GUI ==# 'kitty'
    call s:jobstart(['kitty', '@', 'set-font-size', a:size])
  endif
endfunction

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
    call s:jobstart(['mv', l:file, l:trash_dir])
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

  call s:jobstart(['chmod', a:mode, l:file])
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
