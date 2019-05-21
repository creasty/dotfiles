" Handle isx_<Tab>, i_<Esc>, i_<CR>
"
" - Shougo/deoplete.nvim
" - mattn/emmet-vim
" - SirVer/ultisnips
" - cohama/lexima.vim

if exists('g:loaded_super_tab') || v:version < 702
  finish
endif
let g:loaded_super_tab = 1

let s:save_cpo = &cpoptions
set cpoptions&vim

"  Placeholder
"-----------------------------------------------
let s:placeholder_delim = [
  \ '{{+',
  \ '+}}',
\ ]
let s:placeholder_pattern = '\V' . s:placeholder_delim[0] . '\.\{-}' . s:placeholder_delim[1]

function! s:placeholder_should_trigger() abort
  return search(s:placeholder_pattern, 'e')
endfunction

function! SelectPlaceholder() abort
  " Make sure '< mark is set so the normal command won't error out.
  if getpos("'<") == [0, 0, 0, 0]
    call setpos("'<", getpos('.'))
  endif

  " don't clobber s register
  let l:old_s = @s

  try
    " gn misbehaves when 'wrapscan' isn't set (see vim's #1683)
    let [l:ws, &wrapscan] = [&wrapscan, 1]
    silent keeppatterns execute 'normal! /' . s:placeholder_pattern . "/e\<cr>gn\"sy"
    " save length of entire placeholder for reference later
    let l:slen = len(@s)
    " remove the start and end delimiters
    let @s=substitute(@s, '\V' . s:placeholder_delim[0], '', '')
    let @s=substitute(@s, '\V' . s:placeholder_delim[1], '', '')
  catch /E486:/
    " There's no normal placeholder at all
    let @s = l:old_s
    call feedkeys('i', 'n')
    return
  finally
    let &wrapscan = l:ws
  endtry

  if empty(@s)
    " the placeholder was empty, so just enter insert mode directly
    normal! gv"_d
    call feedkeys(col("'>") - l:slen >= col('$') - 1 ? 'a' : 'i', 'n')
  else
    " paste the placeholder's default value in and enter select mode on it
    execute "normal! gv\"spgv\<C-g>"
  endif

  " restore old value of s register
  let @s = l:old_s
endfunction

"  Tab
"-----------------------------------------------
function! s:ultisnips_is_expandable() abort
  return !(
    \ col('.') <= 1
    \ || !empty(matchstr(getline('.')[:col('.') - 1], '^\s\+$'))
    \ || empty(UltiSnips#SnippetsInCurrentScope())
    \ )
endfunction

function! s:tab_i() abort
  if pumvisible()
    return "\<C-r>=deoplete#close_popup()\<CR>"
  elseif s:placeholder_should_trigger()
    return "\<Esc>:call SelectPlaceholder()\<CR>"
  elseif &filetype =~# 'x\?html\|xml\|s\?css' && emmet#isExpandable()
    return "\<C-g>u\<C-r>=emmet#expandAbbr(0, '')\<CR>"
  elseif s:ultisnips_is_expandable()
    return "\<C-r>=UltiSnips#ExpandSnippetOrJump()\<CR>"
  else
    " return lexima#expand('<TAB>', 'i')
    call feedkeys("\<Tab>", 'n')
    return ''
  endif
endfunction

function! s:tab_s() abort
  if s:placeholder_should_trigger()
    return "\<Esc>:call SelectPlaceholder()\<CR>"
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
