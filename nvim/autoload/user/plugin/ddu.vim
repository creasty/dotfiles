let s:last_cwd = ''
let s:last_win_size = ''

function! s:can_resume() abort
  let l:cwd = getcwd()
  let l:is_same_dir = (l:cwd == s:last_cwd)
  let s:last_cwd = l:cwd

  " Work around misplacement issue
  let l:win_size = &columns . 'x' . &lines
  let l:win_size_changed = s:last_win_size !=# l:win_size
  let s:last_win_size = l:win_size

  return !l:win_size_changed && l:is_same_dir
endfunction

function! user#plugin#ddu#open() abort
  let l:is_startup_dir = (getcwd() == $HOME)
  let l:source = l:is_startup_dir ? 'ghq' : 'fd'

  call ddu#start({
    \ 'name': l:source,
    \ 'sources': [{ 'name': l:source, 'path': getcwd() }],
    \ 'resume': s:can_resume(),
  \ })
endfunction

function! user#plugin#ddu#rg(path, resume) abort
  let l:query = input('search: ')
  call ddu#start({
    \ 'name': 'grep',
    \ 'sources': [{ 'name': 'rg', 'params': { 'path': a:path, 'input': l:query } }],
    \ 'resume': a:resume && s:can_resume(),
  \ })
endfunction

function! user#plugin#ddu#lazy_init() abort
  call ddu#custom#patch_global({
    \ 'ui': 'ff',
    \ 'sourceOptions': {
      \ 'ghq': {
        \ 'matchers': ['matcher_fzy'],
        \ 'defaultAction': 'cd',
      \ },
      \ 'fd': {
        \ 'matchers': ['matcher_fzy'],
      \ },
      \ 'rg': {
        \ 'matchers': ['matcher_substring'],
      \ },
    \ },
    \ 'kindOptions': {
      \ 'file': {
      \   'defaultAction': 'open',
      \ },
    \ },
    \ 'uiParams': {
      \ 'ff': {
        \ 'split': 'floating',
        \ 'startFilter': v:true,
        \ 'filterSplitDirection': 'floating',
        \ 'prompt': '>',
        \ 'highlights': {
          \ 'floating': 'BorderedFloat',
        \ }
      \ },
    \ },
    \ 'filterParams': {
      \ 'matcher_fzy': {
        \ 'hlGroup': 'Constant',
      \ },
    \ },
  \ })
endfunction

function! s:init_ddu() abort
  " b:ddu_ui_name
  nnoremap <buffer> <Esc> <Cmd>call ddu#ui#ff#do_action('quit')<CR>

  nnoremap <buffer> <CR> <Cmd>call ddu#ui#ff#do_action('itemAction')<CR>
  nnoremap <buffer> <C-j> <Cmd>call ddu#ui#ff#do_action('itemAction')<CR>
  nnoremap <buffer> <C-r> <Cmd>call ddu#ui#ff#do_action('refreshItems')<CR>
  nnoremap <buffer> <Tab> <Cmd>call ddu#ui#ff#do_action('chooseAction')<CR>
  nnoremap <buffer> <C-q> <Cmd>call ddu#ui#ff#do_action('quit')<CR>
  nnoremap <buffer> <C-l> <Cmd>call ddu#ui#ff#do_action('refreshItems')<CR>

  inoremap <buffer> <CR> <Cmd>call ddu#ui#ff#do_action('itemAction')<CR>
  inoremap <buffer> <C-j> <Cmd>call ddu#ui#ff#do_action('itemAction')<CR>
  inoremap <buffer> <C-r> <Cmd>call ddu#ui#ff#do_action('refreshItems')<CR>
  inoremap <buffer> <Tab> <Cmd>call ddu#ui#ff#do_action('chooseAction')<CR>
  inoremap <buffer> <C-q> <Cmd>call ddu#ui#ff#do_action('quit')<CR>
  inoremap <buffer> <C-l> <Cmd>call ddu#ui#ff#do_action('refreshItems')<CR>
endfunction

function! user#plugin#ddu#init_ddu_list() abort
  call s:init_ddu()
  nnoremap <buffer> i <Cmd>call ddu#ui#ff#do_action('openFilterWindow')<CR>
  nnoremap <buffer> d <Cmd>call ddu#ui#ff#do_action('itemAction', { 'name': 'delete' })<CR>
  nnoremap <buffer> p <Cmd>call ddu#ui#ff#do_action('preview')<CR>
  nnoremap <buffer> y <Cmd>call ddu#ui#ff#do_action('itemAction', { 'name': 'yank' })<CR>
  nnoremap <buffer> q <Cmd>call ddu#ui#ff#do_action('quit')<CR>
  nnoremap <buffer> - <Cmd>call ddu#ui#ff#do_action('toggleSelectItem')<CR>j
endfunction

function! user#plugin#ddu#init_ddu_filter() abort
  " Remove search highlight
  " setl winhighlight+=,Search:

  " Disable completion
  let b:coc_suggest_disable = 1

  call s:init_ddu()
  inoremap <buffer> <C-p> <Cmd>call ddu#ui#ff#execute("call cursor(line('.')-1,0)")<CR>
  inoremap <buffer> <C-n> <Cmd>call ddu#ui#ff#execute("call cursor(line('.')+1,0)")<CR>
endfunction
