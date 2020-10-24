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
  autocmd User AutoSavePost call <SID>record_time()
  autocmd CursorHold,InsertLeave * ++nested call <SID>auto_save()
  autocmd BufLeave,FocusLost * ++nested call <SID>auto_save()
  autocmd BufWritePost * call <SID>record_time()
augroup END

command! AutoSaveToggle :call <SID>auto_save_toggle()

function! s:is_enabled() abort
  if &readonly || !&modifiable
    return v:false
  endif
  if !empty(&buftype)
    return v:false
  endif
  if bufname() =~# '^__coc_'
    return v:false
  endif
  return v:true
endfunction

function! s:auto_save() abort
  if s:auto_save_enabled == 0
    return
  end
  if !s:is_enabled()
    return
  endif

  if !&modified
    return
  endif

  doautocmd User AutoSavePre
  silent! w

  if &modified
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

function! s:record_time() abort
  let b:auto_save_last_saved_time = localtime()
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
