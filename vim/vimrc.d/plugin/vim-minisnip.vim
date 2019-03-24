let g:minisnip_backrefmarker = '='

" disable default mappings
map <Plug>(minisnip-nop) <Plug>(minisnip)
map <Plug>(minisnip-complete-nop) <Plug>(minisnip-complete)

" remove placeholders before saving
autocmd vimrc BufWritePre *
  \ if &ft !=# 'minisnip' |
    \ exec '%s/{{+\([^+]\|+[^}]\|+}[^}]\)*+}}//ge' |
    \ exec '%s/{{-\([^-]\|-[^}]\|-}[^}]\)*-}}//ge' |
  \ endif

if exists('*candle#highlight')
  call candle#highlight('MinisnipPlaceholder', 'blue', 'dark_blue', '')
  autocmd vimrc BufWinEnter,WinEnter *
    \ call matchadd('MinisnipPlaceholder', '{{+\([^+]\|+[^}]\|+}[^}]\)*+}}', 50)
    \| call matchadd('MinisnipPlaceholder', '{{-\([^-]\|-[^}]\|-}[^}]\)*-}}', 50)
endif

" trigger with Tab in select mode
smap <silent> <expr> <Tab> minisnip#ShouldTrigger() ? "\<Esc>:call minisnip#Minisnip()\<CR>" : "<Nop>"
