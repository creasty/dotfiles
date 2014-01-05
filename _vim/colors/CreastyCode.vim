
set background=dark
hi clear
syntax reset

let g:colors_name = 'CreastyCode'

if !has('gui_running') && &t_Co != 88 && &t_Co != 256
  exit
endif


"-------------------------------------------------------------------------------
" Utils
"-------------------------------------------------------------------------------
" Returns an approximate grey index for the given grey level
fun! <SID>grey_number(x)
  if &t_Co == 88
    if a:x < 23
      return 0
    elseif a:x < 69
      return 1
    elseif a:x < 103
      return 2
    elseif a:x < 127
      return 3
    elseif a:x < 150
      return 4
    elseif a:x < 173
      return 5
    elseif a:x < 196
      return 6
    elseif a:x < 219
      return 7
    elseif a:x < 243
      return 8
    else
      return 9
    endif
  else
    if a:x < 14
      return 0
    else
      let l:n = (a:x - 8) / 10
      let l:m = (a:x - 8) % 10
      if l:m < 5
        return l:n
      else
        return l:n + 1
      endif
    endif
  endif
endfun

" Returns the actual grey level represented by the grey index
fun! <SID>grey_level(n)
  if &t_Co == 88
    if a:n == 0
      return 0
    elseif a:n == 1
      return 46
    elseif a:n == 2
      return 92
    elseif a:n == 3
      return 115
    elseif a:n == 4
      return 139
    elseif a:n == 5
      return 162
    elseif a:n == 6
      return 185
    elseif a:n == 7
      return 208
    elseif a:n == 8
      return 231
    else
      return 255
    endif
  else
    if a:n == 0
      return 0
    else
      return 8 + (a:n * 10)
    endif
  endif
endfun

" Returns the palette index for the given grey index
fun! <SID>grey_colour(n)
  if &t_Co == 88
    if a:n == 0
      return 16
    elseif a:n == 9
      return 79
    else
      return 79 + a:n
    endif
  else
    if a:n == 0
      return 16
    elseif a:n == 25
      return 231
    else
      return 231 + a:n
    endif
  endif
endfun

" Returns an approximate colour index for the given colour level
fun! <SID>rgb_number(x)
  if &t_Co == 88
    if a:x < 69
      return 0
    elseif a:x < 172
      return 1
    elseif a:x < 230
      return 2
    else
      return 3
    endif
  else
    if a:x < 75
      return 0
    else
      let l:n = (a:x - 55) / 40
      let l:m = (a:x - 55) % 40
      if l:m < 20
        return l:n
      else
        return l:n + 1
      endif
    endif
  endif
endfun

" Returns the actual colour level for the given colour index
fun! <SID>rgb_level(n)
  if &t_Co == 88
    if a:n == 0
      return 0
    elseif a:n == 1
      return 139
    elseif a:n == 2
      return 205
    else
      return 255
    endif
  else
    if a:n == 0
      return 0
    else
      return 55 + (a:n * 40)
    endif
  endif
endfun

" Returns the palette index for the given R/G/B colour indices
fun! <SID>rgb_colour(x, y, z)
  if &t_Co == 88
    return 16 + (a:x * 16) + (a:y * 4) + a:z
  else
    return 16 + (a:x * 36) + (a:y * 6) + a:z
  endif
endfun

" Returns the palette index to approximate the given R/G/B colour levels
fun! <SID>colour(r, g, b)
  " Get the closest grey
  let l:gx = <SID>grey_number(a:r)
  let l:gy = <SID>grey_number(a:g)
  let l:gz = <SID>grey_number(a:b)

  " Get the closest colour
  let l:x = <SID>rgb_number(a:r)
  let l:y = <SID>rgb_number(a:g)
  let l:z = <SID>rgb_number(a:b)

  if l:gx == l:gy && l:gy == l:gz
    " There are two possibilities
    let l:dgr = <SID>grey_level(l:gx) - a:r
    let l:dgg = <SID>grey_level(l:gy) - a:g
    let l:dgb = <SID>grey_level(l:gz) - a:b
    let l:dgrey = (l:dgr * l:dgr) + (l:dgg * l:dgg) + (l:dgb * l:dgb)
    let l:dr = <SID>rgb_level(l:gx) - a:r
    let l:dg = <SID>rgb_level(l:gy) - a:g
    let l:db = <SID>rgb_level(l:gz) - a:b
    let l:drgb = (l:dr * l:dr) + (l:dg * l:dg) + (l:db * l:db)
    if l:dgrey < l:drgb
      " Use the grey
      return <SID>grey_colour(l:gx)
    else
      " Use the colour
      return <SID>rgb_colour(l:x, l:y, l:z)
    endif
  else
    " Only one possibility
    return <SID>rgb_colour(l:x, l:y, l:z)
  endif
