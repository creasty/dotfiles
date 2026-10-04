language en_US

" disable builtin plugins
let g:loaded_netrwPlugin = 1
let g:loaded_tar = 1
let g:loaded_tarPlugin = 1
let g:loaded_zip = 1
let g:loaded_zipPlugin = 1

" configure runtime features
let g:markdown_folding = 1
let g:omni_sql_no_default_maps = 1
let g:tex_flavor = 'latex'

"=== Basic
"==============================================================================================
" no backup and swap files
set nowritebackup
set noswapfile

" enable auto write
set autowrite

" disable mode lines
set modelines=0

" yank use system clipboard
set clipboard=unnamed

" automatic formatting
set formatoptions& formatoptions+=lm]

" in/decrement
set nrformats=alpha

" wildcard settings
set wildignore& wildignore+=*.so,*.swp

" find file with suffixes
set suffixesadd& suffixesadd+=.ts,.d.ts,.tsx

" ignore case unless contains upper case
set ignorecase
set smartcase

" ignore case in filenames
set wildignorecase

" indent
set cindent
set shiftround
set expandtab
set tabstop=2 shiftwidth=2 softtabstop=0

" move cursor over lines
set whichwrap=b,s,h,l,<,>,[,]

" virtualedit with freedom
set virtualedit& virtualedit+=block

" split behavior
set splitright
set splitbelow
set splitkeep=screen

"=== Appearance
"==============================================================================================
" enables 24-bit RGB color in the TUI
set termguicolors

" skip intro screen
set shortmess+=I

" stop showing mode
set noshowmode

" always show statusline & tabline
set laststatus=3
set showtabline=2

" show line numbers
set number

" always show sign column
set signcolumn=yes:2

" color column
set colorcolumn=90

" match pairs
set showmatch

" display nonprintable characters as hex
set display+=uhex

" show hidden characters
"
" [tab]
" U+2500 (Box Drawings Light Horizontal)
" U+23F5 (Black Medium Right-Pointing Triangle)
"
" [lead,trail]
" U+00B7 (Middle Dot)
"
" [nbsp]
" U+2219 (Bullet Operator)
"
" [extends,precedes]
" U+276F (Heavy Right-Pointing Angle Quotation Mark Ornament)
" U+276E (Heavy Left-Pointing Angle Quotation Mark Ornament)
set list
set listchars=tab:──⏵,lead:·,trail:·,nbsp:∙,extends:❯,precedes:❮

" indent wrapped lines
" U+21B3 (Downwards Arrow with Tip Rightwards)
set breakindent
set showbreak=↳

" diagonal lines where a diff has none on one side
" U+2571 (Box Drawings Light Diagonal Upper Right to Lower Left)
set fillchars+=diff:╱
" and no fold column, which diff mode opens
set diffopt+=foldcolumn:0

" transparent pmenu
set pumblend=10

" change cursor styles (a terminal's as Insert mode's)
set guicursor=n-c-sm:block-Cursor,i-ci-ve-t:ver25-Cursor,v-r-cr-o:hor20-Cursor

" line offset when scrolling
set scrolloff=5

" fast update
set updatetime=200

" folding
set foldmethod=indent
set foldlevel=20
set foldlevelstart=20

" window title
set title titlestring=%{UserTitleString()}

