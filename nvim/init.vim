"----------------------------------------------------------------------------------------------
"                                        _
"                                 _   __(_)___ ___  __________
"                                | | / / / __ `__ \/ ___/ ___/
"                                | |/ / / / / / / / /  / /__
"                                |___/_/_/ /_/ /_/_/   \___/
"
"                                 github.com/creasty/dotfiles
"
"----------------------------------------------------------------------------------------------

language en_US
scriptencoding utf-8

" disable builtin plugins
let g:loaded_tar = 1
let g:loaded_tarPlugin = 1
let g:loaded_zip = 1
let g:loaded_zipPlugin = 1
let g:loaded_2html_plugin = 1
let g:loaded_vimball = 1
let g:loaded_vimballPlugin = 1
let g:loaded_netrw = 1
let g:loaded_netrwPlugin = 1

" configure runtime features
let g:omni_sql_no_default_maps = 1
let g:tex_flavor = 'latex'

"=== Basic
"==============================================================================================
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

" python provider
set pyxversion=3

"=== Appearance
"==============================================================================================
colorscheme candle

" skip intro screen
set shortmess+=I

" stop showing mode
set noshowmode

" always show statusline
set laststatus=2

" always show tabline
set showtabline=2

" always show sign column
set signcolumn=yes

" show line numbers
set number

" match pairs
set showmatch

" highlighting current line will slow down vim
set nocursorline

" do not redraw during command
set lazyredraw

" limit syntax highlighting
set synmaxcol=512

" display nonprintable charactors as hex
set display+=uhex

" show hidden charactors
set list
set listchars=tab:▸\ ,nbsp:∘,extends:❯,precedes:❮

" indent wrapped lines
set breakindent
let &showbreak = '   ›'

" conceal
set conceallevel=2 concealcursor=

" color column
set colorcolumn=90

" transparent pmenu
set pumblend=10

" enables 24-bit RGB color in the TUI
set termguicolors

" change cursor styles
set guicursor=n-v-c-sm:block-Cursor,i-ci-ve:ver25-Cursor,r-cr-o:hor20-Cursor

" folding
set foldmethod=indent
set fillchars="fold:"
set foldlevel=20
set foldlevelstart=20
set foldtext=vimrc#ui#fold_text()

" window title
set title titlestring=%{vimrc#ui#title_text()}

" tabline
set tabline=%!vimrc#ui#tab_line()

" statusline
call vimrc#ui#setup_statusline()

"=== Editing
"==============================================================================================
" leader key
let g:mapleader = ','

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
nnoremap x "_x
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
augroup _clear_hlsearch
  autocmd!
  autocmd User ClearHlsearch :
  autocmd BufReadPost * ClearHlsearch
augroup END

command! -nargs=0 ClearHlsearch nohlsearch | doautocmd User ClearHlsearch
nnoremap <silent> <Space><Space> <Cmd>ClearHlsearch<CR>

" back to the last line I edited
augroup _restore_last_pos
  autocmd!
  autocmd BufReadPost *
    \ if line("'\"") > 1 && line("'\"") <= line("$") |
      \ exe "normal! g`\"" |
    \ endif
augroup END

" file detect on read / save
augroup _enhance_ftdetect
  autocmd!
  autocmd BufWritePost,BufReadPost,BufEnter *
    \ if &l:filetype ==# '' || exists('b:ftdetect') |
      \ unlet! b:ftdetect |
      \ filetype detect |
    \ endif
augroup END

"=== Misc
"==============================================================================================
" profiler
command! ProfileStart
  \ profile start ~/vim_profile.log |
  \ profile func * |
  \ profile! file *
command! ProfileStop
  \ profile stop

" inspect syntax
command! ScopeInfo echo map(synstack(line('.'), col('.')), 'synIDattr(synIDtrans(v:val), "name")')

" font
command! -nargs=? Font call <SID>change_font_size(<q-args> ? <q-args> : 12)

function! s:change_font_size(size) abort
  exec 'set' 'guifont=Menlo:h' . a:size

  if $NVIM_GUI ==# 'kitty'
    call jobstart(['kitty', '@', 'set-font-size', a:size])
  endif
endfunction

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

" delete current file
command! -nargs=0 Delete call <SID>delete_file(expand('%:p')) | enew!

function! s:delete_file(file) abort
  let l:file = fnameescape(a:file)
  if empty(l:file)
    return
  endif

  let l:trash_dir = $HOME . '/.Trash'
  if isdirectory(l:trash_dir)
    call jobstart(['mv', l:file, l:trash_dir])
  else
    call delete(l:file)
  endif
endfunction

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

"=== Dein
"==============================================================================================
if has('vim_starting')
  let &g:rtp .= ',' . g:vimrc#env.path.dein_repo
endif

let g:dein#_plugins = {}

if dein#load_state(g:vimrc#env.path.dein)
  call dein#begin(g:vimrc#env.path.dein, [
    \ expand('<sfile>'),
    \ g:vimrc#env.path.dein_toml,
    \ g:vimrc#env.path.dein_lazy_toml,
  \ ])

  call dein#load_toml(g:vimrc#env.path.dein_toml,      { 'lazy': 0 })
  call dein#load_toml(g:vimrc#env.path.dein_lazy_toml, { 'lazy': 1 })

  call dein#end()
  call dein#save_state()
