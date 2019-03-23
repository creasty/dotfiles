" auto select
set completeopt+=noinsert

" disable the preview window feature
set completeopt-=preview

" silence "-- XXX completion (YYY)", "match 1 of 2", "The only match", "Pattern not found", "Back at original", etc.
set shortmess+=c

let g:deoplete#enable_at_startup = 1
let g:deoplete#enable_yarp = 1
let g:deoplete#enable_smart_case = 1
let g:deoplete#auto_complete_delay = 0
let g:deoplete#auto_complete_start_length = 1

call deoplete#custom#option('skip_chars', ['(', ')', '{', '}', ';'])

call deoplete#custom#source('buffer', 'min_pattern_length', 3)
call deoplete#custom#source('minisnip', 'min_pattern_length', 1)
call deoplete#custom#source('minisnip', 'rank', 900)

let g:deoplete#sources#vim_lsp#show_info = 1

call deoplete#custom#source('_', 'converters', [
  \ 'converter_auto_paren',
  \ 'converter_remove_overlap',
  \ 'converter_truncate_abbr',
  \ 'converter_truncate_menu',
\ ])

command! DeopleteDebug
  \ call deoplete#custom#option('profile', v:true)
  \| call deoplete#enable_logging('DEBUG', expand('~/deoplete.log'))
  \| call deoplete#custom#source('_', 'is_debug_enabled', 1)

function! s:on_completion() abort
  let l:completed_item = get(v:, 'completed_item', {})
  if empty(l:completed_item)
    let l:completed_item = get(v:event, 'completed_item', {})
  endif

  if !has_key(l:completed_item, 'info')
    return
  endif

  let l:info = l:completed_item['info']
  echomsg l:info

  " TODO: Insert function placeholder
endfunction
autocmd vimrc CompleteDone * :call <SID>on_completion()
