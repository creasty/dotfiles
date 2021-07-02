if exists('g:loaded_next_file') || v:version < 702
  finish
endif
let g:loaded_next_file = 1

let s:save_cpo = &cpoptions
set cpoptions&vim

command! -nargs=0 NextFile call <SID>next_file(1)
command! -nargs=0 PrevFile call <SID>next_file(-1)
nnoremap g0 :NextFile<CR>
nnoremap g9 :PrevFile<CR>

" edit a next file in the same directory
function! s:next_file(direction) abort
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

let &cpoptions = s:save_cpo
unlet s:save_cpo
