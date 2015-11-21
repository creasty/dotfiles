setlocal noet
setlocal tabstop=4 shiftwidth=4

augroup vim_ftplugin_go
  autocmd!
augroup END

function! s:auto_go_fmt(path)
  if !empty(a:path)
    call vimproc#system('gofmt -s -w ' . fnameescape(a:path))
  endif
endfunction

autocmd vim_ftplugin_go FocusLost,BufLeave *.go
  \ call <SID>auto_go_fmt(expand('%:p'))
