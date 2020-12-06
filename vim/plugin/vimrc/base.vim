if exists('g:loaded_vimrc_base') || v:version < 702
  finish
endif
let g:loaded_vimrc_base = 1

let s:save_cpo = &cpoptions
set cpoptions&vim

" split to right / bottom
set splitright
set splitbelow

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

" automatic formatting
set formatoptions&
set formatoptions+=lmq " add multibyte option
set formatoptions-=ro  " don't insert the current comment leader on leading lines
set formatoptions+=j   " remove a comment leader when joining lines

" no beeps
set visualbell t_vb=

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

" ignore case in filenames
set wildignorecase

" fast terminal connection
set ttyfast

" command history
set history=1000

" use dictionaries for completion
set complete=k

" yank use system clipboard
set clipboard=unnamed

" inc/decrement
set nrformats=alpha,hex

" disable IME
set imdisable

" nohidden buffers
set nohidden

" use Blowfish algorithm
if exists('&cryptmethod')
  set cryptmethod=blowfish
endif

" wildcard settings
set suffixes=.bak,~,.swp,.o,.info,.aux,.log,.dvi,.bbl,.blg,.brf,.cb,.ind,.idx,.ilg,.inx,.out,.toc
set wildignore& wildignore+=*.so,*.swp

" find file with suffixes
set suffixesadd& suffixesadd+=.ts,.tsx,.js,.jsx,.d.ts,.coffee,.swift,.scss,.css

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

" ag
if executable('ag')
  set grepprg=ag\ --nogroup\ -iS
  set grepformat=%f:%l:%m
endif

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

let &cpoptions = s:save_cpo
unlet s:save_cpo
