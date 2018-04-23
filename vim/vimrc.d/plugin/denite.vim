function! s:denite_on_source() abort
  " default options
  call denite#custom#option('_', 'statusline', v:false)
  call denite#custom#option('_', 'highlight_matched_range', 'Normal')
  call denite#custom#option('_', 'highlight_matched_char', 'Constant')
  call denite#custom#option('_', 'use_default_mappings', v:false)

  " cursor
  call denite#custom#map('insert', '<C-a>', '<denite:move_caret_to_head>', 'noremap')
  call denite#custom#map('insert', '<C-e>', '<denite:move_caret_to_tail>', 'noremap')
  call denite#custom#map('insert', '<C-p>', '<denite:move_to_previous_line>', 'noremap')
  call denite#custom#map('insert', '<C-n>', '<denite:move_to_next_line>', 'noremap')
  call denite#custom#map('insert', '<C-h>', '<denite:delete_char_before_caret>', 'noremap')
  call denite#custom#map('insert', '<C-d>', '<denite:delete_char_after_caret>', 'noremap')
  call denite#custom#map('insert', '<C-k>', '<denite:do_action:default>', 'noremap')
  call denite#custom#map('insert', '<C-j>', '<denite:do_action:default>', 'noremap')
  call denite#custom#map('insert', '<C-q>', '<denite:enter_mode:normal>', 'noremap')
  call denite#custom#map('insert', '<C-u>', '<denite:delete_entire_text>', 'noremap')
  call denite#custom#map('insert', '<C-w>', '<denite:delete_word_before_caret>', 'noremap')
  call denite#custom#map('normal', 'k', '<denite:move_to_previous_line>', 'noremap')
  call denite#custom#map('normal', 'j', '<denite:move_to_next_line>', 'noremap')
  call denite#custom#map('normal', '<C-p>', '<denite:move_to_previous_line>', 'noremap')
  call denite#custom#map('normal', '<C-n>', '<denite:move_to_next_line>', 'noremap')

  " actions
  call denite#custom#map('_', '<Tab>', '<denite:choose_action>', 'noremap')
  call denite#custom#map('_', '<CR>', '<denite:do_action:default>', 'noremap')
  call denite#custom#map('_', '<C-r>', '<denite:restart>', 'noremap')
  call denite#custom#map('insert', '<C-v>', '<denite:paste_from_register>', 'noremap')
  call denite#custom#map('insert', '<C-l>', '<denite:redraw>', 'noremap')
  call denite#custom#map('insert', '<Esc>', '<denite:enter_mode:normal>', 'noremap')
  call denite#custom#map('insert', '<C-z>', '<denite:suspend>', 'noremap')
  call denite#custom#map('normal', 'i', '<denite:enter_mode:insert>', 'noremap')
  call denite#custom#map('normal', '<C-b>', '<denite:scroll_page_backwards>', 'noremap')
  call denite#custom#map('normal', '<C-d>', '<denite:scroll_window_downwards>', 'noremap')
  call denite#custom#map('normal', '<C-e>', '<denite:scroll_window_up_one_line>', 'noremap')
  call denite#custom#map('normal', '<C-f>', '<denite:scroll_page_forwards>', 'noremap')
  call denite#custom#map('normal', '<C-l>', '<denite:redraw>', 'noremap')
  call denite#custom#map('normal', '<C-u>', '<denite:scroll_window_upwards>', 'noremap')
  call denite#custom#map('normal', '<Space>', '<denite:toggle_select_down>', 'noremap')
  call denite#custom#map('normal', 'gg', '<denite:move_to_first_line>', 'noremap')
  call denite#custom#map('normal', 'G', '<denite:move_to_last_line>', 'noremap')

  " quit
  call denite#custom#map('insert', '<C-q>', '<denite:quit>', 'noremap')
  call denite#custom#map('normal', '<C-q>', '<denite:quit>', 'noremap')
  call denite#custom#map('normal', '<Esc>', '<denite:quit>', 'noremap')

  " use ag
  call denite#custom#var('grep', 'command', ['ag'])
  call denite#custom#var('grep', 'default_opts', ['-i', '--vimgrep'])
  call denite#custom#var('grep', 'recursive_opts', [])
  call denite#custom#var('grep', 'pattern_opt', [])
  call denite#custom#var('grep', 'separator', ['--'])
  call denite#custom#var('grep', 'final_opts', [])

  " file_rec
  call denite#custom#var('file_rec', 'command', ['ag', '--follow', '--nocolor', '--nogroup', '-g', ''])

  " change ignore_globs
  let l:ignore_globs = [
    \ '*~', '*.o', '*.exe', '*.bak',
    \ '.DS_Store', '*.pyc', '*.sw[po]', '*.class',
    \ '.hg/', '.git/', '.bzr/', '.svn/',
    \ 'tags', 'tags-*', '.tags',
    \ '*.jpg', '*.jpeg', '*.png', '*.gif', '*.pdf', '*.ttf', '*.otf', '*.eot', '*.woff', '*.svg', '*.svgz',
    \ 'tmp/**', 'cache/**', 'public/system/**', 'vendor/bundle/**',
    \ 'node_modules/**', 'bower_components/**',
    \ 'Godeps/**',
  \ ]
  call denite#custom#filter('matcher_ignore_globs', 'ignore_globs', l:ignore_globs)
endfunction
call dein#set_hook('denite.nvim', 'hook_source', function('s:denite_on_source'))

function! s:open_best_denite()
  let l:is_home = (getcwd() == $HOME)
  let l:is_same_dir = (getcwd() == get(w:, 'denite_last_cwd', ''))
  let w:denite_last_cwd = getcwd()

  let l:source = l:is_home ? 'ghq' : 'file_rec'
  let l:resume = l:is_same_dir ? '-resume' : ''

  exec 'Denite'
    \ '-buffer-name=' . l:source
    \ l:resume
    \ l:source
endfunction

nnoremap <silent> <C-q> :<C-u>call <SID>open_best_denite()<CR>

command! Ag :Denite -mode=normal -buffer-name=grep -resume grep
nnoremap <Space>/ :Ag<CR>
