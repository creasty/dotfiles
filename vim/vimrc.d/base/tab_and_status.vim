"=== Tabline
"==============================================================================================
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

if exists('*candle#highlight')
  set tabline=%!MyTabLine()

  autocmd vimrc VimEnter,Syntax *
    \ call candle#highlight('TabLineNr', 'selection', 'window', '')
    \ | call candle#highlight('TabLineNrSel', 'comment', 'foreground', '')
    \ | hi TabLineSel term=NONE cterm=NONE gui=NONE
endif


"=== Statusline
"==============================================================================================
function! RefreshStatusline()
  let l:cw = winnr()

  if !exists('*candle#highlight')
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
    \ l:ft ==# 'denite' ? 'Denite' :
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

  if l:active && l:ft ==# 'denite'
    let l:s .= ' ' . denite#get_status('sources')
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

if exists('*candle#highlight')
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
