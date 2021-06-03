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

let s:placeholder_delim = ['{'.'{+', '+}}']
let s:placeholder_pattern = '\V' . s:placeholder_delim[0] . '\.\{-}' . s:placeholder_delim[1]

function! s:is_placeholder_selectable() abort
  return search(s:placeholder_pattern, 'e')
endfunction

function! s:select_placeholder() abort
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
  elseif s:is_placeholder_selectable()
    return "\<Esc>\<Plug>(supertab-select-placeholder)"
  else
    return "\<Plug>(supertab-ctrl-r)"
  endif
endfunction

function! s:tab_s() abort
  if s:is_placeholder_selectable()
    return "\<Esc>\<Plug>(supertab-select-placeholder)"
  else
    return "\<Esc>:call UltiSnips#ExpandSnippetOrJump()\<CR>"
  endif
endfunction

function! s:tab_x() abort
  return ":\<C-u>call UltiSnips#SaveLastVisualSelection()\<CR>gvs"
endfunction

function! s:cancel_completion() abort
  " <C-e>
  call coc#_cancel()
  return ''
endfunction

nnoremap <Plug>(supertab-select-placeholder) :<C-u>call <SID>select_placeholder()<CR>
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
