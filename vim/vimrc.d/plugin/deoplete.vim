function! s:deoplete_on_source() abort
  let g:deoplete#enable_at_startup = 1
  let g:deoplete#enable_yarp = 1
  let g:deoplete#enable_smart_case = 1

  call deoplete#custom#source('buffer', 'min_pattern_length', 3)
endfunction
call dein#set_hook('deoplete.nvim', 'hook_source', function('s:deoplete_on_source'))

" cancel or accept
imap <silent> <expr> <C-c> pumvisible() ? "\<C-r>=deoplete#undo_completion()\<CR>" : "\<Esc>"
imap <silent> <expr> <C-j> pumvisible() ? "\<C-r>=deoplete#close_popup()\<CR>" : "\<CR>"
