" Handle <Tab>, <Esc>, <CR>
"
" - neoclide/coc.nvim
" - mattn/emmet-vim
" - SirVer/ultisnips
" - cohama/lexima.vim
"
if exists('g:loaded_super_tab') || v:version < 702
  finish
endif
let g:loaded_super_tab = 1

let s:save_cpo = &cpoptions
set cpoptions&vim

function! s:tab_i() abort
  if pumvisible()
    return coc#_select_confirm()
  endif

  let l:copilot = copilot#GetDisplayedSuggestion()
  if !empty(l:copilot) && !empty(l:copilot.text)
    return copilot#Accept('')
  endif

  let l:snip = UltiSnips#CanExpandSnippet() || UltiSnips#CanJumpForwards()
  if l:snip
    return "\<C-r>=UltiSnips#ExpandSnippetOrJump()\<CR>"
  endif

  let l:emmet_enabled = &filetype =~# '\vx?html|xml|s?css|[jt]sx'
  if l:emmet_enabled && emmet#isExpandable()
    return emmet#expandAbbr(0, '')
    return "\<C-r>=emmet#expandAbbr(0, '')\<CR>"
  endif

  return lexima#expand('<TAB>', 'i')
endfunction

inoremap <Plug>(supertab-undo) <C-e>
inoremap <Plug>(supertab-accept) <C-y>
inoremap <Plug>(supertab-escape) <C-r>=lexima#insmode#escape()<CR><Esc>
inoremap <Plug>(supertab-enter) <C-g>u<CR><C-r>=coc#on_enter()<CR>

imap <silent> <expr> <Tab> <SID>tab_i()
smap <silent> <Tab> <Esc><Cmd>call UltiSnips#ExpandSnippetOrJump()<CR>

imap <silent> <expr> <Esc> pumvisible() ? "\<Plug>(supertab-undo)" : "\<Plug>(supertab-escape)"
imap <silent> <expr> <CR> pumvisible() ? "\<Plug>(supertab-accept)" : "\<Plug>(supertab-enter)"

let &cpoptions = s:save_cpo
unlet s:save_cpo
