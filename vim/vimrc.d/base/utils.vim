" reopen current buffer with specific encoding
command! -bang -nargs=? Utf8
  \ edit<bang> ++enc=utf-8 <args>
command! -bang -nargs=? Sjis
  \ edit<bang> ++enc=cp932 <args>
command! -bang -nargs=? Jis
  \ edit<bang> ++enc=iso-2022-jp <args>
command! -bang -nargs=? Euc
  \ edit<bang> ++enc=eucjp <args>

" clean up hidden buffers
command! CleanBuffers :call <SID>clean_buffers()

function! s:clean_buffers()
  redir => l:bufs
    silent buffers
  redir END

  for l:ibuf in split(l:bufs, "\n")
    let l:t = matchlist(l:ibuf, '\v^\s*(\d+)([^"]*)')
    if l:t[2] !~# '[#a+]'
      exec 'bdelete' l:t[1]
    endif
  endfor
endfunction

" create directories if not exist
autocmd vimrc BufWritePre *
 \ call s:auto_mkdir(expand('<afile>:p:h'))

function! s:auto_mkdir(dir)
  if !isdirectory(a:dir)
    call mkdir(iconv(a:dir, &encoding, &termencoding), 'p')
  endif
endfunction

" delete current file
function! s:delete_or_trash(file)
  let l:trash_dir = $HOME . '/.Trash'
  let l:file = fnameescape(a:file)

  if empty(l:file)
    return
  endif

  if isdirectory(l:trash_dir)
    call job_start(['mv', l:file, l:trash_dir])
  else
    call delete(l:file)
  endif
endfunction

command! -nargs=0 Delete call <SID>delete_or_trash(expand('%:p')) | enew!

" rename current file name
command! -nargs=1 -complete=file Rename f <args> | w | call delete(expand('#'))

" edit a next file in the same directory
command! -nargs=0 NextFile call <SID>next_file(1)
command! -nargs=0 PrevFile call <SID>next_file(-1)

nnoremap g9 :PrevFile<CR>
nnoremap g0 :NextFile<CR>

function! s:next_file(direction)
  let l:path = expand('%:p')
  let l:directory = fnamemodify(l:path, ':h')

  let l:paths = split(globpath(l:directory, '*'), "\n")
  let l:files = filter(l:paths, '!isdirectory(v:val)')
  let l:n = len(l:files)
  let l:idx = index(l:files, l:path)

  if l:idx >= 0
    exec 'edit' fnameescape(l:files[(l:idx + a:direction) % l:n])
  endif
endfunction

" file detect on read / save
autocmd vimrc BufWritePost,BufReadPost,BufEnter *
  \ if &l:filetype ==# '' || exists('b:ftdetect') |
    \ unlet! b:ftdetect |
    \ filetype detect |
  \ endif

" automatically change input source
" if executable('osascript')
"   autocmd vimrc FocusGained *
"     \ call job_start(['osascript', '-e', 'tell application "System Events" to key code 102'])
" endif

" inspect syntax
command! ScopeInfo echo map(synstack(line('.'), col('.')), 'synIDattr(synIDtrans(v:val), "name")')

" forcibly reload file
autocmd vimrc BufEnter *
  \ if filereadable(expand('%:p')) |
    \ silent! execute 'checktime' bufnr('%') |
  \ endif
