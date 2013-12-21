
"-------------------------------------------------------------------------------
" Plugin manager: neobundle
"-------------------------------------------------------------------------------
if has('vim_starting')
  set runtimepath+=~/dotfiles/neobundle.vim/
  call neobundle#rc(expand('~/dotfiles/vimfiles/bundle/'))
endif

NeoBundleFetch 'Shougo/neobundle.vim'

NeoBundle 'Shougo/vimproc', {
  \ 'build' : {
    \ 'windows' : 'make -f make_mingw32.mak',
    \ 'cygwin' : 'make -f make_cygwin.mak',
    \ 'mac' : 'make -f make_mac.mak',
    \ 'unix' : 'make -f make_unix.mak',
  \ },
\ }

" Editing
NeoBundle 'kana/vim-operator-user'
NeoBundle 'kana/vim-textobj-user'
NeoBundle 'kana/vim-textobj-indent'
NeoBundle 'coderifous/textobj-word-column.vim'
NeoBundle 'surround.vim'
NeoBundle 'Lokaltog/vim-easymotion'
NeoBundle 'scrooloose/nerdcommenter'
NeoBundle 'scrooloose/syntastic'
NeoBundle 'Align'
NeoBundle 'mattn/emmet-vim'
NeoBundle 'tyru/operator-html-escape.vim'
NeoBundle 'tyru/operator-camelize.vim'
NeoBundle 'rhysd/vim-operator-evalruby'
NeoBundle 'pekepeke/vim-operator-tabular'
NeoBundle 'emonkak/vim-operator-sort'
NeoBundleLazy 'tmhedberg/matchit'
NeoBundleLazy 'kana/vim-smartinput'
NeoBundleLazy 'cohama/vim-smartinput-endwise'
NeoBundleLazy 'ecomba/vim-ruby-refactoring',  {
  \ 'autoload': { 'filetypes': ['ruby'] }
\ }
NeoBundle 'AndrewRadev/switch.vim'
NeoBundle 'smartchr'
NeoBundle 't9md/vim-textmanip'
NeoBundle 'Townk/vim-autoclose'
NeoBundle 'deris/vim-rengbang'
NeoBundle 'terryma/vim-expand-region'

" Completion
NeoBundleLazy 'Shougo/neocomplete'
NeoBundleLazy 'Rip-Rip/clang_complete'
NeoBundleLazy 'Shougo/neosnippet', {
  \ 'depends': ['Shougo/neocomplete'],
  \ 'autoload': {
    \ 'commands': ['NeoSnippetEdit', 'NeoSnippetSource'],
    \ 'filetypes': 'snippet',
    \ 'insert': 1,
    \ 'unite_sources': ['snippet', 'neosnippet/user', 'neosnippet/runtime'],
  \ }
\ }

" Utils
NeoBundleLazy 'tpope/vim-fugitive'
NeoBundleLazy 'scrooloose/nerdtree'
NeoBundleLazy 'jistr/vim-nerdtree-tabs', {
  \ 'depends': ['scrooloose/nerdtree'],
\ }
NeoBundle 'xolox/vim-misc'
NeoBundle 'xolox/vim-session'
NeoBundleLazy 'Shougo/unite.vim'
NeoBundleLazy 'Shougo/vimshell.vim', {
  \ 'autoload': { 'commands': ['VimShell'] },
  \ 'depends': ['Shougo/vimproc'],
\ }
NeoBundle 'tyru/open-browser.vim'
NeoBundle 'glidenote/memolist.vim'
NeoBundle 'Shougo/vinarise.vim'
NeoBundle 'kana/vim-fakeclip'
NeoBundle 'kana/vim-altr'
NeoBundle 'airblade/vim-rooter'
NeoBundle 'thinca/vim-quickrun'
NeoBundle 'kana/vim-submode'
NeoBundle 'osyo-manga/vim-over'
NeoBundle 'rizzatti/dash.vim'

" Appearance
NeoBundle 'itchyny/lightline.vim'
NeoBundle 'Yggdroot/indentLine'
NeoBundle 'kshenoy/vim-signature'
NeoBundle 'osyo-manga/vim-anzu'

" Syntax
NeoBundleLazy 'tpope/vim-haml',  {
  \ 'autoload': { 'filetypes': ['haml'] }
\ }
NeoBundleLazy 'tpope/vim-markdown',  {
  \ 'autoload': { 'filetypes': ['markdown'] }
\ }
NeoBundleLazy 'kchmck/vim-coffee-script',  {
  \ 'autoload': { 'filetypes': ['coffee'] }
\ }
NeoBundleLazy 'tpope/vim-rails',  {
  \ 'autoload': { 'filetypes': ['ruby'] }
\ }
NeoBundleLazy 'vim-ruby/vim-ruby',  {
  \ 'autoload': { 'filetypes': ['ruby'] }
\ }
NeoBundleLazy 'tpope/vim-cucumber',  {
  \ 'autoload': { 'filetypes': ['cucumber.ruby'] }
\ }
NeoBundleLazy 'slim-template/vim-slim',  {
  \ 'autoload': { 'filetypes': ['slim'] }
\ }
NeoBundleLazy 'cakebaker/scss-syntax.vim',  {
  \ 'autoload': { 'filetypes': ['scss'] }
\ }
NeoBundleLazy 'msanders/cocoa.vim',  {
  \ 'autoload': { 'filetypes': ['objc'] }
\ }
NeoBundleLazy 'eraserhd/vim-ios',  {
  \ 'autoload': { 'filetypes': ['objc'] }
\ }