function! UserTitleString() abort
  " a file's path, or a terminal's directory (nvim/lua/user/terminal.lua)
  if empty(&buftype) || &buftype ==# 'terminal'
    let l:path = (&buftype ==# 'terminal') ? get(b:, 'user_terminal_cwd', '') : expand('%:p')
    let l:path = (l:path !=# '') ? l:path : getcwd()
    let l:path = substitute(l:path, $HOME, '~', '')
    let l:path = substitute(l:path, '\~/go/src/github.com', '~g', '')
    return l:path
  else
    let l:name = bufname()
    let l:name = (l:name !=# '') ? l:name : &buftype
    return l:name
  endif
endfunction

" schema
colorscheme candle

" tabline & statusline
lua require('user.ui').setup()

"=== Keymaps
"==============================================================================================
" <Space> [nx] and <C-s> [nixs] are used as unofficial leader keys

" leader key
let g:mapleader = ','

" remove default mappings
nnoremap ZQ <Nop>
xnoremap K <Nop>

" move cursor visually with long lines
nmap j gj
xmap j gj
nmap k gk
xmap k gk

" paste with C-v
inoremap <C-v> <C-r><C-p>*
inoremap <C-\> <C-v>
cnoremap <C-v> <C-r>*
cnoremap <C-\> <C-v>
snoremap <C-v> <C-g>"_c<C-r><C-p>*
snoremap <C-\> <C-v>

" do not store to register with x, c
nnoremap X "_X
xnoremap x "_x
nnoremap c "_c
nnoremap C "_C
xnoremap c "_c

" submode for x
nnoremap <SID>(x) <Ignore>
nnoremap <script> x "_x<SID>(x)
nnoremap <script> <SID>(x)x <Cmd>undojoin<CR>x<SID>(x)

" submode for C-a/C-x
nnoremap <SID>(inc) <Ignore>
nnoremap <script> <C-a> <C-a><SID>(inc)
nnoremap <script> <C-x> <C-x><SID>(inc)
nnoremap <script> <SID>(inc)<C-a> <Cmd>undojoin<CR><C-a><SID>(inc)
nnoremap <script> <SID>(inc)<C-x> <Cmd>undojoin<CR><C-x><SID>(inc)

" keep the cursor in place while joining lines
nnoremap J mZJ`ZmZ

" split lines: inverse of J
nnoremap <Space>J ylpr<CR>

" reselect visual block after indent/outdent
xnoremap < <gv
xnoremap > >gv

" indent/outdent
inoremap <C-s><C-h> <C-d>
inoremap <C-s><C-l> <C-t>
inoremap <C-s>h <C-d>
inoremap <C-s>l <C-t>

" submode for ge/gE
nnoremap <SID>(word) <Nop>
nnoremap <script> ge ge<SID>(word)
nnoremap <script> gE gE<SID>(word)
nnoremap <script> <SID>(word)e ge<SID>(word)
nnoremap <script> <SID>(word)E gE<SID>(word)

" easy key
nnoremap <Space>h g^
xnoremap <Space>h g^
nnoremap <Space>l g$
xnoremap <Space>l g$

" paste lines at the indentation of the cursor's line
nnoremap p ]p
nnoremap P [p

" reselect pasted text
nnoremap <expr> gp '`[' . strpart(getregtype(), 0, 1) . '`]'

" select all
nnoremap <Space>a ggVG

" replace selection
xnoremap <Space>s "xy:<C-u>%s/<C-r>=escape(@x, '\\/.*$^~')<CR>/

" replace word under cursor
nnoremap <Space>* "xyiw:<C-u>%s/\<<C-r>=escape(@x, '\\/.*$^~')<CR>\>/

" tags
nnoremap <C-]> g<C-]>

" window and buffer navigation
nmap <C-s> <C-w>

nnoremap <C-w><C-n> gt
nnoremap <C-w>n     gt
nnoremap <C-w><C-b> gT
nnoremap <C-w>b     gT
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

" terminals: shells and commands, in windows and tabs too
lua require('user.terminal').setup()

" command-line shortcuts (:s/ -> :s/\v//g, :ee, :w!!, ...)
lua require('user.cmdline').setup()

" macOS's keyboard layout (ABC) in normal mode, not an input method
lua require('user.input_source').setup()

" operators and commands on text: r{motion}, ge_ and the other cases, :Subs, :RengBang
lua require('user.text_ops').setup()

" submode for window resizing
nnoremap <SID>(ws) <Nop>
nnoremap <script> <C-w>+ <C-w>+<SID>(ws)
nnoremap <script> <C-w>- <C-w>-<SID>(ws)
nnoremap <script> <C-w>> <C-w>><SID>(ws)
nnoremap <script> <C-w>< <C-w><<SID>(ws)
nnoremap <script> <SID>(ws)+ <C-w>+<SID>(ws)
nnoremap <script> <SID>(ws)- <C-w>-<SID>(ws)
nnoremap <script> <SID>(ws)> <C-w>><SID>(ws)
nnoremap <script> <SID>(ws)< <C-w><<SID>(ws)

"=== Misc
"==============================================================================================
" reopen current buffer with specific encoding
command! -bang -nargs=1 -complete=customlist,EncodingNameComplete Encoding
  \ edit<bang> ++enc=<args>
function! EncodingNameComplete(a, l, p) abort
  " :help encoding-names
  let l:list = 'utf-8,sjis,euc-jp'
    \ . ',latin1,iso-8859-n,koi8-r,koi8-u,macroman,euc-kr,euc-cn,big5,euc-tw,ucs-2,ucs-2le,utf-16,utf-16le,ucs-4,ucs-4le'
    \ . ',cp437,cp737,cp775,cp850,cp852,cp855,cp857,cp860,cp861,cp862,cp863,cp865,cp866,cp869'
    \ . ',cp874,cp1250,cp1251,cp1253,cp1254,cp1255,cp1256,cp1257,cp1258,cp932,cp949,cp936,cp950'
  return filter(split(l:list, ','), { _, v -> v =~# a:a })
endfunction

" change indent style
command! -nargs=1 SoftTab :setl expandtab tabstop=<args> shiftwidth=<args>
command! -nargs=1 HardTab :setl noexpandtab tabstop=<args> shiftwidth=<args>

" profiler
command! -nargs=0 ProfStart
  \ profile start /tmp/vim-vimscript.log |
  \ profile func * |
  \ profile! file *
command! -nargs=0 ProfStop profile stop
command! -nargs=0 ProfOpen vsplit /tmp/vim-vimscript.log |

" capture Ex command output and print to a buffer
command! -nargs=+ -complete=command Capture
  \ try |
    \ redir => s:put_command_result |
    \ silent <args> |
  \ finally |
    \ redir END |
    \ call append('.', split(s:put_command_result, '\n')) |
  \ endtry

" clean up hidden buffers
command! CleanBuffers call <SID>clean_buffers()

function! s:clean_buffers() abort
  redir => l:bufs
    silent buffers
  redir END

  for l:buf in split(l:bufs, "\n")
    let l:t = matchlist(l:buf, '\v^\s*(\d+)([^"]*)')
    if l:t[2] !~# '[#a+]'
      exec 'bdelete' l:t[1]
    endif
  endfor
endfunction

" strip trailing spaces
augroup _strip_trailing_spaces
  autocmd!
  autocmd InsertLeave *
    \ call timer_stop(get(b:, 'strip_ts_timer_id', -1)) |
    \ let b:strip_ts_timer_id = timer_start(100, {-> s:strip_ts() })
augroup END

function! s:strip_ts() abort
  if &readonly || !&modifiable
    return
  endif
  if !empty(&buftype)
    return
  endif
  if mode() !=# 'n'
    return
  endif

  let l:saved_cursor = getpos('.')
  keeppatterns %s/\v\s+$//ge
  call setpos('.', l:saved_cursor)
endfunction

" back to the last line I edited
augroup _restore_last_pos
  autocmd!
  autocmd BufReadPost *
    \ if line("'\"") > 1 && line("'\"") <= line("$") |
      \ exe "normal! g`\"" |
    \ endif
augroup END

" file detect on read / save (not a terminal's, whose name ends in its command: term://...:/bin/zsh)
augroup _enhance_ftdetect
  autocmd!
  autocmd BufWritePost,BufReadPost,BufEnter *
    \ if &buftype !=# 'terminal' && &filetype ==# '' |
      \ filetype detect |
    \ endif
augroup END

" create directories if not exist
augroup _auto_mkdir
  autocmd!
  autocmd BufWritePre * call <SID>mkdir(expand('<afile>:p:h'))
augroup END

function! s:mkdir(dir) abort
  if !isdirectory(a:dir)
    call mkdir(a:dir, 'p')
  endif
endfunction

" once the last UI is gone (its window closed), save the ShaDa file with any error silenced, and not again on exit:
" an error on exit waits for Enter where no one can press it, and keeps Neovim running (CLAUDE.md)
augroup _exit_without_ui
  autocmd!
  autocmd UILeave *
    \ if v:exiting is v:null && empty(nvim_list_uis()) |
      \ silent! wshada |
      \ set shada= |
    \ endif
augroup END

"=== Plugins
"==============================================================================================
" (before the tree-sitter plugins load)
lua require('user.plugin.treesitter.compat')

" filetype.vim before $VIMRUNTIME/filetype.lua, as Neovim sources them after init.vim
" (lazy.nvim would source filetype.lua first)
filetype on

" installed and loaded by lazy.nvim
lua require('user.plugins').setup()

"  Cross-plugin integration
"-----------------------------------------------
" completion, snippets, auto-pairs and AI suggestions sharing the insert-mode keys
lua require('user.intelligence').setup()
