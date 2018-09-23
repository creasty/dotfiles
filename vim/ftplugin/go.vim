setlocal noet
setlocal tabstop=4 shiftwidth=4

augroup vim_ftplugin_go
  autocmd!
augroup END

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

command! GoImports
  \ call system('goimports -w ' . shellescape(expand('%:p')))
  \ | e

"  Def
"-----------------------------------------------
function! s:go_def() abort
  let l:fname = expand('%:p')

  " Write current unsaved buffer to a temp file and use the modified content
  " if &modified
  "   let l:tmpname = tempname()
  "   call writefile(go#util#GetLines(), l:tmpname)
  "   let l:fname = l:tmpname
  " endif

  let l:pos = getpos('.')[1:2]
  let l:offs = line2byte(pos[0]) + pos[1] - 2

  let l:out = system('godef'
    \ . ' -f=' . shellescape(l:fname)
    \ . ' -o=' . shellescape(l:offs)
    \ . ' -t'
  \ )
  " if exists('l:tmpname')
  "   call delete(l:tmpname)
  " endif

  let l:out = substitute(l:out, '\n$', '', '')
  let l:out = join(split(l:out, '\n'), ':')

  return l:out
endfunction

if !exists('*s:go_def_jump')
  function! s:go_def_jump() abort
    let l:out = s:go_def()
    let l:parts = split(l:out, ':')
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
