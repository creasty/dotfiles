function! vimrc#plugin#denite#open_best() abort
  let l:cwd = getcwd()
  let l:is_startup_dir = (l:cwd == $HOME || l:cwd == '/')
  let l:is_same_dir = (l:cwd == get(g:, 'denite_last_cwd', ''))
  let g:denite_last_cwd = l:cwd

  let l:source = l:is_startup_dir ? 'ghq' : 'file/rec'
  let l:resume = l:is_same_dir ? '-resume' : ''

  exec 'Denite'
    \ '-start-filter'
    \ '-buffer-name=' . l:source
    \ l:resume
    \ l:source
endfunction

function! vimrc#plugin#denite#lazy_init() abort
  " default options
  call denite#custom#option('_', 'statusline', v:false)
  call denite#custom#option('_', 'highlight_matched_range', 'Normal')
  call denite#custom#option('_', 'highlight_matched_char', 'Constant')
  call denite#custom#option('_', 'match_highlight', v:true)

  if has('nvim') && exists('*nvim_open_win')
    call denite#custom#option('_', 'split', 'floating')
    call denite#custom#option('_', 'filter_split_direction', 'floating')
    call denite#custom#option('_', 'highlight_filter_background', 'StatusLine')
    call denite#custom#option('_', 'highlight_window_background', 'NormalFloat')
  endif

  " use ag
  call denite#custom#var('grep', {
    \ 'command': ['ag'],
    \ 'default_opts': ['--nopager', '--vimgrep'],
    \ 'recursive_opts': [],
    \ 'pattern_opt': [],
    \ 'separator': ['--'],
    \ 'final_opts': [],
  \ })
  call denite#custom#source('grep', {
    \ 'matchers': [],
    \ 'sorters': [],
  \ })

  " file_rec
  call denite#custom#var('file/rec', 'command', [
    \ 'ag', '--follow', '--nocolor', '--nogroup', '--hidden', '-U', '-g', '',
  \ ])
endfunction

function! vimrc#plugin#denite#control_parent(f) abort
  call denite#move_to_parent()
  call a:f()
  call denite#move_to_filter()
  return ''
endfunction

function! s:init_denite() abort
  nnoremap <silent><buffer><expr> <Esc> denite#do_map('quit')

  nnoremap <silent><buffer><expr> <CR> denite#do_map('do_action')
  nnoremap <silent><buffer><expr> <C-j> denite#do_map('do_action')
  nnoremap <silent><buffer><expr> <C-r> denite#do_map('restart')
  nnoremap <silent><buffer><expr> <C-p> 'k'
  nnoremap <silent><buffer><expr> <C-n> 'j'
  nnoremap <silent><buffer><expr> <Tab> denite#do_map('choose_action')
  nnoremap <silent><buffer><expr> <C-q> denite#do_map('quit')
  nnoremap <silent><buffer><expr> <C-l> denite#do_map('redraw')

  inoremap <silent><buffer><expr> <CR> denite#do_map('do_action')
  inoremap <silent><buffer><expr> <C-j> denite#do_map('do_action')
  inoremap <silent><buffer><expr> <C-r> denite#do_map('restart')
  inoremap <silent><buffer><expr> <Tab> denite#do_map('choose_action')
  inoremap <silent><buffer><expr> <C-q> denite#do_map('quit')
  inoremap <silent><buffer><expr> <C-l> denite#do_map('redraw')
endfunction

function! s:init_denite_list() abort
  call s:init_denite()
  nnoremap <silent><buffer><expr> i denite#do_map('open_filter_buffer')
  nnoremap <silent><buffer><expr> d denite#do_map('do_action', 'delete')
  nnoremap <silent><buffer><expr> p denite#do_map('do_action', 'preview')
  nnoremap <silent><buffer><expr> y denite#do_map('do_action', 'yank')
  nnoremap <silent><buffer><expr> q denite#do_map('quit')
  nnoremap <silent><buffer><expr> <Space> denite#do_map('toggle_select') . 'j'
endfunction

function! s:init_denite_filter() abort
  let b:coc_suggest_disable = 1

  call s:init_denite()
  imap <silent><buffer> <Esc> <Plug>(denite_filter_quit)
  inoremap <silent><buffer><expr> <C-p> vimrc#plugin#denite#control_parent({-> cursor(line('.') - 1, 0) })
  inoremap <silent><buffer><expr> <C-n> vimrc#plugin#denite#control_parent({-> cursor(line('.') + 1, 0) })
endfunction

autocmd vimrc FileType denite call s:init_denite_list()
autocmd vimrc FileType denite-filter call s:init_denite_filter()