" NeoBundle 'skammer/vim-css-color'

filetype plugin indent on
NeoBundleCheck


"-------------------------------------------------------------------------------
" Basics
"-------------------------------------------------------------------------------
" unregister autocmds
augroup vimrc
  autocmd!
augroup END

" make special key bindings like <C-s> work
silent !stty -ixon > /dev/null 2>&1

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

" always use new engine
set regexpengine=2

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

" yank use system clipboard
set clipboard=unnamed

" inc/decrement
set nf=alpha,hex

" disable IME
set imdisable

" wildcard settings
set suffixes=.bak,~,.swp,.o,.info,.aux,.log,.dvi,.bbl,.blg,.brf,.cb,.ind,.idx,.ilg,.inx,.out,.toc
set wildignore& wildignore+=*/tmp/*,*.so,*.swp,*.zip

" edit and apply vimrc
command! EditVimrc edit $MYVIMRC
" autocmd vimrc BufWritePost *vimrc source $MYVIMRC
autocmd vimrc BufWritePost *gvimrc
  \ if has('gui_running') |
    \ source $MYGVIMRC |
  \ endif

" tab pages / buffers
nmap <C-w><C-t> <C-w>t
nnoremap <C-w>t :tabnew<CR>
imap <C-w><C-t> <C-w>t
inoremap <C-w>t <C-o>:tabnew<CR>

nmap <C-w><C-v> <C-w>v
nnoremap <C-w>v :vnew<CR>
imap <C-w><C-v> <C-w>v
inoremap <C-w>v <C-o>:vnew<CR>

nmap <C-w><C-c> <C-w>c
nmap <C-w>c <Plug>Kwbd
imap <C-w><C-c> <C-w>c
imap <C-w>c <Plug>Kwbd

" clean up hidden buffers
function! CleanBuffers()
  redir => buffersoutput
    silent buffers
  redir END
  let buflist = split(buffersoutput,"\n")
  for item in buflist
    let t = matchlist(item, '\v^\s*(\d+)([^"]*)')
    if t[2][1] != '#' && t[2][2] != 'a' && t[2][4] != '+'
      exec 'bdelete ' . t[1]
    endif
  endfor
endfunction

command! CleanBuffers :call CleanBuffers()

autocmd vimrc BufRead * call s:set_hidden()
function! s:set_hidden()
  if empty(&buftype) " most explorer plugins have buftype=nofile
    setlocal bufhidden=delete
  endif
endfunction


"-------------------------------------------------------------------------------
" Apperance
"-------------------------------------------------------------------------------
" syntax highlight & color scheme
set background=dark
set t_Co=256
syntax enable
colorscheme CreastyCode

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
set synmaxcol=500

" display very very long line at the end of file
set display& display+=lastline

" display nonprintable charactors as hex
set display+=uhex

" show hidden charactors
set list
set listchars=tab:¦\ ,nbsp:∘,extends:❯,precedes:❮

" show wrap line break
set showbreak=❮

" highlight full-width space
autocmd vimrc BufWinEnter,WinEnter *
  \ call matchadd('ZenkakuSpace', '　')

" highlight trailing spaces
autocmd vimrc BufWinEnter,WinEnter *
  \ call matchadd('TrailingSpace', '\s\+$')


"-------------------------------------------------------------------------------
" Tags
"-------------------------------------------------------------------------------
" move around
nnoremap tn :tn<CR>
nnoremap tp :tp<CR>

" list of tags
nnoremap tl :tags<CR>


"-------------------------------------------------------------------------------
" Search
"-------------------------------------------------------------------------------
" cricle search within files
set wrapscan

" ignore case only if contains upper case
set ignorecase
set smartcase

" incremental search
set incsearch

" match highlight
set hlsearch

" dim match highlight by hitting space twice
nnoremap <silent> <Space><Space> :nohlsearch<CR><Esc>

" erase previous match highlight
autocmd vimrc BufReadPost * :nohlsearch

" search selection
vnoremap // y/=escape(@", '\\/.*$^~')

" replace selection
vnoremap /r "xy:%s/=escape(@x, '\\/.*$^~')//gc

" replace word under cursor
nnoremap <expr> s* ':%s/\<' . expand('') . '\>/'

" auto escaping
cnoremap <expr> /  getcmdtype() == '/' ? '\/' : '/'
cnoremap <expr> ?  getcmdtype() == '?' ? '\?' : '?'


"-------------------------------------------------------------------------------
" Encoding
"-------------------------------------------------------------------------------
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
function! AU_ReCheck_FENC()
  if &fileencoding =~# 'iso-2022-jp' && search("[^\x01-\x7e]", 'n') == 0
    let &fileencoding=&encoding
  endif
endfunction

autocmd vimrc BufReadPost * call AU_ReCheck_FENC()

" reopen current buffer with specific encoding
command! -bang -nargs=? Utf8
  \ edit<bang> ++enc=utf-8 <args>
command! -bang -nargs=? Sjis
  \ edit<bang> ++enc=cp932 <args>
command! -bang -nargs=? Jis
  \ edit<bang> ++enc=iso-2022-jp <args>
command! -bang -nargs=? Euc
  \ edit<bang> ++enc=eucjp <args>


"-------------------------------------------------------------------------------
" Editing
"-------------------------------------------------------------------------------
" indent
set noautoindent
set smartindent
set cindent
set smarttab
set noexpandtab

" tab with
set tabstop=2 shiftwidth=2 softtabstop=0

" toggle paste mode
command! Pt :set paste!

" move cursor visually with long lines
nmap j gj
nmap k gk

" Emacs-like key bindings
imap <C-c> <Esc>
imap <C-n> <C-o>gj
imap <C-p> <C-o>gk
imap <C-b> <Left>
imap <C-f> <Right>
imap <C-a> <C-o>g0
imap <C-e> <C-o>g$
imap <C-j> <CR>
imap <C-d> <Del>
inoremap <silent> <C-h> <C-g>u<C-h>
inoremap <expr> <C-k> "\<C-g>u".(col('.') == col('$') ? '<C-o>gJ' : '<C-o>d$')

cmap <C-a> <Home>
cmap <C-b> <Left>
cmap <C-f> <Right>
cmap <C-d> <Del>
cnoremap <C-k> <C-\>e getcmdpos() == 1 ? '' : getcmdline()[:getcmdpos()-2]<CR>

" shortcuts for till ...
vnoremap ( t(
vnoremap ) t)
vnoremap ] t]
vnoremap [ t[
onoremap ( t(
onoremap ) t)
onoremap ] t]
onoremap [ t[

" do not store to register with x, c
nnoremap x "_x
nnoremap c "_c

" why are you left out??
nnoremap Y y$

" keep the cursor in place while joining lines
nnoremap J mzJ`z

" reselect visual block after indent/outdent
vnoremap < <gv
vnoremap > >gv

" selecting paated text
nnoremap <expr> gp '`[' . strpart(getregtype(), 0, 1) . '`]'

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

" reset previous marks
autocmd vimrc BufReadPost * delmarks!

" numbering selection in visual-block mode
nnoremap <silent> co :ContinuousNumber <C-a><CR>
vnoremap <silent> co :ContinuousNumber <C-a><CR>
command! -count -nargs=1 ContinuousNumber
  \ let c = col('.') |
  \ for n in range(1, <count>?<count>-line('.'):1) |
    \ exec 'normal! j' . n . <q-args> |
    \ call cursor('.', c) |
  \ endfor

" create directories if not exist
autocmd vimrc BufWritePre *
 \ call s:auto_mkdir(expand('<afile>:p:h'), v:cmdbang)

function! s:auto_mkdir(dir, force)
  if !isdirectory(a:dir) && (
    \ a:force ||
    \ input(printf('"%s" does not exist. Create? [y/N]', a:dir)) =~? '^y\%[es]$'
  \ )
    call mkdir(iconv(a:dir, &encoding, &termencoding), 'p')
  endif
endfunction

" rename current file
command! -nargs=1 -complete=file Rename w <args> | call delete(expand('#'))

nmap <C-w><C-r> <C-w>r
nnoremap <C-w>r :Rename <C-r>=expand('%:p')<CR>

" delete current file
command! -nargs=0 Delete call delete(expand('%')) | q!

" insert relative path
cnoremap <C-l> <C-r>=expand('%:h') . '/' <CR>

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


"-------------------------------------------------------------------------------
" Sticky shift
"-------------------------------------------------------------------------------
nmap <expr> ; <SID>sticky_func()
imap <expr> ; <SID>sticky_func()
cmap <expr> ; <SID>sticky_func()
vmap <expr> ; <SID>sticky_func()

" JIS keyboard
let s:sticky_table = {
  \ ',': '<', '.': '>', '/': '?',
  \ '1': '!', '2': '"', '3': '#', '4': '$', '5': '%',
  \ '6': '&', '7': "'", '8': '(', '9': ')', '0': '0', '-': '=', '^': '~',
  \ ';': '+', '[': '{', ']': '}', '@': '`', ':': '*', '\': '|',
\ }

" US keyboard
" let s:sticky_table = {
"   \ ',': '<', '.': '>', '/': '?',
"   \ '1': '!', '2': '@', '3': '#', '4': '$', '5': '%',
"   \ '6': '^', '7': '&', '8': '*', '9': '(', '0': ')', '-': '_', '=': '+',
"   \ ';': ':', '[': '{', ']': '}', '`': '~', "'": "\"", '\': '|',
" \ }

let s:sticky_table_special = {
  \ "\<ESC>": "\<ESC>",
  \ "\<C-c>": "\<ESC>",
  \ "\<Space>": ';',
  \ "\<CR>" : ";\<CR>",
  \ "\<C-j>" : ";\<CR>",
\ }

function! s:sticky_func()
  let l:key = getchar()
  if nr2char(l:key) =~ '\l'
    return toupper(nr2char(l:key))
  elseif has_key(s:sticky_table, nr2char(l:key))
    return s:sticky_table[nr2char(l:key)]
  elseif has_key(s:sticky_table_special, nr2char(l:key))
    return s:sticky_table_special[nr2char(l:key)]
  else
    return ''
  endif
endfunction


"-------------------------------------------------------------------------------
" Filetype specific
"-------------------------------------------------------------------------------
" force soft tab
autocmd vimrc FileType
  \ diff,yaml,ruby,eruby,haml,coffee,scss,sass,sh,sql,vim,scala,scheme
  \ setlocal et

autocmd vimrc BufNewFile,BufRead
  \ *.json
  \ setlocal et

" force encoding
autocmd vimrc FileType
  \ svn,js,css,html,xml,java,scala,yml
  \ setlocal fenc=utf-8

autocmd vimrc FileType
  \ cvs
  \ setlocal fenc=euc-jp


"-------------------------------------------------------------------------------
" Plugin: NeoComplete
"-------------------------------------------------------------------------------
let s:bundle = neobundle#get('neocomplete')
function! s:bundle.hooks.on_source(bundle)
  let g:neocomplete#enable_at_startup = 1
  let g:neocomplete#enable_smart_case = 1
  let g:neocomplcache_max_list = 20
  let g:neocomplete#sources#syntax#min_keyword_length = 3
  let g:neocomplete#lock_buffer_name_pattern = '\*ku\*'
  let g:neocomplete#disable_auto_complete = 0
  let g:neocomplete#enable_auto_select = 1
  let g:neocomplete#enable_insert_char_pre = 1
  set completeopt& completeopt-=preview

  let $DICTDIR = $HOME . '/dotfiles/dict'
  let g:neocomplete#sources#dictionary#dictionaries = {
    \ 'default':    '',
    \ 'vimshell':   $HOME . '/.vimshell_hist',
    \ 'ruby':       $DICTDIR . '/ruby.dict',
    \ 'java':       $DICTDIR . '/java.dict',
    \ 'javascript': $DICTDIR . '/javascript.dict',
    \ 'coffee':     $DICTDIR . '/javascript.dict',
    \ 'html':       $DICTDIR . '/html.dict',
    \ 'php':        $DICTDIR . '/php.dict',
    \ 'objc':       $DICTDIR . '/objc.dict',
    \ 'perl':       $DICTDIR . '/perl.dict',
    \ 'scala':      $DICTDIR . '/scala.dict',
  \ }

  let g:neocomplete#sources#buffer#disabled_pattern = '\.log\|\.log\.\|\.jax'
  let g:neocomplete#lock_buffer_name_pattern = '\.log\|\.log\.\|.*quickrun.*\|.jax'

  " keyword patterns
  let g:neocomplete#keyword_patterns = get(g:, 'neocomplete#keyword_patterns', {})
  let g:neocomplete#keyword_patterns['default'] = '\h\w*'
  let g:neocomplete#keyword_patterns.perl = '\h\w*->\h\w*\|\h\w*::\w*'

  " input patterns
  let g:neocomplete#sources#omni#input_patterns = get(g:, 'neocomplete#sources#omni#input_patterns', {})
  let g:neocomplete#sources#omni#input_patterns.php = '[^. \t]->\h\w*\|\h\w*::'
  let g:neocomplete#sources#omni#input_patterns.c = '[^.[:digit:] *\t]\%(\.\|->\)'
  let g:neocomplete#sources#omni#input_patterns.cpp = '[^.[:digit:] *\t]\%(\.\|->\)\|\h\w*::'
  let g:neocomplete#sources#omni#input_patterns.go = '\h\w*\.\?'
  let g:neocomplete#sources#omni#input_patterns.ruby = '[^. *\t]\.\h\w*\|\h\w*::'

  let g:neocomplete#force_omni_input_patterns = get(g:, 'neocomplete#force_omni_input_patterns', {})
  let g:neocomplete#force_overwrite_completefunc = 1
  let g:neocomplete#force_omni_input_patterns.c = '[^.[:digit:] *\t]\%(\.\|->\)\w*'
  let g:neocomplete#force_omni_input_patterns.cpp = '[^.[:digit:] *\t]\%(\.\|->\)\w*\|\h\w*::\w*'
  let g:neocomplete#force_omni_input_patterns.objc = '[^.[:digit:] *\t]\%(\.\|->\)\w*'
  let g:neocomplete#force_omni_input_patterns.objcpp = '[^.[:digit:] *\t]\%(\.\|->\)\w*\|\h\w*::\w*'

  let g:clang_complete_auto = 0
  let g:clang_auto_select = 0
  let g:clang_use_library = 1

  " cancel or accept
  imap <silent> <expr> <C-f> pumvisible() ? neocomplete#cancel_popup() . "\<Right>" : "\<Right>"
  imap <silent> <expr> <C-b> pumvisible() ? neocomplete#cancel_popup() . "\<Left>" : "\<Left>"
  imap <silent> <expr> <C-a> pumvisible() ? neocomplete#cancel_popup() . "\<C-o>g0" : "\<C-o>g0"
  imap <silent> <expr> <C-e> pumvisible() ? neocomplete#cancel_popup() . "\<C-o>g$" : "\<C-o>g$"
  imap <silent> <expr> <C-c> pumvisible() ? neocomplete#cancel_popup() : "\<Esc>"
  imap <silent> <expr> <C-j> pumvisible() ? neocomplete#close_popup() : "\<CR>"
  inoremap <silent> <expr> <Space> pumvisible() ? neocomplete#cancel_popup() . "\<Space>" : "\<Space>"
  inoremap <silent> <expr> <C-h> pumvisible() ? neocomplete#cancel_popup() : "\<C-g>u<C-h>"

  " omni completion
  autocmd vimrc FileType css
    \ setlocal omnifunc=csscomplete#CompleteCSS
  autocmd vimrc FileType html,markdown
    \ setlocal omnifunc=htmlcomplete#CompleteTags
  autocmd vimrc FileType javascript
    \ setlocal omnifunc=javascriptcomplete#CompleteJS
  autocmd vimrc FileType python
    \ setlocal omnifunc=pythoncomplete#Complete
  autocmd vimrc FileType xml
    \ setlocal omnifunc=xmlcomplete#CompleteTags
endfunction
unlet s:bundle


"-------------------------------------------------------------------------------
" Plugin: NeoSnippet
"-------------------------------------------------------------------------------
let s:bundle = neobundle#get('neosnippet')
function! s:bundle.hooks.on_source(bundle)
  let g:neosnippet#disable_select_mode_mappings = 0
  let g:neosnippet#enable_snipmate_compatibility = 1

  if has('conceal')
    set conceallevel=2 concealcursor=i
  endif

  " super tab completion
  inoremap <expr> <TAB> <SID>super_tab_completion()

  function! s:super_tab_completion()
    let c = col('.') - 1

    if pumvisible()
      return neocomplete#close_popup()
    elseif neosnippet#expandable_or_jumpable()
      return neosnippet#mappings#expand_or_jump_impl()
    elseif &ft =~ 'x\?html\|xml\|s\?css' && emmet#isExpandable()
      return "\<C-r>=emmet#expandAbbr(0, '')\<CR>\<Right>"
    elseif c && getline('.')[c - 1] !~ '\s'
      return "\<C-x>\<C-o>"
    else
      return "\<TAB>"
    endif
  endfunction

  " remove placeholders (hidden markers) before saving
  autocmd vimrc BufWritePre *
    \ exec '%s/<`\d\+:\?[^>]*`>//ge'
endfunction
unlet s:bundle


"-------------------------------------------------------------------------------
" Plugin: Syntastic
"-------------------------------------------------------------------------------
let g:syntastic_error_symbol = '✗'
let g:syntastic_warning_symbol = '⚠'
let g:syntastic_style_error_symbol = '✗'
let g:syntastic_style_warning_symbol = '⚠'
let g:syntastic_stl_format = '%E{✗ %fe (%e)}%B{, }%W{⚠ %fw (%w)}'

let g:syntastic_coffee_checkers = ['coffeelint', 'coffee']
let g:syntastic_coffee_coffeelint_args = '-f ~/dotfiles/_coffeelintrc'


"-------------------------------------------------------------------------------
" Plugin: TextManip
"-------------------------------------------------------------------------------
" move selection
xmap <C-j> <Plug>(textmanip-move-down)
xmap <C-k> <Plug>(textmanip-move-up)
xmap <C-h> <Plug>(textmanip-move-left)
xmap <C-l> <Plug>(textmanip-move-right)

" move current line in insert mode
imap <D-h> <C-o>V<C-h><Esc>
imap <D-j> <C-o>V<C-j><Esc>
imap <D-k> <C-o>V<C-k><Esc>
imap <D-l> <C-o>V<C-l><Esc>
imap <D-d> <C-o>,d

" duplicate line
vmap ,d <Plug>(textmanip-duplicate-down)
vmap ,D <Plug>(textmanip-duplicate-up)
nmap ,d <Plug>(textmanip-duplicate-down)
nmap ,D <Plug>(textmanip-duplicate-up)


"-------------------------------------------------------------------------------
" Plugin: Smartchr
"-------------------------------------------------------------------------------
inoremap <expr> , smartchr#loop(', ', ',')
inoremap <expr> { smartchr#one_of('{', '#{', '{{{')
inoremap <expr> ^ smartchr#loop('^', '->', '=>')


"-------------------------------------------------------------------------------
" Plugin: OpenBrowser
"-------------------------------------------------------------------------------
" disable netrw's gx mapping.
let g:netrw_nogx = 1

nnoremap gx <Plug>(openbrowser-smart-search)
vnoremap gx <Plug>(openbrowser-smart-search)


"-------------------------------------------------------------------------------
" Plugin: Emmet
"-------------------------------------------------------------------------------
let g:user_emmet_mode = 'i'
let g:user_emmet_leader_key = '<c-y>'
let g:user_emmet_settings = {
  \ 'lang': 'ja',
  \ 'indentation': '  ',
  \ 'html': {
    \ 'indentation': "\t",
  \ },
\ }


"-------------------------------------------------------------------------------
" Plugin: surround
"-------------------------------------------------------------------------------
nmap ,( csw(
nmap ,) csw)
nmap ,{ csw{
nmap ,} csw}
nmap ,[ csw[
nmap ,] csw]
nmap ,' csw'
nmap ," csw"


"-------------------------------------------------------------------------------
" Plugin: NerdCommenter
"-------------------------------------------------------------------------------
nmap gcc <leader>cc
nmap gcn <leader>cn
nmap gc  <leader>c
nmap gcm <leader>cm
nmap gci <leader>ci
nmap gcs <leader>cs
nmap gcy <leader>cy
nmap gc$ <leader>c$
nmap gcA <leader>cA
nmap gca <leader>ca
nmap gcl <leader>cl
nmap gcb <leader>cb
nmap gcu <leader>cu


"-------------------------------------------------------------------------------
" Plugin: EasyMotion
"-------------------------------------------------------------------------------
let g:EasyMotion_leader_key = '<Space>'
let g:EasyMotion_keys = 'hjklasdfgyuiopqwertnmzxcvbHJKLASDFGYUIOPQWERTNMZXCVB'

hi EasyMotionTarget guibg=#f0c674 guifg=#000000


"-------------------------------------------------------------------------------
" Plugin: Session
"-------------------------------------------------------------------------------
let g:session_autosave = 0
let g:session_autoload = 0
let g:session_default_to_last = 0
let g:session_default_overwrite = 1
let g:session_command_aliases = 1

nnoremap gs :OpenSession<Space>
nnoremap <Leader>sc :CloseSession<CR>
nnoremap <Leader>ss :SaveSession<CR>


"-------------------------------------------------------------------------------
" Plugin: NERD Tree
"-------------------------------------------------------------------------------
let s:bundle = neobundle#get('vim-nerdtree-tabs')
function! s:bundle.hooks.on_source(bundle)
  let g:NERDSpaceDelims = 1
  let g:NERDShutUp = 1
  let g:NERDTreeShowHidden = 1
  let g:NERDTreeIgnore = ['\~$', '\.sass-cache$', '\.git$']
  let g:NERDTreeAutoDeleteBuffer = 1

  let g:nerdtree_tabs_open_on_gui_startup = 0
  let g:nerdtree_tabs_startup_cd = 0

  nnoremap <silent> <expr> <C-s> <SID>NERDTreeToggleOrFocus()
  function! s:NERDTreeToggleOrFocus()
    let isOpen = 0

    if exists('t:NERDTreeBufName')
      let isOpen = (bufwinnr(t:NERDTreeBufName) != -1 && bufnr(t:NERDTreeBufName) != bufnr('%'))
    endif

    if isOpen
      return ":0wincmd w\<CR>"
    else
      return ":NERDTreeTabsToggle\<CR>"
    endif
  endfun
endfunction
unlet s:bundle


"-------------------------------------------------------------------------------
" Plugin: Rooter
"-------------------------------------------------------------------------------
let g:rooter_patterns = ['.git', '.git/', 'Rakefile', 'Gemfile', 'package.json', '.vimprojectroot', '*.xcodeproj']
" let g:rooter_use_lcd = 1
let g:rooter_manual_only = 1
let g:rooter_change_directory_for_non_project_files = 0

autocmd vimrc BufRead,BufEnter,WinEnter,TabEnter * :Rooter


"-------------------------------------------------------------------------------
" Plugin: Submode
"-------------------------------------------------------------------------------
let g:submode_leave_with_key = 1

call submode#enter_with('winsize', 'n', '', '<C-w>>', '<C-w>>')
call submode#enter_with('winsize', 'n', '', '<C-w><', '<C-w><')
call submode#enter_with('winsize', 'n', '', '<C-w>+', '<C-w>-')
call submode#enter_with('winsize', 'n', '', '<C-w>-', '<C-w>+')
call submode#map('winsize', 'n', '', '>', '<C-w>>')
call submode#map('winsize', 'n', '', '<', '<C-w><')
call submode#map('winsize', 'n', '', '+', '<C-w>-')
call submode#map('winsize', 'n', '', '-', '<C-w>+')
call submode#enter_with('changetab', 'n', '', 'gt', 'gt')
call submode#enter_with('changetab', 'n', '', 'gT', 'gT')
call submode#map('changetab', 'n', '', 't', 'gt')
call submode#map('changetab', 'n', '', 'T', 'gT')


"-------------------------------------------------------------------------------
" Plugin: Memo List
"-------------------------------------------------------------------------------
let g:memolist_memo_suffix = 'md'
let g:memolist_path = '~/Dropbox/memo'
let g:memolist_unite = 1
let g:memolist_unite_source = 'file_rec'
let g:memolist_unite_option = '-start-insert'

nnoremap ,mn :MemoNew<CR>
nnoremap ,mg :MemoGrep<CR>
nnoremap ,ml :MemoList<CR>


"-------------------------------------------------------------------------------
" Plugin: Switch
"-------------------------------------------------------------------------------
let g:switch_custom_definitions =
  \ [
    \ ['public', 'protected', 'private'],
    \ ['on', 'off'],
    \ ['it', 'specify'],
    \ ['describe', 'context'],
    \ ['and', 'or']
  \ ]

nnoremap - :Switch<CR>


"-------------------------------------------------------------------------------
" Plugin: Altr
"-------------------------------------------------------------------------------
nmap ga <Plug>(altr-forward)
nmap gA <Plug>(altr-back)

" Header files
call altr#define('%.c', '%.h', '%.m')

" Jasmine
call altr#define('src/%.coffee', 'spec/%_spec.coffee')

" Rails
call altr#define('app/models/%.rb', 'spec/models/%_spec.rb', 'spec/factories/%s.rb')
call altr#define('app/controllers/%.rb', 'spec/controllers/%_spec.rb')
call altr#define('app/helpers/%.rb', 'spec/helpers/%_spec.rb')
call altr#define('%.html.haml', '%_smart_phone.html.haml')
call altr#define('%.html.slim', '%_smart_phone.html.slim')


"-------------------------------------------------------------------------------
" Plugin: vim rails
"-------------------------------------------------------------------------------
nmap gr :R<CR>


"-------------------------------------------------------------------------------
" Plugin: Ruby refactoring
"-------------------------------------------------------------------------------
nnoremap <Leader>rap  :RAddParameter<CR>
nnoremap <Leader>rcpc :RConvertPostConditional<CR>
nnoremap <Leader>rel  :RExtractLet<CR>
vnoremap <Leader>rec  :RExtractConstant<CR>
vnoremap <Leader>relv :RExtractLocalVariable<CR>
nnoremap <Leader>rit  :RInlineTemp<CR>
vnoremap <Leader>rrlv :RRenameLocalVariable<CR>
vnoremap <Leader>rriv :RRenameInstanceVariable<CR>
vnoremap <Leader>rem  :RExtractMethod<CR>


"-------------------------------------------------------------------------------
" Plugin: SmartInput / Endwise
"-------------------------------------------------------------------------------
call smartinput_endwise#define_default_rules()


"-------------------------------------------------------------------------------
" Plugin: IndentLine
"-------------------------------------------------------------------------------
let g:indentLine_char = '⁞'
let g:indentLine_first_char = '⁞'
let g:indentLine_showFirstIndentLevel = 1
let g:indentLine_color_term = 234
let g:indentLine_color_gui = '#222222'
let g:indentLine_indentLevel = 20


"-------------------------------------------------------------------------------
" Plugin: Over
"-------------------------------------------------------------------------------
let g:over_command_line_key_mappings = {
  \ "\<C-c>": "\<Esc>",
  \ "\<C-j>": "\<CR>",
\ }

cnoremap <expr> :
  \ (getcmdtype() == ':' && getcmdpos() == 1) ? "OverCommandLine\<CR>%s/" : ':'


"-------------------------------------------------------------------------------
" Plugin: Quickrun
"-------------------------------------------------------------------------------
let g:quickrun_config = {}
let g:quickrun_config._ = { 'runner': 'vimproc' }
let g:quickrun_config['ruby.rspec'] = { 'command': 'rspec', 'cmdopt': 'bundle exec', 'exec': '%o %c %s' }
let g:quickrun_config.markdown = {
  \ 'outputter': 'null',
  \ 'command':   'open',
  \ 'cmdopt':    '-a',
  \ 'args':      'Marked',
  \ 'exec':      '%c %o %a %s',
\ }


"-------------------------------------------------------------------------------
" Plugin: Fugitive
"-------------------------------------------------------------------------------
let s:bundle = neobundle#get('vim-fugitive')
function! s:bundle.hooks.on_source(bundle)
  autocmd vimrc User fugitive
    \ if fugitive#buffer().type() =~# '^\%(tree\|blob\)$' |
    \   nnoremap <buffer> .. :edit %:h<CR> |
    \ endif

  autocmd vimrc BufReadPost fugitive://*
    \ set bufhidden=delete
endfunction
unlet s:bundle


"-------------------------------------------------------------------------------
" Plugin: Unite
"-------------------------------------------------------------------------------
let s:bundle = neobundle#get('unite.vim')
function! s:bundle.hooks.on_source(bundle)
  let g:unite_enable_start_insert = 1
  let g:unite_winheight = 10
  let g:unite_enable_ignore_case = 1
  let g:unite_enable_smart_case = 1
  let g:unite_source_rec_min_cache_files = 50
  let g:unite_source_rec_max_cache_files = 5000

  let s:file_rec_ignore_pattern = (unite#sources#rec#define()[0]['ignore_pattern'])
    \ . '\|\.\%(jpe\?g\|png\|gif\|pdf\|ttf\|otf\|eot\|woff\|svg\|svgz\)$\|\%(^\|/\)\%(tmp\|cache\)/'
  call unite#custom#source('file', 'ignore_pattern', s:file_rec_ignore_pattern)
  call unite#custom#source('file_rec', 'ignore_pattern', s:file_rec_ignore_pattern)
  call unite#custom#source('file_rec/async', 'ignore_pattern', s:file_rec_ignore_pattern)
  call unite#custom#source('grep', 'ignore_pattern', s:file_rec_ignore_pattern)

  if executable('ag')
    let g:unite_source_grep_command = 'ag'
    let g:unite_source_grep_default_opts = '--nogroup --nocolor --column'
    let g:unite_source_grep_recursive_opt = ''
  endif

  nnoremap <C-q> :Unite -hide-source-names -buffer-name=files file file/new directory/new<CR>
  autocmd vimrc FileType unite call s:unite_my_settings()
  autocmd vimrc WinEnter,BufEnter *
    \ if &ft != 'unite' |
      \ let g:unite_prev_bufpath = expand('%:p:h') |
    \ endif

  function! s:unite_my_settings()
    call clearmatches()

    nmap <buffer> <C-q> <Plug>(unite_exit)
    imap <buffer> <C-q> <Plug>(unite_exit)
    inoremap <buffer> <C-d> <Del>
    inoremap <buffer> <silent> <C-h> <C-g>u<C-h>
    imap <buffer> <C-k> <Plug>(unite_delete_backward_line)
    inoremap <buffer> <C-b> <Left>
    inoremap <buffer> <C-f> <Right>
    imap <buffer> <C-a> <Plug>(unite_move_head)
    inoremap <buffer> <C-e> <End>
    imap <buffer> <C-j> <Plug>(unite_do_default_action)
    imap <buffer> <C-l> <Plug>(unite_redraw)
    inoremap <buffer> : **/
    inoremap <silent> <buffer> ^ <C-r>=g:unite_prev_bufpath . '/' <CR>
    " [TODO] unite#get_current_unite().prev_bufnr

    let unite = unite#get_current_unite()
    if unite.buffer_name =~# '^search'
      nnoremap <silent><buffer><expr> r unite#do_action('replace')
    else
      nnoremap <silent><buffer><expr> r unite#do_action('rename')
    endif
  endfunction
