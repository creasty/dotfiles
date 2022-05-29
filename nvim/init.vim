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
let g:loaded_netrwPlugin = 1

" configure runtime features
let g:omni_sql_no_default_maps = 1
let g:tex_flavor = 'latex'

"=== Basic
"==============================================================================================
" no backup and swap files
set nobackup
set nowritebackup
set noswapfile

" enable auto write
set autowrite

" disable mode lines
set modelines=0

" command history
set history=1000

" yank use system clipboard
set clipboard=unnamed

" initial dir of explorer
set browsedir=buffer

" automatic formatting
set formatoptions& formatoptions+=lm]

" in/decrement
set nrformats=alpha,hex

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
set smartindent
set cindent
set expandtab
set shiftround
set tabstop=2 shiftwidth=2 softtabstop=0

" move cursor over lines
set whichwrap=b,s,h,l,<,>,[,]

" virtualedit with freedom
set virtualedit& virtualedit+=block

" split to right / bottom
set splitright
set splitbelow

" customize tag searches
set tagfunc=user#tagfunc#fn

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

" transparent pmenu
set pumblend=10

" change cursor styles
set guicursor=n-c-sm:block-Cursor,i-ci-ve:ver25-Cursor,v-r-cr-o:hor20-Cursor

" line offset when scrolling
set scrolloff=5

" fast update
set updatetime=200

" folding
set foldmethod=indent
set fillchars="fold:"
set foldlevel=20
set foldlevelstart=20

" window title
set title titlestring=%{UserTitleString()}

function! UserTitleString() abort
  let l:is_file = empty(&buftype)
  if l:is_file
    let l:path = expand('%:p')
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
nnoremap <SID>(x) <Nop>
nnoremap <script> x "_x<SID>(x)
nnoremap <script> <SID>(x)x <Cmd>undojoin<CR>x<SID>(x)

" submode for C-a/C-x
nnoremap <SID>(inc) <Nop>
nnoremap <script> <C-a> <C-a><SID>(inc)
nnoremap <script> <C-x> <C-x><SID>(inc)
nnoremap <script> <SID>(inc)<C-a> <Cmd>undojoin<CR><C-a><SID>(inc)
nnoremap <script> <SID>(inc)<C-x> <Cmd>undojoin<CR><C-x><SID>(inc)

