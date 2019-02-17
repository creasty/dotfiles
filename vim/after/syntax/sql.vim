syn case ignore

" Various error conditions.
" syn match   sqlError        ")"                 " Lonely closing paren.
syn match   sqlError        ",\(\_\s*[;)]\)\@=" " Comma before a paren or semicolon.
syn match   sqlError        ",\_\s*\(\<\(asc\|desc\|exists\|for\|from\)\>\)\@="
syn match   sqlError        ",\_\s*\(\<\(group by\|into\|limit\|order\)\>\)\@="
syn match   sqlError        ",\_\s*\(\<\(table\|using\|where\)\>\)\@="

" Special words.
syn keyword sqlSpecial      false null true

" Keywords
syn keyword sqlKeyword      access add before after aggregate as asc authorization
syn keyword sqlKeyword      begin by cache cascade check cluster collate
syn keyword sqlKeyword      collation column compress conflict connect connection
syn keyword sqlKeyword      constraint current cursor database debug decimal declare
syn keyword sqlKeyword      default definer desc each else elsif escape exception
syn keyword sqlKeyword      exclusive explain external file for foreign from function
syn keyword sqlKeyword      group having identified if immediate increment index
syn keyword sqlKeyword      initial inner into is join key left level loop
syn keyword sqlKeyword      maxextents mode modify nocompress nowait object of
syn keyword sqlKeyword      off offline on online option order outer pctfree
syn keyword sqlKeyword      primary privileges procedure public raise references
syn keyword sqlKeyword      referencing release resource return returns returning role row rowid
syn keyword sqlKeyword      rowlabel rownum rows schema session share size
syn keyword sqlKeyword      start security successful synonym then to transaction trigger
syn keyword sqlKeyword      uid user using validate values view virtual whenever
syn keyword sqlKeyword      where with without

" Operators
syn keyword sqlOperator     all and any between case distinct elif else end
syn keyword sqlOperator     exit exists if in intersect is like match matches
syn keyword sqlOperator     minus not or out prior regexp some then union
syn keyword sqlOperator     unique when
syn match   sqlOperator     "||\|:="
syn match   sqlOperator     "=\|<\|>\|+\|-"

" Unknown functions
syn match   sqlUnknownFunc  "\<[0-9a-z_-]\+\ze("

" Comments
syn keyword sqlTodo         contained DEBUG FIXME NOTE TODO XXX
syn region sqlComment       start="/\*"  end="\*/" contains=sqlTodo
syn match  sqlComment       "--.*$" contains=sqlTodo

" Types
syn keyword sqlType         bigint bit blob bool boolean byte char
syn keyword sqlType         clob date datetime dec decimal enum
syn keyword sqlType         float int int8 integer interval jsonb long
syn keyword sqlType         longblob longtext lvarchar mediumblob
syn keyword sqlType         mediumint mediumtext mlslabel money
syn keyword sqlType         multiset nchar number numeric nvarchar
syn keyword sqlType         raw real rowid serial serial8 set
syn keyword sqlType         smallfloat smallint text time
syn keyword sqlType         timestamp tinyblob tinyint tinytext
syn keyword sqlType         varchar varchar2 varray year zone
syn keyword sqlType         int64 array string struct

" Mark correct paren use. Different colors for different purposes.
" syn region  sqlParens       transparent matchgroup=sqlParen start="(" end=")"
" syn match   sqlParenEmpty   "()"
" syn region  sqlParens       transparent matchgroup=sqlParenFunc start="\(\<[0-9a-z_-]\+\)\@<=(" end=")"

hi link sqlError       Error
hi link sqlSpecial     Constant
hi link sqlKeyword     Keyword
hi link sqlOperator    Operator
hi link sqlUnknownFunc Function
hi link sqlType        Type
hi link sqlComment     Comment
hi link sqlTodo        Todo

" hi link sqlParen      Comment
" hi link sqlParenEmpty Constant
" hi link sqlParenFunc  Normal
