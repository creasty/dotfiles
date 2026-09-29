" Ghostty's screen in copy mode (filetype.vim), to read: no line numbers, signs or color column, and no file to work on
" ('buftype'), which language servers, linters, Git signs, AI suggestions and auto-pairs leave alone. The tabline,
" statusline and command line go as well, so the screen fills the terminal and its lines stay where the pane had them.
" Those three are global options, and this Neovim views nothing else (ghostty-pane/).
setlocal buftype=nofile nonumber signcolumn=no colorcolumn= laststatus=1 showtabline=1 cmdheight=0
