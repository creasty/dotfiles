let s:last_cwd = ''

function! s:can_resume() abort
  let l:cwd = getcwd()
  let l:is_same_dir = (l:cwd == s:last_cwd)
  let s:last_cwd = l:cwd
  return l:is_same_dir
endfunction

function! user#plugin#ddu#open() abort
  let l:is_startup_dir = (getcwd() == $HOME)
  let l:source = l:is_startup_dir ? 'ghq' : 'fd'

  call ddu#start({
    \ 'name': l:source,
    \ 'sources': [{ 'name': l:source }],
    \ 'uiParams': { 'ff': { 'startFilter': v:true } },
    \ 'resume': s:can_resume(),
  \ })
endfunction

function! user#plugin#ddu#search(path, resume) abort
  call ddu#start({
    \ 'name': 'grep',
    \ 'sources': [{ 'name': 'rg', 'params': { 'path': a:path } }],
    \ 'resume': a:resume && s:can_resume(),
  \ })
endfunction

function! user#plugin#ddu#init() abort
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
        \ 'matchers': ['matcher_fzy'],
      \ },
    \ },
    \ 'sourceParams': {
      \ 'rg': {
        \ 'highlights': {
          \ 'path': 'Identifier',
          \ 'lineNr': 'Comment',
          \ 'word': 'Constant',
        \ },
      \ },
    \ },
    \ 'uiParams': {
      \ 'ff': {
        \ 'split': 'floating',
        \ 'filterSplitDirection': 'floating',
        \ 'floatingBorder': 'rounded',
        \ 'prompt': '>',
        \ 'highlights': {
          \ 'floating': 'Normal:BorderedFloat,Search:',
        \ }
      \ },
    \ },
    \ 'kindOptions': {
      \ 'file': {
      \   'defaultAction': 'open',
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
  nnoremap <buffer> q <Cmd>call ddu#ui#ff#do_action('quit')<CR>
  nnoremap <buffer> <C-q> <Cmd>call ddu#ui#ff#do_action('quit')<CR>
  inoremap <buffer> <C-q> <Cmd>call ddu#ui#ff#do_action('quit')<CR>

  nnoremap <buffer> <CR> <Cmd>call ddu#ui#ff#do_action('itemAction')<CR>
  inoremap <buffer> <CR> <Cmd>call ddu#ui#ff#do_action('itemAction')<CR>
  nnoremap <buffer> <C-j> <Cmd>call ddu#ui#ff#do_action('itemAction')<CR>
  inoremap <buffer> <C-j> <Cmd>call ddu#ui#ff#do_action('itemAction')<CR>

  nnoremap <buffer> <Tab> <Cmd>call ddu#ui#ff#do_action('chooseAction')<CR>
  inoremap <buffer> <Tab> <Cmd>call ddu#ui#ff#do_action('chooseAction')<CR>

  " TODO: <C-r> to preseve the input
  nnoremap <buffer> <C-r> <Cmd>call ddu#ui#ff#do_action('refreshItems', { 'refreshItems': v:true })<CR>
  inoremap <buffer> <C-r> <Cmd>call ddu#ui#ff#do_action('refreshItems', { 'refreshItems': v:true })<CR>

  nnoremap <buffer> <C-l> <Cmd>call ddu#ui#ff#do_action('refreshItems', { 'refreshItems': v:true })<CR>
  inoremap <buffer> <C-l> <Cmd>call ddu#ui#ff#do_action('refreshItems', { 'refreshItems': v:true })<CR>
endfunction

function! user#plugin#ddu#init_ddu_list() abort
  call s:init_ddu()
  nnoremap <buffer> i <Cmd>call ddu#ui#ff#do_action('openFilterWindow')<CR>
  nnoremap <buffer> p <Cmd>call ddu#ui#ff#do_action('preview')<CR>
  nnoremap <buffer> y <Cmd>call ddu#ui#ff#do_action('itemAction', { 'name': 'yank' })<CR>
  nnoremap <buffer> - <Cmd>call ddu#ui#ff#do_action('toggleSelectItem')<CR>j
endfunction

function! user#plugin#ddu#init_ddu_filter() abort
  " Disable completion
  let b:coc_suggest_disable = 1

  call s:init_ddu()
  inoremap <buffer> <C-p> <Cmd>call ddu#ui#ff#execute("call cursor(line('.')-1,0)")<CR>
  inoremap <buffer> <C-n> <Cmd>call ddu#ui#ff#execute("call cursor(line('.')+1,0)")<CR>
endfunction