endfunction
unlet s:bundle


"-------------------------------------------------------------------------------
" Plugin: Anzu
"-------------------------------------------------------------------------------
nmap n <Plug>(anzu-n-with-echo)
nmap N <Plug>(anzu-N-with-echo)
nmap * <Plug>(anzu-star-with-echo)
nmap # <Plug>(anzu-sharp-with-echo)


"-------------------------------------------------------------------------------
" Plugin: Lightline
"-------------------------------------------------------------------------------
let g:unite_force_overwrite_statusline = 0
let g:vimfiler_force_overwrite_statusline = 0
let g:vimshell_force_overwrite_statusline = 0

let g:lightline = {
  \ 'colorscheme': 'creastycode',
  \ 'mode_map': { 'c': 'NORMAL' },
  \ 'active': {
    \ 'left': [
      \ ['mode', 'paste'],
      \ ['fugitive','filename']
    \ ],
    \ 'right': [
      \ ['syntastic', 'lineinfo', 'percent'],
      \ ['filetype'],
      \ ['fileencoding']
    \ ]
  \ },
  \ 'component_function': {
    \ 'modified':     'LightlineModified',
    \ 'readonly':     'LightlineReadonly',
    \ 'fugitive':     'LightlineFugitive',
    \ 'filename':     'LightlineFilename',
    \ 'fileformat':   'LightlineFileformat',
    \ 'filetype':     'LightlineFiletype',
    \ 'fileencoding': 'LightlineFileencoding',
    \ 'mode':         'LightlineMode',
    \ 'anzu':         'anzu#search_status',
  \ },
  \ 'component_expand': {
    \ 'syntastic': 'SyntasticStatuslineFlag',
  \ },
  \ 'component_type': {
    \ 'syntastic': 'error',
  \ },
  \ 'subseparator': { 'left': '|', 'right': '|' },
\ }

