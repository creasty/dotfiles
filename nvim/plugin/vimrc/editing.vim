if exists('g:loaded_vimrc_editing') || v:version < 702
  finish
endif
let g:loaded_vimrc_editing = 1

let s:save_cpo = &cpoptions
set cpoptions&vim

augroup vimrc_editing
  autocmd!
augroup END

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

" break undo with chunk delete actions
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
xnoremap <Space>h g^
nnoremap <Space>l g$
xnoremap <Space>l g$
nmap <Space>m %
xmap <Space>m %

" insert blank lines without going into insert mode
nnoremap <Space>o mZo<Esc>`ZmZ
nnoremap <Space>O mZO<Esc>`ZmZ

" reselect pasted text
nnoremap <expr> gp '`[' . strpart(getregtype(), 0, 1) . '`]'

" select all
nnoremap <Space>a ggVG

" remove default mappings
nnoremap ZQ <Nop>
xnoremap K <Nop>

" tags
nnoremap tn <Cmd>tn<CR>
nnoremap tp <Cmd>tp<CR>
nnoremap tl <Cmd>tags<CR>
nnoremap <C-]> g<C-]>

" tab pages / buffers
nmap <C-s> <C-w>

nnoremap <C-w><C-n> gt
nnoremap <C-w><C-b> gT
nnoremap <C-w><C-t> <Cmd>tabnew<CR>
nnoremap <C-w>t     <Cmd>tabnew<CR>
nnoremap <C-w><C-v> <Cmd>vnew<CR>
nnoremap <C-w>v     <Cmd>vnew<CR>
nnoremap <C-w><C-d> <C-w><C-q>
nnoremap <C-w>d     <C-w>q
nnoremap <C-w><C-s> <C-w><C-n>
nnoremap <C-w>s     <C-w>n
nnoremap <C-w><C-c> <Nop>
nnoremap <C-w>c     <Nop>

nmap <C-w>r     <Plug>(lcb-restore)
nmap <C-w><C-r> <Plug>(lcb-restore)

" search selection
xnoremap * "xy/<C-r>=escape(@x, '\\/.*$^~')<CR>

" replace selection
xnoremap <Space>s "xy<Cmd>%s/<C-r>=escape(@x, '\\/.*$^~')<CR>/

" replace word under cursor
nnoremap <Space>s "xyiw<Cmd>%s/\<<C-r>=escape(@x, '\\/.*$^~')<CR>\>/

" change soft-indent size
command! -nargs=1 SoftTab :setl expandtab tabstop=<args> shiftwidth=<args>

" substitute with match case
command! -nargs=1 -range SubMC <line1>,<line2>call match_case#substitute(<f-args>)

" dim match highlight
autocmd vimrc_editing User ClearSearchHighlight :
autocmd vimrc_editing BufReadPost * ClearSearchHighlight

command! -nargs=0 ClearSearchHighlight nohlsearch | doautocmd User ClearSearchHighlight
nnoremap <silent> <Space><Space> <Cmd>ClearSearchHighlight<CR>

" back to the last line I edited
autocmd vimrc_editing BufReadPost *
  \ if line("'\"") > 1 && line("'\"") <= line("$") |
    \ exe "normal! g`\"" |
  \ endif

" file detect on read / save
autocmd vimrc_editing BufWritePost,BufReadPost,BufEnter *
  \ if &l:filetype ==# '' || exists('b:ftdetect') |
    \ unlet! b:ftdetect |
    \ filetype detect |
  \ endif

let &cpoptions = s:save_cpo
unlet s:save_cpo
