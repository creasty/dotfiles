set background=dark
hi clear
syntax reset

let g:colors_name = 'CreastyCode'

if !has('gui_running') && &t_Co != 88 && &t_Co != 256
  exit
endif


"=== Color palette
"==============================================================================================
let g:creasty_code_palette = {
  \ 'foreground':  ['a0a0a0', 248],
  \ 'comment':     ['666666', 241],
  \ 'selection':   ['424242', 238],
  \ 'line':        ['2a2a2a', 236],
  \ 'window':      ['262626', 235],
  \ 'background':  ['121212', 232],
  \
  \ 'orange':      ['bb8d6f', 137],
  \
  \ 'red':         ['ae7071', 1],
  \ 'green':       ['a3a371', 2],
  \ 'yellow':      ['cdb384', 3],
  \ 'blue':        ['8397a8', 4],
  \ 'purple':      ['9d90a8', 5],
  \ 'aqua':        ['8baaa5', 6],
  \
  \ 'dark_red':    ['503131', 9],
  \ 'dark_green':  ['4c4b30', 10],
  \ 'dark_yellow': ['5f5138', 11],
  \ 'dark_blue':   ['39444d', 12],
  \ 'dark_purple': ['47404d', 13],
  \ 'dark_aqua':   ['3c4e4b', 14],
\ }