if has('gui_running')
  let g:lightline.separator = { 'left': "\u2b80", 'right': "\u2b82" }
  let g:lightline.subseparator = { 'left': "\u2b81", 'right': "\u2b83" }
endif

function! LightlineModified()
  return &ft =~ 'help\|vimfiler\|gundo' ? '' : &modified ? '+' : &modifiable ? '' : '-'
endfunction

function! LightlineReadonly()
  let icon = has("gui_running") ? "\u2b64" : "!!"
  return &ft !~? 'help\|vimfiler\|gundo' && &readonly ? icon : ''
endfunction

function! LightlineFilename()
  let fname = expand('%:t')
  return fname == 'ControlP' ? g:lightline.ctrlp_item :
    \ fname == '__Tagbar__' ? g:lightline.fname :
    \ fname =~ '__Gundo\|NERD_tree' ? '' :
    \ &ft == 'vimfiler' ? vimfiler#get_status_string() :
    \ &ft == 'unite' ? unite#get_status_string() :
    \ &ft == 'vimshell' ? vimshell#get_status_string() :
    \ ('' != LightlineReadonly() ? LightlineReadonly() . ' ' : '') .
    \ ('' != fname ? fname : '[No Name]') .
    \ ('' != LightlineModified() ? ' ' . LightlineModified() : '')
