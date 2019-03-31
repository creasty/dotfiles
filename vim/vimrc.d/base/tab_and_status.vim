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
    \| hi TabLineSel term=NONE cterm=NONE gui=NONE
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
  let l:l0 = []
  let l:l1 = []
  let l:r0 = []
  let l:r1 = []

  " Params
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

  " l0
  if l:active
    let l:l0 += [(l:ft ==# '' ? 'plain' : l:ft), '∙', (empty(&fileencoding) ? 'utf-8' : &fileencoding)]
  elseif l:is_file
    let l:head = fnamemodify(l:_bufname, ':h:t')
    let l:l0 += [(empty(l:head) || l:head ==# '.' ? '' : l:head . '/') . l:bufname]
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

  " r0
  if l:active
    let l:r0 += ['%l:%c', '∙', '%p%%']
  endif

  " Build
  let l:s = ['%#StatusLineLeft' . (l:active ? 'Active' : '') . '#']
    \ + l:l0
    \ + ['%#StatusLine#']
    \ + l:l1
    \ + ['%=']
    \ + l:r1
    \ + ['%#StatusLineRight' . (l:active ? 'Active' : '') . '#']
    \ + l:r0
    \ + ['%#StatusLine#']

  return join(l:s, ' ')
endfunction

if exists('*candle#highlight')
  autocmd vimrc VimEnter,Syntax *
    \ call candle#highlight('StatusLineLeft', 'comment', 'window', '')
    \| call candle#highlight('StatusLineLeftActive', 'green', 'window', '')
    \| call candle#highlight('StatusLineRight', 'comment', 'window', '')
    \| call candle#highlight('StatusLineRightActive', 'comment', 'window', '')

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

    call candle#highlight('StatusLineLeftActive', l:color, '', '')

    return ''
  endfunction

  autocmd vimrc InsertEnter,InsertChange * call <SID>change_status_line_for_mode(v:insertmode)
  autocmd vimrc InsertLeave,CursorHold * call <SID>change_status_line_for_mode(mode())

  nnoremap <expr> v <SID>change_status_line_for_mode('v') . 'v'
  nnoremap <expr> V <SID>change_status_line_for_mode('v') . 'V'
  nnoremap <expr> <C-v> <SID>change_status_line_for_mode('v') . "\<C-v>"
endif
