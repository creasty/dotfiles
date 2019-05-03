if exists('g:loaded_vimrc_appearance') || v:version < 702
  finish
endif
let g:loaded_vimrc_appearance = 1

let s:save_cpo = &cpoptions
set cpoptions&vim


scriptencoding utf-8

" syntax highlight & color scheme
set background=dark
set t_Co=256
syntax enable

if dein#tap('candle.vim')
  colorscheme candle
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


"  Folding
"-----------------------------------------------
set foldmethod=indent
set fillchars="fold:"
set foldlevel=20
set foldlevelstart=20
set foldtext=vimrc#ui#fold_text()


"  Custom highlight
"-----------------------------------------------
if exists('*candle#highlight')
  " highlight full-width space
  call candle#highlight('ZenkakuSpace', '', 'dark_purple', '')
  autocmd vimrc BufWinEnter,WinEnter *
    \ call matchadd('ZenkakuSpace', '　')
    \| call matchadd("SpellRare", '[０１２３４５６７８９]')
    \| call matchadd("SpellRare", '[ａｂｃｄｅｆｇｈｉｊｋｌｍｎｏｐｑｒｓｔｕｖｗｘｙｚ]')
    \| call matchadd("SpellRare", '[ＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯＰＱＲＳＴＵＶＷＸＹＺ]')

  " highlight trailing spaces
  call candle#highlight('TrailingSpace', '', 'line', '')
  autocmd vimrc BufWinEnter,WinEnter *
    \ call matchadd('TrailingSpace', '\s\+$', 50)
endif


"  Window title
"-----------------------------------------------
set title titlestring=%{vimrc#ui#title_text()}


"  TabLine
"-----------------------------------------------
set tabline=%!vimrc#ui#tab_line()


"  StatusLine
"-----------------------------------------------
function! s:refresh_statusline() abort
  let l:cw = winnr()

  for l:nr in range(1, winnr('$'))
    call setwinvar(l:nr, '&statusline', '%!vimrc#ui#status_line(' . l:nr . ', ' . l:cw . ')')
  endfor
endfunction

if exists('*candle#highlight')
  autocmd vimrc VimEnter,WinEnter,BufWinEnter * call <SID>refresh_statusline()
endif

let s:prev_status_line_mode = 'n'

function! s:change_status_line_for_mode(m) abort
  if s:prev_status_line_mode == a:m
    return
  endif
  let s:prev_status_line_mode = a:m

  let l:color =
    \ a:m ==# 'i' ? 'blue' :
    \ a:m ==# 'v' ? 'orange' :
    \ a:m ==# 'r' ? 'purple' :
    \ 'foreground'

  call candle#highlight('StatusLineMode', l:color, '', '')
  call candle#highlight('Cursor', '', l:color, '')

  return ''
endfunction

if exists('*candle#highlight')
  autocmd vimrc VimEnter,Syntax *
    \ call candle#highlight('StatusLineMode', 'foreground', 'window', '')
    \| call candle#highlight('StatusLineDiagnosticError', 'red', 'window', '')
    \| call candle#highlight('StatusLineDiagnosticWarning', 'yellow', 'window', '')
    \| call candle#highlight('StatusLineDiagnosticInfo', 'blue', 'window', '')
    \| call candle#highlight('StatusLineDiagnosticMessage', 'green', 'window', '')

  autocmd vimrc InsertEnter,InsertChange * call <SID>change_status_line_for_mode(v:insertmode)
  autocmd vimrc InsertLeave,CursorHold * call <SID>change_status_line_for_mode(mode())

  nnoremap <expr> v <SID>change_status_line_for_mode('v') . 'v'
  nnoremap <expr> V <SID>change_status_line_for_mode('v') . 'V'
  nnoremap <expr> <C-v> <SID>change_status_line_for_mode('v') . "\<C-v>"
endif


let &cpoptions = s:save_cpo
unlet s:save_cpo
