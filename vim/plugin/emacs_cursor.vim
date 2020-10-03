if exists('g:loaded_emacs_cursor') || v:version < 702
  finish
endif
let g:loaded_emacs_cursor = 1

let s:save_cpo = &cpoptions
set cpoptions&vim

function! s:insert_enter() abort
  set eventignore+=InsertLeave,InsertEnter
  return ''
endfunction

function! s:insert_leave() abort
  set eventignore-=InsertLeave,InsertEnter
  return ''
endfunction

inoremap <expr> <Plug>(insert-enter) <SID>insert_enter()
inoremap <expr> <Plug>(insert-leave) <SID>insert_leave()

inoremap <Plug>(emacs-down) <C-g>u<C-o>gj
inoremap <Plug>(emacs-up) <C-g>u<C-o>gk
inoremap <Plug>(emacs-eol) <C-g>u<C-o>g$
inoremap <expr> <Plug>(emacs-bol) (col('.') == 2) ? "\<Left>" : "\<C-g>u\<C-o>g0"
inoremap <expr> <Plug>(emacs-kill) col('.') == col('$') ? "\<C-o>gJ" : "\<C-g>u\<C-o>d$"

map <C-c> <Esc>
nmap <C-j> <CR>
imap <C-j> <CR>
imap <C-h> <BS>
inoremap <C-b> <Left>
inoremap <C-f> <Right>
inoremap <C-d> <Del>
imap <C-p> <Plug>(insert-enter)<Plug>(emacs-up)<Plug>(insert-leave)
imap <C-n> <Plug>(insert-enter)<Plug>(emacs-down)<Plug>(insert-leave)
imap <C-a> <Plug>(insert-enter)<Plug>(emacs-bol)<Plug>(insert-leave)
imap <C-e> <Plug>(insert-enter)<Plug>(emacs-eol)<Plug>(insert-leave)
imap <C-k> <Plug>(insert-enter)<Plug>(emacs-kill)<Plug>(insert-leave)

cmap <C-h> <BS>
cnoremap <C-a> <Home>
cnoremap <C-b> <Left>
cnoremap <C-f> <Right>
cnoremap <C-d> <Del>
cnoremap <C-k> <C-\>e getcmdpos() == 1 ? '' : getcmdline()[:getcmdpos()-2]<CR>

smap <C-a> <C-g>I
smap <C-e> <C-g>A
smap <C-b> <C-g>I
smap <C-f> <C-g>A
smap <C-v> <C-g>ra

let &cpoptions = s:save_cpo
unlet s:save_cpo
