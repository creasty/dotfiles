let g:deoplete#enable_at_startup = 1
let g:deoplete#enable_yarp = 1
let g:deoplete#enable_smart_case = 1
let g:deoplete#auto_complete_delay = 0
let g:deoplete#auto_complete_start_length = 1
" let g:deoplete#complete_method = 'omnifunc'

" let g:necosyntax#min_keyword_length = 3
"
" clang
let g:clang_complete_auto = 0
let g:clang_auto_select = 0
let g:clang_use_library = 1

call deoplete#custom#source('buffer', 'min_pattern_length', 3)

" cancel or accept
imap <silent> <expr> <C-c> pumvisible() ? "\<C-r>=deoplete#undo_completion()\<CR>" : "\<Esc>"
imap <silent> <expr> <C-j> pumvisible() ? "\<C-r>=deoplete#close_popup()\<CR>" : "\<CR>"
