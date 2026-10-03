if exists('did_load_filetypes')
  finish
endif

let s:aliases = {
  \ 'js': 'javascript',
  \ 'jsx': 'javascriptreact',
  \ 'ts': 'typescript',
  \ 'tsx': 'typescriptreact',
  \ 'md': 'markdown',
  \ 'bq': 'sql.bq',
  \ 'pg': 'sql.pg',
\ }
for [s:lhs, s:rhs] in items(s:aliases)
  execute 'cnoreabbrev' '<expr>'
    \ s:lhs "getcmdtype() ==# ':' && getcmdline() =~# '\\v^setf(iletype)?\\s+" . s:lhs . "'"
    \ " ? '" . s:rhs . "' : '" . s:lhs . "'"
endfor

augroup filetypedetect
  autocmd! BufNewFile,BufRead .env,.env.* setlocal ft=sh
  autocmd! BufNewFile,BufRead LICENSE,LICENSE.txt set filetype=license

  " Compound filetypes
  autocmd! BufNewFile,BufRead *.bq.sql setlocal ft=sql.bq
  autocmd! BufNewFile,BufRead *.pg.sql setlocal ft=sql.pg
augroup END
