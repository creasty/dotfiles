if exists('did_load_filetypes')
  finish
endif

function! s:setf_delayed(ft) abort
  if exists('s:timer_id')
    call timer_stop(s:timer_id)
  endif
  let s:timer_id = timer_start(50, {-> execute('setf ' . a:ft) })
endfunction

augroup filetypedetect
  autocmd! BufNewFile,BufRead *.er setlocal ft=conf
  autocmd! BufNewFile,BufRead *.graphql setlocal ft=graphql
  autocmd! BufNewFile,BufRead gitconfig setlocal ft=gitconfig
  autocmd! BufNewFile,BufRead .gitattributes setlocal ft=gitattributes.toml
  autocmd! BufNewFile,BufRead Vagrantfile,*.jbuilder setlocal ft=ruby
  autocmd! BufNewFile,BufRead LICENSE,LICENSE.txt set filetype=license
  autocmd! BufNewFile,BufRead *.pbxproj set filetype=pbxproj

  "  Compound filetypes
  "-----------------------------------------------
  autocmd! BufNewFile,BufRead *_spec.rb setlocal ft=ruby.rspec
  autocmd! BufNewFile,BufRead *.bq.sql setlocal ft=sql.bq
  autocmd! BufNewFile,BufRead *.pg.sql setlocal ft=sql.pg

  "  Shortcuts
  "-----------------------------------------------
  autocmd! FileType js call s:setf_delayed('javascript')
  autocmd! FileType jsx call s:setf_delayed('javascriptreact')
  autocmd! FileType ts call s:setf_delayed('typescript')
  autocmd! FileType tsx call s:setf_delayed('typescriptreact')
  autocmd! FileType md call s:setf_delayed('markdown')
  autocmd! FileType bq call s:setf_delayed('sql.bq')
  autocmd! FileType pg call s:setf_delayed('sql.pg')
augroup END
