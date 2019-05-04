let s:mold_template_macro = {
  \ 'FILE_PATH': "\\=expand('%:p')",
  \ 'FILE_NAME': "\\=expand('%:t')",
  \ 'FULL_NAME': 'Yuki Iwanaga',
  \ 'USER_NAME': 'Creasty',
\ }

function! vimrc#plugin#mold#template_before_load() abort
  let b:mold_saved_cursor = getcurpos()
endfunction

function! vimrc#plugin#mold#template_after_load() abort
  for [l:macro, l:def] in items(s:mold_template_macro)
    silent exec '%s/\<' . l:macro . '\>/' . l:def . '/ge'
  endfor

  silent! %!erb -T '-'

  if search('<+CURSOR+>')
    execute 'normal! "_da>'
  else
    call setpos('.', b:mold_saved_cursor)
  endif
endfunction
