augroup custom_filetypes
  autocmd!

  "  Remap
  "-----------------------------------------------
  autocmd BufNewFile,BufRead *.er  setf conf
  autocmd BufNewFile,BufRead *.m   setf objc
  autocmd BufNewFile,BufRead *.md  setf markdown
  autocmd BufNewFile,BufRead *.pde setf processing


  "  Based on filename or extension
  "-----------------------------------------------
  autocmd BufNewFile,BufRead
    \ *.psgi,*.t,cpanfile
    \ setf perl

  autocmd BufNewFile,BufRead
    \ *.ejs,*.ep,*.erb,*.tt,*.tt2,*.html.erb
    \ setf html

  autocmd BufNewFile,BufRead
    \ Guardfile,Vagrantfile,*.rabl,*.rake
    \ setf ruby


  "  Subtypes
  "-----------------------------------------------
  autocmd BufNewFile,BufRead *_spec.rb setl ft=ruby.rspec
  autocmd BufNewFile,BufRead *.bq.sql setl ft=sql.bq
  autocmd BufNewFile,BufRead *.pg.sql setl ft=sql.pg


  "  Shortcuts
  "-----------------------------------------------
  let s:shortcut = { 'ft': '' }
  func! s:shortcut.call(name) abort
    exec 'setf' self.ft
  endfunc
  func! s:shortcut.async_call(ft) abort
    let self.ft = a:ft
    call timer_start(50, function(s:shortcut.call))
  endfunc

  autocmd FileType js call s:shortcut.async_call('javascript')
  autocmd FileType ts call s:shortcut.async_call('typescript')
  autocmd FileType md call s:shortcut.async_call('markdown')
  autocmd FileType bq call s:shortcut.async_call('sql.bq')
  autocmd FileType pg call s:shortcut.async_call('sql.pg')


  "  Header file
  "-----------------------------------------------
  autocmd BufNewFile,BufRead *.h call s:detect_header_filetype()

  func! s:detect_header_filetype()
    if match(getline(1, min([line('$'), 200])), '@interface\|@end\|@class\|\#import\|Foundation/') > -1
      setf objc
    elseif exists('c_syntax_for_h')
      setf c
    elseif exists('ch_syntax_for_h')
      setf ch
    else
      setf cpp
    endif
  endfunc

augroup END
