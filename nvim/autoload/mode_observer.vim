let s:mode_key = 'mode_observer_current_mode'

function! s:get_mode(winnr)
  return getwinvar(a:winnr, s:mode_key, '')
endfunction

function! mode_observer#update_mode(winnr)
  let l:prev_mode = s:get_mode(a:winnr)
  let l:mode = mode()

  if l:mode !=# l:prev_mode
    call setwinvar(a:winnr, s:mode_key, mode())
    doautocmd User ModeDidChange
  endif
endfunction

function! mode_observer#get_mode(...) abort
  return s:get_mode(a:0 == 0 ? winnr() : a:1)
endfunction
