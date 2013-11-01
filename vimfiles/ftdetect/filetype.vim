
augroup custom_filetypes
  autocmd!
  autocmd BufNewFile,BufRead *.m         setf objc
  autocmd BufNewFile,BufRead *.h         call s:FTheader()
  autocmd BufNewFile,BufRead *.psgi      setf perl
  autocmd BufNewFile,BufRead *.t         setf perl
  autocmd BufNewFile,BufRead *.ejs       setf html
  autocmd BufNewFile,BufRead *.ep        setf html
  autocmd BufNewFile,BufRead *.pde       setf processing
  autocmd BufNewFile,BufRead *.erb       setf html
  autocmd BufNewFile,BufRead *.tt        setf html
  autocmd BufNewFile,BufRead *.tt2       setf html
  autocmd BufNewFile,BufRead *.scss      setf scss
  autocmd BufNewFile,BufRead *.html.haml setf haml
  autocmd BufNewFile,BufRead *.html.slim setf slim
  autocmd BufNewFile,BufRead *.html.erb  setf html
  autocmd BufNewFile,BufRead *.css.scss  setf scss
  autocmd BufNewFile,BufRead *.js.coffee setf coffee
  autocmd BufNewFile,BufRead Guardfile   setf ruby
  autocmd BufNewFile,BufRead cpanfile    setf perl
  autocmd BufNewFile,BufRead *_spec.rb   setf ruby.rspec

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