" use this command to show all cterm codes
" for c in {000..255}; do echo -n "\e[38;5;${c}m ■$c"; [ $(($c % 16)) -eq 15 ] && echo; done; echo

" sets the highlighting for the given group
fun! CreastyCode(group, fg, bg, attr)
  if a:fg != ''
    exec 'hi ' . a:group . ' guifg=#' . g:creasty_code_palette[a:fg][0] . ' ctermfg=' . g:creasty_code_palette[a:fg][1]
  endif
  if a:bg != ''
    exec 'hi ' . a:group . ' guibg=#' . g:creasty_code_palette[a:bg][0] . ' ctermbg=' . g:creasty_code_palette[a:bg][1]
  endif
  if a:attr != ''
    exec 'hi ' . a:group . ' gui=' . a:attr . ' cterm=' . a:attr
  endif
endfun


"=== Highlighting: Vim
"==============================================================================================
call CreastyCode('Normal', 'foreground', 'background', '')
call CreastyCode('LineNr', 'comment', '', 'none')
call CreastyCode('CursorLineNr', 'comment', 'line', 'none')
call CreastyCode('NonText', 'selection', '', '')
call CreastyCode('SpecialKey', 'line', '', '')
call CreastyCode('Search', 'yellow', 'dark_yellow', 'underline')
call CreastyCode('TabLine', 'window', 'comment', 'reverse')
call CreastyCode('TabLineFill', 'window', 'comment', 'reverse')
call CreastyCode('TabLineSel', 'window', 'foreground', '')
call CreastyCode('StatusLine', 'window', 'comment', 'reverse')
call CreastyCode('StatusLineNC', 'window', 'window', '')
call CreastyCode('VertSplit', 'window', 'window', 'none')
call CreastyCode('Visual', '', 'selection', '')
call CreastyCode('Directory', 'blue', '', '')
call CreastyCode('ModeMsg', 'green', '', '')
call CreastyCode('MoreMsg', 'green', '', '')
call CreastyCode('Question', 'green', '', '')
call CreastyCode('ErrorMsg', 'background', 'red', '')
call CreastyCode('Error', 'background', 'red', '')
call CreastyCode('WarningMsg', 'red', '', '')
call CreastyCode('MatchParen', '', 'selection', '')
call CreastyCode('Folded', 'comment', 'background', '')
call CreastyCode('FoldColumn', '', 'background', '')
call CreastyCode('WildMenu', 'background', 'yellow', '')

if version >= 700
  call CreastyCode('CursorColumn', '', 'line', 'none')
  call CreastyCode('PMenu', 'foreground', 'selection', 'none')
  call CreastyCode('PMenuSel', 'foreground', 'selection', 'reverse')
  call CreastyCode('CursorLine', '', 'line', 'none')
  call CreastyCode('SignColumn', '', 'background', 'none')
end

if version >= 703
  call CreastyCode('ColorColumn', '', 'line', 'none')
end


"=== Highlighting: Standard
"==============================================================================================
call CreastyCode('Comment', 'comment', '', '')

call CreastyCode('Constant', 'yellow', '', '')
call CreastyCode('String', 'green', '', '')
call CreastyCode('Character', 'yellow', '', '')
call CreastyCode('Number', 'orange', '', '')
call CreastyCode('Boolean', 'orange', '', '')
call CreastyCode('Float', 'orange', '', '')

call CreastyCode('Identifier', 'blue', '', 'none')
call CreastyCode('Function', 'blue', '', '')

call CreastyCode('Statement', 'purple', '', '')
call CreastyCode('Conditional', 'purple', '', '')
call CreastyCode('Repeat', 'purple', '', '')
call CreastyCode('Label', 'purple', '', '')
call CreastyCode('Operator', 'aqua', '', 'none')
call CreastyCode('Keyword', 'purple', '', '')
call CreastyCode('Exception', 'purple', '', '')

call CreastyCode('PreProc', 'purple', '', '')
call CreastyCode('Include', 'blue', '', '')
call CreastyCode('Define', 'purple', '', 'none')
call CreastyCode('Macro', 'purple', '', '')
call CreastyCode('PreCondit', 'purple', '', '')

call CreastyCode('Type', 'yellow', '', 'none')
call CreastyCode('Structure', 'purple', '', '')
call CreastyCode('StorageClass', 'purple', '', '')
call CreastyCode('Typedef', 'purple', '', '')

call CreastyCode('Special', 'foreground', '', '')
call CreastyCode('SpecialComment', 'green', '', '')
call CreastyCode('Todo', 'background', 'comment', '')
call CreastyCode('Title', 'foreground', '', '')
call CreastyCode('Folded', 'comment', '', 'underline')


"=== Highlighting: VimScript
"==============================================================================================
call CreastyCode('vimCommand', 'red', '', 'none')
call CreastyCode('vimCommentTitle', 'green', '', '')


"=== Highlighting: C
"==============================================================================================
call CreastyCode('cConditional', 'purple', '', '')
call CreastyCode('cDefine', 'purple', '', '')
call CreastyCode('cFloat', 'orange', '', '')
call CreastyCode('cInclude', 'purple', '', '')
call CreastyCode('cNumber', 'orange', '', '')
call CreastyCode('cRepeat', 'purple', '', '')
call CreastyCode('cSpecial', 'purple', '', '')
call CreastyCode('cStatement', 'purple', '', '')
call CreastyCode('cStorageClass', 'purple', '', '')
call CreastyCode('cType', 'yellow', '', '')


"=== Highlighting: Objective-C
"==============================================================================================
call CreastyCode('cocoaClass', 'yellow', '', '')
call CreastyCode('objcConstant', 'yellow', '', '')
call CreastyCode('objcDirective', 'aqua', '', '')
call CreastyCode('objcImport', 'purple', '', '')
call CreastyCode('objcMethodColon', 'red', '', '')
call CreastyCode('objcObjDef', 'purple', '', '')
call CreastyCode('objcProtocolList', 'aqua', '', '')
call CreastyCode('objcSubclass', 'yellow', '', '')
call CreastyCode('objcSuperclass', 'yellow', '', '')


"=== Highlighting: PHP
"==============================================================================================
call CreastyCode('phpConditional', 'purple', '', '')
call CreastyCode('phpKeyword', 'purple', '', '')
call CreastyCode('phpMemberSelector', 'foreground', '', '')
call CreastyCode('phpRepeat', 'purple', '', '')
call CreastyCode('phpStatement', 'purple', '', '')
call CreastyCode('phpVarSelector', 'red', '', '')


"=== Highlighting: Ruby
"==============================================================================================
call CreastyCode('rubyAccess', 'purple', '', '')
call CreastyCode('rubyAttribute', 'foreground', '', '')
call CreastyCode('rubyBoolean', 'orange', '', '')
call CreastyCode('rubyConditional', 'purple', '', '')
call CreastyCode('rubyConstant', 'yellow', '', '')
call CreastyCode('rubyControl', 'purple', '', '')
call CreastyCode('rubyCurlyBlock', 'foreground', '', '')
call CreastyCode('rubyInclude', 'blue', '', '')
call CreastyCode('rubyInteger', 'orange', '', '')
call CreastyCode('rubyInterpolationDelimiter', 'purple', '', '')
call CreastyCode('rubyKeyword', 'purple', '', '')
call CreastyCode('rubyLocalVariableOrMethod', 'blue', '', '')
call CreastyCode('rubyRegexp', 'aqua', '', '')
call CreastyCode('rubyRegexpAnchor', 'green', '', '')
call CreastyCode('rubyRegexpDelimiter', 'aqua', '', '')
call CreastyCode('rubyRepeat', 'purple', '', '')
call CreastyCode('rubyStringDelimiter', 'green', '', '')
call CreastyCode('rubySymbol', 'red', '', '')


"=== Highlighting: Python
"==============================================================================================
call CreastyCode('pythonConditional', 'purple', '', '')
call CreastyCode('pythonException', 'purple', '', '')
call CreastyCode('pythonFunction', 'blue', '', '')
call CreastyCode('pythonInclude', 'purple', '', '')
call CreastyCode('pythonRepeat', 'purple', '', '')
call CreastyCode('pythonStatement', 'purple', '', '')


"=== Highlighting: CoffeeScript
"==============================================================================================
call CreastyCode('coffeeBoolean', 'orange', '', '')
call CreastyCode('coffeeConditional', 'purple', '', '')
call CreastyCode('coffeeEscape', 'purple', '', '')
call CreastyCode('coffeeException', 'purple', '', '')
call CreastyCode('coffeeKeyword', 'purple', '', '')
call CreastyCode('coffeeNumber', 'orange', '', '')
call CreastyCode('coffeeObjAssign', 'red', '', '')
call CreastyCode('coffeeObject', 'yellow', '', '')
call CreastyCode('coffeeRepeat', 'purple', '', '')
call CreastyCode('coffeeStatement', 'purple', '', '')


"=== Highlighting: JavaScript
"==============================================================================================
call CreastyCode('javaScriptBoolean', 'orange', '', '')
call CreastyCode('javaScriptBraces', 'foreground', '', '')
call CreastyCode('javaScriptConditional', 'purple', '', '')
call CreastyCode('javaScriptFunction', 'purple', '', '')
call CreastyCode('javaScriptMember', 'foreground', '', '')
call CreastyCode('javaScriptNumber', 'orange', '', '')
call CreastyCode('javaScriptRepeat', 'purple', '', '')
call CreastyCode('javaScriptSpecial', 'purple', '', '')
call CreastyCode('javaScriptStatement', 'purple', '', '')


"=== Highlighting: CSS
"==============================================================================================
call CreastyCode('cssAttributeSelector', 'purple', '', '')
call CreastyCode('cssBackgroundProp', 'red', '', '')
call CreastyCode('cssBorderProp', 'red', '', '')
call CreastyCode('cssBoxProp', 'red', '', '')
call CreastyCode('cssBraces', 'foreground', '', '')
call CreastyCode('cssClassName', 'blue', '', '')
call CreastyCode('cssColor', 'orange', '', '')
call CreastyCode('cssColorProp', 'red', '', '')
call CreastyCode('cssDimensionProp', 'red', '', '')
call CreastyCode('cssFlexibleBoxProp', 'red', '', '')
call CreastyCode('cssFontProp', 'red', '', '')
call CreastyCode('cssFunctionName', 'aqua', '', '')
call CreastyCode('cssIdentifier', 'red', '', '')
call CreastyCode('cssImportant', 'red', '', '')
call CreastyCode('cssListProp', 'red', '', '')
call CreastyCode('cssPageProp', 'red', '', '')
call CreastyCode('cssPositioningAttr', 'red', '', '')
call CreastyCode('cssPositioningProp', 'red', '', '')
call CreastyCode('cssTextProp', 'red', '', '')
call CreastyCode('cssTransformProp', 'red', '', '')
call CreastyCode('cssTransitionProp', 'red', '', '')
call CreastyCode('cssUIAttr', 'red', '', '')
call CreastyCode('cssUIProp', 'red', '', '')
call CreastyCode('cssUnitDecorators', 'foreground', '', '')
call CreastyCode('cssValueAngle', 'orange', '', '')
call CreastyCode('cssValueLength', 'orange', '', '')
call CreastyCode('cssValueNumber', 'orange', '', '')
call CreastyCode('cssValueTime', 'orange', '', '')


"=== Highlighting: SCSS
"==============================================================================================
call CreastyCode('scssElse', 'purple', '', '')
call CreastyCode('scssElseIf', 'purple', '', '')
call CreastyCode('scssFor', 'purple', '', '')
call CreastyCode('scssIf', 'purple', '', '')
call CreastyCode('scssReturn', 'purple', '', '')


"=== Highlighting: HTML
"==============================================================================================
call CreastyCode('htmlArg', 'red', '', '')
call CreastyCode('htmlEndTag', 'comment', '', '')
call CreastyCode('htmlH1', 'foreground', '', '')
call CreastyCode('htmlH2', 'foreground', '', '')
call CreastyCode('htmlH3', 'foreground', '', '')
call CreastyCode('htmlH4', 'foreground', '', '')
call CreastyCode('htmlH5', 'foreground', '', '')
call CreastyCode('htmlH6', 'foreground', '', '')
call CreastyCode('htmlLink', 'blue', '', 'underline')
call CreastyCode('htmlScriptTag', 'comment', '', '')
call CreastyCode('htmlSpecialTagName', 'orange', '', '')
call CreastyCode('htmlTag', 'comment', '', '')
call CreastyCode('htmlTagN', 'orange', '', '')
call CreastyCode('htmlTagName', 'orange', '', '')
call CreastyCode('htmlTitle', 'foreground', '', '')


"=== Highlighting: XML
"==============================================================================================
call CreastyCode('xmlAttrib', 'red', '', '')
call CreastyCode('xmlEndTag', 'comment', '', '')
call CreastyCode('xmlEqual', 'comment', '', '')
call CreastyCode('xmlTag', 'comment', '', '')
call CreastyCode('xmlTagName', 'orange', '', '')


"=== Highlighting: Markdown
"==============================================================================================
call CreastyCode('markdownBold', 'red', '', '')
call CreastyCode('markdownCode', 'green', '', '')
call CreastyCode('markdownCodeBlock', 'green', '', '')
call CreastyCode('markdownH1', 'purple', '', '')
call CreastyCode('markdownH2', 'purple', '', '')
call CreastyCode('markdownH3', 'purple', '', '')
call CreastyCode('markdownH4', 'purple', '', '')
call CreastyCode('markdownH5', 'purple', '', '')
call CreastyCode('markdownH6', 'purple', '', '')
call CreastyCode('markdownHeadingDelimiter', 'purple', '', '')
call CreastyCode('markdownItalic', 'red', '', '')
call CreastyCode('markdownLineBreak', '', 'blue', '')
call CreastyCode('markdownListMarker', 'orange', '', '')
call CreastyCode('markdownOrderedListMarker', 'orange', '', '')
call CreastyCode('markdownUrl', 'comment', '', '')


"=== Highlighting: Diff
"==============================================================================================
call CreastyCode('diffAdded', 'green', 'dark_green', '')
call CreastyCode('diffRemoved', 'red', 'dark_red', '')

