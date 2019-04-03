let g:searchhi_user_autocmds_enabled = 1
let g:searchhi_redraw_before_on = 1

nmap n <Plug>(searchhi-n)
nmap N <Plug>(searchhi-N)
nmap * <Plug>(searchhi-*)
nmap g* <Plug>(searchhi-g*)
nmap # <Plug>(searchhi-#)
nmap g# <Plug>(searchhi-g#)
nmap <Space><Space> <Plug>(searchhi-clear-all)

if dein#tap('vim-anzu')
  autocmd vimrc User SearchHiOn AnzuUpdateSearchStatusOutput
  autocmd vimrc User SearchHiOff echo g:anzu_no_match_word
endif

if exists('*candle#highlight')
  autocmd vimrc VimEnter,Syntax *
    \ call candle#highlight('CurrentSearch', 'background', 'orange', 'bold')
endif
