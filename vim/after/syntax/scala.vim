syn match myScalaType /\<\([A-Z][a-z0-9]*_\?\)\+\>/
hi link myScalaType Type

hi link scalaInstanceDeclaration Type
hi link scalaSpecial Operator

syn keyword scalaSpecialFunction this import ne eq to until
hi link scalaSpecialFunction Function

syn clear scalaTypeStatement
syn keyword scalaKeyword type package
syn keyword scalaKeyword private protected public abstract override

syn keyword scalaBoolean true false
hi link scalaBoolean Constant

syn keyword scalaNull null
hi link scalaNull Number
