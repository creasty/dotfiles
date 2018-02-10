" disable default mappings
map <Nop> <Plug>(minisnip)
map <Nop> <Plug>(minisnip-complete)

" remove placeholders before saving
autocmd vimrc BufWritePre *
  \ exec '%s/{{+\([^+]\|+[^}]\|+}[^}]\)*+}}//ge'
