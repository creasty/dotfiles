if exists('g:loaded_auto_chmod') || !has('nvim')
  finish
endif
let g:loaded_auto_chmod = 1

let s:save_cpo = &cpoptions
set cpoptions&vim

function! s:chmod(file, mode) abort
  let l:file = fnameescape(a:file)
  if empty(l:file)
    return
  endif

  call jobstart(['chmod', a:mode, l:file])
endfunction

augroup auto_chmod
  autocmd!

  autocmd BufNewFile  * let b:auto_chmod_new_file = 1
  autocmd BufWritePost * unlet! b:auto_chmod_new_file
  autocmd BufWritePre *
    \ if exists('b:auto_chmod_new_file') && getline(1) =~ '^#!\s*/' |
      \ let b:chmod_post = '+x' |
    \ endif
  autocmd BufWritePost,FileWritePost * nested
    \ if exists('b:chmod_post') |
      \ call <SID>chmod(expand('<afile>:p'), b:chmod_post) |
      \ unlet b:chmod_post |
    \ endif
augroup END

let &cpoptions = s:save_cpo
unlet s:save_cpo
