if exists('g:loaded_vimrc_misc') || v:version < 702
  finish
endif
let g:loaded_vimrc_misc = 1

let s:save_cpo = &cpoptions
set cpoptions&vim

augroup vimrc_misc
  autocmd!
augroup END

" profiler
command! ProfileStart
  \ profile start ~/vim_profile.log |
  \ profile func * |
  \ profile! file *
command! ProfileStop
  \ profile stop

" inspect syntax
command! ScopeInfo echo map(synstack(line('.'), col('.')), 'synIDattr(synIDtrans(v:val), "name")')

" font
command! -nargs=? Font :call <SID>change_font_size(<q-args> ? <q-args> : 12)

" clean up hidden buffers
command! CleanBuffers :call <SID>clean_buffers()

" delete current file
command! -nargs=0 Delete call <SID>delete_file(expand('%:p')) | enew!

" create directories if not exist
autocmd vimrc_misc BufWritePre *
  \ call <SID>mkdir(expand('<afile>:p:h'))

"  Utility functions
"-----------------------------------------------
function! s:clean_buffers() abort
  redir => l:bufs
    silent buffers
  redir END

  for l:buf in split(l:bufs, "\n")
    let l:t = matchlist(l:buf, '\v^\s*(\d+)([^"]*)')
    if l:t[2] !~# '[#a+]'
      exec 'bdelete' l:t[1]
    endif
  endfor
endfunction

function! s:change_font_size(size) abort
  exec 'set' 'guifont=Menlo:h' . a:size

  if $NVIM_GUI ==# 'kitty'
    call jobstart(['kitty', '@', 'set-font-size', a:size])
  endif
endfunction

function! s:mkdir(dir) abort
  if !isdirectory(a:dir)
    call mkdir(a:dir, 'p')
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

let &cpoptions = s:save_cpo
unlet s:save_cpo
