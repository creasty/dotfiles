" Handle isx_<Tab>, i_<Esc>, i_<CR>
"
" - Shougo/deoplete.nvim
" - mattn/emmet-vim
" - joereynolds/vim-minisnip
" - SirVer/ultisnips
" - cohama/lexima.vim

if exists('g:loaded_super_tab') || v:version < 702
  finish
endif
let g:loaded_super_tab = 1

let s:save_cpo = &cpoptions
set cpoptions&vim

"  Tab
"-----------------------------------------------
function! TriggerUltiSnipsOrLexima()
  call UltiSnips#ExpandSnippetOrJump()
  if g:ulti_expand_or_jump_res > 0
    return ''
  endif

  return lexima#expand('<TAB>', 'i')
endfunction

function! s:tab_i() abort
  if pumvisible()
    return "\<C-r>=deoplete#close_popup()\<CR>"
  elseif minisnip#ShouldTrigger()
     return "\<Esc>:call minisnip#Minisnip()\<CR>"
  elseif &filetype =~# 'x\?html\|xml\|s\?css' && emmet#isExpandable()
    return "\<C-g>u\<C-r>=emmet#expandAbbr(0, '')\<CR>"
  else
    return "\<C-r>=TriggerUltiSnipsOrLexima()\<CR>"
  endif
endfunction

function! s:tab_s() abort
  if minisnip#ShouldTrigger()
    return "\<Esc>:call minisnip#Minisnip()\<CR>"
  else
    return "\<Esc>:call UltiSnips#ExpandSnippetOrJump()\<CR>"
  endif
endfunction

function! s:tab_x() abort
  return ":\<C-u>call UltiSnips#SaveLastVisualSelection()\<CR>gvs"
endfunction

imap <silent> <expr> <Tab> <SID>tab_i()
smap <silent> <expr> <Tab> <SID>tab_s()
xmap <silent> <expr> <Tab> <SID>tab_x()

"  Esc
"-----------------------------------------------
inoremap <Plug>(deoplete-my-undo) <C-e><C-r>=deoplete#close_popup()<CR>
inoremap <Plug>(deoplete-my-escape) <C-r>=lexima#insmode#escape()<CR><Esc>
imap <silent> <expr> <C-c> pumvisible() ? "\<Plug>(deoplete-my-undo)" : "\<Plug>(deoplete-my-escape)"
imap <silent> <expr> <Esc> pumvisible() ? "\<Plug>(deoplete-my-undo)" : "\<Plug>(deoplete-my-escape)"

"  Return
"-----------------------------------------------
imap <silent> <expr> <C-j> pumvisible() ? "\<C-r>=deoplete#close_popup()\<CR>" : "\<CR>"


let &cpoptions = s:save_cpo
unlet s:save_cpo
