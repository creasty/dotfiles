if exists('g:loaded_vimrc_appearance') || v:version < 702
  finish
endif
let g:loaded_vimrc_appearance = 1

let s:save_cpo = &cpoptions
set cpoptions&vim

scriptencoding utf-8

augroup vimrc_appearance
  autocmd!
augroup END

" enable 24-bits colors
if has('termguicolors')
  set termguicolors
endif

" skip intro screen
set shortmess+=I

" always show statusline
set laststatus=2

" always show tabline
set showtabline=2

" match pairs
set showmatch

" show line numbers
set number

" highlighting current line will slow down vim
set nocursorline

" do not redraw during command
set lazyredraw

" limit syntax highlighting
set synmaxcol=512

" display very very long line at the end of file
set display& display+=lastline

" display nonprintable charactors as hex
set display+=uhex

" show hidden charactors
set list
set listchars=tab:▸\ ,nbsp:∘,extends:❯,precedes:❮

" indent wrapped lines
if has('linebreak')
  set breakindent
  let &showbreak = '   ›'
else
  let &showbreak = '›'
end

" conceal
if has('conceal')
  set conceallevel=2 concealcursor=
endif

" color column
set colorcolumn=90

" always show sign column
set signcolumn=yes

" transparent pmenu
if exists('&pumblend')
  set pumblend=10
endif

" enables 24-bit RGB color in the TUI
set termguicolors

" change cursor styles
set guicursor=n-v-c-sm:block-Cursor,i-ci-ve:ver25-Cursor,r-cr-o:hor20-Cursor

" folding
set foldmethod=indent
set fillchars="fold:"
set foldlevel=20
set foldlevelstart=20
set foldtext=vimrc#ui#fold_text()

" window title
set title titlestring=%{vimrc#ui#title_text()}

" tabline
set tabline=%!vimrc#ui#tab_line()

"  StatusLine
"-----------------------------------------------
function! s:refresh_statusline() abort
  let l:cw = winnr()

  for l:nr in range(1, winnr('$'))
    call setwinvar(l:nr, '&statusline', '%!vimrc#ui#status_line(' . l:nr . ', ' . l:cw . ')')
  endfor
endfunction

autocmd vimrc_appearance FocusGained,BufEnter,BufReadPost,BufWritePost * call vimrc#ui#update_filereadable()
autocmd vimrc_appearance VimEnter,WinEnter,BufWinEnter * call <SID>refresh_statusline()

"  Custom highlighting
"-----------------------------------------------
autocmd vimrc_appearance User ModeDidChange call s:update_mode_highlight()
function! s:update_mode_highlight() abort
  if g:colors_name !=# 'candle'
    return
  endif

  lua <<EOF
    local mode = vim.api.nvim_eval('vimrc#ui#get_mode()')
    require('candle').update_mode_highlight(mode)
EOF
endfunction

autocmd vimrc_appearance BufWinEnter * call s:setup_matchadd()
function s:setup_matchadd() abort
  for l:match_id in get(w:, 'vimrc_appearance_match_ids', [])
    call matchdelete(l:match_id)
  endfor

  let w:vimrc_appearance_match_ids = [
    \ matchadd('FullwidthSpace', '　'),
    \ matchadd("SpellRare", '[０１２３４５６７８９]'),
    \ matchadd("SpellRare", '[ａｂｃｄｅｆｇｈｉｊｋｌｍｎｏｐｑｒｓｔｕｖｗｘｙｚ]'),
    \ matchadd("SpellRare", '[ＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯＰＱＲＳＴＵＶＷＸＹＺ]'),
    \ matchadd('GitConflictMarker', '^\(<<<<<<<.\{-}\|=======\|>>>>>>>.\{-}\)$', 50),
    \ matchadd('ExtraWhitespace', '\s\+$', 50),
    \ matchadd('SnipPlaceholder', '{'.'{+\([^+]\|+[^}]\|+}[^}]\)*+}}', 50),
    \ matchadd('SnipPlaceholder', '{'.'{-\([^-]\|-[^}]\|-}[^}]\)*-}}', 50),
  \ ]
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
