" [coc-clangd] brew install llvm
" [coc-css] npm install -g vscode-css-languageserver-bin
" [coc-eslint] npm install -g eslint
" [coc-pyright] npm install -g pyright
" [coc-rls] rustup update && rustup component add rls rust-analysis rust-src
" [coc-solargraph] gem install solargraph
" [coc-tsserver] npm install -g typescript typescript-language-server typescript-styled-plugin && brew install watchman
let g:coc_global_extensions = [
  \ '@yaegassy/coc-tailwindcss3',
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
  \ 'coc-yaml',
\ ]

let g:coc_selectmode_mapping = 0
let g:coc_snippet_next = '<Plug>(coc-snippet-next)'
let g:coc_snippet_prev = '<Plug>(coc-snippet-prev)'

function! user#plugin#coc#init() abort
  augroup user_plugin_coc
    autocmd!

    " Highlight the symbol and its references when holding the cursor.
    autocmd CursorHold * silent call CocActionAsync('highlight')

    " Update signature help on jump placeholder.
    autocmd User CocJumpPlaceholder silent call CocActionAsync('showSignatureHelp')

    " Auto format
    autocmd FocusLost,BufLeave *.go call user#plugin#coc#auto_format()

    " Override plugin commands
    autocmd VimEnter * command! -nargs=0 CocRestart :silent call coc#rpc#restart()
  augroup END
endfunction

function! user#plugin#coc#auto_format() abort
  if &readonly || !&modifiable
    return
  endif
  if mode() !=# 'n'
    return
  endif
  silent call CocActionAsync('format')
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
inoremap <silent><expr> <Left> coc#pum#cancel() . "\<Left>"
inoremap <silent><expr> <Right> coc#pum#cancel() . "\<Right>"

" Refactoring
" TODO: gr -> grn, gq -> gra
nmap <nowait> <silent> gr <Plug>(coc-rename)
nmap <silent> gq <Plug>(coc-codeaction-cursor)
xmap <silent> gq <Plug>(coc-codeaction-selected)

" Cross references
" TODO: gR -> grr, gi -> gri
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gt <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gD <Plug>(coc-peek-definition)
nmap <silent> gT <Plug>(coc-peek-type-definition)
nmap <silent> gR <Plug>(coc-references-used)

" Hover
nmap <silent> gh <Plug>(coc-hover)
imap <silent> <C-s><C-s> <Plug>(coc-signature-help)

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
