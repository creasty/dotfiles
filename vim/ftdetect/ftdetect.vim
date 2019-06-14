let s:shortcut = { 'ft': '' }
function! s:shortcut.call(name) abort
  exec 'setf' self.ft
endfunction
function! s:shortcut.async_call(ft) abort
  let self.ft = a:ft
  call timer_start(50, function(s:shortcut.call))
endfunction

function! s:detect_header_filetype()
  if match(getline(1, min([line('$'), 200])), '@interface\|@end\|@class\|\#import\|Foundation/') > -1
    setf objc
  elseif exists('c_syntax_for_h')
    setf c
  elseif exists('ch_syntax_for_h')
    setf ch
  else
    setf cpp
  endif
endfunction

augroup custom_filetypes
  autocmd!

  autocmd BufNewFile,BufRead *.er  setf conf
  autocmd BufNewFile,BufRead *.m   setf objc
  autocmd BufNewFile,BufRead *.md  setf markdown
  autocmd BufNewFile,BufRead *.pde setf processing

  autocmd BufNewFile,BufRead gitconfig setf toml
  autocmd BufNewFile,BufRead *.psgi,*.t,cpanfile setf perl
  autocmd BufNewFile,BufRead Guardfile,Vagrantfile,*.rake,*.jbuilder setf ruby

  "  Compound filetypes
  "-----------------------------------------------
  autocmd BufNewFile,BufRead *.jsx setf javascript.jsx
  autocmd BufNewFile,BufRead *.tsx setf typescript.tsx
  autocmd BufNewFile,BufRead *_spec.rb setf ruby.rspec
  autocmd BufNewFile,BufRead *.bq.sql setf sql.bq
  autocmd BufNewFile,BufRead *.pg.sql setf sql.pg

  "  Shortcuts
  "-----------------------------------------------
  autocmd FileType js call s:shortcut.async_call('javascript')
  autocmd FileType jsx call s:shortcut.async_call('javascript.jsx')
  autocmd FileType ts call s:shortcut.async_call('typescript')
  autocmd FileType tsx call s:shortcut.async_call('typescript.tsx')
  autocmd FileType md call s:shortcut.async_call('markdown')
  autocmd FileType bq call s:shortcut.async_call('sql.bq')
  autocmd FileType pg call s:shortcut.async_call('sql.pg')

  "  Header file
  "-----------------------------------------------
  autocmd BufNewFile,BufRead *.h call s:detect_header_filetype()
augroup END
