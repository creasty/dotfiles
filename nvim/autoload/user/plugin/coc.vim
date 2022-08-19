" [coc-clangd] brew install llvm
" [coc-css] npm install -g vscode-css-languageserver-bin
" [coc-eslint] npm install -g eslint
" [coc-pyright] npm install -g pyright
" [coc-rls] rustup update && rustup component add rls rust-analysis rust-src
" [coc-solargraph] gem install solargraph
" [coc-tsserver] npm install -g typescript typescript-language-server typescript-styled-plugin && brew install watchman
let g:coc_global_extensions = [
  \ 'coc-calc',
  \ 'coc-clangd',
  \ 'coc-css',
  \ 'coc-deno',
  \ 'coc-diagnostic',
  \ 'coc-eslint',
  \ 'coc-flutter',
  \ 'coc-git',
  \ 'coc-go',
  \ 'coc-json',
  \ 'coc-lua',
  \ 'coc-metals',
  \ 'coc-prettier',
  \ 'coc-pyright',
  \ 'coc-react-refactor',
  \ 'coc-rls',
  \ 'coc-snippets',
  \ 'coc-solargraph',
  \ 'coc-spell-checker',
  \ 'coc-sqlfluff',
  \ 'coc-styled-components',
  \ 'coc-syntax',
  \ 'coc-tabnine',
  \ 'coc-tag',
  \ 'coc-tsserver',
  \ 'coc-vimlsp',
\ ]

let g:coc_selectmode_mapping = 0
let g:coc_snippet_next = '<Tab>'
let g:coc_snippet_prev = '<S-Tab>'

function! user#plugin#coc#init() abort
  hi link CocMenuSel PMenuSel
  hi link CocErrorSign DiagnosticError
  hi link CocWarningSign DiagnosticWarn
  hi link CocInfoSign DiagnosticInfo
  hi link CocHintSign DiagnosticHint
  hi link CocErrorHighlight DiagnosticUnderlineError
  hi link CocWarningHighlight DiagnosticUnderlineWarn
  hi link CocInfoHighlight DiagnosticUnderlineInfo
  hi link CocHintHighlight DiagnosticUnderlineHint

  augroup user_plugin_coc
    autocmd!

    " Highlight the symbol and its references when holding the cursor.
    autocmd CursorHold * silent call CocActionAsync('highlight')

    " Update signature help on jump placeholder.
    autocmd User CocJumpPlaceholder silent call CocActionAsync('showSignatureHelp')

    " Auto format
    autocmd FocusLost,BufLeave *.go silent call CocActionAsync('format')

    " Override plugin commands
    autocmd User CocNvimInit delcommand CocRebuild
    autocmd User CocNvimInit command! -nargs=0 CocRestart :silent call coc#rpc#restart()
  augroup END
endfunction

"  Custom actions
"-----------------------------------------------
nnoremap <Plug>(coc-hover) <Cmd>call CocActionAsync('doHover')<CR>
nnoremap <Plug>(coc-peek-definition) <Cmd>call CocActionAsync('jumpDefinition', v:false)<CR>
nnoremap <Plug>(coc-peek-type-definition) <Cmd>call CocActionAsync('jumpTypeDefinition', v:false)<CR>
inoremap <Plug>(coc-signature-help) <C-r>=CocActionAsync('showSignatureHelp')<CR>

command! -nargs=0 Import
  \ call CocAction('runCommand', 'editor.action.organizeImport')

command! -nargs=0 -range=% Format call <SID>run_format(<range>, <line1>, <line2>)

function! s:run_format(range, line1, line2) abort
  if a:range == 0
    call CocActionAsync('format')
  else
    call CocActionAsync('formatSelected', visualmode())
  endif
endfunction

"  Key mappings
"-----------------------------------------------
" Completion
inoremap <silent><expr> <Down> coc#pum#visible() ? coc#pum#next(0) : "\<Down>"
inoremap <silent><expr> <Up> coc#pum#visible() ? coc#pum#prev(0) : "\<Up>"

" Refactoring
nmap <silent> gr <Plug>(coc-rename)
nmap <silent> gq <Plug>(coc-codeaction-cursor)
xmap <silent> gq <Plug>(coc-codeaction-selected)

" Cross references
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gt <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gD <Plug>(coc-peek-definition)
nmap <silent> gT <Plug>(coc-peek-type-definition)
nmap <silent> gR <Plug>(coc-references-used)

" Hover
nmap <silent> gh <Plug>(coc-hover)
imap <silent> <C-s><C-p> <Plug>(coc-signature-help)

" Diagnostics
nmap <silent> [d <Plug>(coc-diagnostic-prev)
nmap <silent> ]d <Plug>(coc-diagnostic-next)
nmap <silent> [e <Plug>(coc-diagnostic-prev-error)
nmap <silent> ]e <Plug>(coc-diagnostic-next-error)

" Scroll float
nnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
nnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
inoremap <silent><nowait><expr> <Right> coc#float#has_scroll() ? "\<C-r>=coc#float#scroll(1)\<CR>" : "\<Right>"
inoremap <silent><nowait><expr> <Left> coc#float#has_scroll() ? "\<C-r>=coc#float#scroll(0)\<CR>" : "\<Left>"

"  coc-git
"-----------------------------------------------
" navigate chunks of current buffer
nmap [g <Plug>(coc-git-prevchunk)
nmap ]g <Plug>(coc-git-nextchunk)

" navigate conflicts of current buffer
nmap [C <Plug>(coc-git-prevconflict)
nmap ]C <Plug>(coc-git-nextconflict)
