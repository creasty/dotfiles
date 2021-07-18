if exists('did_load_filetypes')
  finish
endif

let s:shortcut = { 'ft': '', 'timer': -1 }
function! s:shortcut.call(...) abort
  exec 'setf' self.ft
endfunction
function! s:shortcut.async_call(ft) abort
  let self.ft = a:ft
  if self.timer >= 0
    call timer_stop(self.timer)
  endif
  let self.timer = timer_start(50, function(self.call))
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
  autocmd! FileType js call s:shortcut.async_call('javascript')
  autocmd! FileType jsx call s:shortcut.async_call('javascriptreact')
  autocmd! FileType ts call s:shortcut.async_call('typescript')
  autocmd! FileType tsx call s:shortcut.async_call('typescriptreact')
  autocmd! FileType md call s:shortcut.async_call('markdown')
  autocmd! FileType bq call s:shortcut.async_call('sql.bq')
  autocmd! FileType pg call s:shortcut.async_call('sql.pg')
augroup END
