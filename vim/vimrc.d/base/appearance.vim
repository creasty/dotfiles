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
set title titlestring=%{MyTitleText()}

function! MyTitleText() abort
  let l:path = expand('%:p')
  let l:path = (l:path !=# '') ? l:path : getcwd()
  let l:path = substitute(l:path, $HOME, '~', '')
  let l:path = substitute(l:path, '\~/go/src/github.com', '~g', '')
  return l:path
endfunction


"  TabLine
"-----------------------------------------------
function! MyTabLine() abort
  let l:s = ''
  let l:current = tabpagenr()

  for l:i in range(tabpagenr('$'))
    let l:tabnr = l:i + 1 " range() starts at 0
    let l:winnr = tabpagewinnr(l:tabnr)
    let l:buflist = tabpagebuflist(l:tabnr)
    let l:bufnr = l:buflist[l:winnr - 1]
    let l:bufname = fnamemodify(bufname(l:bufnr), ':t')

    let l:s .= '%' . l:tabnr . 'T'
    let l:s .= (l:tabnr ==# l:current ? '%#TabLineSel#' : '%#TabLine#')

    let l:s .= empty(l:bufname) ? ' [No Name] ' : ' ' . l:bufname . ' '
    if getbufvar(l:bufnr, '&mod')
      let l:s .= '+ '
    endif
  endfor

  let l:s .= '%#TabLineFill#'

  return l:s
endfunction

set tabline=%!MyTabLine()


"  StatusLine
"-----------------------------------------------
function! s:refresh_statusline() abort
  let l:cw = winnr()

  for l:nr in range(1, winnr('$'))
    call setwinvar(l:nr, '&statusline', '%!MyStatusLine(' . l:nr . ', ' . l:cw . ')')
  endfor
endfunction

if exists('*candle#highlight')
  autocmd vimrc VimEnter,WinEnter,BufWinEnter * call <SID>refresh_statusline()
endif

function! MyStatusLine(w, cw) abort
  let l:l0 = []
  let l:l1 = []
  let l:r0 = []
  let l:r1 = []

  " Params
  let l:bufnr = winbufnr(a:w)
  let l:_bufname = bufname(l:bufnr)
  let l:active = (a:w == a:cw)
  let l:ft = getbufvar(l:bufnr, '&ft')
  let l:enough_width = (winwidth(a:w) > 70)

  let l:bufname =
    \ empty(l:_bufname) ? '[No Name]' :
    \ l:_bufname ==# '__Tagbar__' ? 'Tagbar' :
    \ l:_bufname =~# '__Gundo\|NERD_tree' || l:ft ==# 'nerdtree' ? 'File' :
    \ l:ft ==# 'denite' ? 'Denite' :
    \ l:ft ==# 'help' ? 'Help' :
    \ ''

  let l:is_file = empty(l:bufname)
  if l:is_file
    let l:bufname = fnamemodify(l:_bufname, ':t')
  endif

  " l0
  if l:active
    let l:l0 += [(l:ft ==# '' ? 'plain' : l:ft)]
    if l:is_file || l:ft ==# ''
      let l:l0 += ['∙', empty(&fileencoding) ? 'utf-8' : &fileencoding, &fileformat]
    endif
  elseif l:is_file
    let l:l0 += [fnamemodify(l:_bufname, ':p:~:.')]
  else
    let l:l0 += [l:bufname]
  endif

  let l:flag = ''
  let l:flag .= getbufvar(l:bufnr, '&readonly') ? '!' : ''
  let l:flag .= getbufvar(l:bufnr, '&mod') ? '+' : ''
  if !empty(l:flag)
    let l:l0 += [l:flag]
  endif

  " l1
  if l:active && l:ft ==# 'denite'
    let l:l1 += [denite#get_status('sources')]
  endif

  " r1
  let l:diagnostics = {
    \ 'E': 0,
    \ 'W': 0,
    \ 'I': 0,
    \ 'H': 0,
  \ }

  if l:active
    let l:status = getbufvar(l:bufnr, 'vim_lsp_diagnostics', {})
    let l:diagnostics['E'] += get(l:status, 'E', 0)
    let l:diagnostics['W'] += get(l:status, 'W', 0)
    let l:diagnostics['I'] += get(l:status, 'I', 0)
    let l:diagnostics['H'] += get(l:status, 'H', 0)
  endif

  if l:active && exists('*neomake#statusline#LoclistCounts')
    let l:status = neomake#statusline#LoclistCounts()
    let l:diagnostics['E'] += get(l:status, 'E', 0)
    let l:diagnostics['W'] += get(l:status, 'W', 0)
    let l:diagnostics['I'] += get(l:status, 'I', 0)
    let l:diagnostics['H'] += get(l:status, 'M', 0)
  endif

  if l:active
    if l:diagnostics['E'] > 0
      let l:r1 += ['%#StatusLineDiagnosticError#' . '✗', l:diagnostics['E'] . '%*']
    end
    if l:diagnostics['W'] > 0
      let l:r1 += ['%#StatusLineDiagnosticWarning#' . '∆', l:diagnostics['W'] . '%*']
    end
    if l:diagnostics['I'] > 0
      let l:r1 += ['%#StatusLineDiagnosticInfo#' . '▸', l:diagnostics['I'] . '%*']
    end
    if l:diagnostics['H'] > 0
      let l:r1 += ['%#StatusLineDiagnosticMessage#' . '▪︎', l:diagnostics['H'] . '%*']
    end
  endif

  " r0
  if l:active
    let l:r0 += ['%l:%c', '∙', '%p%%']
  endif

  " Build
  let l:s = [l:active ? '%#StatusLineMode#' : '%#StatusLine#']
    \ + l:l0
    \ + ['%*']
    \ + l:l1
    \ + ['%=']
    \ + l:r1
    \ + ['%*']
    \ + l:r0
    \ + ['%*']

  return join(l:s, ' ')
endfunction

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
