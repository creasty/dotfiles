augroup custom_filetypes
  autocmd!

  "  Remap
  "-----------------------------------------------
  autocmd BufNewFile,BufRead *.m   setf objc
  autocmd BufNewFile,BufRead *.md  setf markdown
  autocmd BufNewFile,BufRead *.pde setf processing

  autocmd FileType objcpp setlocal ft=objc


  "  Fix rails' assets pipeline
  "-----------------------------------------------
  autocmd BufNewFile,BufRead *.scss,*.css.scss setf scss
  autocmd BufNewFile,BufRead *.html.haml       setf haml
  autocmd BufNewFile,BufRead *.html.slim       setf slim
  autocmd BufNewFile,BufRead *.js.coffee       setf coffee

  autocmd FileType scss.css  setlocal ft=scss
  autocmd FileType coffee.js setlocal ft=coffee
  autocmd FileType slim.html setlocal ft=slim
  autocmd FileType haml.html setlocal ft=haml


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
  autocmd BufNewFile,BufRead *_spec.rb setf ruby.rspec


  "  Shortcuts
  "-----------------------------------------------
  autocmd FileType js setlocal ft=javascript
  autocmd FileType cs setlocal ft=coffee
  autocmd FileType md setlocal ft=markdown


  "  Header file
  "-----------------------------------------------
  autocmd BufNewFile,BufRead *.h call s:FTheader()

  func! s:FTheader()
    if match(getline(1, min([line("$"), 200])), '@interface\|@end\|@class\|\#import\|Foundation/') > -1
      setf objc
    elseif exists("c_syntax_for_h")
      setf c
    elseif exists("ch_syntax_for_h")
      setf ch
    else
      setf cpp
    endif
  endfunc

augroup END
