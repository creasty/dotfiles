scriptencoding utf-8

let s:filereadable_key = 'filereadable'

function! s:update_filereadable() abort
  let l:path = expand('%:p')
  if !empty(l:path)
    let b:filereadable = filereadable(l:path)
  endif
endfunction

function! s:get_filereadable(bufnr)
  return getbufvar(a:bufnr, s:filereadable_key, v:false)
endfunction

function! user#ui#fold_text() abort
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

function! user#ui#title_text() abort
  let l:path = expand('%:p')
  let l:path = (l:path !=# '') ? l:path : getcwd()
  let l:path = substitute(l:path, $HOME, '~', '')
  let l:path = substitute(l:path, '\~/go/src/github.com', '~g', '')
  return l:path
endfunction

function! user#ui#tab_line() abort
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

function! s:render_statusline(w, active) abort
  let l:l0 = []
  let l:l1 = []
  let l:r0 = []
  let l:r1 = []

  " Params
  let l:bufnr = winbufnr(a:w)
  let l:bufname = bufname(l:bufnr)
  let l:ft = getbufvar(l:bufnr, '&ft')
  let l:enough_width = (winwidth(a:w) > 120)
  let l:is_file = !empty(l:bufname)

  " l0
  if a:active
    let l:l0 += [(l:ft ==# '' ? 'plain' : l:ft)]
    if l:is_file || l:ft ==# ''
      let l:l0 += ['∙', empty(&fileencoding) ? 'utf-8' : &fileencoding, &fileformat]
    endif
  else
    let l:l0 += [l:is_file ? fnamemodify(l:bufname, ':p:~:.') : '[No Name]']
  endif

  let l:flag = ''
  let l:flag .= getbufvar(l:bufnr, '&readonly') ? '!' : ''
  let l:flag .= getbufvar(l:bufnr, '&mod') ? '+' : ''
  let l:flag .= l:is_file && !s:get_filereadable(l:bufnr) ? '?' : ''
  if !empty(l:flag)
    let l:l0 += [l:flag]
  endif

  " l1
  if l:is_file
    let l:last_saved_time = getbufvar(l:bufnr, 'auto_save_last_saved_time', 0)
    if 0 < l:last_saved_time && l:last_saved_time >= localtime() - 60
      let l:l1 += [strftime('✓ %T', l:last_saved_time)]
    endif
  endif

  if a:active
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
      let l:l1 += ['%#StatusLineDiagnosticsError#' . '✗', l:diagnostics['E'] . '%*']
    end
    if l:diagnostics['W'] > 0
      let l:l1 += ['%#StatusLineDiagnosticsWarning#' . '∆', l:diagnostics['W'] . '%*']
    end
    if l:diagnostics['I'] > 0
      let l:l1 += ['%#StatusLineDiagnosticsInfo#' . '▸', l:diagnostics['I'] . '%*']
    end
    if l:diagnostics['H'] > 0
      let l:l1 += ['%#StatusLineDiagnosticsHint#' . '▪︎', l:diagnostics['H'] . '%*']
    end
  endif

  " r1
  let l:coc_status = get(g:, 'coc_status', '')
  if a:active && l:coc_status !=# ''
    let l:r1 += [l:coc_status[0:60]]
  endif

  " r0
  if a:active
    let l:r0 += ['%l:%c', '∙', '%p%%']
  endif

  " Build
  let l:s = [a:active ? '%#StatusLineMode#' : '%#StatusLine#']
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

function! user#ui#statusline(winnr, active) abort
  if a:active
    call mode_observer#update_mode(a:winnr)
  endif
  return s:render_statusline(a:winnr, a:active)
endfunction

function! s:update_statusline() abort
  let l:cw = winnr()
  for l:nr in range(1, winnr('$'))
    let l:active = l:cw == l:nr
    call setwinvar(l:nr, '&statusline', '%!user#ui#statusline(' . l:nr . ',' . l:active . ')')
  endfor
endfunction

function! user#ui#setup_statusline() abort
  augroup user_ui_statusline
    autocmd!
    autocmd FocusGained,BufEnter,BufReadPost,BufWritePost *
      \ call s:update_filereadable()
    autocmd WinEnter,BufWinEnter *
      \ call s:update_statusline()
  augroup END
endfunction
