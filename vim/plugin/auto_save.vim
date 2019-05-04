if exists('g:loaded_auto_save') || v:version < 702
  finish
endif
let g:loaded_auto_save = 1

let s:save_cpo = &cpoptions
set cpoptions&vim

let s:auto_save_enabled = 1

augroup auto_save
  autocmd!
  autocmd User AutoSavePre :
  autocmd User AutoSavePost :
  autocmd CursorHoldI,CompleteDone * call <SID>auto_save()
  autocmd CursorHold,InsertLeave * call <SID>auto_save()
augroup END

command! AutoSaveToggle :call <SID>auto_save_toggle()

function! s:auto_save() abort
  if s:auto_save_enabled == 0
    return
  end
  let l:was_modified = &modified

  doautocmd User AutoSavePre
  silent! wa

  if !l:was_modified || &modified
    return
  endif

  let s:auto_save_enabled = 0
  try
    doautocmd User AutoSavePost
  finally
    let s:auto_save_enabled = 1
  endtry
endfunction

function! s:auto_save_toggle() abort
  if s:auto_save_enabled >= 1
    let s:auto_save_enabled = 0
    echo 'AutoSave is OFF'
  else
    let s:auto_save_enabled = 1
    echo 'AutoSave is ON'
  endif
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
