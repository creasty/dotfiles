let g:submode_keep_leaving_key = 1

"  Window resizing
"-----------------------------------------------
call submode#enter_with('winsize', 'n', '', '<C-w>>', '<C-w>>')
call submode#map(       'winsize', 'n', '', '>',      '<C-w>>')
call submode#enter_with('winsize', 'n', '', '<C-w><', '<C-w><')
call submode#map(       'winsize', 'n', '', '<',      '<C-w><')
call submode#enter_with('winsize', 'n', '', '<C-w>+', '<C-w>-')
call submode#map(       'winsize', 'n', '', '-',      '<C-w>+')
call submode#enter_with('winsize', 'n', '', '<C-w>-', '<C-w>+')
call submode#map(       'winsize', 'n', '', '+',      '<C-w>-')


"  Macro
"-----------------------------------------------
call submode#enter_with('macro', 'n', '', '@@', '@@')
call submode#map(       'macro', 'n', '', '@',  '@@')


"  Fold navigation
"-----------------------------------------------
call submode#enter_with('move-to-fold', 'n', '', 'zj', 'zj')
call submode#map(       'move-to-fold', 'n', '', 'j',  'zj')
call submode#enter_with('move-to-fold', 'n', '', 'zk', 'zk')
call submode#map(       'move-to-fold', 'n', '', 'k',  'zk')


"  Better undo
"-----------------------------------------------
function! s:better_undo(key)
  undojoin
  exec 'normal!' a:key
endfunction

noremap <silent> <Plug>(my-x) :<C-u>call <SID>better_undo('"_x')<CR>
call submode#enter_with('my_x', 'n', '',  'x', '"_x')
call submode#map(       'my_x', 'n', 'r', 'x', '<Plug>(my-x)')

noremap <silent> <Plug>(my-ca) :<C-u>call <SID>better_undo('<C-a>')<CR>
call submode#enter_with('my_ca', 'n', '',  '<C-a>', '<C-a>')
call submode#map(       'my_ca', 'n', 'r', '<C-a>', '<Plug>(my-ca)')

noremap <silent> <Plug>(my-cx) :<C-u>call <SID>better_undo('<C-x>')<CR>
call submode#enter_with('my_ca', 'n', '',  '<C-x>', '<C-x>')
call submode#map(       'my_ca', 'n', 'r', '<C-x>', '<Plug>(my-cx)')
