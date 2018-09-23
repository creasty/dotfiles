"=== Fast <C-o> hack
"==============================================================================================
function! s:insert_enter()
  set eventignore+=InsertLeave,InsertEnter
  return ''
endfunction

function! s:insert_leave()
  set eventignore-=InsertLeave,InsertEnter
  return "\<C-r>\<Esc>" | " Fix for missing screen update
endfunction

inoremap <expr> <Plug>(insert-enter) <SID>insert_enter()
inoremap <expr> <Plug>(insert-leave) <SID>insert_leave()


"=== Editing
"==============================================================================================
" indent
set noautoindent
set smartindent
set cindent
set smarttab
set expandtab
set tabstop=2 shiftwidth=2 softtabstop=0
set shiftround

" change soft-indent size
command! -nargs=1 SoftTab :setl expandtab tabstop=<args> shiftwidth=<args>

" virtualedit with freedom
set virtualedit& virtualedit+=block

" don't insert the current comment leader on leading lines
set formatoptions-=ro

" remove a comment leader when joining lines
if has('gui_running')
  set formatoptions+=j
endif

" edit and apply vimrc
command! EditVimrc edit $MYVIMRC

" toggle paste mode
command! Pt :set paste!

" pay respect to vim
nnoremap <Up> <Nop>
nnoremap <Down> <Nop>
nnoremap <Left> <Nop>
nnoremap <Right> <Nop>

" move cursor visually with long lines
nmap j gj
vmap j gj
nmap k gk
vmap k gk

" Emacs-like key bindings
inoremap <Plug>(emacs-down) <C-g>u<C-o>gj
inoremap <Plug>(emacs-up) <C-g>u<C-o>gk
inoremap <Plug>(emacs-eol) <C-g>u<C-o>g$
inoremap <expr> <Plug>(emacs-bol) (col('.') == 2) ? "\<Left>" : "\<C-g>u\<C-o>g0"
inoremap <expr> <Plug>(emacs-kill) col('.') == col('$') ? "\<C-o>gJ" : "\<C-g>u\<C-o>d$"

map <C-c> <Esc>
imap <C-j> <CR>
inoremap <C-b> <Left>
inoremap <C-f> <Right>
inoremap <C-d> <Del>
imap <C-p> <Plug>(insert-enter)<Plug>(emacs-up)<Plug>(insert-leave)
imap <C-n> <Plug>(insert-enter)<Plug>(emacs-down)<Plug>(insert-leave)
imap <C-a> <Plug>(insert-enter)<Plug>(emacs-bol)<Plug>(insert-leave)
imap <C-e> <Plug>(insert-enter)<Plug>(emacs-eol)<Plug>(insert-leave)
imap <C-k> <Plug>(insert-enter)<Plug>(emacs-kill)<Plug>(insert-leave)

cnoremap <C-a> <Home>
cnoremap <C-b> <Left>
cnoremap <C-f> <Right>
cnoremap <C-d> <Del>
cnoremap <C-k> <C-\>e getcmdpos() == 1 ? '' : getcmdline()[:getcmdpos()-2]<CR>

" paste
inoremap <C-v> <C-r><C-p>*
cnoremap <C-v> <C-r>*

inoremap <C-\> <C-v>
cnoremap <C-\> <C-v>

" do not store to register with x, c
nnoremap x "_x
nnoremap X "_X
nnoremap c "_c
nnoremap C "_C
vnoremap c "_c
vnoremap x "_x

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
vnoremap < <gv
vnoremap > >gv

" indent/outdent
inoremap <C-s><C-h> <C-d>
inoremap <C-s><C-l> <C-t>
inoremap <C-s>h <C-d>
inoremap <C-s>l <C-t>

" easy key
nnoremap <Space>h g^
nnoremap <Space>l g$
nnoremap <Space>m %
vnoremap <Space>h g^
vnoremap <Space>l g$
vnoremap <Space>m %

" insert blank lines without going into insert mode
nnoremap <Space>o mZo<Esc>`ZmZ
nnoremap <Space>O mZO<Esc>`ZmZ

" reselect pasted text
nnoremap <expr> gp '`[' . strpart(getregtype(), 0, 1) . '`]'

" select all
map <Space>a ggVG

" repeat the last recorded macro
map Q @@

" avoid suicide
nnoremap ZQ <Nop>

" useless and annoying
vnoremap K <Nop>

" sort lines inside block
nnoremap <leader>sor ?{<CR>jV/\v^\s*\}?$<CR>k:sort<CR>:noh<CR>

" tags
nnoremap tn :tn<CR>
nnoremap tp :tp<CR>
nnoremap tl :tags<CR>

nnoremap <C-]> g<C-]>

" tab pages / buffers
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

if has('gui_running')
  nmap <C-w><C-o> <C-w>o
  nnoremap <C-w>o :maca newWindow:<CR>
end

" tmux
nmap <C-s> <C-w>

" remove trailing spaces before saving
autocmd vimrc BufWritePre *
  \ if &ft != 'markdown' |
    \ :%s/\s\+$//ge |
  \ endif

" convert tabs to soft tabs if expandtab is set
autocmd vimrc BufWritePre *
  \ if &et |
    \ exec "%s/\t/" . repeat(' ', &tabstop) . "/ge" |
  \ endif

" back to the last line I edited
autocmd vimrc BufReadPost *
  \ if line("'\"") > 1 && line("'\"") <= line("$") |
    \ exe "normal! g`\"" |
  \ endif

" numbering selection in visual-block mode
nnoremap <silent> sc :ContinuousNumber <C-a><CR>
vnoremap <silent> sc :ContinuousNumber <C-a><CR>
command! -count -nargs=1 ContinuousNumber
  \ let c = col('.') |
  \ for n in range(1, <count>?<count>-line('.'):1) |
    \ exec 'normal! j' . n . <q-args> |
    \ call cursor('.', c) |
  \ endfor

" use I, A for all visual modes
vnoremap <expr> I <SID>force_blockwise_visual('I')
vnoremap <expr> A <SID>force_blockwise_visual('A')

function! s:force_blockwise_visual(next_key)
  let l:m = mode()

  if l:m ==# 'v'
    return "\<C-v>" . a:next_key
  elseif l:m ==# 'V'
    return "\<C-v>0o$" . a:next_key
  else
    return a:next_key
  endif
endfunction

" q:
nnoremap q: :q
nnoremap <Space>: q:

" dotfiles
command! Dotfiles :exec 'lcd' fnameescape(g:env.path.dotfiles)
