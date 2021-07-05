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

" no backup and swap files
set nobackup
set noswapfile

" nohidden buffers
set nohidden

" automatic formatting
set formatoptions&
set formatoptions+=lmq] " add multibyte option
set formatoptions-=ro " don't insert the current comment leader on leading lines
set formatoptions+=j " remove a comment leader when joining lines

" initial dir of explorer
set browsedir=buffer

" move cursor over lines
set whichwrap=b,s,h,l,<,>,[,]

" unnecessary, use lightline
set noshowmode

" disable mode lines
set modelines=0

" command history
set history=1000

" yank use system clipboard
set clipboard=unnamed

" inc/decrement
set nrformats=alpha,hex

" wildcard settings
set wildignore& wildignore+=*.so,*.swp

" find file with suffixes
set suffixesadd& suffixesadd+=.ts,.tsx,.js,.jsx,.d.ts,.swift,.scss,.css

" fast update
set updatetime=200

" ignore case unless contains upper case
set ignorecase
set smartcase

" ignore case in filenames
set wildignorecase

" indent
set smartindent
set cindent
set expandtab
set shiftround
set tabstop=2 shiftwidth=2 softtabstop=0

" virtualedit with freedom
set virtualedit& virtualedit+=block

let &cpoptions = s:save_cpo
unlet s:save_cpo