endfunction

function! LightlineFugitive()
  try
    if expand('%:t') !~? 'Tagbar\|Gundo\|NERD' && &ft !~? 'vimfiler' && exists('*fugitive#head')
      let icon = has("gui_running") ? "\u2b60 " : "~ "
      let branch = fugitive#head()
      let branch = substitute(branch, '^feature/', 'F/', '')
      let branch = substitute(branch, '^hotfix/', 'X/', '')
      let branch = substitute(branch, '^release/', 'R/', '')
      return strlen(branch) ? icon . branch : ''
    endif
  catch
  endtry
  return ''
endfunction

function! LightlineFileformat()
  return winwidth(0) > 70 ? &fileformat : ''
endfunction

function! LightlineFiletype()
  return winwidth(0) > 70 ? (strlen(&filetype) ? &filetype : 'plain') : ''
endfunction

function! LightlineFileencoding()
  return winwidth(0) > 70 ? (strlen(&fenc) ? &fenc : &enc) : ''
endfunction

function! LightlineMode()
  let fname = expand('%:t')
  return fname == '__Tagbar__' ? 'Tagbar' :
    \ fname == 'ControlP' ? 'CtrlP' :
    \ fname == '__Gundo__' ? 'Gundo' :
    \ fname == '__Gundo_Preview__' ? 'Gundo Preview' :
    \ fname =~ 'NERD_tree' ? 'NERDTree' :
    \ &ft == 'unite' ? 'Unite' :
    \ &ft == 'vimfiler' ? 'VimFiler' :
    \ &ft == 'vimshell' ? 'VimShell' :
    \ winwidth(0) > 60 ? lightline#mode() : ''
