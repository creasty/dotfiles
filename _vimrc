
"-------------------------------------------------------------------------------
" Plugin manager: neobundle
"-------------------------------------------------------------------------------
set nocompatible
filetype plugin indent off

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
NeoBundle 'kana/vim-operator-user'
NeoBundle 'kana/vim-textobj-user'
NeoBundle 'kana/vim-textobj-indent'
NeoBundle 'osyo-manga/vim-textobj-multiblock'
NeoBundle 'Shougo/unite.vim'
NeoBundle 'davidoc/taskpaper.vim'
NeoBundle 'itchyny/lightline.vim'
NeoBundle 'surround.vim'
NeoBundle 'kien/ctrlp.vim'
NeoBundle 'tpope/vim-fugitive'
NeoBundle 'tpope/vim-commentary'
NeoBundle 'Lokaltog/vim-easymotion'
NeoBundle 'scrooloose/nerdcommenter'
NeoBundle 'scrooloose/nerdtree'
NeoBundle 'jistr/vim-nerdtree-tabs'
NeoBundle 'scrooloose/syntastic'
NeoBundle 'xolox/vim-misc'
NeoBundle 'xolox/vim-session'
NeoBundle 'terryma/vim-multiple-cursors'
NeoBundle 'mattn/multi-vim'
NeoBundle 'Align'
NeoBundle 'gitv'
NeoBundle 'mattn/emmet-vim'
NeoBundle 'Shougo/neocomplete'
NeoBundleLazy 'Shougo/neosnippet', {
  \ 'autoload': {
  \   'commands': ['NeoSnippetEdit', 'NeoSnippetSource'],
  \   'filetypes': 'snippet',
  \   'insert': 1,
  \   'unite_sources': ['snippet', 'neosnippet/user', 'neosnippet/runtime'],
  \ }
\ }
NeoBundle 'SyntaxComplete'
NeoBundleLazy 'Shougo/vimshell.vim', {
\   'autoload': { 'commands': ['VimShell'] },
\   'depends': ['Shougo/vimproc'],
\ }
NeoBundle 'Shougo/unite.vim'
NeoBundle 'tomtom/tcomment_vim'
NeoBundle 'othree/eregex.vim'
NeoBundle 'tyru/operator-html-escape.vim'
NeoBundle 'tyru/operator-camelize.vim'
NeoBundle 'tek/vim-operator-assign'
NeoBundle 'rhysd/vim-operator-evalruby'
NeoBundle 'pekepeke/vim-operator-tabular'
NeoBundle 'emonkak/vim-operator-sort'
NeoBundle 'tyru/open-browser.vim'
NeoBundle 'qtmplsel.vim'
NeoBundle 'glidenote/memolist.vim'
NeoBundle 'rking/ag.vim'
NeoBundle 'tmhedberg/matchit.git'
NeoBundleLazy 'alpaca-tc/vim-endwise.git', {
  \ 'autoload': {
  \   'insert': 1,
  \ }
\ }
NeoBundle 'Yggdroot/indentLine'
NeoBundle 'Shougo/vinarise.vim'
NeoBundle 'kshenoy/vim-signature'
NeoBundle 'AndrewRadev/switch.vim'
NeoBundle 'closetag.vim'
NeoBundle 'SearchComplete'
NeoBundle 'smartchr'
NeoBundle 'kana/vim-fakeclip.git'
NeoBundle 'YankRing.vim'
NeoBundle 'rubycomplete.vim'
NeoBundle 'Rip-Rip/clang_complete'
NeoBundle 'kana/vim-altr'
NeoBundle 't9md/vim-textmanip'
NeoBundle 'tyru/open-browser.vim'
NeoBundle 'airblade/vim-rooter'
NeoBundle 'ecomba/vim-ruby-refactoring'

NeoBundle 'tpope/vim-haml'
NeoBundle 'tpope/vim-markdown'
NeoBundle 'claco/jasmine.vim'
NeoBundle 'kchmck/vim-coffee-script'
NeoBundle 'tpope/vim-rails'
NeoBundle 'vim-ruby/vim-ruby'
NeoBundle 'tpope/vim-cucumber'
NeoBundle 'slim-template/vim-slim'

NeoBundle 'altercation/vim-colors-solarized'
NeoBundle 'chriskempson/vim-tomorrow-theme'

" 何故か動かない
" NeoBundle 'thinca/vim-quickrun.git'
" NeoBundle 'thinca/vim-qfreplace'
" NeoBundle 'm2ym/rsense'


