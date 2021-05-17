" [coc-tsserver] npm install -g typescript typescript-language-server typescript-styled-plugin && brew install watchman
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
  \ 'coc-git',
  \ 'coc-json',
  \ 'coc-prettier',
  \ 'coc-python',
  \ 'coc-react-refactor',
  \ 'coc-rls',
  \ 'coc-solargraph',
  \ 'coc-spell-checker',
  \ 'coc-styled-components',
  \ 'coc-syntax',
  \ 'coc-tabnine',
  \ 'coc-tag',
  \ 'coc-tsserver',
  \ 'coc-ultisnips',
  \ 'coc-vimlsp',
\ ]

let g:coc_config_home = '~/.vim'

let g:coc_selectmode_mapping = 0
let g:coc_snippet_next = '<Plug>(coc-snippet-next)'
let g:coc_snippet_prev = '<Plug>(coc-snippet-prev)'

set completeopt+=noinsert " auto select
set completeopt-=preview " disable the preview window feature
set shortmess+=c " silence annoying messages

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
nnoremap <Plug>(coc-hover) :call CocAction('doHover')<CR>
nnoremap <Plug>(coc-peek-definition) :call CocAction('jumpDefinition', v:false)<CR>
nnoremap <Plug>(coc-peek-type-definition) :call CocAction('jumpTypeDefinition', v:false)<CR>

command! -nargs=0 -range=% Format
  \ if <range> == 0 |
  \   call CocAction('format') |
  \ else |
  \   call CocAction('formatSelected', visualmode()) |
  \ endif

command! -nargs=0 OrganizeImport
  \ call CocAction('runCommand', 'editor.action.organizeImport')

"  Key mappings
"-----------------------------------------------
" Introduce function text object
" NOTE: Requires 'textDocument.documentSymbol' support from the language server.
xmap <silent> if <Plug>(coc-funcobj-i)
xmap <silent> af <Plug>(coc-funcobj-a)
omap <silent> if <Plug>(coc-funcobj-i)
omap <silent> af <Plug>(coc-funcobj-a)

" Selection range
" NOTE: Requires 'textDocument/selectionRange' support from the language server.
" coc-tsserver, coc-python are the examples of servers that support it.
nmap <silent> gs <Plug>(coc-range-select)
xmap <silent> gs <Plug>(coc-range-select)

" Refactoring
nmap <silent> gr <Plug>(coc-rename)
nmap <silent> gq <Plug>(coc-codeaction-cursor)
xmap <silent> gq <Plug>(coc-codeaction-selected)

" GoTo code navigation
nmap <silent> gh <Plug>(coc-hover)
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gD <Plug>(coc-peek-definition)
nmap <silent> gt <Plug>(coc-type-definition)
nmap <silent> gT <Plug>(coc-peek-type-definition)
nmap <silent> gR <Plug>(coc-references-used)
nmap <silent> gi <Plug>(coc-implementation)

" Navigate through diagnostics
nnoremap <silent> gll :<C-u>CocListResume<CR>
nnoremap <silent> gld :<C-u>CocList diagnostics<CR>
nnoremap <silent> gls :<C-u>CocList symbols<CR>
nmap <silent> [d <Plug>(coc-diagnostic-prev)
nmap <silent> ]d <Plug>(coc-diagnostic-next)
nmap <silent> [e <Plug>(coc-diagnostic-prev-error)
nmap <silent> ]e <Plug>(coc-diagnostic-next-error)

" Scroll float
if has('nvim-0.4.0') || has('patch-8.2.0750')
  nnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
  nnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
endif

"  coc-git
"-----------------------------------------------
" navigate chunks of current buffer
nmap [g <Plug>(coc-git-prevchunk)
nmap ]g <Plug>(coc-git-nextchunk)

" navigate conflicts of current buffer
nmap [c <Plug>(coc-git-prevconflict)
nmap ]c <Plug>(coc-git-nextconflict)
