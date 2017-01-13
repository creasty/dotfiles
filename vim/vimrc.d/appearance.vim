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
  let &showbreak = '∙∙∙∙'
else
  let &showbreak = '❮'
end

" conceal
if has('conceal')
  set conceallevel=2 concealcursor=
endif

" color column
set colorcolumn=90
hi ColorColumn guibg=#1f1f1f ctermbg=234


"  Folding
"-----------------------------------------------
set foldmethod=indent
set fillchars="fold:"
set foldlevel=20
set foldlevelstart=20
set foldtext=CustomFoldText()

function! CustomFoldText()
  let fs = v:foldstart

  while getline(fs) =~ '^\s*$' | let fs = nextnonblank(fs + 1)
  endwhile

  if fs > v:foldend
    let line = getline(v:foldstart)
  else
    let line = substitute(getline(fs), '\t', repeat(' ', &tabstop), 'g')
  endif

  let w = winwidth(0) - &foldcolumn - (&number ? 8 : 0)

  let lineCounter = ' (' . (1 + v:foldend - v:foldstart) . ')'
  let expansion = repeat(' ', w - strwidth(lineCounter . line))

  return line . expansion . lineCounter
endfunction


"  Custom highlight
"-----------------------------------------------
if dein#tap('candle.vim')
  " highlight full-width space
  call candle#highlight('ZenkakuSpace', '', 'dark_red', '')
  autocmd vimrc BufWinEnter,WinEnter *
    \ call matchadd('ZenkakuSpace', '　')

  " highlight trailing spaces
  call candle#highlight('TrailingSpace', '', 'line', '')
  autocmd vimrc BufWinEnter,WinEnter *
    \ call matchadd('TrailingSpace', '\s\+$')
endif


"  Sign column
"-----------------------------------------------
" make sign column always visible
sign define mydummy

autocmd vimrc BufEnter * call <SID>add_dummy_sign()

function! s:add_dummy_sign()
  let bufnr = bufnr('')

  if !getbufvar(bufnr, 'my_dummy_sign')
    exec 'sign place 9999 line=1 name=mydummy buffer=' . bufnr
    call setbufvar(bufnr, 'my_dummy_sign', 1)
  endif
endfunction


"  Windo title
"-----------------------------------------------
set title titlestring=%{MyTitleText()}

function! MyTitleText()
  let t = []

  if !empty(v:servername)
    let name = substitute(v:servername, 'VIM', '', '')
    if name == ''
      let name = '0'
    endif
    call add(t, '$' . name . ':')
  endif

  let session = fnamemodify(v:this_session, ':t:r')

  if session != ''
    call add(t, '[' . session . ']')
  endif

  let path = expand('%:p')
  let path = (path != '') ? path : getcwd()
  let path = substitute(path, $HOME, '~', '')
  let path = substitute(path, '\~/go/src/github.com', '~g', '')
  call add(t, path)

  return join(t, ' ')
endfunction


"  Tabline
"-----------------------------------------------
function! MyTabLine()
  let s = ''
  let current = tabpagenr()

  for i in range(tabpagenr('$'))
    let tabnr = i + 1 " range() starts at 0
    let winnr = tabpagewinnr(tabnr)
    let buflist = tabpagebuflist(tabnr)
    let bufnr = buflist[winnr - 1]
    let bufname = fnamemodify(bufname(bufnr), ':t')

    let s .= '%' . tabnr . 'T'
    let s .= (tabnr == current ? '%#TabLineNrSel#' : '%#TabLineNr#')
    let s .= ' ' . tabnr
    let s .= '%#TabLineFill#'
    let s .= (tabnr == current ? '%#TabLineSel#' : '%#TabLine#')

    let s .= empty(bufname) ? ' [No Name] ' : ' ' . bufname . ' '
    if getbufvar(bufnr, "&mod")
      let s .= '+ '
    endif
  endfor

  let s .= '%#TabLineFill#'

  return s
endfunction

if dein#tap('candle.vim')
  set tabline=%!MyTabLine()

  autocmd vimrc VimEnter,Syntax *
    \ call candle#highlight('TabLineNr', 'selection', 'window', '')
    \ | call candle#highlight('TabLineNrSel', 'comment', 'foreground', '')
