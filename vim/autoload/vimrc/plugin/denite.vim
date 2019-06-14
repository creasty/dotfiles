function! vimrc#plugin#denite#open_best() abort
  let l:is_home = (getcwd() == $HOME)
  let l:is_same_dir = (getcwd() == get(g:, 'denite_last_cwd', ''))
  let g:denite_last_cwd = getcwd()

  let l:source = l:is_home ? 'ghq' : 'file/rec'
  let l:resume = l:is_same_dir ? '-resume' : ''

  exec 'Denite'
    \ '-buffer-name=' . l:source
    \ l:resume
    \ l:source
endfunction

function! vimrc#plugin#denite#lazy_init() abort
  " default options
  call denite#custom#option('_', 'statusline', v:false)
  call denite#custom#option('_', 'highlight_matched_range', 'Normal')
  call denite#custom#option('_', 'highlight_matched_char', 'Constant')
  call denite#custom#option('_', 'use_default_mappings', v:false)

  " cursor
  call denite#custom#map('insert', '<C-a>', '<denite:move_caret_to_head>', 'noremap')
  call denite#custom#map('insert', '<C-e>', '<denite:move_caret_to_tail>', 'noremap')
  call denite#custom#map('insert', '<C-f>', '<denite:move_caret_to_right>', 'noremap')
  call denite#custom#map('insert', '<C-b>', '<denite:move_caret_to_left>', 'noremap')
  call denite#custom#map('insert', '<C-h>', '<denite:delete_char_before_caret>', 'noremap')
  call denite#custom#map('insert', '<C-w>', '<denite:delete_word_before_caret>', 'noremap')
  call denite#custom#map('insert', '<C-d>', '<denite:delete_char_after_caret>', 'noremap')
  call denite#custom#map('insert', '<C-k>', '<denite:delete_text_after_caret>', 'noremap')
  call denite#custom#map('insert', '<C-u>', '<denite:delete_entire_text>', 'noremap')

  call denite#custom#map('normal', 'k', '<denite:move_to_previous_line>', 'noremap')
  call denite#custom#map('normal', 'j', '<denite:move_to_next_line>', 'noremap')

  " actions
  call denite#custom#map('_', '<CR>', '<denite:do_action:default>', 'noremap')
  call denite#custom#map('_', '<C-p>', '<denite:move_to_previous_line>', 'noremap')
  call denite#custom#map('_', '<C-n>', '<denite:move_to_next_line>', 'noremap')
  call denite#custom#map('_', '<Tab>', '<denite:choose_action>', 'noremap')
  call denite#custom#map('_', '<C-r>', '<denite:multiple_mappings:denite:restart,denite:move_to_first_line>', 'noremap')
  call denite#custom#map('_', '<C-j>', '<denite:do_action:default>', 'noremap')

  call denite#custom#map('insert', '<C-v>', '<denite:paste_from_default_register>', 'noremap')
  call denite#custom#map('insert', '<C-l>', '<denite:redraw>', 'noremap')
  call denite#custom#map('insert', '<C-z>', '<denite:suspend>', 'noremap')
  call denite#custom#map('normal', '<Space>', '<denite:toggle_select_down>', 'noremap')
  call denite#custom#map('normal', '<C-l>', '<denite:redraw>', 'noremap')

  call denite#custom#map('normal', '<C-b>', '<denite:scroll_page_backwards>', 'noremap')
  call denite#custom#map('normal', '<C-d>', '<denite:scroll_window_downwards>', 'noremap')
  call denite#custom#map('normal', '<C-e>', '<denite:scroll_window_up_one_line>', 'noremap')
  call denite#custom#map('normal', '<C-f>', '<denite:scroll_page_forwards>', 'noremap')
  call denite#custom#map('normal', '<C-u>', '<denite:scroll_window_upwards>', 'noremap')
  call denite#custom#map('normal', 'gg', '<denite:move_to_first_line>', 'noremap')
  call denite#custom#map('normal', 'G', '<denite:move_to_last_line>', 'noremap')
  call denite#custom#map('normal', 'y', '<denite:do_action:yank>', 'noremap')

  " mode / quit
  call denite#custom#map('insert', '<Esc>', '<denite:enter_mode:normal>', 'noremap')
  call denite#custom#map('normal', 'i', '<denite:enter_mode:insert>', 'noremap')
  call denite#custom#map('insert', '<C-q>', '<denite:quit>', 'noremap')
  call denite#custom#map('normal', '<C-q>', '<denite:quit>', 'noremap')
  call denite#custom#map('normal', '<Esc>', '<denite:quit>', 'noremap')

  " use ag
  call denite#custom#var('grep', 'command', ['ag'])
  call denite#custom#var('grep', 'default_opts', ['--nopager', '--vimgrep'])
  call denite#custom#var('grep', 'recursive_opts', [])
  call denite#custom#var('grep', 'pattern_opt', [])
  call denite#custom#var('grep', 'separator', ['--'])
  call denite#custom#var('grep', 'final_opts', [])

  " file_rec
  call denite#custom#var('file_rec', 'command', ['ag', '--follow', '--nocolor', '--nogroup', '--hidden', '-U', '-g', ''])
endfunction
