" autocmd vimrc BufNewFile * call mold#load('', 1)

autocmd vimrc User MoldTemplateLoadPre  call <SID>template_before_load()
autocmd vimrc User MoldTemplateLoadPost call <SID>template_after_load()

let s:mold_template_macro = {
  \ 'FILE_PATH': "\\=expand('%:p')",
  \ 'FILE_NAME': "\\=expand('%:t')",
  \ 'FULL_NAME': 'Yuki Iwanaga',
  \ 'USER_NAME': 'Creasty',
\ }

function! s:template_before_load()
  let b:mold_saved_cursor = getcurpos()
endfunction

function! s:template_after_load()
  for [l:macro, l:def] in items(s:mold_template_macro)
    silent exec '%s/\<' . l:macro . '\>/' . l:def . '/ge'
  endfor

  " silent! read !erb -T '-'  " FIXME

  if search('<+CURSOR+>')
    execute 'normal! "_da>'
  else
    call setpos('.', b:mold_saved_cursor)
  endif
endfunction
