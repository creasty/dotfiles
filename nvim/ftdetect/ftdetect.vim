let s:shortcut = { 'ft': '' }
function! s:shortcut.call(name) abort
  exec 'setf' self.ft
endfunction
function! s:shortcut.async_call(ft) abort
  let self.ft = a:ft
  call timer_start(50, function(s:shortcut.call))
endfunction

augroup custom_filetypes
  autocmd!

  autocmd BufNewFile,BufRead *.er setlocal ft=conf
  autocmd BufNewFile,BufRead *.graphql setlocal ft=graphql
  autocmd BufNewFile,BufRead gitconfig setlocal ft=gitconfig
  autocmd BufNewFile,BufRead .gitattributes setlocal ft=gitattributes.toml
  autocmd BufNewFile,BufRead cpanfile setlocal ft=perl
  autocmd BufNewFile,BufRead Vagrantfile,*.jbuilder setlocal ft=ruby

  "  Compound filetypes
  "-----------------------------------------------
  autocmd BufNewFile,BufRead *.jsx setlocal ft=javascript.jsx
  autocmd BufNewFile,BufRead *.tsx setlocal ft=typescript.tsx
  autocmd BufNewFile,BufRead *_spec.rb setlocal ft=ruby.rspec
  autocmd BufNewFile,BufRead *.bq.sql setlocal ft=sql.bq
  autocmd BufNewFile,BufRead *.pg.sql setlocal ft=sql.pg

  "  Shortcuts
  "-----------------------------------------------
  autocmd FileType js call s:shortcut.async_call('javascript')
  autocmd FileType jsx call s:shortcut.async_call('javascript.jsx')
  autocmd FileType ts call s:shortcut.async_call('typescript')
  autocmd FileType tsx call s:shortcut.async_call('typescript.tsx')
  autocmd FileType md call s:shortcut.async_call('markdown')
  autocmd FileType bq call s:shortcut.async_call('sql.bq')
  autocmd FileType pg call s:shortcut.async_call('sql.pg')
augroup END
