if exists('g:loaded_mode_observer') || v:version < 702
  finish
endif
let g:loaded_mode_observer = 1

let s:save_cpo = &cpoptions
set cpoptions&vim

let g:mode_observer_current_mode = 'n'

function! s:handle_mode_change(m) abort
  if g:mode_observer_current_mode == a:m
    return ''
  endif
  let g:mode_observer_current_mode = a:m

  doautocmd User ModeDidChange

  return ''
endfunction

augroup mode_observer
  autocmd!
  autocmd User ModeDidChange :
  autocmd InsertEnter,InsertChange * call <SID>handle_mode_change(v:insertmode)
  autocmd InsertLeave,CursorHold * call <SID>handle_mode_change(mode())
augroup END

snoremap <expr> <Esc> <SID>handle_mode_change('n') . "\<Esc>"
xnoremap <expr> <Esc> <SID>handle_mode_change('n') . "\<Esc>"
nnoremap <expr> v <SID>handle_mode_change('v') . 'v'
nnoremap <expr> V <SID>handle_mode_change('v') . 'V'
nnoremap <expr> <C-v> <SID>handle_mode_change('v') . "\<C-v>"

let &cpoptions = s:save_cpo
unlet s:save_cpo
