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

  let l:case_changed = (tolower(l:new_path) ==# tolower(l:old_path))
  let l:extension_changed = fnamemodify(tolower(l:new_path), ':e') !=# fnamemodify(tolower(l:old_path), ':e')

  if l:case_changed && filereadable(l:new_path)
    let l:answer = input(l:new_path . ' already exists, overwrite? (y/n)')
    call inputrestore()
    if l:answer =~# '^[yY]$'
      call s:delete_file(l:new_path)
    else
      return
    endif
  endif

  " ensure directory
  call mkdir(fnamemodify(l:new_path, ':h'), 'p')

  " https://github.com/facebook/watchman
  " @see https://man7.org/linux/man-pages/man2/rename.2.html
  call v:lua.os.rename(l:old_path, l:new_path)

  if l:case_changed
    exec 'keepalt' 'enew'
    exec l:bufnr . 'bwipeout!'
    exec 'keepalt' 'edit' fnameescape(l:new_path)
  else
    exec 'keepalt' 'edit' fnameescape(l:new_path)
    exec l:bufnr . 'bwipeout!'
  endif

  if l:extension_changed
    filetype detect
  endif
endfunction

function! s:delete_file(file) abort
  let l:file = fnameescape(a:file)
  if empty(l:file)
    return
  endif

  let l:trash_dir = $HOME . '/.Trash'
  if isdirectory(l:trash_dir)
    call jobstart(['mv', l:file, l:trash_dir])
  else
    call delete(l:file)
  endif
endfunction

command! -nargs=1 -complete=file Rename call <SID>rename_current_file(<q-args>)
command! -nargs=0 Delete call <SID>delete_file(expand('%:p')) | enew!
