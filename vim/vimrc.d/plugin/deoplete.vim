" auto select
set completeopt+=noinsert

" disable the preview window feature
set completeopt-=preview

" silence "-- XXX completion (YYY)", "match 1 of 2", "The only match", "Pattern not found", "Back at original", etc.
set shortmess+=c

let g:deoplete#enable_at_startup = 1
let g:deoplete#enable_yarp = 1
let g:deoplete#enable_smart_case = 1
let g:deoplete#auto_complete_delay = 0
let g:deoplete#auto_complete_start_length = 1

call deoplete#custom#source('buffer', 'min_pattern_length', 3)

" cancel or accept
imap <silent> <expr> <C-c> pumvisible() ? "\<C-r>=deoplete#undo_completion()\<CR>" : "\<Esc>"
imap <silent> <expr> <C-j> pumvisible() ? "\<C-r>=deoplete#close_popup()\<CR>" : "\<CR>"
