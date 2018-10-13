setlocal noet
setlocal tabstop=4 shiftwidth=4

augroup vim_ftplugin_go
  autocmd!
augroup END

"  Imports
"-----------------------------------------------
command! GoImports
  \ call system('goimports -w ' . shellescape(expand('%:p')))
  \ | e

"  Fmt
"-----------------------------------------------
function! s:auto_gofmt(path) abort
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

"  Def
"-----------------------------------------------
function! s:go_def() abort
  let l:fname = expand('%:p')
  let l:pos = getpos('.')[1:2]
  let l:offs = line2byte(pos[0]) + pos[1] - 2

  silent let l:out = system('godef'
    \ . ' -f=' . shellescape(l:fname)
    \ . ' -o=' . shellescape(l:offs)
  \ )
  let l:out = substitute(l:out, '\n$', '', '')

  return l:out
endfunction

if !exists('*s:go_def_jump')
  function! s:go_def_jump() abort
    let l:out = s:go_def()

    let l:parts = split(l:out, ':')
    if len(l:parts) < 3
      echomsg 'tag not found'
      return
    endif

    let l:filename = l:parts[0]
    let l:line = l:parts[1]
    let l:col = l:parts[2]

    normal! m'
    if l:filename != expand('%:p')
      exec 'edit' fnameescape(fnamemodify(filename, ':.'))
    endif

    call cursor(l:line, l:col)
    normal! zz
  endfunction
endif

command! GoDef
  \ call <SID>go_def_jump()

nnoremap <buffer> <silent> <C-]> :call <SID>go_def_jump()<CR>