endif


"  Statusline
"-----------------------------------------------
function! RefreshStatusline()
  let cw = winnr()

  if !dein#tap('candle.vim')
    return
  endif

  for nr in range(1, winnr('$'))
    call setwinvar(nr, '&statusline', '%!MyStatusLine(' . nr . ', ' . cw . ')')
  endfor
endfunction

autocmd vimrc VimEnter,WinEnter,BufWinEnter * call RefreshStatusline()

function! MyStatusLine(w, cw)
  let s = ''

  let bufnr = winbufnr(a:w)
  let _bufname = bufname(bufnr)
  let bufmodified = getbufvar(bufnr, '&mod')
  let active = (a:w == a:cw)
  let width = winwidth(a:w)
  let ft = getbufvar(bufnr, '&ft')
  let enough_width = (width > 70)

  let bufname =
    \ empty(_bufname) ? '[No Name]' :
    \ _bufname == '__Tagbar__' ? 'Tagbar' :
    \ _bufname =~ '__Gundo\|NERD_tree' || ft == 'nerdtree' ? 'File' :
    \ ft == 'unite' ? 'Unite' :
    \ ft == 'help' ? 'Help' :
    \ ''

  let is_file = empty(bufname)

  if is_file
    let bufname = fnamemodify(_bufname, ':t')
  endif

  " file name
  let s .= '%#StatusLineLeft' . (active ? 'Active' : '') . '# '

  if is_file
    let s .= '#' . bufnr
    let s .= ' '
  endif

  if active || !is_file
    let s .= bufname
  else
    let head = fnamemodify(_bufname, ':h:t')
    let s .= (empty(head) || head == '.' ? '' : head . '/') . bufname
  endif

  let flag = ''
  let flag .= getbufvar(bufnr, '&readonly') ? '!' : ''
  let flag .= getbufvar(bufnr, '&mod') ? '+' : ''

  if !empty(flag)
    let s .= ' ' . flag
  endif

  let s .= ' %#StatusLine#'

  if active && ft == 'unite'
    let s .= ' ' . unite#get_status_string()
  endif

  " space
  let s .= '%='

  if active && enough_width
    " file type & encoding
    let s .= ' ' . (ft == '' ? 'plain' : ft) . ' ∙ ' . (empty(&fenc) ? 'utf-8' : &fenc) . ' '

    " cursor
    let s .= '%#StatusLineRight' . (active ? 'Active' : '') . '# '
    let s .= '%l:%c ∙ %p%%'
    let s .= ' %#StatusLine#'
  endif

  return s
endfunction

if dein#tap('candle.vim')
  autocmd vimrc VimEnter,Syntax *
    \ call candle#highlight('StatusLineLeft', 'selection', 'window', '')
    \ | call candle#highlight('StatusLineLeftActive', 'background', 'green', '')
    \ | call candle#highlight('StatusLineRight', 'background', 'selection', '')
    \ | call candle#highlight('StatusLineRightActive', 'window', 'foreground', '')

  let s:prev_status_line_mode = 'n'

  function! s:change_status_line_for_mode(m)
    if s:prev_status_line_mode == a:m
      return
    endif
    let s:prev_status_line_mode = a:m

    let color =
      \ a:m == 'i' ? 'blue' :
      \ a:m == 'v' ? 'orange' :
      \ a:m == 'r' ? 'purple' :
      \ 'green'

    call candle#highlight('StatusLineLeftActive', '', color, '')

    return ''
  endfunction

  autocmd vimrc InsertEnter,InsertChange * call <SID>change_status_line_for_mode(v:insertmode)
  autocmd vimrc InsertLeave,CursorHold * call <SID>change_status_line_for_mode(mode())

  nnoremap <expr> v <SID>change_status_line_for_mode('v') . 'v'
  nnoremap <expr> V <SID>change_status_line_for_mode('v') . 'V'
  nnoremap <expr> <C-v> <SID>change_status_line_for_mode('v') . "\<C-v>"
endif
