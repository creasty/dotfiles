filetype plugin indent on


"=== Encoding
"==============================================================================================
set encoding=utf-8
set fileencodings=ucs_bom,utf8,ucs-2le,ucs-2
set fileformats=unix,dos,mac

" auto detection
if &encoding !=# 'utf-8'
  set encoding=japan
  set fileencoding=japan
endif
if has('iconv')
  let s:enc_euc = 'euc-jp'
  let s:enc_jis = 'iso-2022-jp'

  if iconv("\x87\x64\x87\x6a", 'cp932', 'eucjp-ms') ==# "\xad\xc5\xad\xcb"
    let s:enc_euc = 'eucjp-ms'
    let s:enc_jis = 'iso-2022-jp-3'
  elseif iconv("\x87\x64\x87\x6a", 'cp932', 'euc-jisx0213') ==# "\xad\xc5\xad\xcb"
    let s:enc_euc = 'euc-jisx0213'
    let s:enc_jis = 'iso-2022-jp-3'
  endif

  if &encoding ==# 'utf-8'
    let s:fileencodings_default = &fileencodings
    let &fileencodings = s:enc_jis .','. s:enc_euc .',cp932'
    let &fileencodings = s:fileencodings_default .','. &fileencodings
    unlet s:fileencodings_default
  else
    let &fileencodings = &fileencodings .','. s:enc_jis
    set fileencodings+=utf-8,ucs-2le,ucs-2
    if &encoding =~# '^\(euc-jp\|euc-jisx0213\|eucjp-ms\)$'
      set fileencodings+=cp932
      set fileencodings-=euc-jp
      set fileencodings-=euc-jisx0213
      set fileencodings-=eucjp-ms
      let &encoding = s:enc_euc
      let &fileencoding = s:enc_euc
    else
      let &fileencodings = &fileencodings .','. s:enc_euc
    endif
  endif

  unlet s:enc_euc
  unlet s:enc_jis
endif

" force &fileencoding to use &encoding
" when files not contain japanese charactors
augroup AutoDetectEncording
  autocmd!
  autocmd BufReadPost *
    \ if &fileencoding =~# 'iso-2022-jp' && search("[^\x01-\x7e]", 'n') == 0 |
      \ let &fileencoding = &encoding |
    \ endif
augroup END


"=== Basics
"==============================================================================================
" unregister autocmds
augroup vimrc
  autocmd!
augroup END

" make special key bindings like <C-s> work
if !has('gui_running')
  silent !stty -ixon > /dev/null 2>&1
endif

" use comma as leader
let mapleader = ','

" split to right
set splitright

" use double width to print non-ascii charactors
set ambiwidth=double

" line offset when scrolling
set scrolloff=5

" no auto line breaking
set textwidth=0

" no backup and swap files
set nobackup
set noswapfile

" reload when files modified outside of vim
set autoread

" delete over lines and indents
set backspace=indent,eol,start

" add multibyte option
set formatoptions& formatoptions+=lmoq

" no beeps
set vb t_vb=

" initial dir of explorer
set browsedir=buffer

" move cursor over lines
set whichwrap=b,s,h,l,<,>,[,]

" display commands in statusline
set showcmd

" unnecessary, use lightline
set noshowmode

" config viminfo
" remember marks for last 50 files
" contents of register up to 100 lines each
" skip register with more than 100 kbytes
set viminfo='50,<1000,s100

" disable mode lines
set modelines=0

" command line completion
set wildmenu
set wildmode=list:full

" fast terminal connection
set ttyfast

" command history
set history=1000

" use dictionaries for completion
set complete& complete+=k

" inc/decrement
set nf=alpha,hex

" disable IME
set imdisable

" nohidden buffers
set nohidden

