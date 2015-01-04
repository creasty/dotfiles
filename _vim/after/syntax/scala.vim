syn match myScalaType /\<\([A-Z][a-z0-9]*_\?\)\+\>/
hi link myScalaType Type

syn clear scalaTypeStatement
syn keyword scalaKeyword type null
