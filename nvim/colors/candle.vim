let g:colors_name = 'candle'

lua require('candle').setup()

function! s:setup_matchadd() abort
  for l:match_id in get(w:, 'candle_match_ids', [])
    call matchdelete(l:match_id)
  endfor

  " cSpell:disable
  let w:candle_match_ids = [
    \ matchadd('FullwidthSpace', '　'),
    \ matchadd("SpellRare", '[０１２３４５６７８９]'),
    \ matchadd("SpellRare", '[ａｂｃｄｅｆｇｈｉｊｋｌｍｎｏｐｑｒｓｔｕｖｗｘｙｚ]'),
    \ matchadd("SpellRare", '[ＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯＰＱＲＳＴＵＶＷＸＹＺ]'),
    \ matchadd('GitConflictMarker', '^\(<<<<<<<.\{-}\|=======\|>>>>>>>.\{-}\)$', 50),
    \ matchadd('ExtraWhitespace', '\s\+$', 50),
    \ matchadd('SnipPlaceholder', '{'.'{+\([^+]\|+[^}]\|+}[^}]\)*+}}', 50),
    \ matchadd('SnipPlaceholder', '{'.'{-\([^-]\|-[^}]\|-}[^}]\)*-}}', 50),
  \ ]
endfunction

function! s:update_mode_highlight() abort
  if g:colors_name !=# 'candle'
    return
  endif

  let l:mode = get(w:, 'mode_observer_current_mode', 'n')
  call v:lua.require('candle').update_mode_highlight(l:mode)
endfunction

augroup candle_theme
  autocmd!
  autocmd BufWinEnter * call s:setup_matchadd()
  autocmd User ModeDidChange call s:update_mode_highlight()
augroup END
