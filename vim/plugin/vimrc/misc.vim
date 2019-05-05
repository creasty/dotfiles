if exists('g:loaded_vimrc_misc') || v:version < 702
  finish
endif
let g:loaded_vimrc_misc = 1

let s:save_cpo = &cpoptions
set cpoptions&vim

augroup vimrc_misc
  autocmd!
augroup END

" edit configurations
command! Vimrc edit $MYVIMRC
command! Dotfiles exec 'lcd' vimrc#env.path.dotfiles
command! MacVim exec 'lcd' vimrc#env.path.runtime

" clean up hidden buffers
command! CleanBuffers :call vimrc#util#clean_buffers()

" delete current file
command! -nargs=0 Delete call vimrc#util#delete_file(expand('%:p')) | enew!

" rename current file name
command! -nargs=1 -complete=file Rename keepalt saveas <args>

" edit a next file in the same directory
command! -nargs=0 NextFile call vimrc#util#next_file(1)
command! -nargs=0 PrevFile call vimrc#util#next_file(-1)

nnoremap g9 :PrevFile<CR>
nnoremap g0 :NextFile<CR>

" inspect syntax
command! ScopeInfo echo map(synstack(line('.'), col('.')), 'synIDattr(synIDtrans(v:val), "name")')

" create directories if not exist
autocmd vimrc_misc BufWritePre *
 \ call vimrc#util#mkdir(expand('<afile>:p:h'))

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

" hash-bang file
autocmd vimrc_misc BufNewFile  * let b:vimrc_misc_new_file = 1
autocmd vimrc_misc BufWritePost * unlet! b:vimrc_misc_new_file
autocmd vimrc_misc BufWritePre *
  \ if exists('b:vimrc_misc_new_file') && getline(1) =~ '^#!\s*/' |
    \ let b:chmod_post = '+x' |
  \ endif
autocmd vimrc_misc BufWritePost,FileWritePost * nested
  \ if exists('b:chmod_post') |
    \ call vimrc#util#chmod(expand('<afile>:p'), b:chmod_post) |
    \ unlet b:chmod_post |
  \ endif

let &cpoptions = s:save_cpo
unlet s:save_cpo
