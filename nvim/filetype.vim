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
  autocmd! BufNewFile,BufRead *.er setlocal ft=conf
  autocmd! BufNewFile,BufRead *.graphql setlocal ft=graphql
  autocmd! BufNewFile,BufRead gitconfig setlocal ft=gitconfig
  autocmd! BufNewFile,BufRead .gitattributes setlocal ft=gitattributes.toml
  autocmd! BufNewFile,BufRead LICENSE,LICENSE.txt set filetype=license
  autocmd! BufNewFile,BufRead coc-settings.json set filetype=jsonc

  "  Compound filetypes
  "-----------------------------------------------
  autocmd! BufNewFile,BufRead *_spec.rb setlocal ft=ruby.rspec
  autocmd! BufNewFile,BufRead *.bq.sql setlocal ft=sql.bq
  autocmd! BufNewFile,BufRead *.pg.sql setlocal ft=sql.pg
augroup END
