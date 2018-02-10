let g:auto_save = 1

autocmd vimrc User AutoSavePre :
autocmd vimrc User AutoSavePost :
autocmd vimrc CursorHoldI,CompleteDone * call <SID>auto_save()
autocmd vimrc CursorHold,InsertLeave * call <SID>auto_save()

command! AutoSaveToggle :call <SID>auto_save_toggle()

function! s:auto_save()
  if g:auto_save == 0
    return
  end
  let l:was_modified = &modified

  doautocmd User AutoSavePre
  silent! wa

  if !l:was_modified || &modified
    return
  endif

  let g:auto_save = 0
  try
    doautocmd User AutoSavePost
  finally
    let g:auto_save = 1
  endtry

  if mode() !=# 'i'
    echo '(AutoSaved at ' . strftime('%H:%M:%S') . ')'
  endif
endfunction

function! s:auto_save_toggle()
  if g:auto_save >= 1
    let g:auto_save = 0
    echo 'AutoSave is OFF'
  else
    let g:auto_save = 1
    echo 'AutoSave is ON'
  endif
endfunction