NeoBundleCheck
filetype plugin indent on


"-------------------------------------------------------------------------------
" Plugin manager: pathogen
"-------------------------------------------------------------------------------
filetype off
call pathogen#runtime_append_all_bundles()
call pathogen#helptags()
set helpfile=$VIMRUNTIME/doc/help.txt
filetype plugin on


"-------------------------------------------------------------------------------
" Basics
"-------------------------------------------------------------------------------
" Vi 互換なし
set nocompatible

" C-s とかのキーバインディングを有効にする
silent !stty -ixon > /dev/null 2>/dev/null
set wildignore+=*/tmp/*,*.so,*.swp,*.zip

" キーマップリーダー
let mapleader = ','

" 全角記号の幅
set ambiwidth=double

" スクロール時の余白確保
set scrolloff=5

" 一行に長い文章を書いていても自動折り返しをしない
set textwidth=0

" バックアップ取らない
set nobackup

" 他で書き換えられたら自動で読み直す
set autoread

" スワップファイル作らない
set noswapfile

" 編集中でも他のファイルを開けるようにする
set hidden

" バックスペースでなんでも消せるように
set backspace=indent,eol,start

" テキスト整形オプション，マルチバイト系を追加
set formatoptions=lmoq

" ビープをならさない
set vb t_vb=

" Explore の初期ディレクトリ
set browsedir=buffer

" カーソルを行頭、行末で止まらないようにする
set whichwrap=b,s,h,l,<,>,[,]

" コマンドをステータス行に表示
set showcmd

" 現在のモードを表示
set showmode

" viminfoファイルの設定
set viminfo='50,<1000,s100,\"50

" モードラインは無効
set modelines=0

" コマンド補完を強化
set wildmenu

" コマンド補完を開始するキー
"set wildchar=

" リスト表示，最長マッチ
set wildmode=list:full

" コマンド・検索パターンの履歴数
set history=1000

" 補完に辞書ファイル追加
set complete+=k

" ヤンクした文字は、システムのクリップボードに入れる
set clipboard=unnamed

" 常に10進数を使う
set nf=

" IME を無効化
set imdisable

" Ev/Rvでvimrcの編集と反映
command Ev edit $MYVIMRC
command Sv source $MYVIMRC

" C-c と Esc の挙動を同じに
inoremap <C-c> <esc>

" Undo/Redo
nnoremap U :redo<CR>
inoremap <c-u> <esc>ui
inoremap <c-s-u> <esc>Ui

" タブページ
nmap ;; :tabnew<cr>


"-------------------------------------------------------------------------------
" Apperance
"-------------------------------------------------------------------------------
" Color scheme
set background=dark
set t_Co=256
colorscheme My-Tomorrow-Night-Bright

" シンタックスハイライト
syntax enable

" 常にステータスラインを表示
set laststatus=2

" 常にタブバーを表示
set showtabline=2

" 括弧の対応をハイライト
set showmatch

" 行番号表示
set number

" カーソル行をハイライト
set cursorline

" 不可視文字の表示
set list
set listchars=tab:▸\ ,trail:˽

" 印字不可能文字を16進数で表示
set display=uhex

" 全角スペースを可視化
match ZenkakuSpace /　/

" カレントウィンドウにのみ罫線を引く
augroup cch
  autocmd! cch
  autocmd WinLeave * set nocursorline
  autocmd WinEnter,BufRead * set cursorline
augroup END

" コマンド実行中は再描画しない
set lazyredraw

" 高速ターミナル接続を行う
set ttyfast


"-------------------------------------------------------------------------------
" Tags
"-------------------------------------------------------------------------------
" set tags

if has("autochdir")
  " 編集しているファイルのディレクトリに自動で移動
  set autochdir
  set tags=tags;
else
  set tags=./tags,./../tags,./*/tags,./../../tags,./../../../tags,./../../../../tags,./../../../../../tags
endif

"「進む」
nnoremap tn :tn

"「戻る」
nnoremap tp :tp

"履歴一覧
nnoremap tl :tags


"-------------------------------------------------------------------------------
" Search
"-------------------------------------------------------------------------------
" 最後まで検索したら先頭へ戻る
set wrapscan

" 大文字小文字無視
set ignorecase

" 検索文字列に大文字が含まれている場合は区別して検索する
set smartcase

" インクリメンタルサーチ
set incsearch