" keep the cursor in place while joining lines
nnoremap J mZJ`ZmZ

" split lines: inverse of J
nnoremap K ylpr<CR>

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

" insert blank lines without going into insert mode
nnoremap <Space>o mZo<Esc>`ZmZ
nnoremap <Space>O mZO<Esc>`ZmZ

" reselect pasted text
nnoremap <expr> gp '`[' . strpart(getregtype(), 0, 1) . '`]'

" select all
nnoremap <Space>a ggVG

" search selection
xnoremap * "xy/<C-r>=escape(@x, '\\/.*$^~')<CR>

" replace selection
xnoremap s "xy:<C-u>%s/<C-r>=escape(@x, '\\/.*$^~')<CR>/

" replace word under cursor
nnoremap <Space>* "xyiw:<C-u>%s/\<<C-r>=escape(@x, '\\/.*$^~')<CR>\>/

" dim match highlight
nnoremap <silent> <Space><Space> <Cmd>nohlsearch<Bar>doautocmd User NoHlsearchPost<CR>

" tags
nnoremap tn <Cmd>tn<CR>
nnoremap tp <Cmd>tp<CR>
nnoremap tl <Cmd>tags<CR>
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
" change soft-indent size
command! -nargs=1 SoftTab :setl expandtab tabstop=<args> shiftwidth=<args>

" substitute with match case
command! -nargs=1 -range SubMC <line1>,<line2>call match_case#substitute(<f-args>)

" inspect syntax
command! ScopeInfo lua require'user.treesitter-helper'.show_hl_captures()

" profiler
command! ProfStart
  \ profile start /tmp/vim-vimscript.log |
  \ profile func * |
  \ profile! file * |
  \ lua pcall(function() require('plenary.profile').start('/tmp/vim-lua.log') end)
command! ProfStop
  \ profile stop |
  \ lua pcall(function() require('plenary.profile').stop() end)
command! ProfOpen
  \ vsplit /tmp/vim-vimscript.log |
  \ vsplit /tmp/vim-lua.log

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
    \ if &filetype ==# '' || exists('b:ftdetect') |
      \ unlet! b:ftdetect |
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

"=== Plugins
"==============================================================================================
let s:config_path = stdpath('config')
let s:dein_path = s:config_path . '/dein'
let s:dein_repos_path = s:dein_path . '/repos'
let s:dein_rtp = s:dein_repos_path . '/github.com/Shougo/dein.vim'
let s:dein_toml_path = s:config_path . '/dein.toml'
let s:dein_lazy_toml_path = s:config_path . '/dein_lazy.toml'

if has('vim_starting')
  let &g:rtp .= ',' . s:dein_rtp
endif

if dein#load_state(s:dein_path)
  call dein#begin(s:dein_path, [
    \ expand('<sfile>'),
    \ s:dein_toml_path,
    \ s:dein_lazy_toml_path,
  \ ])

  call dein#load_toml(s:dein_toml_path,      { 'lazy': 0 })
  call dein#load_toml(s:dein_lazy_toml_path, { 'lazy': 1 })

  call dein#end()
  call dein#save_state()
endif

if dein#check_install()
  call dein#install()
endif

call dein#call_hook('post_source')

"  Dein commands
"-----------------------------------------------
command! DeinUpdate
  \ call dein#update()
command! DeinPurgeCache
  \ call dein#recache_runtimepath() |
  \ call dein#clear_state()
command! DeinPrunePlugins
  \ call map(dein#check_clean(), "delete(v:val, 'rf')") |
  \ exec 'DeinPurgeCache'
command! DeinGotoRepos
  \ exec 'lcd' s:dein_repos_path

"  Cross-plugin integration
"-----------------------------------------------
if dein#is_available('switch.vim')
  nnoremap <silent> - <Cmd>call <SID>my_switch()<CR>
  function! s:my_switch() abort
    if quote_toggler#toggle() | return | endif
    :Switch
  endfunction
endif

if dein#is_available('vim-searchhi')
  augroup _init_searchhi
    autocmd!

    autocmd User NoHlsearchPost
      \ call searchhi#clear(0, 0) |
      \ call searchhi#await(0, 0)

    if dein#is_available('vim-anzu')
      autocmd User SearchHiOn AnzuUpdateSearchStatusOutput
      autocmd User SearchHiOff echo g:anzu_no_match_word
    endif
  augroup END
endif

if dein#is_available('coc.nvim') && dein#is_available('ultisnips')
  augroup _init_coc
    autocmd!
    autocmd User UltiSnipsEnterFirstSnippet doautocmd User CocJumpPlaceholder
    autocmd User UltiSnipsExitLastSnippet doautocmd User CocJumpPlaceholder
  augroup END
endif

if dein#is_available('coc.nvim') &&
  \ dein#is_available('copilot.vim') &&
  \ dein#is_available('lexima.vim')

  function! s:is_copilot_suggested() abort
    let l:copilot = copilot#GetDisplayedSuggestion()
    if empty(l:copilot) || empty(l:copilot.text)
      return v:false
    endif
    " Could be a bug?
    let l:line = getline('.')
    let l:offset = col('.') - 1
    let l:ahead = strpart(line, offset, l:copilot.deleteSize)
    return l:ahead !=# l:copilot.text
  endfunction

  function! s:super_tab_i() abort
    if pumvisible()
      return coc#_select_confirm()
    endif

    if s:is_copilot_suggested()
      return copilot#Accept('')
    endif

    if coc#expandableOrJumpable()
      return "\<Plug>(coc-snippets-expand-jump)"
    endif

    return lexima#expand('<TAB>', 'i')
  endfunction

  function! s:super_esc_i() abort
    if pumvisible()
       return "\<Plug>(completion-undo)"
    endif

    if s:is_copilot_suggested()
      call copilot#Dismiss()
      return ''
    endif

    return "\<Plug>(lexima-escape)"
  endfunction

  function! s:super_cr_i() abort
    if pumvisible()
      return "\<Plug>(completion-accept)"
    endif

    return "\<Plug>(coc-on-enter)"
  endfunction

  inoremap <Plug>(completion-undo) <C-e>
  inoremap <Plug>(completion-accept) <C-y>
  inoremap <Plug>(coc-on-enter) <C-g>u<CR><C-r>=coc#on_enter()<CR>
  inoremap <Plug>(lexima-escape) <C-r>=lexima#insmode#escape()<CR><Esc>

  imap <silent><expr> <Tab> <SID>super_tab_i()
  imap <silent><expr> <Esc> <SID>super_esc_i()
  imap <silent><expr> <CR> <SID>super_cr_i()
endif
