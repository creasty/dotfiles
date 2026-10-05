if exists('g:loaded_emacs_cursor') || v:version < 702
  finish
endif
let g:loaded_emacs_cursor = 1

let s:save_cpo = &cpoptions
set cpoptions&vim

function! s:pumvisible() abort
  let l:Fn = get(g:, 'EmacsCursorPumvisible', v:null)
  if l:Fn != v:null && l:Fn()
    return v:true
  endif
  return pumvisible()
endfunction

" A Normal mode command through <C-o>, then an empty <Cmd>: with no key after
" the command's last one, 'showcmd' would flush the screen while in Normal
" mode, showing its block cursor for a moment.
function! s:normal(command) abort
  return "\<C-o>" . a:command . "\<Cmd>\<CR>"
endfunction

imap <expr> <Plug>(emacs-down) <SID>pumvisible()
  \ ? "\<Down>"
  \ : "\<C-g>u" . <SID>normal('gj')
imap <expr> <Plug>(emacs-up) <SID>pumvisible()
  \ ? "\<Up>"
  \ : "\<C-g>u" . <SID>normal('gk')
inoremap <expr> <Plug>(emacs-eol) "\<C-g>u" . <SID>normal('g$')
inoremap <expr> <Plug>(emacs-bol) col('.') == 2 ? "\<Left>" : "\<C-g>u" . <SID>normal('g0')
inoremap <expr> <Plug>(emacs-kill) col('.') == col('$') ? <SID>normal('gJ') : "\<C-g>u" . <SID>normal('d$')

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

cmap <C-a> <Home>
cmap <C-b> <Left>
cmap <C-f> <Right>
cmap <C-d> <Del>
cnoremap <C-k> <C-\>e getcmdpos() == 1 ? '' : getcmdline()[:getcmdpos()-2]<CR>
cnoremap <expr> <C-c> pumvisible() ? "\<C-e>" : "\<C-c>"

smap <C-a> <C-g>I
smap <C-e> <C-g>A
smap <C-b> <C-g>I
smap <C-f> <C-g>A
smap <C-d> <Del>

let &cpoptions = s:save_cpo
unlet s:save_cpo
