if exists('b:current_syntax') && b:current_syntax == 'swift'
  finish
endif

let b:current_syntax = 'swift'


"=== Operators
"==============================================================================================
syn match swiftOperator "->\|-\|+\|\*\|/\|=\|&\|%=\|!\|\~\|\.\|?\|\^\|<\|>\|:"
hi link swiftOperator Operator


"=== Comments
"==============================================================================================
syn region swiftComment start=#\/\*# end=#\*\/#
syn match swiftComment /\/\/.*$/
hi link swiftComment Comment


"=== Marks
"==============================================================================================
syn match swiftMark /@[a-zA-Z_][a-zA-Z_0-9]*/
hi link swiftMark Operator


"=== Functions
"==============================================================================================
syn keyword swiftFuncKeyword func contained
syn match swiftFuncIdentifer /\<[a-zA-Z_][a-zA-Z_0-9]*\>/ contained

syn match swiftFuncDef /\<func\>\_[^{]*\ze{/ contains=swiftFuncKeyword,swiftFuncIdentifer,swiftType nextgroup=swiftFuncBody
syn match swiftSpecialFuncDef /\<\%(init\|deinit\|subscript\)\>\_[^{]*\ze{/ contains=swiftFuncIdentifer nextgroup=swiftFuncBody

syn region swiftFuncBody matchgroup=swiftFuncBody start="{" end="}" contained contains=TOP fold
syn region swiftFuncArgs matchgroup=swiftFuncArgs start="(" end=")" contained containedin=swiftFuncDef contains=TOP transparent

hi link swiftFuncKeyword Keyword
hi link swiftFuncIdentifer Identifier


"=== Keywords
"==============================================================================================
syn keyword swiftKeyword class convenience deinit enum extension import init let protocol static struct subscript typealias var
syn keyword swiftKeyword break case continue default do else fallthrough if in for return switch where while
syn keyword swiftKeyword as dynamicType is new super self Self Type
syn keyword swiftKeyword associativity didSet get infix inout left mutating none nonmutating operator override postfix precedence prefix right set unowned unowned(safe) unowned(unsafe) weak willSet
syn keyword swiftKeyword public private internal
hi link swiftKeyword Keyword

syn keyword swiftBoolean true false
hi link swiftBoolean Boolean

syn keyword swiftConstant nil __COLUMN__ __FILE__ __FUNCTION__ __LINE__
hi link swiftNil Constant


"=== Literals
"==============================================================================================
syn match swiftIntegerLiteral /\<[0-9_]\+\>/
syn match swiftIntegerLiteral /\<0x[0-9a-fA-F\._]\+\>/
syn match swiftIntegerLiteral /\<0o[0-7_]\+\>/
syn match swiftIntegerLiteral /\<0b[01_]\+\>/
hi link swiftIntegerLiteral Number

syn region swiftStringLiteral start=/"/ skip=/\\"/ end=/"/ contains=swiftInterpolatedWrapper
syn region swiftInterpolatedWrapper start="\v\\\(\s*" end="\v\s*\)" contained containedin=swiftStringLiteral contains=TOP
hi link swiftStringLiteral String


"=== Type
"==============================================================================================
syn match swiftType /\<\([A-Z][a-z0-9]*_\?\)\+\>/
hi link swiftType Type
