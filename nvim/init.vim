"----------------------------------------------------------------------------------------------
"                                        _
"                                 _   __(_)___ ___  __________
"                                | | / / / __ `__ \/ ___/ ___/
"                                | |/ / / / / / / / /  / /__
"                                |___/_/_/ /_/ /_/_/   \___/
"
"                                 github.com/creasty/dotfiles
"
"----------------------------------------------------------------------------------------------

language en_US
scriptencoding utf-8

" disable builtin plugins
let g:loaded_tar = 1
let g:loaded_tarPlugin = 1
let g:loaded_zip = 1
let g:loaded_zipPlugin = 1
let g:loaded_2html_plugin = 1
let g:loaded_vimball = 1
let g:loaded_vimballPlugin = 1
let g:loaded_netrw = 1
let g:loaded_netrwPlugin = 1

" configure runtime features
let g:omni_sql_no_default_maps = 1
let g:tex_flavor = 'latex'

" python provider
set pyxversion=3

" leader key
let g:mapleader = ','

" unregister autocmds
augroup vimrc
  autocmd!
augroup END

"=== Dein
"==============================================================================================
if has('vim_starting')
  let &g:rtp .= ',' . g:vimrc#env.path.dein_repo
endif

let g:dein#_plugins = {}

if dein#load_state(g:vimrc#env.path.dein)
  call dein#begin(g:vimrc#env.path.dein, [expand('<sfile>'), g:vimrc#env.path.dein_toml, g:vimrc#env.path.dein_lazy_toml])

  call dein#load_toml(g:vimrc#env.path.dein_toml,      { 'lazy': 0 })
  call dein#load_toml(g:vimrc#env.path.dein_lazy_toml, { 'lazy': 1 })

  call dein#end()
  call dein#save_state()
endif

if dein#check_install()
  call dein#install()
endif

autocmd vimrc VimEnter * call dein#call_hook('post_source')

"  Commands
"-----------------------------------------------
command! DeinUpdate call dein#update()
command! DeinPurgeCache
  \ call dein#recache_runtimepath() |
  \ call dein#clear_state()
