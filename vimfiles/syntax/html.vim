
syn include @leafJsTop syntax/javascript.vim
unlet b:current_syntax

syn region leafInterpolation matchgroup=leafInterpolationDelimiter start='{{' end='}}' contains=@leafJsTop containedin=ALLBUT,htmlString,htmlArg,htmlValue

syn keyword htmlTagName contained outlet render component if elseif else each collection

syn match leafHtmlArg '\(\(\$\|@\)[\-a-z]\+\)\=\>' containedin=htmlTag

hi def link leafHtmlArg Identifier
hi def link leafInterpolationDelimiter Structure

