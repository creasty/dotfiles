" syntax highlight & color scheme
set background=dark
set t_Co=256
syntax enable

if dein#tap('candle.vim')
  colorscheme candle
endif

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
hi ColorColumn guibg=#1f1f1f ctermbg=234

" always show sign column
set signcolumn=yes


"  Folding
"-----------------------------------------------
set foldmethod=indent
set fillchars="fold:"
set foldlevel=20
set foldlevelstart=20
set foldtext=CustomFoldText()

function! CustomFoldText()
  let l:fs = v:foldstart

  while getline(l:fs) =~# '^\s*$' | let l:fs = nextnonblank(l:fs + 1)
  endwhile

  if l:fs > v:foldend
    let l:line = getline(v:foldstart)
  else
    let l:line = substitute(getline(l:fs), '\t', repeat(' ', &tabstop), 'g')
  endif

  let l:w = winwidth(0) - &foldcolumn - (&number ? 8 : 0)

  let l:linecounter = ' (' . (1 + v:foldend - v:foldstart) . ')'
  let l:expansion = repeat(' ', l:w - strwidth(l:linecounter . l:line))

  return l:line . l:expansion . l:linecounter
endfunction


"  Custom highlight
"-----------------------------------------------
if dein#tap('candle.vim')
  " highlight full-width space
  call candle#highlight('ZenkakuSpace', '', 'dark_red', '')
  autocmd vimrc BufWinEnter,WinEnter *
    \ call matchadd('ZenkakuSpace', '　')

  " highlight trailing spaces
  call candle#highlight('TrailingSpace', '', 'line', '')
  autocmd vimrc BufWinEnter,WinEnter *
    \ call matchadd('TrailingSpace', '\s\+$')
endif


"  Windo title
"-----------------------------------------------
set title titlestring=%{MyTitleText()}

function! MyTitleText()
  let l:t = []

  if !empty(v:servername)
    let l:name = substitute(v:servername, 'VIM', '', '')
    if l:name ==# ''
      let l:name = '0'
    endif
    call add(l:t, '$' . l:name . ':')
  endif

  let l:session = fnamemodify(v:this_session, ':t:r')

  if l:session !=# ''
    call add(l:t, '[' . l:session . ']')
  endif

  let l:path = expand('%:p')
  let l:path = (l:path !=# '') ? l:path : getcwd()
  let l:path = substitute(l:path, $HOME, '~', '')
  let l:path = substitute(l:path, '\~/go/src/github.com', '~g', '')
  call add(l:t, l:path)

  return join(l:t, ' ')
endfunction