endfun

" Returns the palette index to approximate the 'rrggbb' hex string
fun! <SID>rgb(rgb)
  let l:r = ('0x' . strpart(a:rgb, 0, 2)) + 0
  let l:g = ('0x' . strpart(a:rgb, 2, 2)) + 0
  let l:b = ('0x' . strpart(a:rgb, 4, 2)) + 0

  return <SID>colour(l:r, l:g, l:b)
endfun

" Sets the highlighting for the given group
fun! CreastyCode(group, fg, bg, attr)
  let p = g:creasty_code_palette

  if a:fg != ''
    exec 'hi ' . a:group . ' guifg=#' . p[a:fg] . ' ctermfg=' . <SID>rgb(p[a:fg])
  endif
  if a:bg != ''
    exec 'hi ' . a:group . ' guibg=#' . p[a:bg] . ' ctermbg=' . <SID>rgb(p[a:bg])
  endif
  if a:attr != ''
    exec 'hi ' . a:group . ' gui=' . a:attr . ' cterm=' . a:attr
  endif
endfun


"-------------------------------------------------------------------------------
" Color palette
"-------------------------------------------------------------------------------
let g:creasty_code_palette = {
  \ 'foreground': 'b8b8b8',
  \ 'background': '000000',
  \ 'selection':  '424242',
  \ 'line':       '2a2a2a',
  \ 'comment':    '666666',
  \ 'red':        'cc6666',
  \ 'orange':     'de935f',
  \ 'yellow':     'f0c674',
  \ 'green':      'b5bd68',
  \ 'aqua':       '8abeb7',
  \ 'blue':       '81a2be',
  \ 'purple':     'b294bb',
  \ 'window':     '262626',
\ }


"-------------------------------------------------------------------------------
" Highlighting: Vim
"-------------------------------------------------------------------------------
call CreastyCode('Normal', 'foreground', 'background', '')
call CreastyCode('LineNr', 'comment', '', 'none')
call CreastyCode('CursorLineNr', 'comment', 'line', 'none')
call CreastyCode('NonText', 'selection', '', '')
call CreastyCode('SpecialKey', 'line', '', '')
call CreastyCode('Search', 'background', 'yellow', '')
call CreastyCode('TabLine', 'foreground', 'background', 'reverse')
call CreastyCode('StatusLine', 'window', 'yellow', 'reverse')
call CreastyCode('StatusLineNC', 'window', 'foreground', 'reverse')
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


"-------------------------------------------------------------------------------
" Highlighting: Standard
"-------------------------------------------------------------------------------
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


"-------------------------------------------------------------------------------
" Highlighting: VimScript
"-------------------------------------------------------------------------------
call CreastyCode('vimCommand', 'red', '', 'none')
call CreastyCode('vimCommentTitle', 'green', '', '')


"-------------------------------------------------------------------------------
" Highlighting: C
"-------------------------------------------------------------------------------
call CreastyCode('cType', 'yellow', '', '')
call CreastyCode('cStorageClass', 'purple', '', '')
call CreastyCode('cConditional', 'purple', '', '')
call CreastyCode('cRepeat', 'purple', '', '')
call CreastyCode('cSpecial', 'purple', '', '')
call CreastyCode('cStatement', 'purple', '', '')
call CreastyCode('cDefine', 'purple', '', '')
call CreastyCode('cInclude', 'purple', '', '')
call CreastyCode('cNumber', 'orange', '', '')
call CreastyCode('cFloat', 'orange', '', '')


"-------------------------------------------------------------------------------
" Highlighting: Objective-C
"-------------------------------------------------------------------------------
call CreastyCode('cocoaClass', 'yellow', '', '')
call CreastyCode('objcSubclass', 'yellow', '', '')
call CreastyCode('objcMethodColon', 'red', '', '')
call CreastyCode('objcObjDef', 'purple', '', '')
call CreastyCode('objcImport', 'purple', '', '')
call CreastyCode('objcConstant', 'yellow', '', '')
call CreastyCode('objcSuperclass', 'yellow', '', '')
call CreastyCode('objcProtocolList', 'aqua', '', '')
call CreastyCode('objcDirective', 'aqua', '', '')


