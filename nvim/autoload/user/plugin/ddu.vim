let s:last_cwd = ''
function! s:can_resume() abort
  let l:cwd = getcwd()
  let l:is_same_dir = (l:cwd == s:last_cwd)
  let s:last_cwd = l:cwd
  return l:is_same_dir
endfunction

let s:preserved_inputs = {}
function! s:get_preserved_input(name, reset) abort
  if a:reset || get(s:preserved_inputs, a:name, '') ==# ''
    let s:preserved_inputs[a:name] = input('Search: ')
  endif
  return s:preserved_inputs[a:name]
endfunction

function! user#plugin#ddu#update_input() abort
  let l:input = has_key(s:preserved_inputs, b:ddu_ui_name)
    \ ? s:get_preserved_input(b:ddu_ui_name, v:true)
    \ : ''
  call ddu#redraw(b:ddu_ui_name, {
    \ 'refreshItems': v:true,
    \ 'input': l:input,
  \ })
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
  let l:source = 'rg'
  let l:resume = a:resume && s:can_resume()
  let l:input = s:get_preserved_input(l:source, !l:resume)

  call ddu#start({
    \ 'name': l:source,
    \ 'sources': [{
      \ 'name': l:source,
      \ 'params': { 'path': a:path, 'input': l:input },
    \ }],
    \ 'resume': l:resume,
  \ })
endfunction

function! user#plugin#ddu#coc_locations(resume) abort
  let l:source = 'coc-locations'

  call ddu#start({
    \ 'name': l:source,
    \ 'sources': [{ 'name': l:source }],
    \ 'resume': a:resume && s:can_resume(),
  \ })
endfunction

function! user#plugin#ddu#init() abort
  call ddu#custom#patch_global({
    \ 'ui': 'ff',
    \ 'sourceOptions': {
      \ '_': {
        \ 'matchers': ['matcher_fzy'],
      \ },
      \ 'ghq': {
        \ 'defaultAction': 'cd',
      \ },
    \ },
    \ 'uiParams': {
      \ 'ff': {
        \ 'split': 'floating',
        \ 'filterSplitDirection': 'floating',
        \ 'floatingBorder': 'rounded',
        \ 'prompt': '>',
        \ 'highlights': {
          \ 'floating': 'BorderedFloat,Search:',
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

function! user#plugin#ddu#init_buffer() abort
  nnoremap <buffer> <SID>(quit) <Cmd>call ddu#ui#do_action('quit')<CR>
  nnoremap <buffer><script> <Esc> <SID>(quit)
  nnoremap <buffer><script> q <SID>(quit)
  nnoremap <buffer><script> <C-q> <SID>(quit)
  inoremap <buffer><script> <C-q> <Esc><SID>(quit)

  nnoremap <buffer> <SID>(item-action) <Cmd>call ddu#ui#do_action('itemAction')<CR>
  nnoremap <buffer><script> <CR> <SID>(item-action)
  inoremap <buffer><script> <CR> <Esc><SID>(item-action)
  nnoremap <buffer><script> <C-j> <SID>(item-action)
  inoremap <buffer><script> <C-j> <Esc><SID>(item-action)

  nnoremap <buffer> <SID>(choose-action) <Cmd>call ddu#ui#do_action('chooseAction')<CR>
  nnoremap <buffer><script> <Tab> <SID>(choose-action)
  inoremap <buffer><script> <Tab> <Esc><SID>(choose-action)

  nnoremap <buffer> <SID>(reset-cursor) <Cmd>call ddu#ui#ff#execute("call cursor(1,0)")<CR>
  nnoremap <buffer> <SID>(refresh) <Cmd>call ddu#ui#do_action('refreshItems')<CR>
  nnoremap <buffer><script> <C-l> <SID>(reset-cursor)<SID>(refresh)
  inoremap <buffer><script> <C-l> <Esc><SID>(reset-cursor)<SID>(refresh)i

  nnoremap <buffer> <SID>(reload) <Cmd>call user#plugin#ddu#update_input()<CR>
  nnoremap <buffer><script> <C-r> <SID>(reload)
  inoremap <buffer><script> <C-r> <Esc><SID>(reload)i

  if &ft ==# 'ddu-ff'
    setl cursorline
    nnoremap <buffer> i <Cmd>call ddu#ui#do_action('openFilterWindow')<CR>
    nnoremap <buffer> p <Cmd>call ddu#ui#do_action('preview')<CR>
    nnoremap <buffer> o <Cmd>call ddu#ui#do_action('itemAction', { 'name': 'open' })<CR>
    nnoremap <buffer> y <Cmd>call ddu#ui#do_action('itemAction', { 'name': 'yank' })<CR>
    nnoremap <buffer> - <Cmd>call ddu#ui#do_action('toggleSelectItem')<CR>j
  endif
  if &ft ==# 'ddu-ff-filter'
    inoremap <buffer> <C-p> <Cmd>call ddu#ui#ff#execute("call cursor(line('.')-1,0)<Bar>redraw")<CR>
    inoremap <buffer> <C-n> <Cmd>call ddu#ui#ff#execute("call cursor(line('.')+1,0)<Bar>redraw")<CR>
  endif
endfunction