endif

if dein#check_install()
  call dein#install()
endif

augroup _dein_hook
  autocmd!
  autocmd VimEnter * call dein#call_hook('post_source')
augroup END

"  Commands
"-----------------------------------------------
command! DeinUpdate call dein#update()
command! DeinPurgeCache
  \ call dein#recache_runtimepath() |
  \ call dein#clear_state()
command! DeinPrunePlugins
  \ call map(dein#check_clean(), "delete(v:val, 'rf')") |
  \ exec 'DeinPurgeCache' |
  \ echo 'done'

"=== Plugins
"==============================================================================================
if dein#tap('switch.vim')
  let g:switch_mapping = ''
  let g:switch_custom_definitions = [
    \ switch#Words(['public', 'protected', 'private']),
    \ switch#Words(['and', 'or']),
    \ switch#Words(['if', 'unless']),
    \ switch#NormalizedCaseWords(['true', 'false']),
    \ switch#NormalizedCaseWords(['on', 'off']),
    \ switch#NormalizedCaseWords(['yes', 'no']),
  \ ]

  nnoremap <silent> - <Cmd>call <SID>my_switch()<CR>

  function! s:my_switch() abort
    if quote_toggler#toggle()
      return
    endif

    :Switch
  endfunction
endif

if dein#tap('vim-textmanip')
  let g:textmanip_enable_mappings = 0

  let g:textmanip_hooks = {}
  function! g:textmanip_hooks.finish(tm) abort
    let l:tm = a:tm
    let l:helper = textmanip#helper#get()
    if !l:tm.linewise
      call l:helper.remove_trailing_WS(l:tm)
    endif
  endfunction

  " move selection
  xmap <C-j> <Plug>(textmanip-move-down)
  xmap <C-k> <Plug>(textmanip-move-up)
  xmap <C-h> <Plug>(textmanip-move-left)
  xmap <C-l> <Plug>(textmanip-move-right)

  " duplicate line
  xmap <Space><C-j> <Plug>(textmanip-duplicate-down)
  xmap <Space><C-k> <Plug>(textmanip-duplicate-up)
  xmap <Space><C-h> <Plug>(textmanip-duplicate-left)
  xmap <Space><C-l> <Plug>(textmanip-duplicate-right)
endif

if dein#tap('coc.nvim')
  function! s:coc_re_enable() abort
    silent! CocDisable
    silent! CocEnable
    doautocmd InsertLeave
  endfunction

  augroup _init_coc
    autocmd!

    autocmd User ForceRefresh3 call coc#float#close_all()
    autocmd User ForceRefresh call <SID>coc_re_enable()

    if dein#tap('ultisnips')
      autocmd User UltiSnipsEnterFirstSnippet doautocmd User CocJumpPlaceholder
      autocmd User UltiSnipsExitLastSnippet doautocmd User CocJumpPlaceholder
    endif
  augroup END
endif

if dein#tap('denite.nvim')
  " NOTE: See :UpdateRemotePlugins

  augroup _init_denite
    autocmd!
    autocmd FileType denite call vimrc#plugin#denite#init_denite_list()
    autocmd FileType denite-filter call vimrc#plugin#denite#init_denite_filter()
  augroup END

  command! Open :call vimrc#plugin#denite#open_best()
  nnoremap <silent> <C-q> <Cmd>Open<CR>

  command! Rg :Denite -buffer-name=grep grep
  nnoremap <Space>/ <Cmd>Denite -buffer-name=grep -resume grep<CR>
  nnoremap <silent> <Space>* <Cmd>DeniteCursorWord -buffer-name=grep grep<CR>

  command! I18n :Denite -buffer-name=i18n_flow -resume i18n_flow
  nnoremap <Space>i <Cmd>I18n<CR>
endif

if dein#tap('vim-quickrun')
  let g:quickrun_config = {}
  let g:quickrun_config['_'] = {
    \ 'runner': 'job',
    \ 'outputter/buffer/split': ':botright 15sp',
  \ }
  let g:quickrun_config['ruby.rspec'] = {
    \ 'type': 'ruby.rspec',
    \ 'command': 'rspec',
    \ 'cmdopt': 'bundle exec',
    \ 'exec': '%o %c %s',
  \ }

  nmap <Leader>r <Plug>(quickrun)
endif

if dein#tap('vim-searchhi')
  let g:searchhi_user_autocmds_enabled = 1
  let g:searchhi_redraw_before_on = 1

  nmap n <Plug>(searchhi-n)
  nmap N <Plug>(searchhi-N)
  nmap * <Plug>(searchhi-*)
  nmap g* <Plug>(searchhi-g*)
  nmap # <Plug>(searchhi-#)
  nmap g# <Plug>(searchhi-g#)

  augroup _init_searchhi
    autocmd!

    autocmd User ClearHlsearch
      \ call searchhi#clear(0, 0) |
      \ call searchhi#await(0, 0)

    if dein#tap('vim-anzu')
      autocmd User SearchHiOn AnzuUpdateSearchStatusOutput
      autocmd User SearchHiOff echo g:anzu_no_match_word
    endif
  augroup END
endif
