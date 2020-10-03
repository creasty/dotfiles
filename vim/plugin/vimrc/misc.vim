if exists('g:loaded_vimrc_misc') || v:version < 702
  finish
endif
let g:loaded_vimrc_misc = 1

let s:save_cpo = &cpoptions
set cpoptions&vim

augroup vimrc_misc
  autocmd!
augroup END

" next/last text-object
onoremap <silent> an :<C-u>call vimrc#text_object#next('a', '/')<CR>
xnoremap <silent> an :<C-u>call vimrc#text_object#next('a', '/')<CR>
onoremap <silent> in :<C-u>call vimrc#text_object#next('i', '/')<CR>
xnoremap <silent> in :<C-u>call vimrc#text_object#next('i', '/')<CR>
onoremap <silent> al :<C-u>call vimrc#text_object#next('a', '?')<CR>
xnoremap <silent> al :<C-u>call vimrc#text_object#next('a', '?')<CR>
onoremap <silent> il :<C-u>call vimrc#text_object#next('i', '?')<CR>
xnoremap <silent> il :<C-u>call vimrc#text_object#next('i', '?')<CR>

" number text-object
onoremap <silent> m  :<C-u>call vimrc#text_object#number(0)<CR>
xnoremap <silent> m  :<C-u>call vimrc#text_object#number(0)<CR>
onoremap <silent> am :<C-u>call vimrc#text_object#number(1)<CR>
xnoremap <silent> am :<C-u>call vimrc#text_object#number(1)<CR>
onoremap <silent> im :<C-u>call vimrc#text_object#number(1)<CR>
xnoremap <silent> im :<C-u>call vimrc#text_object#number(1)<CR>

" edit configurations
command! Vimrc edit $MYVIMRC
command! Dotfiles exec 'lcd' g:vimrc#env.path.dotfiles
command! MacVim exec 'lcd' g:vimrc#env.path.runtime

" clean up hidden buffers
command! CleanBuffers :call vimrc#util#clean_buffers()

" delete current file
command! -nargs=0 Delete call vimrc#util#delete_file(expand('%:p')) | enew!

" rename current file name
command! -nargs=1 -complete=file Rename call vimrc#util#rename_file(<q-args>)

" edit a next file in the same directory
command! -nargs=0 PrevFile call vimrc#util#next_file(-1)
command! -nargs=0 NextFile call vimrc#util#next_file(1)

nnoremap g9 :PrevFile<CR>
nnoremap g0 :NextFile<CR>

" inspect syntax
command! ScopeInfo echo map(synstack(line('.'), col('.')), 'synIDattr(synIDtrans(v:val), "name")')

" font
command! -nargs=? Font :call vimrc#util#change_font_size(<q-args> ? <q-args> : 12)

" force refresh buffer
autocmd vimrc_misc User ForceRefresh :
nnoremap <expr> <C-l> <SID>force_refresh(1)
autocmd vimrc_misc FocusGained,BufEnter call <SID>force_refresh(0)
function! s:force_refresh(normal) abort
  " reload if modified externally
  silent! checktime

  " fix broken syntax highlight
  " @see https://vim.fandom.com/wiki/Fix_syntax_highlighting
  if a:normal
    syntax sync fromstart
  endif

  " clear textprops
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

command! Profile
  \ profile start ~/vim_profile.log |
  \ profile func * |
  \ profile! file *

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
autocmd vimrc_misc BufEnter,BufReadPost *
  \ let b:filereadable = filereadable(expand('%:p'))

autocmd vimrc_misc BufEnter *
  \ if b:filereadable |
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
