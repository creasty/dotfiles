setlocal noet
setlocal tabstop=4 shiftwidth=4

augroup vim_ftplugin_go
  autocmd!
augroup END

function! s:auto_gofmt(path)
  if empty(a:path)
    return
  end

  let l:auto_gofmt_job = get(b:, 'auto_gofmt_job', v:null)
  if l:auto_gofmt_job != v:null && job_status(l:auto_gofmt_job) ==# 'run'
    call job_stop(l:auto_gofmt_job, 'kill')
  endif

  let b:auto_gofmt_job = job_start(['gofmt', '-s', '-w', a:path])
endfunction

autocmd vim_ftplugin_go FocusLost,BufLeave *.go
  \ call <SID>auto_gofmt(expand('%:p'))

command! GoImports :call system('goimports -w ' . shellescape(expand('%:p')))
