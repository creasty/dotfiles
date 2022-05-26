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
  \ 'coc-diagnostic',
  \ 'coc-deno',
  \ 'coc-eslint',
  \ 'coc-git',
  \ 'coc-go',
  \ 'coc-json',
  \ 'coc-lua',
  \ 'coc-metals',
  \ 'coc-prettier',
  \ 'coc-pyright',
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

let g:coc_selectmode_mapping = 0
let g:coc_snippet_next = '<Plug>(coc-snippet-next)'
let g:coc_snippet_prev = '<Plug>(coc-snippet-prev)'

function! user#plugin#coc#init() abort
  set completeopt+=noinsert " auto select
  set completeopt-=preview " disable the preview window feature
  set shortmess+=c " silence annoying messages

  augroup user_plugin_coc
    autocmd!

    " Highlight the symbol and its references when holding the cursor.
    autocmd CursorHold * silent call CocActionAsync('highlight')

    " Update signature help on jump placeholder.
    autocmd User CocJumpPlaceholder silent call CocActionAsync('showSignatureHelp')

    " Customize floating windows
    autocmd User CocOpenFloat call user#plugin#coc#configure_float(g:coc_last_float_win)

    " Auto format
    autocmd FocusLost,BufLeave *.go silent call CocActionAsync('format')

    " Remove rebuild command
    autocmd User CocNvimInit delcommand CocRebuild
  augroup END
endfunction

function! user#plugin#coc#configure_float(winid) abort
  " Remove search highlight
  let l:value = getwinvar(a:winid, '&winhighlight')
  let l:newValue = join(filter([l:value, 'Search:'], '!empty(v:val)'), ',')
  call setwinvar(a:winid, '&winhighlight', l:newValue)

  " Make foldcolumn blank
  call setwinvar(a:winid, '&foldenable', 0)
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
  if &ft ==# 'proto' && executable('clang-format')
    normal mZ
    if a:range == 0
      exec '%!clang-format' '%'
    else
      exec '%!clang-format' '-lines='.a:line1.':'.a:line2 '%'
    endif
    normal 'Zzz
    return
  end

  if a:range == 0
    call CocActionAsync('format')
  else
    call CocActionAsync('formatSelected', visualmode())
  endif
endfunction

"  Key mappings
"-----------------------------------------------
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
imap <silent> <C-x><C-p> <Plug>(coc-signature-help)
imap <silent> <C-x>p <Plug>(coc-signature-help)

" Diagnostics
nmap <silent> [d <Plug>(coc-diagnostic-prev)
nmap <silent> ]d <Plug>(coc-diagnostic-next)
nmap <silent> [e <Plug>(coc-diagnostic-prev-error)
nmap <silent> ]e <Plug>(coc-diagnostic-next-error)

" Scroll float
if has('nvim-0.4.0') || has('patch-8.2.0750')
  nnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
  nnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
endif

" List
nnoremap <silent> gll <Cmd>CocListResume<CR>
nnoremap <silent> gld <Cmd>CocList diagnostics<CR>
nnoremap <silent> gls <Cmd>CocList symbols<CR>

"  coc-git
"-----------------------------------------------
" navigate chunks of current buffer
nmap [g <Plug>(coc-git-prevchunk)
nmap ]g <Plug>(coc-git-nextchunk)

" navigate conflicts of current buffer
nmap [C <Plug>(coc-git-prevconflict)
nmap ]C <Plug>(coc-git-nextconflict)
