function! s:rename_current_file(new_path) abort
  let l:bufnr = bufnr('%')
  let l:old_path = expand('%:p')
  let l:new_path = fnamemodify(expand(a:new_path), ':p')

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

  if filereadable(l:new_path)
    let l:answer = input(l:new_path . ' already exists, overwrite? (y/n)')
    call inputrestore()
    if l:answer !~# '^[yY]$'
      return
    endif
  endif

  " ensure directory
  call mkdir(fnamemodify(l:new_path, ':h'), 'p')

  " rename(2) is required by https://github.com/facebook/watchman
  " @see https://man7.org/linux/man-pages/man2/rename.2.html
  call v:lua.os.rename(l:old_path, l:new_path)

  keepalt enew
  exec l:bufnr . 'bwipeout!'
  exec 'keepalt' 'edit' fnameescape(l:new_path)

  filetype detect
endfunction

function! s:delete_current_file() abort
  let l:bufnr = bufnr('%')
  let l:file = expand('%:p')

  if empty(l:file)
    return
  endif

  if &modified
    noautocmd w
  endif

  keepalt enew

  " @see https://github.com/ali-rantakari/trash
  if executable('trash')
    call jobstart(['trash', l:file])
  else
    call delete(l:file)
  endif

  exec l:bufnr . 'bwipeout!'
endfunction

command! -nargs=1 -complete=file Rename call <SID>rename_current_file(<q-args>)
command! -nargs=0 Delete call s:delete_current_file()