command! DeinPrunePlugins
  \ call map(dein#check_clean(), "delete(v:val, 'rf')") |
  \ exec 'DeinPurgeCache' |
  \ echo 'done'

"=== Load
"==============================================================================================
colorscheme candle

if dein#tap('vim-textobj-multiblock')
  let g:textobj_multiblock_blocks = [
    \ [ '(', ')' ],
    \ [ '[', ']' ],
    \ [ '{', '}' ],
    \ [ '<', '>' ],
    \ [ '"', '"' ],
    \ [ "'", "'" ],
    \ [ '「', '」' ],
    \ [ '（', '）' ],
  \ ]

  omap ab <Plug>(textobj-multiblock-a)
  omap ib <Plug>(textobj-multiblock-i)
  xmap ab <Plug>(textobj-multiblock-a)
  xmap ib <Plug>(textobj-multiblock-i)
endif

if dein#tap('vim-easy-align')
  let g:easy_align_delimiters = {
    \ '=': {
      \ 'pattern':       '===\|<=>\|=\~[#?]\?\|=>\|[:+/*!%^=><&|.-?]*=[#?]\?'
      \                  . '\|[-=]>\|<[-=]',
      \ 'left_margin':   1,
      \ 'right_margin':  1,
      \ 'stick_to_left': 0,
    \ },
    \ ';': {
      \ 'pattern':       ':',
      \ 'left_margin':   0,
      \ 'right_margin':  1,
      \ 'stick_to_left': 1
    \ },
  \ }

  xnoremap <silent> L :EasyAlign<cr>
endif

if dein#tap('switch.vim')
  let g:switch_mapping = ''
  let g:switch_custom_definitions = [
    \ switch#Words(['public', 'protected', 'private']),
    \ switch#Words(['and', 'or']),
    \ switch#Words(['if', 'unless']),
    \ switch#NormalizedCaseWords(['true', 'false']),
    \ switch#NormalizedCaseWords(['on', 'off']),
    \ switch#NormalizedCaseWords(['yes', 'no']),
  \ ]

  nnoremap <silent> - :call <SID>my_switch()<CR>

  function! s:my_switch() abort
    if quote_toggler#toggle()
      return
    endif

    :Switch
  endfunction
endif

if dein#tap('vim-textmanip')
  let g:textmanip_enable_mappings = 0

  let g:textmanip_hooks = {}
  function! g:textmanip_hooks.finish(tm) abort
    let l:tm = a:tm
    let l:helper = textmanip#helper#get()
    if !l:tm.linewise
      call l:helper.remove_trailing_WS(l:tm)
    endif
  endfunction

  " move selection
  xmap <C-j> <Plug>(textmanip-move-down)
  xmap <C-k> <Plug>(textmanip-move-up)
  xmap <C-h> <Plug>(textmanip-move-left)
  xmap <C-l> <Plug>(textmanip-move-right)

  " duplicate line
  xmap <Space><C-j> <Plug>(textmanip-duplicate-down)
  xmap <Space><C-k> <Plug>(textmanip-duplicate-up)
  xmap <Space><C-h> <Plug>(textmanip-duplicate-left)
  xmap <Space><C-l> <Plug>(textmanip-duplicate-right)
endif

if dein#tap('mold.vim')
  let s:mold_template_macro = {
    \ 'FILE_PATH': "\\=expand('%:p')",
    \ 'FILE_NAME': "\\=expand('%:t')",
    \ 'FILE_BASE_NAME': "\\=expand('%:t:r')",
    \ 'FULL_NAME': 'Yuki Iwanaga',
    \ 'USER_NAME': 'Creasty',
  \ }

  function! s:mold_before_load() abort
    let b:mold_saved_cursor = getcurpos()
  endfunction

  function! s:mold_after_load() abort
    for [l:macro, l:def] in items(s:mold_template_macro)
      silent exec '%s/\<' . l:macro . '\>/' . l:def . '/ge'
    endfor

    silent! %!erb -T '-'

    if search('<+CURSOR+>')
      execute 'normal! "_da>'
    else
      call setpos('.', b:mold_saved_cursor)
    endif
  endfunction

  autocmd vimrc User MoldTemplateLoadPre  call s:mold_before_load()
  autocmd vimrc User MoldTemplateLoadPost call s:mold_after_load()
endif

if dein#tap('ultisnips')
  let g:UltiSnipsSnippetDirectories = ['ultisnips']
  let g:UltiSnipsRemoveSelectModeMappings = 0
  let g:UltiSnipsEnableSnipMate = 0

  let g:UltiSnipsExpandTrigger = '<Plug>(ultisnips-expand)'
  let g:UltiSnipsJumpForwardTrigger = '<Plug>(ultisnips-jump-forward)'
  let g:UltiSnipsJumpBackwardTrigger = '<Plug>(ultisnips-jump-backward)'
  let g:UltiSnipsListSnippets = '<Plug>(ultisnips-list)'

  if dein#tap('coc.nvim')
    autocmd vimrc User UltiSnipsEnterFirstSnippet doautocmd User CocJumpPlaceholder
    autocmd vimrc User UltiSnipsExitLastSnippet doautocmd User CocJumpPlaceholder
  endif
endif

if dein#tap('coc.nvim')
  autocmd vimrc User ForceRefresh3 call coc#float#close_all()
  autocmd vimrc User ForceRefresh call <SID>coc_re_enable()
  function! s:coc_re_enable() abort
    silent! CocDisable
    silent! CocEnable
    doautocmd InsertLeave
  endfunction
endif

if dein#tap('denite.nvim')
  " NOTE: See :UpdateRemotePlugins

  autocmd vimrc FileType denite call vimrc#plugin#denite#init_denite_list()
  autocmd vimrc FileType denite-filter call vimrc#plugin#denite#init_denite_filter()

  command! Open :call vimrc#plugin#denite#open_best()
  nnoremap <silent> <C-q> :<C-u>Open<CR>

  command! Rg :Denite -buffer-name=grep grep
  nnoremap <Space>/ :Denite -buffer-name=grep -resume grep<CR>
  nnoremap <silent> <Space>* :DeniteCursorWord -buffer-name=grep grep<CR>

  command! I18n :Denite -buffer-name=i18n_flow -resume i18n_flow
  nnoremap <Space>i :I18n<CR>
endif

if dein#tap('vim-quickrun')
  let g:quickrun_config = {}
  let g:quickrun_config['_'] = {
    \ 'runner': 'job',
    \ 'outputter/buffer/split': ':botright 15sp',
  \ }
  let g:quickrun_config['ruby.rspec'] = {
    \ 'type': 'ruby.rspec',
    \ 'command': 'rspec',
    \ 'cmdopt': 'bundle exec',
    \ 'exec': '%o %c %s',
  \ }

  nmap <Leader>r <Plug>(quickrun)
endif

if dein#tap('vim-searchhi')
  let g:searchhi_user_autocmds_enabled = 1
  let g:searchhi_redraw_before_on = 1

  nmap n <Plug>(searchhi-n)
  nmap N <Plug>(searchhi-N)
  nmap * <Plug>(searchhi-*)
  nmap g* <Plug>(searchhi-g*)
  nmap # <Plug>(searchhi-#)
  nmap g# <Plug>(searchhi-g#)

  autocmd vimrc User ClearSearchHighlight
    \ call searchhi#clear(0, 0) |
    \ call searchhi#await(0, 0)

  if dein#tap('vim-anzu')
    autocmd vimrc User SearchHiOn AnzuUpdateSearchStatusOutput
    autocmd vimrc User SearchHiOff echo g:anzu_no_match_word
  endif
endif