" 検索文字をハイライト
set hlsearch

" Escの2回押しでハイライト消去
nmap <Esc><Esc> :nohlsearch<CR><Esc>

" 選択した文字列を検索
vnoremap // y/=escape(@", '\\/.*$^~')

" 選択した文字列を置換
vnoremap /r "xy;%s/=escape(@x, '\\/.*$^~')//gc

" s*置換後文字列/gでカーソル下のキーワードを置換
nnoremap s* ':%substitute/\<' . expand('') . '\>/'

" 検索語が真ん中に来るようにする
nmap n nzz
nmap N Nzz
nmap * *zz
nmap # #zz
nmap g* g*zz
nmap g# g#zz

" 検索パターンの入力時に自動エスケープ
cnoremap <expr> /  getcmdtype() == '/' ? '\/' : '/'
cnoremap <expr> ?  getcmdtype() == '?' ? '\?' : '?'


"-------------------------------------------------------------------------------
" Encoding
"-------------------------------------------------------------------------------
set encoding=utf-8
set fileencodings=ucs_bom,utf8,ucs-2le,ucs-2
set fileformats=unix,dos,mac

" 文字コードの自動認識
if &encoding !=# 'utf-8'
  set encoding=japan
  set fileencoding=japan
endif
if has('iconv')
  let s:enc_euc = 'euc-jp'
  let s:enc_jis = 'iso-2022-jp'
  " iconvがeucJP-msに対応しているかをチェック
  if iconv("\x87\x64\x87\x6a", 'cp932', 'eucjp-ms') ==# "\xad\xc5\xad\xcb"
    let s:enc_euc = 'eucjp-ms'
    let s:enc_jis = 'iso-2022-jp-3'
  " iconvがJISX0213に対応しているかをチェック
  elseif iconv("\x87\x64\x87\x6a", 'cp932', 'euc-jisx0213') ==# "\xad\xc5\xad\xcb"
    let s:enc_euc = 'euc-jisx0213'
    let s:enc_jis = 'iso-2022-jp-3'
  endif
  " fileencodingsを構築
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
  " 定数を処分
  unlet s:enc_euc
  unlet s:enc_jis
endif

" 日本語を含まない場合は fileencoding に encoding を使うようにする
function! AU_ReCheck_FENC()
  if &fileencoding =~# 'iso-2022-jp' && search("[^\x01-\x7e]", 'n') == 0
    let &fileencoding=&encoding
  endif
endfunction

autocmd BufReadPost * call AU_ReCheck_FENC()

" 改行コードの自動認識
set fileformats=unix,dos,mac

" cvsの時は文字コードをeuc-jpに設定
autocmd FileType cvs :set fileencoding=euc-jp

" ワイルドカードで表示するときに優先度を低くする拡張子
set suffixes=.bak,~,.swp,.o,.info,.aux,.log,.dvi,.bbl,.blg,.brf,.cb,.ind,.idx,.ilg,.inx,.out,.toc

" 指定文字コードで強制的にファイルを開く
command! Cp932 edit ++enc=cp932
command! Eucjp edit ++enc=euc-jp
command! Iso2022jp edit ++enc=iso-2022-jp
command! Utf8 edit ++enc=utf-8
command! Jis Iso2022jp
command! Sjis Cp932


"-------------------------------------------------------------------------------
" Editing
"-------------------------------------------------------------------------------
" 自動でインデント
set noautoindent
set smartindent
set cindent
set smarttab
set noexpandtab

" softtabstop は Tab キー押し下げ時の挿入される空白の量
" 0 の場合は tabstop と同じ
set tabstop=2 shiftwidth=2 softtabstop=0

" ファイルタイプの検索を有効にする
filetype plugin on

" そのファイルタイプにあわせたインデントを利用する
filetype indent on

" yeでそのカーソル位置にある単語をレジスタに追加
nmap ye ;let @"=expand("")

" Visualモードでのpで選択範囲をレジスタの内容に置き換える
vnoremap p ;let current_reg = @"gvdi=current_reg

" :Ptでインデントモード切替
command! Pt :set paste!

" Emacs のカーソル移動
imap <C-n> <Down>
imap <C-p> <Up>
imap <C-b> <Left>
imap <C-f> <Right>
imap <C-a> <Home>
imap <C-e> <End>
imap <C-j> <CR>
imap <C-d> <Del>
imap <silent> <C-h> <C-g>u<C-h>
imap <expr> <C-k> "\<C-g>u".(col('.') == col('$') ? '<C-o>gJ' : '<C-o>d$')

