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
let g:loaded_2html_plugin = 1
let g:loaded_netrwPlugin = 1
let g:loaded_tar = 1
let g:loaded_tarPlugin = 1
let g:loaded_vimball = 1
let g:loaded_vimballPlugin = 1
let g:loaded_zip = 1
let g:loaded_zipPlugin = 1

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

" display nonprintable characters as hex
set display+=uhex

" show hidden characters
"
" [tab]
" U+2192 (Rightwards Arrow)
" @see https://github.com/microsoft/vscode/blob/6ef862703e3a2a477e0bde0e715a1cb0ef3959cc/src/vs/editor/common/viewLayout/viewLineRenderer.ts#L995-L999
"
" [lead,trail]
" U+00B7 (Middle Dot)
" @see https://github.com/microsoft/vscode/blob/6ef862703e3a2a477e0bde0e715a1cb0ef3959cc/src/vs/editor/common/viewLayout/viewLineRenderer.ts#L122-L128
"
" [nbsp]
" U+2219 (Bullet Operator)
"
" [extends,precedes]
" U+276F (Heavy Right-Pointing Angle Quotation Mark Ornament)
" U+276E (Heavy Left-Pointing Angle Quotation Mark Ornament)
set list
set listchars=tab:→\ ,lead:·,trail:·,nbsp:∙,extends:❯,precedes:❮

" indent wrapped lines
" U+203A (Single Right-Pointing Angle Quotation Mark)
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

" replace selection
xnoremap s "xy:<C-u>%s/<C-r>=escape(@x, '\\/.*$^~')<CR>/

" replace word under cursor
nnoremap <Space>* "xyiw:<C-u>%s/\<<C-r>=escape(@x, '\\/.*$^~')<CR>\>/

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
" remap command
function s:remap_command(lhs, rhs) abort
  execute 'cnoreabbrev' '<expr>'
    \ a:lhs "getcmdtype() ==# ':' && getcmdline() ==# '" . a:lhs . "'"
    \ " ? '" . a:rhs . "' : '" . a:lhs . "'"
endfunction

" change indent style
command! -nargs=1 SoftTab :setl expandtab tabstop=<args> shiftwidth=<args>
command! -nargs=1 HardTab :setl noexpandtab tabstop=<args> shiftwidth=<args>

" substitute with match case
command! -nargs=1 -range SubMC <line1>,<line2>call match_case#substitute(<f-args>)

" inspect syntax
command! ScopeInfo lua require'user.plugin.treesitter.helper'.show_hl_captures()

" profiler
command! -nargs=0 ProfStart
  \ profile start /tmp/vim-vimscript.log |
  \ profile func * |
  \ profile! file *
command! -nargs=0 ProfStop profile stop
command! -nargs=0 ProfOpen vsplit /tmp/vim-vimscript.log |

" change font size
command! -nargs=? Font call <SID>change_font_size(<q-args> ? <q-args> : 12)
call s:remap_command('font', 'Font')

function! s:change_font_size(size) abort
  exec 'set' 'guifont=Menlo:h' . a:size

  if $NVIM_GUI ==# 'kitty'
    call jobstart(['kitty', '@', 'set-font-size', a:size])
  endif
endfunction

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
    \ let b:strip_ts_timer_id = timer_start(50, {-> s:strip_ts() })
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
let s:dein_path = stdpath('config') . '/dein'
let s:dein_repos_path = s:dein_path . '/repos/github.com'

if has('vim_starting')
  let &g:rtp .= ',' . s:dein_repos_path . '/Shougo/dein.vim'
endif

let g:dein#install_log_filename = s:dein_path . '/install.log'

if dein#min#load_state(s:dein_path)
  let s:dein_default_toml = s:dein_path . '/default.toml'
  let s:dein_lazy_toml = s:dein_path . '/lazy.toml'

  call dein#begin(s:dein_path, [
    \ expand('<sfile>'),
    \ s:dein_default_toml,
    \ s:dein_lazy_toml,
  \ ])

  call dein#load_toml(s:dein_default_toml, { 'lazy': 0 })
  call dein#load_toml(s:dein_lazy_toml,    { 'lazy': 1 })

  call dein#end()
  call dein#save_state()
endif

if dein#check_install()
  call dein#install()
endif

call dein#call_hook('post_source')

"  Dein commands
"-----------------------------------------------
command! -nargs=0 DeinPurgeCache
  \ call dein#recache_runtimepath() |
  \ call dein#clear_state()

