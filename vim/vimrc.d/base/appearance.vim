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
  let l:fs = v:foldstart

  while getline(l:fs) =~# '^\s*$' | let l:fs = nextnonblank(l:fs + 1)
  endwhile

  if l:fs > v:foldend
    let l:line = getline(v:foldstart)
  else
    let l:line = substitute(getline(l:fs), '\t', repeat(' ', &tabstop), 'g')
  endif

  let l:w = winwidth(0) - &foldcolumn - (&number ? 8 : 0)

  let l:linecounter = ' (' . (1 + v:foldend - v:foldstart) . ')'
  let l:expansion = repeat(' ', l:w - strwidth(l:linecounter . l:line))

  return l:line . l:expansion . l:linecounter
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
  let l:bufnr = bufnr('')

  if !getbufvar(l:bufnr, 'my_dummy_sign')
    exec 'sign place 9999 line=1 name=mydummy buffer=' . l:bufnr
    call setbufvar(l:bufnr, 'my_dummy_sign', 1)
  endif
endfunction


"  Windo title
"-----------------------------------------------
set title titlestring=%{MyTitleText()}

function! MyTitleText()
  let l:t = []

  if !empty(v:servername)
    let l:name = substitute(v:servername, 'VIM', '', '')
    if l:name ==# ''
      let l:name = '0'
    endif
    call add(l:t, '$' . l:name . ':')
  endif

  let l:session = fnamemodify(v:this_session, ':t:r')

  if l:session !=# ''
    call add(l:t, '[' . l:session . ']')
  endif

  let l:path = expand('%:p')
  let l:path = (l:path !=# '') ? l:path : getcwd()
  let l:path = substitute(l:path, $HOME, '~', '')
  let l:path = substitute(l:path, '\~/go/src/github.com', '~g', '')
  call add(l:t, l:path)

  return join(l:t, ' ')
endfunction


"  Tabline
"-----------------------------------------------
function! MyTabLine()
  let l:s = ''
  let l:current = tabpagenr()

  for l:i in range(tabpagenr('$'))
    let l:tabnr = l:i + 1 " range() starts at 0
    let l:winnr = tabpagewinnr(l:tabnr)
    let l:buflist = tabpagebuflist(l:tabnr)
    let l:bufnr = l:buflist[l:winnr - 1]
    let l:bufname = fnamemodify(bufname(l:bufnr), ':t')

    let l:s .= '%' . l:tabnr . 'T'
    let l:s .= (l:tabnr ==# l:current ? '%#TabLineNrSel#' : '%#TabLineNr#')
    let l:s .= ' ' . l:tabnr
    let l:s .= '%#TabLineFill#'
    let l:s .= (l:tabnr ==# l:current ? '%#TabLineSel#' : '%#TabLine#')

    let l:s .= empty(l:bufname) ? ' [No Name] ' : ' ' . l:bufname . ' '
    if getbufvar(l:bufnr, '&mod')
      let l:s .= '+ '
    endif
  endfor

  let l:s .= '%#TabLineFill#'

  return l:s
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
  let l:cw = winnr()

  if !dein#tap('candle.vim')
    return
  endif

  for l:nr in range(1, winnr('$'))
    call setwinvar(l:nr, '&statusline', '%!MyStatusLine(' . l:nr . ', ' . l:cw . ')')
  endfor
endfunction

autocmd vimrc VimEnter,WinEnter,BufWinEnter * call RefreshStatusline()

function! MyStatusLine(w, cw)
  let l:s = ''

  let l:bufnr = winbufnr(a:w)
  let l:_bufname = bufname(l:bufnr)
  let l:bufmodified = getbufvar(l:bufnr, '&mod')
  let l:active = (a:w == a:cw)
  let l:width = winwidth(a:w)
  let l:ft = getbufvar(l:bufnr, '&ft')
  let l:enough_width = (l:width > 70)

  let l:bufname =
    \ empty(l:_bufname) ? '[No Name]' :
    \ l:_bufname ==# '__Tagbar__' ? 'Tagbar' :
    \ l:_bufname =~# '__Gundo\|NERD_tree' || l:ft ==# 'nerdtree' ? 'File' :
    \ l:ft ==# 'unite' ? 'Unite' :
    \ l:ft ==# 'help' ? 'Help' :
    \ ''

  let l:is_file = empty(l:bufname)

  if l:is_file
    let l:bufname = fnamemodify(l:_bufname, ':t')
  endif

  " file name
  let l:s .= '%#StatusLineLeft' . (l:active ? 'Active' : '') . '# '

  if l:is_file
    let l:s .= '#' . l:bufnr
    let l:s .= ' '
  endif

  if l:active || !l:is_file
    let l:s .= l:bufname
  else
    let l:head = fnamemodify(l:_bufname, ':h:t')
    let l:s .= (empty(l:head) || l:head ==# '.' ? '' : l:head . '/') . l:bufname
  endif

  let l:flag = ''
  let l:flag .= getbufvar(l:bufnr, '&readonly') ? '!' : ''
  let l:flag .= getbufvar(l:bufnr, '&mod') ? '+' : ''

  if !empty(l:flag)
    let l:s .= ' ' . l:flag
  endif

  let l:s .= ' %#StatusLine#'

  if l:active && l:ft ==# 'unite'
    let l:s .= ' ' . unite#get_status_string()
  endif

  " space
  let l:s .= '%='

  if l:active && l:enough_width
    " file type & encoding
    let l:s .= ' ' . (l:ft ==# '' ? 'plain' : l:ft) . ' ∙ ' . (empty(&fileencoding) ? 'utf-8' : &fileencoding) . ' '

    " cursor
    let l:s .= '%#StatusLineRight' . (l:active ? 'Active' : '') . '# '
    let l:s .= '%l:%c ∙ %p%%'
    let l:s .= ' %#StatusLine#'
  endif

  return l:s
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

    let l:color =
      \ a:m ==# 'i' ? 'blue' :
      \ a:m ==# 'v' ? 'orange' :
      \ a:m ==# 'r' ? 'purple' :
      \ 'green'

    call candle#highlight('StatusLineLeftActive', '', l:color, '')

    return ''
  endfunction

  autocmd vimrc InsertEnter,InsertChange * call <SID>change_status_line_for_mode(v:insertmode)
  autocmd vimrc InsertLeave,CursorHold * call <SID>change_status_line_for_mode(mode())

  nnoremap <expr> v <SID>change_status_line_for_mode('v') . 'v'
  nnoremap <expr> V <SID>change_status_line_for_mode('v') . 'V'
  nnoremap <expr> <C-v> <SID>change_status_line_for_mode('v') . "\<C-v>"
endif
