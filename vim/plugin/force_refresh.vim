if exists('g:loaded_force_refresh') || v:version < 702
  finish
endif
let g:loaded_force_refresh = 1

let s:save_cpo = &cpoptions
set cpoptions&vim

augroup force_refresh
  autocmd!
augroup END

autocmd force_refresh User ForceRefresh :

" force refresh buffer
function! s:force_refresh(normal) abort
  " reload if modified externally
  silent! checktime

  " fix broken syntax highlight
  " @see https://vim.fandom.com/wiki/Fix_syntax_highlighting
  if a:normal
    syntax sync fromstart
  endif

  " clear highlights
  if has('textprop')
    call prop_clear(1, line('$'))
  endif
  if has('nvim')
    call nvim_buf_clear_namespace(0, -1, 1, line('$'))
  endif

  " fix glitches
  redraw!
  redrawstatus

  " plugins
  doautocmd User ForceRefresh

  " trigger content change event
  doautocmd InsertLeave

  return 'zz'
endfunction

nnoremap <expr> <C-l> <SID>force_refresh(1)
autocmd force_refresh FocusGained,BufEnter call <SID>force_refresh(0)

" forcibly reload file
autocmd force_refresh BufEnter,BufReadPost *
  \ let b:filereadable = filereadable(expand('%:p'))

autocmd force_refresh BufEnter *
  \ if b:filereadable |
    \ silent! execute 'checktime' bufnr('%') |
  \ endif

let &cpoptions = s:save_cpo
unlet s:save_cpo