" wildcard settings
set suffixes=.bak,~,.swp,.o,.info,.aux,.log,.dvi,.bbl,.blg,.brf,.cb,.ind,.idx,.ilg,.inx,.out,.toc
set wildignore& wildignore+=*/tmp/*,*.so,*.swp,*.zip

" find file with suffixes
set suffixesadd& suffixesadd+=.js,.coffee,.swift,.scss


"=== Apperance
"==============================================================================================
" syntax highlight
syntax enable

" always show statusline
set laststatus=2

" always show tabline
set showtabline=2

" match pairs
set showmatch

" show line numbers
set number

" highlighting current line will slow down vim
set nocursorline

" do not redraw during command
set lazyredraw

" limit syntax highlighting
set synmaxcol=512

" display very very long line at the end of file
set display& display+=lastline

" display nonprintable charactors as hex
set display+=uhex


"=== Search
"==============================================================================================
" cricle search within files
set wrapscan

" ignore case only if contains upper case
set ignorecase
set smartcase

" incremental search
set incsearch

" match highlight
set hlsearch

" dim match highlight
nnoremap <silent> // :nohlsearch<CR><Esc>

" erase previous match highlight
autocmd vimrc BufReadPost * :nohlsearch

" search selection
vnoremap // /<C-r>=escape(@", '\\/.*$^~')<CR>

" replace selection
vnoremap /r "xy:%s/<C-r>=escape(@x, '\\/.*$^~')<CR>/

" replace word under cursor
nnoremap <expr> s* ':%s/\<' . expand('<cword>') . '\>/'

" auto escaping
cnoremap <expr> /  getcmdtype() == '/' ? '\/' : '/'
cnoremap <expr> ?  getcmdtype() == '?' ? '\?' : '?'


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

" virtualedit with freedom
set virtualedit& virtualedit+=block

" don't insert the current comment leader on leading lines
set formatoptions-=ro

" toggle paste mode
command! Pt :set paste!

" move cursor visually with long lines
nmap j gj
vmap j gj
nmap k gk
vmap k gk

" Emacs-like key bindings
imap <C-j> <CR>
map <C-c> <Esc>
inoremap <C-n> <C-o>gj
inoremap <C-p> <C-o>gk
inoremap <C-b> <Left>
inoremap <C-f> <Right>
inoremap <expr> <C-a> (col('.') == 2) ? "\<Left>" : "\<C-o>g0"
inoremap <C-e> <C-o>g$
inoremap <C-d> <Del>
" inoremap <C-h> <C-g>u<C-h>
inoremap <expr> <C-k> "\<C-g>u".(col('.') == col('$') ? '<C-o>gJ' : '<C-o>d$')

cnoremap <C-a> <Home>
cnoremap <C-b> <Left>
cnoremap <C-f> <Right>
cnoremap <C-d> <Del>
cnoremap <C-k> <C-\>e getcmdpos() == 1 ? '' : getcmdline()[:getcmdpos()-2]<CR>

" paste
inoremap <C-v> <C-r><C-p>*
cnoremap <C-v> <C-r>*

" auto wrap
vnoremap ( S(
vnoremap { S{
vnoremap [ S[
vnoremap " S"
vnoremap ' S'

" do not store to register with x, c
nnoremap x "_x
nnoremap X "_X
nnoremap c "_c
nnoremap C "_C

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

" use sane regexes
nnoremap / /\v
vnoremap / /\v

" easy key
nnoremap <Space>h ^
nnoremap <Space>l $
nnoremap <Space>m %

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

" tab pages / buffers
nmap <C-w><C-t> <C-w>t
nnoremap <C-w>t :tabnew<CR>

nmap <C-w><C-v> <C-w>v
nnoremap <C-w>v :vnew<CR>

" remove trailing spaces before saving
autocmd vimrc BufWritePre *
  \ if &ft != 'markdown' |
    \ :%s/\s\+$//ge |
  \ endif

" convert tabs to soft tabs if expandtab is set
autocmd vimrc BufWritePre *
  \ if &et |
    \ exec "%s/\t/  /ge" |
  \ endif

" back to the last line I edited
autocmd vimrc BufReadPost *
  \ if line("'\"") > 1 && line("'\"") <= line("$") |
    \ exe "normal! g`\"" |
  \ endif

" use I, A for all visual modes
vnoremap <expr> I <SID>force_blockwise_visual('I')
vnoremap <expr> A <SID>force_blockwise_visual('A')

function! s:force_blockwise_visual(next_key)
  let m = mode()

  if m == 'v'
    return "\<C-v>" . a:next_key
  elseif m == 'V'
    return "\<C-v>0o$" . a:next_key
  else
    return a:next_key
  endif
endfunction


"=== Utils
"==============================================================================================
" reopen current buffer with specific encoding
command! -bang -nargs=? Utf8
  \ edit<bang> ++enc=utf-8 <args>
command! -bang -nargs=? Sjis
  \ edit<bang> ++enc=cp932 <args>
command! -bang -nargs=? Jis
  \ edit<bang> ++enc=iso-2022-jp <args>
command! -bang -nargs=? Euc
  \ edit<bang> ++enc=eucjp <args>

" create directories if not exist
autocmd vimrc BufWritePre *
 \ call s:auto_mkdir(expand('<afile>:p:h'))

function! s:auto_mkdir(dir)
  if !isdirectory(a:dir)
    call mkdir(iconv(a:dir, &encoding, &termencoding), 'p')
  endif
endfunction

" delete current file
command! -nargs=0 Delete call delete(expand('%')) | enew!

" insert relative path
cnoremap <C-l> <C-r>=expand('%:h') . '/' <CR>

" edit relative :ee
cnoremap <expr> e
  \ (getcmdtype() . getcmdline() == ':e') ? " \<C-r>=expand('%:h') . '/' \<CR>" : 'e'

" home directory :eh
cnoremap <expr> h
  \ (getcmdtype() . getcmdline() == ':e') ? ' ~/' : 'h'

" rename :er
cnoremap <expr> r
  \ (getcmdtype() . getcmdline() == ':e') ? "\<C-u>Rename \<C-r>=expand('%:p') \<CR>" : 'r'

command! -nargs=1 -complete=file Rename f <args> | w | call delete(expand('#'))

" w!! to write a file as sudo
cnoremap <expr> !
  \ (getcmdtype() . getcmdline() == ':w!') ? "\<C-u>w !sudo tee % >/dev/null" : '!'