"-------------------------------------------------------------------------------
" Highlighting: PHP
"-------------------------------------------------------------------------------
call CreastyCode('phpVarSelector', 'red', '', '')
call CreastyCode('phpKeyword', 'purple', '', '')
call CreastyCode('phpRepeat', 'purple', '', '')
call CreastyCode('phpConditional', 'purple', '', '')
call CreastyCode('phpStatement', 'purple', '', '')
call CreastyCode('phpMemberSelector', 'foreground', '', '')


"-------------------------------------------------------------------------------
" Highlighting: Ruby
"-------------------------------------------------------------------------------
call CreastyCode('rubySymbol', 'red', '', '')
call CreastyCode('rubyConstant', 'yellow', '', '')
call CreastyCode('rubyAttribute', 'foreground', '', '')
call CreastyCode('rubyInclude', 'blue', '', '')
call CreastyCode('rubyLocalVariableOrMethod', 'blue', '', '')
call CreastyCode('rubyCurlyBlock', 'foreground', '', '')
call CreastyCode('rubyStringDelimiter', 'green', '', '')
call CreastyCode('rubyInterpolationDelimiter', 'purple', '', '')
call CreastyCode('rubyConditional', 'purple', '', '')
call CreastyCode('rubyRepeat', 'purple', '', '')
call CreastyCode('rubyControl', 'purple', '', '')
call CreastyCode('rubyKeyword', 'purple', '', '')
call CreastyCode('rubyBoolean', 'orange', '', '')
call CreastyCode('rubyInteger', 'orange', '', '')
call CreastyCode('rubyAccess', 'purple', '', '')


"-------------------------------------------------------------------------------
" Highlighting: Python
"-------------------------------------------------------------------------------
call CreastyCode('pythonInclude', 'purple', '', '')
call CreastyCode('pythonStatement', 'purple', '', '')
call CreastyCode('pythonConditional', 'purple', '', '')
call CreastyCode('pythonRepeat', 'purple', '', '')
call CreastyCode('pythonException', 'purple', '', '')
call CreastyCode('pythonFunction', 'blue', '', '')


"-------------------------------------------------------------------------------
" Highlighting: CoffeeScript
"-------------------------------------------------------------------------------
call CreastyCode('coffeeKeyword', 'purple', '', '')
call CreastyCode('coffeeRepeat', 'purple', '', '')
call CreastyCode('coffeeConditional', 'purple', '', '')
call CreastyCode('coffeeStatement', 'purple', '', '')
call CreastyCode('coffeeException', 'purple', '', '')
call CreastyCode('coffeeEscape', 'purple', '', '')
call CreastyCode('coffeeObject', 'yellow', '', '')
call CreastyCode('coffeeObjAssign', 'red', '', '')
call CreastyCode('coffeeBoolean', 'orange', '', '')
call CreastyCode('coffeeNumber', 'orange', '', '')


"-------------------------------------------------------------------------------
" Highlighting: JavaScript
"-------------------------------------------------------------------------------
call CreastyCode('javaScriptBraces', 'foreground', '', '')
call CreastyCode('javaScriptFunction', 'purple', '', '')
call CreastyCode('javaScriptStatement', 'purple', '', '')
call CreastyCode('javaScriptSpecial', 'purple', '', '')
call CreastyCode('javaScriptConditional', 'purple', '', '')
call CreastyCode('javaScriptRepeat', 'purple', '', '')
call CreastyCode('javaScriptBoolean', 'orange', '', '')
call CreastyCode('javaScriptNumber', 'orange', '', '')
call CreastyCode('javaScriptMember', 'foreground', '', '')


