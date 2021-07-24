if exists('g:loaded_emacs_cursor') || v:version < 702
  finish
endif
let g:loaded_emacs_cursor = 1

let s:save_cpo = &cpoptions
set cpoptions&vim

augroup emacs_cursor
  autocmd!
  autocmd InsertEnter * set eventignore-=InsertLeave
augroup END

function! s:insert_enter() abort
  set eventignore+=InsertLeave
  return ""
endfunction

inoremap <expr> <Plug>(emacs-ins) <SID>insert_enter()

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
imap <C-p> <Plug>(emacs-ins)<Plug>(emacs-up)
imap <C-n> <Plug>(emacs-ins)<Plug>(emacs-down)
imap <C-a> <Plug>(emacs-ins)<Plug>(emacs-bol)
imap <C-e> <Plug>(emacs-ins)<Plug>(emacs-eol)
imap <C-k> <Plug>(emacs-ins)<Plug>(emacs-kill)

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
smap <C-d> <Del>
smap <C-c> <Esc>

let &cpoptions = s:save_cpo
unlet s:save_cpo
