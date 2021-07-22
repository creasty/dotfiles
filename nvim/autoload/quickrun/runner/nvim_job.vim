function! s:runner_run(commands, input, session) abort dict
  let l:command = join(a:commands, ' && ')
  let l:cmd_arg = ['sh', '-c', l:command]
  let l:options = {
    \ 'session': a:session.continue(),
    \ 'on_stdout': funcref('s:on_stdout'),
    \ 'on_stderr': funcref('s:on_stdout'),
    \ 'on_exit': funcref('s:on_exit'),
  \ }
  let self._job = jobstart(l:cmd_arg, l:options)
  if !empty(a:input)
    call chansend(self._job, a:input)
    call chanclose(self._job)
  endif
endfunction

function! s:runner_sweep() abort dict
  if !has_key(self, '_job')
    return
  endif
  try
    call jobstop(self._job)
  catch /^Vim\%((\a\+)\)\=:E900/
  endtry
endfunction

function! s:on_stdout(job_id, data, event) abort dict
  let l:message = join(a:data, "\n")
  call quickrun#session(self.session, 'output', l:message)
endfunction

function! s:on_exit(job_id, exitval, event) abort dict
  call quickrun#session(self.session, 'finish', a:exitval)
endfunction

function! quickrun#runner#nvim_job#new() abort
  return {
    \ 'config': {
      \ 'cwd': v:null,
      \ 'pty': v:null,
    \ },
    \ 'run': funcref('s:runner_run'),
    \ 'sweep': funcref('s:runner_sweep'),
  \ }
endfunction
