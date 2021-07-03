setlocal noet
setlocal tabstop=4 shiftwidth=4

augroup vim_ftplugin_go
  autocmd!
augroup END

let g:go_highlight_space_tab_error = 0
let g:go_highlight_trailing_whitespace_error = 0
let g:go_highlight_extra_types = 0

"  Fmt
"-----------------------------------------------
function! s:auto_gofmt(path) abort
  if empty(a:path)
    return
  end

  let l:auto_gofmt_job = get(b:, 'auto_gofmt_job', v:null)
  if l:auto_gofmt_job != v:null
    call jobstop(l:auto_gofmt_job)
  endif

  let b:auto_gofmt_job = jobstart(['gofmt', '-s', '-w', a:path])
endfunction

autocmd vim_ftplugin_go FocusLost,BufLeave *.go
  \ call <SID>auto_gofmt(expand('%:p'))
