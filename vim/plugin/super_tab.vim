if exists('g:loaded_super_tab') || v:version < 702
  finish
endif
let g:loaded_super_tab = 1

let s:save_cpo = &cpoptions
set cpoptions&vim

function! s:tab_i() abort
  if pumvisible()
    return "\<C-r>=deoplete#close_popup()\<CR>"
  elseif minisnip#ShouldTrigger()
     return "\<Esc>:call minisnip#Minisnip()\<CR>"
  elseif &filetype =~# 'x\?html\|xml\|s\?css' && emmet#isExpandable()
    return "\<C-g>u\<C-r>=emmet#expandAbbr(0, '')\<CR>"
  else
    return "\<C-r>=UltiSnips#ExpandSnippetOrJump()\<CR>"
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

let &cpoptions = s:save_cpo
unlet s:save_cpo
