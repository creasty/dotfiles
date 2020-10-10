if exists('g:loaded_vimrc_appearance') || v:version < 702
  finish
endif
let g:loaded_vimrc_appearance = 1

let s:save_cpo = &cpoptions
set cpoptions&vim

scriptencoding utf-8

augroup vimrc_appearance
  autocmd!
augroup END

" enable 24-bits colors
if has('termguicolors')
  set termguicolors
endif

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

" show hidden charactors
set list
set listchars=tab:▸\ ,nbsp:∘,extends:❯,precedes:❮

" indent wrapped lines
if has('linebreak')
  set breakindent
  let &showbreak = '   ›'
else
  let &showbreak = '›'
end

" conceal
if has('conceal')
  set conceallevel=2 concealcursor=
endif

" color column
set colorcolumn=90
hi ColorColumn guibg=#1f1f1f ctermbg=234

" always show sign column
set signcolumn=yes

" transparent pmenu
if exists('&pumblend')
  set pumblend=10
endif

" enables 24-bit RGB color in the TUI
set termguicolors

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

"  Custom highlights
"-----------------------------------------------
if g:colors_name ==# 'candle'
  " highlight full-width space
  call candle#highlight('ZenkakuSpace', '', 'dark_purple', '')
  autocmd vimrc_appearance BufWinEnter,WinEnter *
    \ call matchadd('ZenkakuSpace', '　') |
    \ call matchadd("SpellRare", '[０１２３４５６７８９]') |
    \ call matchadd("SpellRare", '[ａｂｃｄｅｆｇｈｉｊｋｌｍｎｏｐｑｒｓｔｕｖｗｘｙｚ]') |
    \ call matchadd("SpellRare", '[ＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯＰＱＲＳＴＵＶＷＸＹＺ]')

  " highlight extra blank lines
  " autocmd vimrc_appearance BufWinEnter,WinEnter *
  "   \ call matchadd("SpellBad", '^\n\ze\n\+\%$\@!')

  call candle#highlight('GitConflictMarker', 'red', 'dark_red', '')
  autocmd vimrc_appearance BufWinEnter,WinEnter *
    \ call matchadd('GitConflictMarker', '^\(<<<<<<<.\{-}\|=======\|>>>>>>>.\{-}\)$', 50)

  " highlight trailing spaces
  call candle#highlight('TrailingSpace', '', 'line', '')
  autocmd vimrc_appearance BufWinEnter,WinEnter *
    \ call matchadd('TrailingSpace', '\s\+$', 50)
endif

"  StatusLine
"-----------------------------------------------
function! s:refresh_statusline() abort
  let l:cw = winnr()

  for l:nr in range(1, winnr('$'))
    call setwinvar(l:nr, '&statusline', '%!vimrc#ui#status_line(' . l:nr . ', ' . l:cw . ')')
  endfor
endfunction

function! s:change_status_line_for_mode() abort
  let l:m = g:mode_observer_current_mode

  let l:color =
    \ l:m ==# 'i' ? 'blue' :
    \ l:m ==# 'v' ? 'orange' :
    \ l:m ==# 'r' ? 'purple' :
    \ 'foreground'

  call candle#highlight('StatusLineMode', l:color, '', '')
  call candle#highlight('Cursor', '', l:color, '')
endfunction

if g:colors_name ==# 'candle'
  autocmd vimrc_appearance VimEnter,WinEnter,BufWinEnter * call <SID>refresh_statusline()

  autocmd vimrc_appearance VimEnter,Syntax *
    \ call candle#highlight('StatusLineMode', 'foreground', 'window', '') |
    \ call candle#highlight('StatusLineDiagnosticError', 'red', 'window', '') |
    \ call candle#highlight('StatusLineDiagnosticWarning', 'yellow', 'window', '') |
    \ call candle#highlight('StatusLineDiagnosticInfo', 'blue', 'window', '') |
    \ call candle#highlight('StatusLineDiagnosticMessage', 'green', 'window', '')

  autocmd vimrc_appearance User ModeDidChange call <SID>change_status_line_for_mode()
endif

let &cpoptions = s:save_cpo
unlet s:save_cpo
