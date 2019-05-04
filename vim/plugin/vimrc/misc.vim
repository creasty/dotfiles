if exists('g:loaded_vimrc_misc') || v:version < 702
  finish
endif
let g:loaded_vimrc_misc = 1

let s:save_cpo = &cpoptions
set cpoptions&vim

augroup vimrc_misc
  autocmd!
augroup END

" clean up hidden buffers
command! CleanBuffers :call vimrc#util#clean_buffers()

" delete current file
command! -nargs=0 Delete call vimrc#util#delete_or_trash(expand('%:p')) | enew!

" rename current file name
command! -nargs=1 -complete=file Rename f <args> | w | call delete(expand('#'))

" edit a next file in the same directory
command! -nargs=0 NextFile call vimrc#util#next_file(1)
command! -nargs=0 PrevFile call vimrc#util#next_file(-1)

nnoremap g9 :PrevFile<CR>
nnoremap g0 :NextFile<CR>

" inspect syntax
command! ScopeInfo echo map(synstack(line('.'), col('.')), 'synIDattr(synIDtrans(v:val), "name")')

" create directories if not exist
autocmd vimrc_misc BufWritePre *
 \ call vimrc#util#auto_mkdir(expand('<afile>:p:h'))

" file detect on read / save
autocmd vimrc_misc BufWritePost,BufReadPost,BufEnter *
  \ if &l:filetype ==# '' || exists('b:ftdetect') |
    \ unlet! b:ftdetect |
    \ filetype detect |
  \ endif

" forcibly reload file
autocmd vimrc_misc BufEnter *
  \ if filereadable(expand('%:p')) |
    \ silent! execute 'checktime' bufnr('%') |
  \ endif

let &cpoptions = s:save_cpo
unlet s:save_cpo
