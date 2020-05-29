scriptencoding utf-8

function! vimrc#ui#fold_text() abort
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

function! vimrc#ui#title_text() abort
  let l:path = expand('%:p')
  let l:path = (l:path !=# '') ? l:path : getcwd()
  let l:path = substitute(l:path, $HOME, '~', '')
  let l:path = substitute(l:path, '\~/go/src/github.com', '~g', '')
  return l:path
endfunction

function! vimrc#ui#tab_line() abort
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

function! vimrc#ui#status_line(w, cw) abort
  let l:l0 = []
  let l:l1 = []
  let l:r0 = []
  let l:r1 = []

  " Params
  let l:bufnr = winbufnr(a:w)
  let l:_bufname = bufname(l:bufnr)
  let l:active = (a:w == a:cw)
  let l:ft = getbufvar(l:bufnr, '&ft')
  " let l:enough_width = (winwidth(a:w) > 70)

  let l:bufname =
    \ empty(l:_bufname) ? '[No Name]' :
    \ l:ft ==# 'denite' ? '>>>>' :
    \ l:ft ==# 'denite-filter' ? 'Denite' :
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
  let l:flag .= l:is_file && !getbufvar(l:bufnr, 'filereadable', v:true) ? '?' : ''
  if !empty(l:flag)
    let l:l0 += [l:flag]
  endif

  " l1
  if l:active && l:ft ==# 'denite'
    let l:l1 += [denite#get_status('sources')]
  endif

  " r1
  if l:active
    let l:diagnostics = {
      \ 'E': 0,
      \ 'W': 0,
      \ 'I': 0,
      \ 'H': 0,
    \ }

    let l:status = getbufvar(l:bufnr, 'coc_diagnostic_info', {})
    if !empty(l:status)
      let l:diagnostics['E'] += get(l:status, 'error', 0)
      let l:diagnostics['W'] += get(l:status, 'warning', 0)
      let l:diagnostics['I'] += get(l:status, 'information', 0)
      let l:diagnostics['H'] += get(l:status, 'hint', 0)
    end

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
