if exists('g:loaded_vimrc_editing') || v:version < 702
  finish
endif
let g:loaded_vimrc_editing = 1

let s:save_cpo = &cpoptions
set cpoptions&vim

augroup vimrc_editing
  autocmd!
augroup END

" disable arrow keys
nnoremap <Up> <Nop>
nnoremap <Down> <Nop>
nnoremap <Left> <Nop>
nnoremap <Right> <Nop>

" move cursor visually with long lines
nmap j gj
xmap j gj
nmap k gk
xmap k gk

" paste
inoremap <C-v> <C-r><C-p>*
cnoremap <C-v> <C-r>*

inoremap <C-\> <C-v>
cnoremap <C-\> <C-v>

" do not store to register with x, c
if empty(mapcheck('x', 'n')) " check for a 'better undo' support
  nnoremap x "_x
endif
nnoremap X "_X
xnoremap x "_x
nnoremap c "_c
nnoremap C "_C
xnoremap c "_c

" undo
inoremap <C-u> <C-g>u<C-u>
inoremap <C-w> <C-g>u<C-w>

" why are you left out??
nnoremap Y y$

" keep the cursor in place while joining lines
nnoremap J mZJ`ZmZ

" split lines: inverse of J
nnoremap <silent> K ylpr<Enter>

" reselect visual block after indent/outdent
xnoremap < <gv
xnoremap > >gv

" indent/outdent
inoremap <C-s><C-h> <C-d>
inoremap <C-s><C-l> <C-t>
inoremap <C-s>h <C-d>
inoremap <C-s>l <C-t>

" easy key
nnoremap <Space>h g^
nnoremap <Space>l g$
nnoremap <Space>m %
xnoremap <Space>h g^
xnoremap <Space>l g$
xnoremap <Space>m %

" insert blank lines without going into insert mode
nnoremap <Space>o mZo<Esc>`ZmZ
nnoremap <Space>O mZO<Esc>`ZmZ

" reselect pasted text
nnoremap <expr> gp '`[' . strpart(getregtype(), 0, 1) . '`]'

" select all
nnoremap <Space>a ggVG

" avoid suicide
nnoremap ZQ <Nop>

" useless and annoying
xnoremap K <Nop>

" tags
nnoremap tn :tn<CR>
nnoremap tp :tp<CR>
nnoremap tl :tags<CR>
nnoremap <C-]> g<C-]>

" tab pages / buffers
nmap <C-s> <C-w>

nmap <C-w><C-t> <C-w>t
nnoremap <C-w>t :tabnew<CR>

nmap <C-w><C-v> <C-w>v
nnoremap <C-w>v :vnew<CR>

nmap <C-w><C-s> <C-w>s
nnoremap <C-w>s :split +enew<CR>

nmap <C-w><C-c> <Nop>
nnoremap <C-w>c <Nop>

nmap <C-w><C-d> <C-w>d
nnoremap <C-w>d :quit<CR>

nnoremap <C-w><C-n> gt
nnoremap <C-w><C-b> gT

nmap <C-w>r <Plug>(lcb-restore)
nmap <C-w><C-r> <Plug>(lcb-restore)

" search selection
xnoremap * "xy/<C-r>=escape(@x, '\\/.*$^~')<CR>

" replace selection
xnoremap <Space>s "xy:%s/<C-r>=escape(@x, '\\/.*$^~')<CR>/

" replace word under cursor
nnoremap <Space>s "xyiw:%s/\<<C-r>=escape(@x, '\\/.*$^~')<CR>\>/

" auto escaping
cnoremap <expr> / getcmdtype() == '/' ? '\/' : '/'
cnoremap <expr> ? getcmdtype() == '?' ? '\?' : '?'

" change soft-indent size
command! -nargs=1 SoftTab :setl expandtab tabstop=<args> shiftwidth=<args>

" dim match highlight
autocmd vimrc_editing User ClearSearchHighlight :
command! -nargs=0 ClearSearchHighlight nohlsearch | doautocmd User ClearSearchHighlight
autocmd vimrc_editing BufReadPost * ClearSearchHighlight
nnoremap <silent> <Space><Space> :ClearSearchHighlight<CR>

" back to the last line I edited
autocmd vimrc_editing BufReadPost *
  \ if line("'\"") > 1 && line("'\"") <= line("$") |
    \ exe "normal! g`\"" |
  \ endif

let &cpoptions = s:save_cpo
unlet s:save_cpo