"-------------------------------------------------------------------------------
" Highlighting: CSS
"-------------------------------------------------------------------------------
call CreastyCode('javaScriptBraces', 'foreground', '', '')
call CreastyCode('cssBraces', 'foreground', '', '')
call CreastyCode('cssBoxProp', 'red', '', '')
call CreastyCode('cssBackgroundProp', 'red', '', '')
call CreastyCode('cssTextProp', 'red', '', '')
call CreastyCode('cssPositioningProp', 'red', '', '')
call CreastyCode('cssPositioningAttr', 'red', '', '')
call CreastyCode('cssDimensionProp', 'red', '', '')
call CreastyCode('cssTransitionProp', 'red', '', '')
call CreastyCode('cssBorderProp', 'red', '', '')
call CreastyCode('cssFlexibleBoxProp', 'red', '', '')
call CreastyCode('cssPageProp', 'red', '', '')
call CreastyCode('cssListProp', 'red', '', '')
call CreastyCode('cssColorProp', 'red', '', '')
call CreastyCode('cssUIProp', 'red', '', '')
call CreastyCode('cssUIAttr', 'red', '', '')
call CreastyCode('cssFontProp', 'red', '', '')
call CreastyCode('cssTransformProp', 'red', '', '')
call CreastyCode('cssIdentifier', 'red', '', '')
call CreastyCode('cssClassName', 'blue', '', '')
call CreastyCode('cssColor', 'orange', '', '')
call CreastyCode('cssValueAngle', 'orange', '', '')
call CreastyCode('cssValueTime', 'orange', '', '')
call CreastyCode('cssValueLength', 'orange', '', '')
call CreastyCode('cssValueNumber', 'orange', '', '')
call CreastyCode('cssUnitDecorators', 'foreground', '', '')
call CreastyCode('cssAttributeSelector', 'purple', '', '')
call CreastyCode('cssFunctionName', 'aqua', '', '')
call CreastyCode('cssImportant', 'red', '', '')


"-------------------------------------------------------------------------------
" Highlighting: SCSS
"-------------------------------------------------------------------------------
call CreastyCode('scssIf', 'purple', '', '')
call CreastyCode('scssElseIf', 'purple', '', '')
call CreastyCode('scssElse', 'purple', '', '')
call CreastyCode('scssFor', 'purple', '', '')
call CreastyCode('scssReturn', 'purple', '', '')


"-------------------------------------------------------------------------------
" Highlighting: HTML
"-------------------------------------------------------------------------------
call CreastyCode('htmlTag', 'comment', '', '')
call CreastyCode('htmlEndTag', 'comment', '', '')
call CreastyCode('htmlTagName', 'orange', '', '')
call CreastyCode('htmlSpecialTagName', 'orange', '', '')
call CreastyCode('htmlTagN', 'orange', '', '')
call CreastyCode('htmlArg', 'red', '', '')
call CreastyCode('htmlScriptTag', 'comment', '', '')
call CreastyCode('htmlLink', 'blue', '', 'underline')
call CreastyCode('htmlTitle', 'foreground', '', '')
call CreastyCode('htmlH1', 'foreground', '', '')
call CreastyCode('htmlH2', 'foreground', '', '')
call CreastyCode('htmlH3', 'foreground', '', '')
call CreastyCode('htmlH4', 'foreground', '', '')
call CreastyCode('htmlH5', 'foreground', '', '')
call CreastyCode('htmlH6', 'foreground', '', '')


"-------------------------------------------------------------------------------
" Highlighting: XML
"-------------------------------------------------------------------------------
call CreastyCode('xmlTag', 'comment', '', '')
call CreastyCode('xmlEndTag', 'comment', '', '')
call CreastyCode('xmlTagName', 'orange', '', '')
call CreastyCode('xmlAttrib', 'red', '', '')
call CreastyCode('xmlEqual', 'comment', '', '')


"-------------------------------------------------------------------------------
" Highlighting: Markdown
"-------------------------------------------------------------------------------
call CreastyCode('markdownHeadingDelimiter', 'purple', '', '')
call CreastyCode('markdownH1', 'purple', '', '')
call CreastyCode('markdownH2', 'purple', '', '')
call CreastyCode('markdownH3', 'purple', '', '')
call CreastyCode('markdownH4', 'purple', '', '')
call CreastyCode('markdownH5', 'purple', '', '')
call CreastyCode('markdownH6', 'purple', '', '')
call CreastyCode('markdownLineBreak', '', 'blue', '')
call CreastyCode('markdownBold', 'red', '', '')
call CreastyCode('markdownItalic', 'red', '', '')
call CreastyCode('markdownListMarker', 'orange', '', '')
call CreastyCode('markdownOrderedListMarker', 'orange', '', '')
call CreastyCode('markdownCode', 'green', '', '')
call CreastyCode('markdownCodeBlock', 'green', '', '')
call CreastyCode('markdownUrl', 'comment', '', '')


"-------------------------------------------------------------------------------
" Highlighting: Diff
"-------------------------------------------------------------------------------
call CreastyCode('diffAdded', 'green', '', '')
call CreastyCode('diffRemoved', 'red', '', '')


