if exists('b:current_syntax')
  let s:current_syntax=b:current_syntax
  unlet b:current_syntax
endif

syn match myTypescriptType /\<\([A-Z][a-z0-9]*_\?\)\+\>/
hi link myTypescriptType Type

runtime! syntax/styledcomponents.vim

if exists('s:current_syntax')
  let b:current_syntax=s:current_syntax
endif