cmap <C-a> <Home>
cmap <C-b> <Left>
cmap <C-f> <Right>
cmap <C-d> <Del>
cmap <C-k> <C-\>e getcmdpos() == 1 ? '' : getcmdline()[:getcmdpos()-2]<CR>

nmap <C-j> <CR>
nmap <C-n> <Down>
nmap <C-p> <Up>

" 括弧までを消したり置き換えたりする
" http://vim-users.jp/2011/04/hack214/
vnoremap ( t(
vnoremap ) t)
vnoremap ] t]
vnoremap [ t[
onoremap ( t(
onoremap ) t)
onoremap ] t]
onoremap [ t[

" ヤンク
inoremap <silent> <C-y>e <Esc>ly0<Insert>
inoremap <silent> <C-y>0 <Esc>ly$<Insert>

" 保存時に行末の空白を除去する
autocmd BufWritePre * :%s/\s\+$//ge

" 保存時に tab をスペースに変換する (expandtab が設定されているなら)
autocmd BufWritePre * if &et | exec "%s/\t/  /ge" | endif

" 日時の自動入力
inoremap ,df strftime('%Y/%m/%d %H:%M:%S')
inoremap ,dd strftime('%Y/%m/%d')
inoremap ,dt strftime('%H:%M:%S')

" ファイルを開いた時に最後のカーソル位置を再現する
au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g`\"" | endif

" automatically change the current directory
autocmd BufEnter * silent! lcd %:p:h

" 各種エンコーディングで開き直す
command! -bang -nargs=? Utf8
  \ edit<bang> ++enc=utf-8 <args>
command! -bang -nargs=? Sjis
  \ edit<bang> ++enc=cp932 <args>
command! -bang -nargs=? Euc
  \ edit<bang> ++enc=eucjp <args>

" 矩形選択で連番を付ける: 3co
nnoremap <silent> co :ContinuousNumber <C-a><CR>
vnoremap <silent> co :ContinuousNumber <C-a><CR>
command! -count -nargs=1 ContinuousNumber let c = col('.')|for n in range(1, <count>?<count>-line('.'):1)|exec 'normal! j' . n . <q-args>|call cursor('.', c)|endfor

" 自動的にディレクトリを作成する
" http://vim-users.jp/2011/02/hack202/
augroup vimrc-auto-mkdir
  autocmd!
  autocmd BufWritePre * call s:auto_mkdir(expand('<afile>:p:h'), v:cmdbang)
  function! s:auto_mkdir(dir, force)
    if !isdirectory(a:dir) && (
      \ a:force ||
      \ input(printf('"%s" does not exist. Create? [y/N]', a:dir)) =~? '^y\%[es]$'
    \ )
      call mkdir(iconv(a:dir, &encoding, &termencoding), 'p')
    endif
  endfunction
augroup END

" 閉じタグを補完する
augroup MyXML
  autocmd!
  autocmd Filetype xml inoremap <buffer> </ </<C-x><C-o>
  autocmd Filetype html inoremap <buffer> </ </<C-x><C-o>
augroup END

" 編集中ファイルのファイル名を変更する
command! -nargs=1 -complete=file Rename f <args>|call delete(expand('#'))

" 編集中ファイルのファイル名を変更する
command! -nargs=0 Delete call delete(expand('%'))|q!


"-------------------------------------------------------------------------------
" Filetype specific
"-------------------------------------------------------------------------------
" 拡張子
au BufNewFile,BufRead *.psgi    set ft=perl
au BufNewFile,BufRead *.t       set ft=perl
au BufNewFile,BufRead *.ejs     set ft=html
au BufNewFile,BufRead *.ep      set ft=html
au BufNewFile,BufRead *.pde     set ft=processing
au BufNewFile,BufRead *.erb     set ft=html
au BufNewFile,BufRead *.tt      set ft=html
au BufNewFile,BufRead *.tt2     set ft=html
au BufNewFile,BufRead *.scss    set ft=scss
au BufNewFile,BufRead Guardfile set ft=ruby
au BufNewFile,BufRead cpanfile  set ft=perl

" ソフトタブ
autocmd FileType yaml   setlocal et
autocmd FileType diff   setlocal et
autocmd FileType eruby  setlocal et
autocmd FileType coffee setlocal et
autocmd FileType ruby   setlocal et
autocmd FileType haml   setlocal et
autocmd FileType sh     setlocal et
autocmd FileType sql    setlocal et
autocmd FileType vim    setlocal et
autocmd FileType yaml   setlocal et
autocmd FileType scala  setlocal et
autocmd FileType scheme setlocal et

" 以下のファイルの時は文字コードをutf-8に設定
autocmd FileType svn   setlocal fenc=utf-8
autocmd FileType js    setlocal fenc=utf-8
autocmd FileType css   setlocal fenc=utf-8
autocmd FileType html  setlocal fenc=utf-8
autocmd FileType xml   setlocal fenc=utf-8
autocmd FileType java  setlocal fenc=utf-8
autocmd FileType scala setlocal fenc=utf-8
autocmd FileType yml   setlocal fenc=utf-8

" ファイルタイプのエリアス
autocmd FileType js setlocal ft=javascript
autocmd FileType cs setlocal ft=coffee


"-------------------------------------------------------------------------------
" Plugin: NeoComplete
"-------------------------------------------------------------------------------
let g:acp_enableAtStartup = 0
let g:neocomplete#enable_at_startup = 1
let g:neocomplete#enable_smart_case = 1
let g:neocomplcache_max_list = 20
let g:neocomplete#sources#syntax#min_keyword_length = 3
let g:neocomplete#lock_buffer_name_pattern = '\*ku\*'
let g:neocomplete#disable_auto_complete = 0
let g:neocomplete#enable_auto_select = 0
let g:neocomplete#enable_insert_char_pre = 1
set completeopt-=preview

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

if !exists('g:neocomplete#keyword_patterns')
  let g:neocomplete#keyword_patterns = {}
endif

" キャッシュしないファイル名
let g:neocomplete#sources#buffer#disabled_pattern = '\.log\|\.log\.\|\.jax'

" 自動補完を行わないバッファ名
let g:neocomplete#lock_buffer_name_pattern = '\.log\|\.log\.\|.*quickrun.*\|.jax'

let g:neocomplete#keyword_patterns['default'] = '\h\w*'
let g:neocomplete#keyword_patterns.perl = '\h\w*->\h\w*\|\h\w*::\w*'

inoremap <silent> <CR> <C-r>=<SID>my_cr_function()<CR>
function! s:my_cr_function()
  return pumvisible() ? neocomplete#close_popup() : "\<CR>"
endfunction

inoremap <expr><TAB> pumvisible() ? neocomplete#close_popup() : "\<TAB>"

inoremap <expr><c-f> pumvisible() ? neocomplete#cancel_popup() . "\<right>" : "\<right>"
inoremap <expr><c-b> pumvisible() ? neocomplete#cancel_popup() . "\<left>" : "\<left>"
inoremap <expr><c-a> pumvisible() ? neocomplete#cancel_popup() . "\<home>" : "\<home>"
inoremap <expr><c-e> pumvisible() ? neocomplete#cancel_popup() . "\<end>" : "\<end>"
inoremap <expr><space> pumvisible() ? neocomplete#cancel_popup() . "\<space>" : "\<space>"
inoremap <expr><c-c> pumvisible() ? neocomplete#cancel_popup() : "\<esc>"
inoremap <expr><c-j> pumvisible() ? neocomplete#close_popup() : "\<cr>"

" Omni completion
autocmd FileType css setlocal omnifunc=csscomplete#CompleteCSS
autocmd FileType html,markdown setlocal omnifunc=htmlcomplete#CompleteTags
autocmd FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
autocmd FileType python setlocal omnifunc=pythoncomplete#Complete
autocmd FileType xml setlocal omnifunc=xmlcomplete#CompleteTags

if !exists('g:neocomplete#sources#omni#input_patterns')
  let g:neocomplete#sources#omni#input_patterns = {}
endif
let g:neocomplete#sources#omni#input_patterns.php = '[^. \t]->\h\w*\|\h\w*::'
let g:neocomplete#sources#omni#input_patterns.c = '[^.[:digit:] *\t]\%(\.\|->\)'
let g:neocomplete#sources#omni#input_patterns.cpp = '[^.[:digit:] *\t]\%(\.\|->\)\|\h\w*::'
let g:neocomplete#sources#omni#input_patterns.go = '\h\w*\.\?'
let g:neocomplete#sources#omni#input_patterns.ruby = '[^. *\t]\.\h\w*\|\h\w*::'


"-------------------------------------------------------------------------------
" Plugin: NeoSnippet
"-------------------------------------------------------------------------------
let g:neosnippet#disable_select_mode_mappings = 0
let g:neosnippet#enable_snipmate_compatibility = 1
let g:neosnippet#snippets_directory='~/.vim/snippets, ~/.vim/snipmate-snippets/snippets, ~/.vim/snipmate-snippets-rubymotion/snippets'

imap <expr><TAB> neosnippet#expandable_or_jumpable()
  \ ? "\<Plug>(neosnippet_expand_or_jump)"
  \ : pumvisible()
    \ ? neocomplete#close_popup()
    \ : "\<TAB>"

if has('conceal')
  set conceallevel=2 concealcursor=i
endif


"-------------------------------------------------------------------------------
" Plugin: SyntaxComplete
"-------------------------------------------------------------------------------
if has("autocmd") && exists("+omnifunc")
  autocmd Filetype *
    \ if &omnifunc == "" |
      \ setlocal omnifunc=syntaxcomplete#Complete |
    \ endif
endif


"-------------------------------------------------------------------------------
" Plugin: clang_complete
"-------------------------------------------------------------------------------
let g:clang_complete_auto = 0
let g:clang_auto_select = 0
" let g:clang_use_library = 1


"-------------------------------------------------------------------------------
" Plugin: Ruby complete
"-------------------------------------------------------------------------------
let g:rubycomplete_rails = 1
let g:rubycomplete_buffer_loading = 1
let g:rubycomplete_classes_in_global = 1
let g:rubycomplete_include_object = 1
let g:rubycomplete_include_object_space = 1

" MyAutocmd FileType ruby,eruby setlocal omnifunc=rubycomplete#Complete


"-------------------------------------------------------------------------------
" Plugin: TextManip
"-------------------------------------------------------------------------------
" 選択したテキストの移動
vmap <c-j> <Plug>(Textmanip.move_selection_down)
vmap <c-k> <Plug>(Textmanip.move_selection_up)
vmap <c-h> <Plug>(Textmanip.move_selection_left)
vmap <c-l> <Plug>(Textmanip.move_selection_right)

" 行の複製
vmap <c-m> <Plug>(Textmanip.duplicate_selection_v)
nmap mm <Plug>(Textmanip.duplicate_selection_n)


"-------------------------------------------------------------------------------
" Plugin: Smartchr
"-------------------------------------------------------------------------------
inoremap <expr> , smartchr#one_of(', ', ',')
inoremap <expr> : smartchr#one_of(':', '=>')
inoremap <expr> { smartchr#one_of('{', '#{', '{{{')
autocmd FileType c inoremap <buffer> <expr> . smartchr#loop('.',  '->')


"-------------------------------------------------------------------------------
" Plugin: OpenBrowser
"-------------------------------------------------------------------------------
let g:netrw_nogx = 1 " disable netrw's gx mapping.
nmap gx <Plug>(openbrowser-smart-search)
vmap gx <Plug>(openbrowser-smart-search)


"-------------------------------------------------------------------------------
" Plugin: Emmet
"-------------------------------------------------------------------------------
let g:user_emmet_mode='a'
let g:user_emmet_leader_key = '<c-m>'
let g:user_emmet_settings = {
  \ 'lang': 'ja',
  \ 'indentation': '  ',
  \ 'html' : {
    \ 'indentation': "\t",
  \ },
\ }
" inoremap <expr> ] searchpair('\[', '', '\]', 'nbW', 'synIDattr(synID(line("."), col("."), 1), "name") =~? "String"') ? ']' : "\<C-n>"


"-------------------------------------------------------------------------------
" Plugin: textobj-multiblock
"-------------------------------------------------------------------------------
omap ab <Plug>(textobj-multiblock-a)
omap ib <Plug>(textobj-multiblock-i)
vmap ab <Plug>(textobj-multiblock-a)
vmap ib <Plug>(textobj-multiblock-i)


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
" Plugin: tComment
"-------------------------------------------------------------------------------
let g:tcommentMapLeader1 = '<C-/>'
let g:tcommentMapLeader2 = '<Leader>'
let g:tcommentMapLeaderOp1 = 'gc'
let g:tcommentMapLeaderOp2 = 'gC'
let g:tcommentGuessFileType = 1


"-------------------------------------------------------------------------------
" Plugin: Session
"-------------------------------------------------------------------------------
let g:session_autosave = 0
let g:session_autoload = 0
let g:session_default_to_last = 0
let g:session_default_overwrite = 1
let g:session_command_aliases = 1

ab os OpenSession
ab cs CloseSession


"-------------------------------------------------------------------------------
" Plugin: NERD Tree
"-------------------------------------------------------------------------------
let g:NERDSpaceDelims = 1
let g:NERDShutUp = 1
let g:NERDTreeShowHidden = 1
let g:NERDTreeIgnore = ['\~$', '\.sass-cache$', '\.git$']

let g:nerdtree_tabs_open_on_gui_startup = 0
let g:nerdtree_tabs_startup_cd = 0
" let g:nerdtree_tabs_open_on_new_tab = 0

map <C-s> :NERDTreeTabsToggle<CR>


"-------------------------------------------------------------------------------
" Plugin: Rooter
"-------------------------------------------------------------------------------
let g:rooter_patterns = ['.git', '.git/', 'Rakefile', 'Gemfile', 'package.json', '.vimprojectroot']
" let g:rooter_use_lcd = 1
let g:rooter_manual_only = 1
let g:rooter_change_directory_for_non_project_files = 1
autocmd BufEnter * :Rooter


"-------------------------------------------------------------------------------
" Plugin: Alter
"-------------------------------------------------------------------------------
nmap <F3> <Plug>(altr-forward)
nmap <F2> <Plug>(altr-back)

let s:bundle = neobundle#get("vim-altr")
function! s:bundle.hooks.on_source(bundle)
  " For ruby tdd
  call altr#define('%.rb', 'spec/%_spec.rb')
  " For ruby tdd
  call altr#define('lib/%.rb', 'spec/lib/%_spec.rb', 'spec/%_spec.rb')
  " For rails tdd
  call altr#define('app/models/%.rb', 'spec/models/%_spec.rb', 'spec/factories/%s.rb')
  call altr#define('app/controllers/%.rb', 'spec/controllers/%_spec.rb')
  call altr#define('app/helpers/%.rb', 'spec/helpers/%_spec.rb')
endfunction
unlet s:bundle


"-------------------------------------------------------------------------------
" Plugin: Multi Cursor
"-------------------------------------------------------------------------------
let g:multi_cursor_use_default_mapping = 0
let g:multi_cursor_next_key = 'D'
" let g:multi_cursor_prev_key = ''
let g:multi_cursor_skip_key = ',D'
let g:multi_cursor_quit_key = '<c-c>'


"-------------------------------------------------------------------------------
" Plugin: Ag
"-------------------------------------------------------------------------------
" nnoremap gg/  :<C-u>Ag <C-R><C-w><CR>
" vnoremap gg/ y:<C-u>Ag <C-R>"<CR>


"-------------------------------------------------------------------------------
" Plugin: Memo List
"-------------------------------------------------------------------------------
let g:memolist_memo_suffix = 'md'
let g:memolist_path = '~/Dropbox/memo'

nnoremap ,mn :MemoNew<cr>
nnoremap ,mg :MemoGrep<cr>
nnoremap ,ml :MemoList<CR>
nnoremap ,mf :exe "CtrlP" g:memolist_path<cr><f5>


"-------------------------------------------------------------------------------
" Plugin: Align
"-------------------------------------------------------------------------------
xnoremap <silent> a: :Alignta 01 :<CR>
xnoremap al :Alignta<Space>


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

nnoremap - :Switch<cr>


"-------------------------------------------------------------------------------
" Plugin: Ruby refactoring
"-------------------------------------------------------------------------------
" メソッドに引数を追加する
nmap <leader>rap  :RAddParameter<cr>

" 一行で書かれた条件文(e.g. "hoge if fuga?" のようなもの)を伝統的な複数行の形式に変換する
nmap <leader>rcpc :RConvertPostConditional<cr>

" 選択部分を RSpec の "let(:hoge) { fuga }" の形式に切り出す
nmap <leader>rel  :RExtractLet<cr>

" 選択部分を定数として切り出す
vmap <leader>rec  :RExtractConstant<cr>

" 選択部分を変数として切り出す
vmap <leader>relv :RExtractLocalVariable<cr>

" 一時変数を取り除く
nmap <leader>rit  :RInlineTemp<cr>

" ローカル変数をリネームする
vmap <leader>rrlv :RRenameLocalVariable<cr>

" インスタンス変数をリネームする
vmap <leader>rriv :RRenameInstanceVariable<cr>

" 選択部分をメソッドに切り出す
vmap <leader>rem  :RExtractMethod<cr>


"-------------------------------------------------------------------------------
" Plugin: Endwise
"-------------------------------------------------------------------------------
let g:endwise_no_mappings = 1
imap <c-j> <CR><Plug>DiscretionaryEnd


"-------------------------------------------------------------------------------
" Plugin: YankRing
"-------------------------------------------------------------------------------
let g:yankring_replace_n_pkey = '<m-p>'
let g:yankring_replace_n_nkey = '<m-n>'
nnoremap <space><space>y :YRShow<CR>


"-------------------------------------------------------------------------------
" Plugin: indent line
"-------------------------------------------------------------------------------
let g:indentLine_char = '¦'
let g:indentLine_color_term = 234
let g:indentLine_color_gui = '#2a2a2a'


"-------------------------------------------------------------------------------
" Plugin: Unite
"-------------------------------------------------------------------------------
" nmap <c-q> :Unite file_rec/async:!<cr>

ab unr Unite file_rec/async:!


"-------------------------------------------------------------------------------
" Plugin: CtrlP
"-------------------------------------------------------------------------------
let g:ctrlp_cmd = 'CtrlPMixed'
let g:ctrlp_map = '<c-q>'
let g:ctrlp_by_filename = 0
let g:ctrlp_max_height = 10
let g:ctrlp_switch_buffer = 'et'
let g:ctrlp_use_caching = 1
let g:ctrlp_clear_cache_on_exit = 0
let g:ctrlp_mruf_max = 250

let g:ctrlp_custom_ignore = {
  \ 'dir':  '\v[\/]\.(git|hg|svn|build|sass-cache)$',
  \ 'file': '\v\.(exe|so|dll)$',
  \ 'link': 'SOME_BAD_SYMBOLIC_LINKS',
\ }

let g:ctrlp_buftag_types = {
  \ 'go':       '--language-force=go --golang-types=ftv',
  \ 'coffee':   '--language-force=coffee --coffee-types=cmfvf',
  \ 'markdown': '--language-force=markdown --markdown-types=hik',
  \ 'objc':     '--language-force=objc --objc-types=mpci',
  \ 'rc':       '--language-force=rust --rust-types=fTm',
\ }


"-------------------------------------------------------------------------------
" Plugin: Lightline
"-------------------------------------------------------------------------------
let g:lightline = {
  \ 'mode_map': { 'c': 'NORMAL' },
  \ 'active': {
    \ 'left': [
      \ ['mode', 'paste'],
      \ ['fugitive','filename'],
      \ ['ctrlpmark']
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
    \ 'ctrlpmark':    'LightlineCtrlPMark',
  \ },
  \ 'component_expand': {
    \ 'syntastic': 'SyntasticStatuslineFlag',
  \ },
  \ 'component_type': {
    \ 'syntastic': 'error',
  \ },
  \ 'subseparator': { 'left': "│", 'right': "│" },
\ }

if has("gui_running")
  let g:lightline['separator'] = { 'left': "\u2b80", 'right': "\u2b82" }
  let g:lightline['subseparator'] = { 'left': "\u2b81", 'right': "\u2b83" }
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
      let _ = fugitive#head()
      return strlen(_) ? icon._ : ''
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

let g:lightline.ctrlp_regex = ''
let g:lightline.ctrlp_prev = ''
let g:lightline.ctrlp_item = ''
let g:lightline.ctrlp_next = ''

let g:ctrlp_status_func = {
  \ 'main': 'CtrlPStatusFunc_1',
  \ 'prog': 'CtrlPStatusFunc_2',
\ }

function! CtrlPStatusFunc_1(focus, byfname, regex, prev, item, next, marked)
  let g:lightline.ctrlp_regex = a:regex
  let g:lightline.ctrlp_prev = a:prev
  let g:lightline.ctrlp_item = a:item
  let g:lightline.ctrlp_next = a:next
  return lightline#statusline(0)
endfunction

function! CtrlPStatusFunc_2(str)
  return lightline#statusline(0)
endfunction

function! LightlineCtrlPMark()
  if expand('%:t') =~ 'ControlP'
    call lightline#link('iR'[g:lightline.ctrlp_regex])
    return ''
  else
    return ''
  endif
endfunction

augroup AutoSyntastic
  autocmd!
  autocmd BufWritePost *.c,*.cpp call s:syntastic()
augroup END
function! s:syntastic()
  SyntasticCheck
  call lightline#update()
endfunction
