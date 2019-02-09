let g:minisnip_backrefmarker = '='

" disable default mappings
map <Plug>(minisnip-nop) <Plug>(minisnip)
map <Plug>(minisnip-complete-nop) <Plug>(minisnip-complete)

" remove placeholders before saving
autocmd vimrc BufWritePre *
  \ exec '%s/{{+\([^+]\|+[^}]\|+}[^}]\)*+}}//ge'

" trigger with Tab in select mode
smap <silent> <expr> <Tab> minisnip#ShouldTrigger() ? "\<Esc>:call minisnip#Minisnip()\<CR>" : "<Nop>"
