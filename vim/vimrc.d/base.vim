" change cursor shape in iTerm
if !g:env.is_gui && exists('$ITERM_PROFILE')
  if exists('$TMUX')
    let &t_SI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=1\x7\<Esc>\\"
    let &t_EI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=0\x7\<Esc>\\"
  else
    let &t_SI = "\<Esc>]50;CursorShape=1\x7"
    let &t_EI = "\<Esc>]50;CursorShape=0\x7"
  endif
endif

" use comma as leader
let mapleader = ','

" split to right / bottom
set splitright
set splitbelow

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
set complete=k

" yank use system clipboard
set clipboard=unnamed

" inc/decrement
set nf=alpha,hex

" disable IME
set imdisable

" nohidden buffers
set nohidden

" use Blowfish algorithm
set cryptmethod=blowfish

" wildcard settings
set suffixes=.bak,~,.swp,.o,.info,.aux,.log,.dvi,.bbl,.blg,.brf,.cb,.ind,.idx,.ilg,.inx,.out,.toc
set wildignore& wildignore+=*.so,*.swp

" find file with suffixes
set suffixesadd& suffixesadd+=.js,.coffee,.swift,.scss

" fast update
set updatetime=200

" cricle search within files
set wrapscan

" ignore case only if contains upper case
set ignorecase
set smartcase

" incremental search
set incsearch

" match highlight
set hlsearch

" make regex a little easier to type
" set magic

" dim match highlight
nnoremap <silent> <Space><Space> :nohlsearch<CR><Esc>

" erase previous match highlight
autocmd vimrc BufReadPost * :nohlsearch

" search selection
vnoremap <Space>/ "xy/<C-r>=escape(@x, '\\/.*$^~')<CR>

" replace selection
vnoremap <Space>r "xy:%s/<C-r>=escape(@x, '\\/.*$^~')<CR>/

" replace word under cursor
nnoremap <Space>* "xyiw:%s/\<<C-r>=escape(@x, '\\/.*$^~')<CR>\>/

" auto escaping
cnoremap <expr> /  getcmdtype() == '/' ? '\/' : '/'
cnoremap <expr> ?  getcmdtype() == '?' ? '\?' : '?'

" ag
if g:env.support.ag
  set grepprg=ag\ --nogroup\ -iS
  set grepformat=%f:%l:%m
endif
