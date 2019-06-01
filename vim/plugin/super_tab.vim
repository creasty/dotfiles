" Handle isx_<Tab>, i_<Esc>, i_<CR>
"
" - Shougo/deoplete.nvim
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
    return "\<C-r>=deoplete#close_popup()\<CR>"
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

imap <silent> <expr> <Tab> <SID>tab_i()
smap <silent> <expr> <Tab> <SID>tab_s()
xmap <silent> <expr> <Tab> <SID>tab_x()

inoremap <Plug>(deoplete-my-undo) <C-e><C-r>=deoplete#close_popup()<CR>
inoremap <Plug>(deoplete-my-escape) <C-r>=lexima#insmode#escape()<CR><Esc>
imap <silent> <expr> <C-c> pumvisible() ? "\<Plug>(deoplete-my-undo)" : "\<Plug>(deoplete-my-escape)"
imap <silent> <expr> <Esc> pumvisible() ? "\<Plug>(deoplete-my-undo)" : "\<Plug>(deoplete-my-escape)"

imap <silent> <expr> <C-j> pumvisible() ? "\<C-r>=deoplete#close_popup()\<CR>" : "\<CR>"

augroup super_tab
  autocmd!
  autocmd CompleteDone * call funcsig#on_completion()
  autocmd CursorHold * call funcsig#on_cursor_hold()
augroup END

let &cpoptions = s:save_cpo
unlet s:save_cpo
