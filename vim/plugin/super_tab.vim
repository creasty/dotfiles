" Handle isx_<Tab>, i_<Esc>, i_<CR>
"
" - neoclide/coc.nvim
" - mattn/emmet-vim
" - SirVer/ultisnips
" - cohama/lexima.vim

if exists('g:loaded_super_tab') || v:version < 702
  finish
endif
let g:loaded_super_tab = 1

let s:save_cpo = &cpoptions
set cpoptions&vim

function! s:tab_r()
  call UltiSnips#ExpandSnippetOrJump()
  if g:ulti_expand_or_jump_res > 0
    return ''
  endif

  if &filetype =~# 'x\?html\|xml\|s\?css' && emmet#isExpandable()
    return emmet#expandAbbr(0, '')
  endif

  " return lexima#expand('<TAB>', 'i')
  call feedkeys("\<Tab>", 'n')
  return ''
endfunction

function! s:tab_i() abort
  if pumvisible()
    return coc#_select_confirm()
  else
    return "\<Plug>(supertab-ctrl-r)"
  endif
endfunction

function! s:tab_s() abort
  return "\<Esc>:call UltiSnips#ExpandSnippetOrJump()\<CR>"
endfunction

function! s:tab_x() abort
  return ":\<C-u>call UltiSnips#SaveLastVisualSelection()\<CR>gvs"
endfunction

function! s:cancel_completion() abort
  " <C-e>
  call coc#_cancel()
  return ''
endfunction

inoremap <expr> <Plug>(supertab-undo) <SID>cancel_completion()
inoremap <Plug>(supertab-accept) <C-y>
inoremap <Plug>(supertab-ctrl-r) <C-r>=<SID>tab_r()<CR>
inoremap <Plug>(supertab-escape) <C-r>=lexima#insmode#escape()<CR><Esc>
imap <Plug>(supertab-enter) <C-g>u<CR><C-r>=coc#on_enter()<CR>

imap <silent> <expr> <Tab> <SID>tab_i()
smap <silent> <expr> <Tab> <SID>tab_s()
xmap <silent> <expr> <Tab> <SID>tab_x()

imap <silent> <expr> <C-c> pumvisible() ? "\<Plug>(supertab-undo)" : "\<Plug>(supertab-escape)"
imap <silent> <expr> <Esc> pumvisible() ? "\<Plug>(supertab-undo)" : "\<Plug>(supertab-escape)"
imap <silent> <expr> <C-j> pumvisible() ? "\<Plug>(supertab-accept)" : "\<Plug>(supertab-enter)"

let &cpoptions = s:save_cpo
unlet s:save_cpo
