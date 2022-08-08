let g:colors_name = 'candle'

lua require('candle').setup()

function! s:setup_matchadd() abort
  for l:match_id in get(w:, 'candle_match_ids', [])
    call matchdelete(l:match_id)
  endfor

  " cSpell:disable
  let w:candle_match_ids = [
    \ matchadd("SpellRare", '[０１２３４５６７８９　]'),
    \ matchadd("SpellRare", '[ａｂｃｄｅｆｇｈｉｊｋｌｍｎｏｐｑｒｓｔｕｖｗｘｙｚ]'),
    \ matchadd("SpellRare", '[ＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯＰＱＲＳＴＵＶＷＸＹＺ]'),
    \ matchadd('GitConflictMarker', '^\(<<<<<<<.\{-}\|=======\|>>>>>>>.\{-}\)$', 50),
    \ matchadd('SnipPlaceholder', '{'.'{+\([^+]\|+[^}]\|+}[^}]\)*+}}', 50),
    \ matchadd('SnipPlaceholder', '{'.'{-\([^-]\|-[^}]\|-}[^}]\)*-}}', 50),
    \ matchadd('Todo', '\v<(TODO|FIXME)>', 50),
  \ ]
endfunction

augroup candle_theme
  autocmd!
  autocmd BufWinEnter * call s:setup_matchadd()
augroup END
