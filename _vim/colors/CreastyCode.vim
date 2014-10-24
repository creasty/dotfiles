set background=dark
hi clear
syntax reset

let g:colors_name = 'CreastyCode'

if !has('gui_running') && &t_Co != 88 && &t_Co != 256
  exit
endif


"=== Colors
"==============================================================================================
let g:creasty_code_palette = {
  \ 'foreground':  ['a0a0a0', 248],
  \ 'comment':     ['666666', 241],
  \ 'selection':   ['424242', 238],
  \ 'line':        ['2a2a2a', 236],
  \ 'window':      ['262626', 235],
  \ 'background':  ['121212', 232],
  \
  \ 'orange':      ['bc8d6d', 137],
  \
  \ 'red':         ['af7070', 1],
  \ 'green':       ['a3a46f', 2],
  \ 'yellow':      ['ceb481', 3],
  \ 'blue':        ['8397a9', 4],
  \ 'purple':      ['9d91a9', 5],
  \ 'aqua':        ['8aaaa5', 6],
  \
  \ 'dark_red':    ['503131', 9],
  \ 'dark_green':  ['4c4b30', 10],
  \ 'dark_yellow': ['5f5138', 11],
  \ 'dark_blue':   ['39444d', 12],
  \ 'dark_purple': ['47404d', 13],
  \ 'dark_aqua':   ['3c4e4b', 14],
\ }

