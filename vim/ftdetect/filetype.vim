augroup custom_filetypes
  autocmd!

  "  Remap
  "-----------------------------------------------
  autocmd BufNewFile,BufRead *.er  setf conf
  autocmd BufNewFile,BufRead *.m   setf objc
  autocmd BufNewFile,BufRead *.md  setf markdown
  autocmd BufNewFile,BufRead *.pde setf processing

  autocmd FileType objcpp setf objc


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
  autocmd BufNewFile,BufRead *_spec.rb setlocal ft=ruby.rspec


  "  Shortcuts
  "-----------------------------------------------
  autocmd FileType js setlocal ft=javascript
  autocmd FileType ts setlocal ft=typescript
  autocmd FileType cf setlocal ft=coffee
  autocmd FileType md setlocal ft=markdown


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
