if exists('g:loaded_force_refresh') || v:version < 702
  finish
endif
let g:loaded_force_refresh = 1

let s:save_cpo = &cpoptions
set cpoptions&vim

function! s:is_enabled() abort
  if &ft =~# 'denite'
    return v:false
  endif
  if &readonly || !&modifiable
    return v:false
  endif
  return v:true
endfunction

function! s:reload_display(level) abort
  if !getbufvar('%', 'force_refresh_enabled', v:false)
    return
  endif

  if a:level >= 3
    " reload if modified externally
    silent! checktime

    " fix broken syntax highlight
    " @see https://vim.fandom.com/wiki/Fix_syntax_highlighting
    syntax sync fromstart
  endif

  " clear highlights
  if has('textprop')
    call prop_clear(1, line('$'))
  endif
  if has('nvim')
    call nvim_buf_clear_namespace(0, -1, 1, line('$'))
  endif

  if a:level >= 2
    " fix glitches
    redraw!
    redrawstatus
  endif

  " for plugins
  doautocmd User ForceRefresh

  " trigger content change event
  doautocmd InsertLeave

  return 'zz'
endfunction

function! s:reload_file() abort
  if getbufvar('%', 'filereadable', v:false)
    silent! execute 'checktime' bufnr('%')
  endif
endfunction

nnoremap <expr> <C-l> <SID>reload_display(3)

augroup force_refresh
  autocmd!

  autocmd User ForceRefresh :

  autocmd BufLeave * let b:force_refresh_enabled = v:false
  autocmd BufEnter * let b:force_refresh_enabled = <SID>is_enabled()
  autocmd BufEnter * call <SID>reload_display(0)
  autocmd FocusGained * call <SID>reload_display(1)

  autocmd FocusGained,BufEnter,BufReadPost,BufWritePost * let b:filereadable = filereadable(expand('%:p'))
  autocmd FocusGained,BufEnter,BufReadPost * nested call <SID>reload_file()
augroup END

let &cpoptions = s:save_cpo
unlet s:save_cpo