endfunction

autocmd vimrc BufWritePost * call lightline#update()


"-------------------------------------------------------------------------------
" Function: SyntaxInfo
"-------------------------------------------------------------------------------
function! s:get_syn_id(transparent)
  let synid = synID(line('.'), col('.'), 1)

  if a:transparent
    return synIDtrans(synid)
  else
    return synid
  endif
endfunction

function! s:get_syn_attr(synid)
  let name = synIDattr(a:synid, 'name')
  let ctermfg = synIDattr(a:synid, 'fg', 'cterm')
  let ctermbg = synIDattr(a:synid, 'bg', 'cterm')
  let guifg = synIDattr(a:synid, 'fg', 'gui')
  let guibg = synIDattr(a:synid, 'bg', 'gui')

  return {
    \ 'name': name,
    \ 'ctermfg': ctermfg,
    \ 'ctermbg': ctermbg,
    \ 'guifg': guifg,
    \ 'guibg': guibg
  \ }
endfunction

function! s:get_syn_info()
  let baseSyn = s:get_syn_attr(s:get_syn_id(0))

  echo 'name: ' . baseSyn.name .
    \ ' ctermfg: ' . baseSyn.ctermfg .
    \ ' ctermbg: ' . baseSyn.ctermbg .
    \ ' guifg: ' . baseSyn.guifg .
    \ ' guibg: ' . baseSyn.guibg

  let linkedSyn = s:get_syn_attr(s:get_syn_id(1))

  echo 'link to'
  echo 'name: ' . linkedSyn.name .
    \ ' ctermfg: ' . linkedSyn.ctermfg .
    \ ' ctermbg: ' . linkedSyn.ctermbg .
    \ ' guifg: ' . linkedSyn.guifg .
    \ ' guibg: ' . linkedSyn.guibg
endfunction

command! ScopeInfo call s:get_syn_info()

