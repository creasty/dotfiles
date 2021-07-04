let g:submode_keep_leaving_key = 1

function! vimrc#plugin#submode#init() abort
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
function! s:better_undo(key) abort
  undojoin
  exec 'normal!' a:key
endfunction

noremap <silent> <Plug>(my-x) <Cmd>call <SID>better_undo('"_x')<CR>
call submode#enter_with('better-x', 'n', '',  'x', '"_x')
call submode#map(       'better-x', 'n', 'r', 'x', '<Plug>(my-x)')

noremap <silent> <Plug>(my-ca) <Cmd>call <SID>better_undo('<C-a>')<CR>
call submode#enter_with('better-ca', 'n', '',  '<C-a>', '<C-a>')
call submode#map(       'better-ca', 'n', 'r', '<C-a>', '<Plug>(my-ca)')

noremap <silent> <Plug>(my-cx) <Cmd>call <SID>better_undo('<C-x>')<CR>
call submode#enter_with('better-ca', 'n', '',  '<C-x>', '<C-x>')
call submode#map(       'better-ca', 'n', 'r', '<C-x>', '<Plug>(my-cx)')
