function! s:denite_on_source() abort
  " cursor
  call denite#custom#map('insert', '<C-a>', '<denite:move_caret_to_head>', 'noremap')
  call denite#custom#map('insert', '<C-e>', '<denite:move_caret_to_tail>', 'noremap')
  call denite#custom#map('insert', '<C-n>', '<denite:move_to_next_line>', 'noremap')
  call denite#custom#map('insert', '<C-p>', '<denite:move_to_previous_line>', 'noremap')
  call denite#custom#map('insert', '<C-h>', '<denite:delete_char_before_caret>', 'noremap')
  call denite#custom#map('insert', '<C-d>', '<denite:delete_char_after_caret>', 'noremap')
  call denite#custom#map('insert', '<C-k>', '<denite:do_action:default>', 'noremap')
  call denite#custom#map('insert', '<C-j>', '<denite:do_action:default>', 'noremap')
  call denite#custom#map('insert', '<C-q>', '<denite:enter_mode:normal>', 'noremap')
  call denite#custom#map('insert', '<C-u>', '<denite:delete_entire_text>', 'noremap')
  call denite#custom#map('insert', '<C-w>', '<denite:delete_word_before_caret>', 'noremap')

  " actions
  call denite#custom#map('insert', '<C-v>', '<denite:paste_from_register>', 'noremap')
  call denite#custom#map('insert', '<C-y>', '<denite:assign_previous_text>', 'noremap')
  call denite#custom#map('insert', '<Tab>', '<denite:choose_action>', 'noremap')
  call denite#custom#map('insert', '<C-l>', '<denite:redraw>', 'noremap')

  " quit
  call denite#custom#map('insert', '<C-q>', '<denite:quit>', 'noremap')
  call denite#custom#map('normal', '<C-q>', '<denite:quit>', 'noremap')

  " use ag
  call denite#custom#var('file_rec', 'command', ['ag', '--follow', '--nocolor', '--nogroup', '-g', ''])
  call denite#custom#var('grep', 'command', ['ag'])
  call denite#custom#var('grep', 'default_opts', ['-i', '--vimgrep'])
  call denite#custom#var('grep', 'recursive_opts', [])
  call denite#custom#var('grep', 'pattern_opt', [])
  call denite#custom#var('grep', 'separator', ['--'])
  call denite#custom#var('grep', 'final_opts', [])

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

function! s:open_best_denite()
  if getcwd() == $HOME
    Denite -no-statusline -default-action=cd ghq
  else
    Denite -no-statusline file_rec
  endif
endfunction

nnoremap <silent> <C-q> :<C-u>call <SID>open_best_denite()<CR>

call dein#set_hook('denite.nvim', 'hook_source', function('s:denite_on_source'))
