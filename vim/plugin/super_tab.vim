" Handle isx_<Tab>, i_<Esc>, i_<CR>
"
" - neoclide/coc.nvim
" - mattn/emmet-vim
" - SirVer/ultisnips
" - cohama/lexima.vim
" - funcsig

if exists('g:loaded_super_tab') || v:version < 702
  finish
endif
let g:loaded_super_tab = 1

let s:save_cpo = &cpoptions
set cpoptions&vim

function! InsCtrlR()
  call UltiSnips#ExpandSnippetOrJump()
  if g:ulti_expand_or_jump_res > 0
    return ''
  endif

  " return lexima#expand('<TAB>', 'i')

  call feedkeys("\<Tab>", 'n')
  return ''
endfunction

function! s:tab_i() abort
  if pumvisible()
    return coc#_select_confirm()
  elseif funcsig#should_trigger()
    return "\<Esc>:call funcsig#select_placeholder()\<CR>"
  elseif &filetype =~# 'x\?html\|xml\|s\?css' && emmet#isExpandable()
    return "\<C-g>u\<C-r>=emmet#expandAbbr(0, '')\<CR>"
  else
    return "\<C-r>=InsCtrlR()\<CR>"
  endif
endfunction

function! s:tab_s() abort
  if funcsig#should_trigger()
    return "\<Esc>:call funcsig#select_placeholder()\<CR>"
  else
    return "\<Esc>:call UltiSnips#ExpandSnippetOrJump()\<CR>"
  endif
endfunction

function! s:tab_x() abort
  return ":\<C-u>call UltiSnips#SaveLastVisualSelection()\<CR>gvs"
endfunction

inoremap <Plug>(supertab-undo) <C-e>
inoremap <Plug>(supertab-escape) <C-r>=lexima#insmode#escape()<CR><Esc>
inoremap <Plug>(supertab-accept) <C-y>

imap <silent> <expr> <Tab> <SID>tab_i()
smap <silent> <expr> <Tab> <SID>tab_s()
xmap <silent> <expr> <Tab> <SID>tab_x()

imap <silent> <expr> <C-c> pumvisible() ? "\<Plug>(supertab-undo)" : "\<Plug>(supertab-escape)"
imap <silent> <expr> <Esc> pumvisible() ? "\<Plug>(supertab-undo)" : "\<Plug>(supertab-escape)"
imap <silent> <expr> <C-j> pumvisible() ? "\<Plug>(supertab-accept)" : "\<C-g>u\<CR>\<C-r>=coc#on_enter()\<CR>"

augroup super_tab
  autocmd!
  " autocmd CompleteDone * call funcsig#on_completion()
  " autocmd CursorHold * call funcsig#on_cursor_hold()
augroup END

let &cpoptions = s:save_cpo
unlet s:save_cpo
