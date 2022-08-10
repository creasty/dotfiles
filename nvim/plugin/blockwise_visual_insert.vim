if exists('g:loaded_blockwise_visual_insert') || v:version < 702
  finish
endif
let g:loaded_blockwise_visual_insert = 1

let s:save_cpo = &cpoptions
set cpoptions&vim

xnoremap <expr> I <SID>force_blockwise_visual('I')
xnoremap <expr> A <SID>force_blockwise_visual('A')

let s:paste = 0

function! s:force_blockwise_visual(next_key) abort
  let l:m = mode()

  let s:paste = 1
  doautocmd User BlockwiseVisualInsertPre

  if l:m ==# 'v'
    return "\<C-v>" . a:next_key
  elseif l:m ==# 'V'
    return "\<C-v>0o$" . a:next_key
  else
    return a:next_key
  endif
endfunction

augroup blockwise_visual_insert
  autocmd!

  autocmd InsertLeave *
    \ if s:paste == 1 |
      \ let s:paste = 0 |
      \ doautocmd User BlockwiseVisualInsertPost |
    \ endif

  " autocmd User BlockwiseVisualInsertPre set paste
  autocmd User BlockwiseVisualInsertPost set nopaste
augroup END

let &cpoptions = s:save_cpo
unlet s:save_cpo
