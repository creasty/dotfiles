function! s:unite_on_source() abort
  let g:unite_force_overwrite_statusline = 0
  let g:unite_enable_start_insert = 1
  let g:unite_winheight = 10
  let g:unite_enable_ignore_case = 1
  let g:unite_enable_smart_case = 1
  let g:unite_source_rec_min_cache_files = 50
  let g:unite_source_rec_max_cache_files = 30000
  let g:unite_source_history_yank_enable = 1

  let l:ignore_globs = unite#sources#rec#define()[0]['ignore_globs'] + [
    \ '.tags',
    \ '*.jpg', '*.jpeg', '*.png', '*.gif', '*.pdf', '*.ttf', '*.otf', '*.eot', '*.woff', '*.svg', '*.svgz',
    \ 'tmp/**', 'cache/**', 'public/system/**', 'vendor/bundle/**',
    \ 'node_modules/**', 'bower_components/**',
    \ 'Godeps/**',
  \ ]

  call unite#custom#source(
    \ join([
      \ 'file',
      \ 'file_rec',
      \ 'file_rec/async',
      \ 'file_rec/git',
      \ 'grep',
    \ ], ','),
    \ 'ignore_globs',
    \ l:ignore_globs
  \ )

  call unite#custom#profile('source/grep', 'context', {
    \ 'no_quit':  1,
    \ 'no_empty': 1,
  \ })

  if g:env.support.ag
    let g:unite_source_grep_command       = 'ag'
    let g:unite_source_grep_default_opts  = '--nogroup --nocolor --column'
    let g:unite_source_grep_recursive_opt = ''
  endif

  autocmd vimrc FileType unite call s:unite_my_settings()

  function! s:unite_my_settings()
    let l:unite = unite#get_current_unite()

    call clearmatches()

    imap <buffer> <C-h> <BS>
    inoremap <buffer> <C-d> <Del>
    inoremap <buffer> <C-b> <Left>
    inoremap <buffer> <C-f> <Right>
    inoremap <buffer> <C-e> <End>

    nmap <buffer> <C-q> <Plug>(unite_exit)
    imap <buffer> <C-q> <Plug>(unite_exit)
    imap <buffer> <C-k> <Plug>(unite_delete_backward_line)
    imap <buffer> <C-a> <Plug>(unite_move_head)
    imap <buffer> <C-j> <Plug>(unite_do_default_action)
    imap <buffer> <C-l> <Plug>(unite_redraw)

    if l:unite.buffer_name =~# '^search'
      nnoremap <silent><buffer><expr> r unite#do_action('replace')
    else
      nnoremap <silent><buffer><expr> r unite#do_action('rename')
    endif
  endfunction

endfunction

function! s:dispatch_unite_file_rec_async_or_git()
  if getcwd() == $HOME
    Unite ghq
  elseif isdirectory(get(b:, 'current_root_directory', '.') . '/.git')
    Unite -hide-source-names -buffer-name=files file_rec/git
  else
    Unite -hide-source-names -buffer-name=files file_rec/async
  endif
endfunction

nnoremap <silent> <C-q> :<C-u>call <SID>dispatch_unite_file_rec_async_or_git()<CR>
nnoremap <silent> <Space><C-q>a :Unite -hide-source-names -buffer-name=files file_rec/async<CR>
nnoremap <silent> <Space>p :Unite -hide-source-names history/yank<CR>
imap <silent> <C-x><C-v> <C-o><Space>p

nnoremap <silent> <Space>g :<C-u>Unite -buffer-name=search-buffer grep:.<CR>

call dein#set_hook('unite.vim', 'hook_source', function('s:unite_on_source'))