" use this command to show all cterm codes
" for c in {0..255}; do printf "\e[48;5;%dm %3d \e[0m" $c $c; [ $(($c % 16)) -eq 15 ] && echo; done

" sets the highlighting for the given group
function! CreastyCode(group, fg, bg, attr)
  let options = ''

  if a:fg != ''
    let fg = g:creasty_code_palette[a:fg]
    let options .= ' guifg=#' . fg[0] . ' ctermfg=' . fg[1]
  endif
  if a:bg != ''
    let bg = g:creasty_code_palette[a:bg]
    let options .= ' guibg=#' . bg[0] . ' ctermbg=' . bg[1]
  endif
  if a:attr != ''
    let options .= ' gui=' . a:attr . ' cterm=' . a:attr
  endif

  exec 'hi' a:group options
endfunction


"=== General
"==============================================================================================
call CreastyCode('CursorLineNr', 'comment', 'line', 'none')
call CreastyCode('Directory', 'blue', '', '')
call CreastyCode('Error', 'background', 'red', '')
call CreastyCode('ErrorMsg', 'background', 'red', '')
call CreastyCode('FoldColumn', '', 'background', '')
call CreastyCode('Folded', 'comment', 'background', '')
call CreastyCode('LineNr', 'comment', '', 'none')
call CreastyCode('MatchParen', '', 'selection', '')
call CreastyCode('ModeMsg', 'green', '', '')
call CreastyCode('MoreMsg', 'green', '', '')
call CreastyCode('NonText', 'selection', '', '')
call CreastyCode('Normal', 'foreground', 'background', '')
call CreastyCode('Question', 'green', '', '')
call CreastyCode('Search', 'yellow', 'dark_yellow', 'underline')
call CreastyCode('SpecialKey', 'line', '', '')
call CreastyCode('StatusLine', 'window', 'comment', 'reverse')
call CreastyCode('StatusLineNC', 'window', 'window', '')
call CreastyCode('TabLine', 'window', 'comment', 'reverse')
call CreastyCode('TabLineFill', 'window', 'comment', 'reverse')
call CreastyCode('TabLineSel', 'window', 'foreground', '')
call CreastyCode('VertSplit', 'window', 'window', 'none')
call CreastyCode('Visual', '', 'selection', '')
call CreastyCode('WarningMsg', 'red', '', '')
call CreastyCode('WildMenu', 'background', 'yellow', '')

if version >= 700
  call CreastyCode('CursorColumn', '', 'line', 'none')
  call CreastyCode('CursorLine', '', 'line', 'none')
  call CreastyCode('PMenu', 'foreground', 'selection', 'none')
  call CreastyCode('PMenuSel', 'foreground', 'selection', 'reverse')
  call CreastyCode('SignColumn', '', 'background', 'none')
end

if version >= 703
  call CreastyCode('ColorColumn', '', 'line', 'none')
end


"=== Basic
"==============================================================================================
call CreastyCode('Comment', 'comment', '', '')

call CreastyCode('Boolean', 'orange', '', '')
call CreastyCode('Character', 'yellow', '', '')
call CreastyCode('Constant', 'yellow', '', '')
call CreastyCode('Float', 'orange', '', '')
call CreastyCode('Number', 'orange', '', '')
call CreastyCode('String', 'green', '', '')

call CreastyCode('Function', 'blue', '', '')
call CreastyCode('Identifier', 'blue', '', 'none')

call CreastyCode('Conditional', 'purple', '', '')
call CreastyCode('Exception', 'purple', '', '')
call CreastyCode('Keyword', 'purple', '', '')
call CreastyCode('Label', 'purple', '', '')
call CreastyCode('Operator', 'aqua', '', 'none')
call CreastyCode('Repeat', 'purple', '', '')
call CreastyCode('Statement', 'purple', '', '')

call CreastyCode('Define', 'purple', '', 'none')
call CreastyCode('Include', 'blue', '', '')
call CreastyCode('Macro', 'purple', '', '')
call CreastyCode('PreCondit', 'purple', '', '')
call CreastyCode('PreProc', 'purple', '', '')

call CreastyCode('StorageClass', 'purple', '', '')
call CreastyCode('Structure', 'purple', '', '')
call CreastyCode('Type', 'yellow', '', 'none')
call CreastyCode('Typedef', 'purple', '', '')

call CreastyCode('Folded', 'comment', '', 'underline')
call CreastyCode('Special', 'foreground', '', '')
call CreastyCode('SpecialChar', 'purple', '', '')
call CreastyCode('SpecialComment', 'green', '', '')
call CreastyCode('Title', 'foreground', '', '')
call CreastyCode('Todo', 'background', 'comment', '')


"=== vim
"==============================================================================================
call CreastyCode('vimCommand', 'red', '', 'none')


"=== c
"==============================================================================================
call CreastyCode('cStorageClass', 'purple', '', '')


"=== objc
"==============================================================================================
call CreastyCode('cocoaClass', 'yellow', '', '')
call CreastyCode('objcConstant', 'yellow', '', '')
call CreastyCode('objcDirective', 'aqua', '', '')
call CreastyCode('objcMethodColon', 'red', '', '')
call CreastyCode('objcObjDef', 'purple', '', '')
call CreastyCode('objcProtocolList', 'aqua', '', '')
call CreastyCode('objcSubclass', 'yellow', '', '')
call CreastyCode('objcSuperclass', 'yellow', '', '')


"=== php
"==============================================================================================
call CreastyCode('phpMemberSelector', 'foreground', '', '')
call CreastyCode('phpVarSelector', 'red', '', '')


"=== ruby
"==============================================================================================
call CreastyCode('rubyAttribute', 'foreground', '', '')
call CreastyCode('rubyConstant', 'yellow', '', '')
call CreastyCode('rubyCurlyBlock', 'foreground', '', '')
call CreastyCode('rubyLocalVariableOrMethod', 'blue', '', '')
call CreastyCode('rubyRegexp', 'aqua', '', '')
call CreastyCode('rubyRegexpAnchor', 'dark_aqua', '', '')
call CreastyCode('rubyRegexpCharClass', 'aqua', '', '')
call CreastyCode('rubyRegexpDelimiter', 'aqua', '', '')
call CreastyCode('rubyRegexpDot', 'dark_aqua', '', '')
call CreastyCode('rubyRegexpEscape', 'dark_aqua', '', '')
call CreastyCode('rubyRegexpSpecial', 'aqua', '', '')
call CreastyCode('rubyStringDelimiter', 'green', '', '')
call CreastyCode('rubySymbol', 'red', '', '')


"=== coffee
"==============================================================================================
call CreastyCode('coffeeCurlies', 'foreground', '', '')
call CreastyCode('coffeeObjAssign', 'red', '', '')
call CreastyCode('coffeeObject', 'yellow', '', '')


"=== javascript
"==============================================================================================
call CreastyCode('javaScriptBraces', 'foreground', '', '')
call CreastyCode('javaScriptFunction', 'purple', '', '')
call CreastyCode('javaScriptMember', 'foreground', '', '')
call CreastyCode('javaScriptNumber', 'orange', '', '')
call CreastyCode('javaScriptSpecial', 'purple', '', '')


"=== css
"==============================================================================================
call CreastyCode('cssAttr', 'red', '', '')
call CreastyCode('cssAttributeSelector', 'purple', '', '')
call CreastyCode('cssBraces', 'foreground', '', '')
call CreastyCode('cssClassName', 'blue', '', '')
call CreastyCode('cssColor', 'orange', '', '')
call CreastyCode('cssFunctionName', 'aqua', '', '')
call CreastyCode('cssIdentifier', 'red', '', '')
call CreastyCode('cssImportant', 'red', '', '')
call CreastyCode('cssProp', 'red', '', '')
call CreastyCode('cssUnitDecorators', 'foreground', '', '')


"=== scss
"==============================================================================================
call CreastyCode('scssElseIf', 'purple', '', '')
call CreastyCode('scssFor', 'purple', '', '')


"=== html
"==============================================================================================
call CreastyCode('htmlArg', 'red', '', '')
call CreastyCode('htmlEndTag', 'comment', '', '')
call CreastyCode('htmlLink', 'blue', '', 'underline')
call CreastyCode('htmlScriptTag', 'comment', '', '')
call CreastyCode('htmlSpecialTagName', 'orange', '', '')
call CreastyCode('htmlTag', 'comment', '', '')
call CreastyCode('htmlTagN', 'orange', '', '')
call CreastyCode('htmlTagName', 'orange', '', '')


"=== xml
"==============================================================================================
call CreastyCode('xmlAttrib', 'red', '', '')
call CreastyCode('xmlEndTag', 'comment', '', '')
call CreastyCode('xmlEqual', 'comment', '', '')
call CreastyCode('xmlTag', 'comment', '', '')
call CreastyCode('xmlTagName', 'orange', '', '')


"=== markdown
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
call CreastyCode('markdownUrl', 'comment', '', '')


"=== diff
"==============================================================================================
call CreastyCode('diffAdded', 'green', 'dark_green', '')
call CreastyCode('diffRemoved', 'red', 'dark_red', '')
