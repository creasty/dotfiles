scriptencoding utf-8

" [coc-tsserver] npm install -g typescript typescript-language-server typescript-styled-plugin
" [coc-eslint] npm install -g eslint
" [coc-css] npm install -g vscode-css-languageserver-bin
" [coc-rls] rustup update && rustup component add rls rust-analysis rust-src
" [coc-solargraph] gem install solargraph
" [coc-python] pip install python-language-server
let g:coc_global_extensions = [
  \ 'coc-calc',
  \ 'coc-css',
  \ 'coc-diagnostic',
  \ 'coc-eslint',
  \ 'coc-json',
  \ 'coc-prettier',
  \ 'coc-python',
  \ 'coc-rls',
  \ 'coc-solargraph',
  \ 'coc-spell-checker',
  \ 'coc-styled-components',
  \ 'coc-syntax',
  \ 'coc-tabnine',
  \ 'coc-tag',
  \ 'coc-tslint-plugin',
  \ 'coc-tsserver',
  \ 'coc-ultisnips',
  \ 'coc-vimlsp',
\ ]

set completeopt+=noinsert " auto select
set completeopt-=preview " disable the preview window feature
set shortmess+=c " silence anoyying messages

function! vimrc#plugin#coc#init() abort
  if g:colors_name ==# 'candle'
    autocmd vimrc BufWinEnter,WinEnter *
      \ call candle#highlight('CocErrorSign', 'red', '', '') |
      \ call candle#highlight('CocWarningSign', 'yellow', '', '') |
      \ call candle#highlight('CocInfoSign', 'blue', '', '') |
      \ call candle#highlight('CocHintSign', 'green', '', '') |
      \ call candle#highlight('CocErrorHighlight', 'red', '', 'undercurl') |
      \ call candle#highlight('CocWarningHighlight', 'yellow', '', 'undercurl') |
      \ call candle#highlight('CocInfoHighlight', 'blue', '', 'undercurl') |
      \ call candle#highlight('CocHintHighlight', 'green', '', 'undercurl')
  endif

  " Highlight the symbol and its references when holding the cursor.
  autocmd vimrc CursorHold * silent call CocActionAsync('highlight')

  " Update signature help on jump placeholder.
  autocmd vimrc User CocJumpPlaceholder silent call CocActionAsync('showSignatureHelp')
endfunction

"  Custom actions
"-----------------------------------------------
nnoremap <silent> <Plug>(coc-hover) :call CocAction('doHover')<CR>
nnoremap <silent> <Plug>(coc-peek-definition) :call CocAction('jumpDefinition', v:false)<CR>
nnoremap <silent> <Plug>(coc-peek-type-definition) :call CocAction('jumpTypeDefinition', v:false)<CR>

command! -nargs=0 -range=% Format
  \ if <range> == 0 |
  \   call CocAction('format') |
  \ else |
  \   call CocAction('formatSelected', visualmode()) |
  \ endif

"  Key mappings
"-----------------------------------------------
" Use <c-space> to trigger completion.
inoremap <silent><expr> <c-space> coc#refresh()

" Introduce function text object
" NOTE: Requires 'textDocument.documentSymbol' support from the language server.
xmap if <Plug>(coc-funcobj-i)
xmap af <Plug>(coc-funcobj-a)
omap if <Plug>(coc-funcobj-i)
omap af <Plug>(coc-funcobj-a)

" Use <TAB> for selections ranges.
" NOTE: Requires 'textDocument/selectionRange' support from the language server.
" coc-tsserver, coc-python are the examples of servers that support it.
" nmap <silent> <Tab> <Plug>(coc-range-select)
" xmap <silent> <Tab> <Plug>(coc-range-select)

" Refactoring
nmap gr <Plug>(coc-rename)
nmap gq <Plug>(coc-codeaction)

" GoTo code navigation.
nmap gd <Plug>(coc-definition)
nmap gD <Plug>(coc-peek-definition)
nmap gh <Plug>(coc-hover)
nmap gt <Plug>(coc-type-definition)
nmap gT <Plug>(coc-peek-type-definition)
nmap gR <Plug>(coc-references)
