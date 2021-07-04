if exists('g:loaded_force_refresh') || v:version < 702
  finish
endif
let g:loaded_force_refresh = 1

let s:save_cpo = &cpoptions
set cpoptions&vim

function! s:is_enabled() abort
  if &readonly || !&modifiable
    return v:false
  endif
  if !empty(&buftype)
    return v:false
  endif
  return v:true
endfunction

function! s:reload_display(level) abort
  if !getbufvar('%', 'force_refresh_enabled', v:false)
    return
  endif
  if !s:is_enabled()
    return
  endif
  if get(b:, "force_refresh_initial_reload_display", v:true)
    let b:force_refresh_initial_reload_display = v:false
    return
  endif

  " clear highlights
  if has('textprop')
    call prop_clear(1, line('$'))
  endif
  call nvim_buf_clear_namespace(0, -1, 1, line('$'))

  if a:level >= 3
    " reload if modified externally
    silent! checktime

    " fix broken syntax highlight
    " @see https://vim.fandom.com/wiki/Fix_syntax_highlighting
    syntax sync fromstart

    " fix broken treesitter highlight
    " @see https://github.com/nvim-treesitter/nvim-treesitter/issues/78
    if exists(':TSBufEnable') == 2
      silent! edit
      TSBufEnable highlight
    endif
  endif

  if a:level >= 2
    " fix glitches
    redraw!
    redrawstatus
  endif

  " for plugins
  doautocmd User ForceRefresh
  if a:level >= 3
    doautocmd User ForceRefresh3
  endif

  return ''
endfunction

function! s:reload_file() abort
  if get(b:, "force_refresh_initial_reload_file", v:true)
    let b:force_refresh_initial_reload_file = v:false
    return
  endif

  if filereadable(expand('%:p'))
    silent! execute 'checktime' bufnr('%')
  endif
endfunction

nnoremap <expr> <C-l> <SID>reload_display(3)

augroup force_refresh
  autocmd!

  autocmd User ForceRefresh :
  autocmd User ForceRefresh3 :

  autocmd BufLeave * let b:force_refresh_enabled = v:false
  autocmd BufEnter * let b:force_refresh_enabled = v:true
  autocmd BufEnter * call <SID>reload_display(0)
  autocmd FocusGained * call <SID>reload_display(1)

  autocmd FocusGained,BufEnter * ++nested call <SID>reload_file()
augroup END

let &cpoptions = s:save_cpo
unlet s:save_cpo
