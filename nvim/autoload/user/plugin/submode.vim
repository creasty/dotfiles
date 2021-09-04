let g:submode_keep_leaving_key = 1

function! user#plugin#submode#init() abort
endfunction

"  Window resizing
"-----------------------------------------------
call submode#enter_with('winsize', 'n', '', '<C-w>>', '<C-w>>')
call submode#map(       'winsize', 'n', '', '>',      '<C-w>>')
call submode#enter_with('winsize', 'n', '', '<C-w><', '<C-w><')
call submode#map(       'winsize', 'n', '', '<',      '<C-w><')
call submode#enter_with('winsize', 'n', '', '<C-w>+', '<C-w>+')
call submode#map(       'winsize', 'n', '', '+',      '<C-w>+')
call submode#enter_with('winsize', 'n', '', '<C-w>-', '<C-w>-')
call submode#map(       'winsize', 'n', '', '-',      '<C-w>-')

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

"  Word motions
"-----------------------------------------------
call submode#enter_with('n-ge', 'n', '', 'ge', 'ge')
call submode#map(       'n-ge', 'n', '', 'e',  'ge')
call submode#enter_with('n-ge', 'n', '', 'gE', 'gE')
call submode#map(       'n-ge', 'n', '', 'E',  'gE')

"  Better undo
"-----------------------------------------------
call submode#enter_with('better-x',  'n', '',  'x',     '"_x')
call submode#map(       'better-x',  'n', 'r', 'x',     '<Cmd>undojoin<CR>"_x')
call submode#enter_with('better-ca', 'n', '',  '<C-a>', '<C-a>')
call submode#map(       'better-ca', 'n', 'r', '<C-a>', '<Cmd>undojoin<CR><C-a>')
call submode#enter_with('better-cx', 'n', '',  '<C-x>', '<C-x>')
call submode#map(       'better-cx', 'n', 'r', '<C-x>', '<Cmd>undojoin<CR><C-x>')