command! -nargs=0 DeinPrunePlugins
  \ call map(dein#check_clean(), "delete(v:val, 'rf')") |
  \ exec 'DeinPurgeCache'

command! -nargs=0 DeinOpenLog
  \ execute 'vsplit' g:dein#install_log_filename

command! -nargs=? -complete=customlist,DeinPluginNameComplete DeinUpdate
  \ call dein#update(fnamemodify(trim(<q-args>), ':t'))

command! -nargs=? -complete=customlist,DeinPluginNameComplete DeinGotoRepos
  \ exec 'lcd' s:dein_repos_path . '/' . trim(<q-args>)

function! DeinPluginNameComplete(a, l, p) abort
  let l:prefix_len = strlen(s:dein_repos_path) + 1
  let l:list = map(split(globpath(s:dein_repos_path, '*/*')), { _, v -> v[l:prefix_len:] })
  return filter(l:list, { _, v -> v =~# a:a })
endfunction

"  Cross-plugin integration
"-----------------------------------------------
if v:true
  function! s:stop_intelligence() abort
    " coc.nvim
    let b:coc_suggest_disable = 1
    " copilot.nvim
    let b:copilot_disabled = v:true
    " lexima.vim
    let b:lexima_disabled = 1
  endfunction

  function! s:resume_intelligence() abort
    " coc.nvim
    unlet! b:coc_suggest_disable
    " copilot.nvim
    unlet! b:copilot_disabled
    " lexima.vim
    unlet! b:lexima_disabled
  endfunction

  augroup _init_intelligence
    autocmd!

    " plugin/blockwise_visual_insert.vim
    autocmd User BlockwiseVisualInsertPre call s:stop_intelligence()
    autocmd User BlockwiseVisualInsertPost call s:resume_intelligence()

    " ddu.vim
    autocmd FileType ddu-ff-filter call s:stop_intelligence()
  augroup END
endif

if dein#is_available('ddu.vim') && dein#is_available('coc.nvim')
  let g:coc_enable_locationlist = 0
  nnoremap <silent> gll <Cmd>call user#plugin#ddu#coc_locations(v:true)<CR>

  augroup _init_coc_ddu
    autocmd!
    autocmd User CocLocationsChange call user#plugin#ddu#coc_locations(v:false)
  augroup END
endif

if dein#is_available('coc.nvim') &&
  \ dein#is_available('copilot.vim') &&
  \ dein#is_available('lexima.vim') &&
  \ dein#is_available('ultisnips')

  function! s:is_copilot_suggested() abort
    let l:copilot = copilot#GetDisplayedSuggestion()
    return !empty(l:copilot.text)
  endfunction

  function! s:super_tab_i() abort
    if coc#pum#visible()
      return coc#_select_confirm()
    elseif pumvisible()
      return "\<Plug>(completion-accept)"
    endif

    let l:snip = UltiSnips#CanExpandSnippet() || UltiSnips#CanJumpForwards()
    if l:snip
      return "\<Plug>(ultisnips-expand)"
    endif

    return lexima#expand('<TAB>', 'i')
  endfunction

  function! s:super_tab_s() abort
    if coc#jumpable()
      return coc#snippet#next()
    endif

    return "\<Plug>(ultisnips-expand)"
  endfunction

  function! s:super_esc_i() abort
    if coc#pum#visible()
      return coc#pum#cancel()
    elseif pumvisible()
      return "\<Plug>(completion-cancel)"
    endif

    if coc#float#has_float()
      return "\<C-o>\<Plug>(coc-float-hide)"
    endif

    if s:is_copilot_suggested()
      call copilot#Dismiss()
      return ''
    endif

    return "\<Plug>(lexima-escape)"
  endfunction

  function! s:super_cr_i() abort
    if coc#pum#visible()
      return coc#_select_confirm()
    elseif pumvisible()
      return "\<Plug>(completion-accept)"
    endif

    " return "\<Plug>(coc-enter)"
    return lexima#expand('<CR>', 'i')
  endfunction

  function! s:super_ctrl_l() abort
    if coc#pum#visible()
      return coc#refresh()
    endif

    return lexima#expand('<C-L>', 'i')
  endfunction

  function! s:super_ctrl_s_ctrl_j() abort
    if s:is_copilot_suggested()
      return copilot#Accept('')
    endif

    if coc#expandableOrJumpable()
      return "\<Plug>(coc-snippets-expand-jump)"
    endif

    return "\<Ignore>"
  endfunction

  inoremap <Plug>(completion-cancel) <C-e>
  inoremap <Plug>(completion-accept) <C-y>
  inoremap <Plug>(coc-enter) <C-g>u<CR><C-r>=coc#on_enter()<CR>
  inoremap <Plug>(lexima-escape) <C-r>=lexima#insmode#escape()<CR><Esc>

  function! s:setup_super_mappings() abort
    imap <silent><expr> <Tab> <SID>super_tab_i()
    smap <silent><expr> <Tab> <SID>super_tab_s()
    imap <silent><expr> <Esc> <SID>super_esc_i()
    imap <silent><expr> <CR>  <SID>super_cr_i()

    imap <silent><expr> <C-l> <SID>super_ctrl_l()
    imap <silent><expr> <C-s><C-j> <SID>super_ctrl_s_ctrl_j()
  endfunction

  function! s:auto_dismiss_copilot(float) abort
    let l:disabled = a:float
      \ || coc#pum#visible()
      \ || UltiSnips#CanExpandSnippet()

    if l:disabled
      let b:copilot_enabled = v:false
      call copilot#Dismiss()
    else
      unlet! b:copilot_enabled
    endif
  endfunction

  " plugin/emacs_cursor.vim
  let g:EmacsCursorPumvisible = function('coc#pum#visible')

  augroup _init_super_mappings
    autocmd!
    autocmd User PluginLeximaPostInit call s:setup_super_mappings()

    autocmd User CocOpenFloat call s:auto_dismiss_copilot(v:true)
    autocmd TextChangedI,CursorMovedI * call s:auto_dismiss_copilot(v:false)
    autocmd InsertEnter * unlet! b:copilot_enabled

    autocmd User UltiSnipsEnterFirstSnippet doautocmd User CocJumpPlaceholder
    autocmd User UltiSnipsExitLastSnippet doautocmd User CocJumpPlaceholder
  augroup END
endif
