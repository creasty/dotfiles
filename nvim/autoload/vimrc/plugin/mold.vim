let s:macro = {
  \ 'FILE_PATH': "\\=expand('%:p')",
  \ 'FILE_NAME': "\\=expand('%:t')",
  \ 'FILE_BASE_NAME': "\\=expand('%:t:r')",
  \ 'FULL_NAME': 'Yuki Iwanaga',
  \ 'USER_NAME': 'Creasty',
\ }

function! vimrc#plugin#mold#before_load() abort
  let b:mold_saved_cursor = getcurpos()
endfunction

function! vimrc#plugin#mold#after_load() abort
  for [l:macro, l:def] in items(s:macro)
    silent exec '%s/\<' . l:macro . '\>/' . l:def . '/ge'
  endfor

  silent! %!erb -T '-'

  if search('<+CURSOR+>')
    execute 'normal! "_da>'
  else
    call setpos('.', b:mold_saved_cursor)
  endif
endfunction
