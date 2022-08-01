if exists('g:loaded_emacs_cursor') || v:version < 702
  finish
endif
let g:loaded_emacs_cursor = 1

let s:save_cpo = &cpoptions
set cpoptions&vim

let g:EmacsCursorPumvisible = get(g:, 'EmacsCursorPumvisible', function('pumvisible'))

inoremap <Plug>(emacs-enter) <Cmd>set eventignore+=InsertEnter,InsertLeave<CR>
inoremap <Plug>(emacs-leave) <Cmd>set eventignore-=InsertEnter,InsertLeave<CR>

imap <expr> <Plug>(emacs-down) g:EmacsCursorPumvisible() ?
  \ "\<Down>"
  \ : "\<Plug>(emacs-enter)\<C-g>u\<C-o>gj\<Plug>(emacs-leave)"
imap <expr> <Plug>(emacs-up) g:EmacsCursorPumvisible() ?
  \ "\<Up>"
  \ : "\<Plug>(emacs-enter)\<C-g>u\<C-o>gk\<Plug>(emacs-leave)"
imap <Plug>(emacs-eol) <C-g>u<C-o>g$
imap <expr> <Plug>(emacs-bol) col('.') == 2 ? "\<Left>" : "\<C-g>u\<C-o>g0"
imap <expr> <Plug>(emacs-kill) col('.') == col('$') ? "\<C-o>gJ" : "\<C-g>u\<C-o>d$"

nmap <C-c> <Esc>
nmap <C-j> <CR>

imap <C-c> <Esc>
imap <C-j> <CR>
imap <C-h> <BS>
imap <C-b> <Left>
imap <C-f> <Right>
imap <C-d> <Del>
imap <C-p> <Plug>(emacs-up)
imap <C-n> <Plug>(emacs-down)
imap <C-a> <Plug>(emacs-bol)
imap <C-e> <Plug>(emacs-eol)
imap <C-k> <Plug>(emacs-kill)
inoremap <C-t> <Esc>"0ylxa<C-r>0<Left>

cmap <C-h> <BS>
cmap <C-a> <Home>
cmap <C-b> <Left>
cmap <C-f> <Right>
cmap <C-d> <Del>
cnoremap <C-k> <C-\>e getcmdpos() == 1 ? '' : getcmdline()[:getcmdpos()-2]<CR>

smap <C-a> <C-g>I
smap <C-e> <C-g>A
smap <C-b> <C-g>I
smap <C-f> <C-g>A
smap <C-d> <Del>
smap <C-c> <Esc>

let &cpoptions = s:save_cpo
unlet s:save_cpo
