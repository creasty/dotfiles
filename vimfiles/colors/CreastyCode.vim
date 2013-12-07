
" Default GUI Colours
let s:foreground = 'b8b8b8'
let s:background = '000000'
let s:selection = '424242'
let s:line = '2a2a2a'
let s:comment = '666666'
let s:red = 'cc6666'
let s:orange = 'de935f'
let s:yellow = 'f0c674'
let s:green = 'b5bd68'
let s:aqua = '8abeb7'
let s:blue = '81a2be'
let s:purple = 'b294bb'
let s:window = '4d5057'

set background=dark
hi clear
syntax reset

let g:colors_name = 'CreastyCode'

if has('gui_running') || &t_Co == 88 || &t_Co == 256
  " Returns an approximate grey index for the given grey level
  fun <SID>grey_number(x)
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
  fun <SID>grey_level(n)
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
  fun <SID>grey_colour(n)
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
  fun <SID>rgb_number(x)
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
  fun <SID>rgb_level(n)
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
  fun <SID>rgb_colour(x, y, z)
    if &t_Co == 88
      return 16 + (a:x * 16) + (a:y * 4) + a:z
    else
      return 16 + (a:x * 36) + (a:y * 6) + a:z
    endif
  endfun

  " Returns the palette index to approximate the given R/G/B colour levels
  fun <SID>colour(r, g, b)
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
  fun <SID>rgb(rgb)
    let l:r = ('0x' . strpart(a:rgb, 0, 2)) + 0
    let l:g = ('0x' . strpart(a:rgb, 2, 2)) + 0
    let l:b = ('0x' . strpart(a:rgb, 4, 2)) + 0

    return <SID>colour(l:r, l:g, l:b)
  endfun

  " Sets the highlighting for the given group
  fun <SID>X(group, fg, bg, attr)
    if a:fg != ''
      exec 'hi ' . a:group . ' guifg=#' . a:fg . ' ctermfg=' . <SID>rgb(a:fg)
    endif
    if a:bg != ''
      exec 'hi ' . a:group . ' guibg=#' . a:bg . ' ctermbg=' . <SID>rgb(a:bg)
    endif
    if a:attr != ''
      exec 'hi ' . a:group . ' gui=' . a:attr . ' cterm=' . a:attr
    endif
  endfun

  " Vim Highlighting
  call <SID>X('Normal', s:foreground, s:background, '')
  call <SID>X('LineNr', s:comment, '', 'none')
  call <SID>X('CursorLineNr', s:comment, s:line, 'none')
  call <SID>X('NonText', s:selection, '', '')
  call <SID>X('SpecialKey', s:line, '', '')
  call <SID>X('Search', s:background, s:yellow, '')
  call <SID>X('TabLine', s:foreground, s:background, 'reverse')
  call <SID>X('StatusLine', s:window, s:yellow, 'reverse')
  call <SID>X('StatusLineNC', s:window, s:foreground, 'reverse')
  call <SID>X('VertSplit', s:window, s:window, 'none')
  call <SID>X('Visual', '', s:selection, '')
  call <SID>X('Directory', s:blue, '', '')
  call <SID>X('ModeMsg', s:green, '', '')
  call <SID>X('MoreMsg', s:green, '', '')
  call <SID>X('Question', s:green, '', '')
  call <SID>X('WarningMsg', s:red, '', '')
  call <SID>X('MatchParen', '', s:selection, '')
  call <SID>X('Folded', s:comment, s:background, '')
  call <SID>X('FoldColumn', '', s:background, '')
  if version >= 700
    call <SID>X('CursorColumn', '', s:line, 'none')
    call <SID>X('PMenu', s:foreground, s:selection, 'none')
    call <SID>X('PMenuSel', s:foreground, s:selection, 'reverse')
    call <SID>X('CursorLine', '', s:line, 'none')
    call <SID>X('SignColumn', '', s:background, 'none')
  end
  if version >= 703
    call <SID>X('ColorColumn', '', s:line, 'none')
  end
  call <SID>X('SyntasticErrorSign', s:red, '', '')
  call <SID>X('SyntasticWarningSign', s:yellow, '', '')

  " Standard Highlighting
  call <SID>X('Comment', s:comment, '', '')
  call <SID>X('Todo', s:comment, s:background, '')
  call <SID>X('Title', s:comment, '', '')
  call <SID>X('Identifier', s:blue, '', 'none')
  call <SID>X('Statement', s:foreground, '', '')
  call <SID>X('Conditional', s:foreground, '', '')
  call <SID>X('Repeat', s:foreground, '', '')
  call <SID>X('Structure', s:purple, '', '')
  call <SID>X('Function', s:blue, '', '')
  call <SID>X('Constant', s:yellow, '', '')
  call <SID>X('String', s:green, '', '')
  call <SID>X('Special', s:foreground, '', '')
  call <SID>X('PreProc', s:purple, '', '')
  call <SID>X('Operator', s:aqua, '', 'none')
  call <SID>X('Type', s:yellow, '', 'none')
  call <SID>X('Define', s:purple, '', 'none')
  call <SID>X('Include', s:blue, '', '')
  call <SID>X('ZenkakuSpace', '', s:red, '')
  call <SID>X('TrailingSpace', '', s:line, '')

  " Vim Highlighting
  call <SID>X('vimCommand', s:red, '', 'none')

  " C Highlighting
  call <SID>X('cType', s:yellow, '', '')
  call <SID>X('cStorageClass', s:purple, '', '')
  call <SID>X('cConditional', s:purple, '', '')
  call <SID>X('cRepeat', s:purple, '', '')
  call <SID>X('cSpecial', s:purple, '', '')
  call <SID>X('cStatement', s:purple, '', '')
  call <SID>X('cDefine', s:purple, '', '')
  call <SID>X('cInclude', s:purple, '', '')
  call <SID>X('cNumber', s:orange, '', '')
  call <SID>X('cFloat', s:orange, '', '')

  " Objective-C Highlighting
  call <SID>X('cocoaClass', s:yellow, '', '')
  call <SID>X('objcSubclass', s:yellow, '', '')
  call <SID>X('objcMethodColon', s:red, '', '')
  call <SID>X('objcObjDef', s:purple, '', '')
  call <SID>X('objcImport', s:purple, '', '')
  call <SID>X('objcConstant', s:yellow, '', '')
  call <SID>X('objcSuperclass', s:yellow, '', '')
  call <SID>X('objcProtocolList', s:aqua, '', '')
  call <SID>X('objcDirective', s:aqua, '', '')

  " PHP Highlighting
  call <SID>X('phpVarSelector', s:red, '', '')
  call <SID>X('phpKeyword', s:purple, '', '')
  call <SID>X('phpRepeat', s:purple, '', '')
  call <SID>X('phpConditional', s:purple, '', '')
  call <SID>X('phpStatement', s:purple, '', '')
  call <SID>X('phpMemberSelector', s:foreground, '', '')

  " Ruby Highlighting
  call <SID>X('rubySymbol', s:red, '', '')
  call <SID>X('rubyConstant', s:yellow, '', '')
  call <SID>X('rubyAttribute', s:foreground, '', '')
  call <SID>X('rubyInclude', s:blue, '', '')
  call <SID>X('rubyLocalVariableOrMethod', s:blue, '', '')
  call <SID>X('rubyCurlyBlock', s:foreground, '', '')
  call <SID>X('rubyStringDelimiter', s:green, '', '')
  call <SID>X('rubyInterpolationDelimiter', s:purple, '', '')
  call <SID>X('rubyConditional', s:purple, '', '')
  call <SID>X('rubyRepeat', s:purple, '', '')
  call <SID>X('rubyControl', s:purple, '', '')
  call <SID>X('rubyKeyword', s:purple, '', '')
  call <SID>X('rubyBoolean', s:orange, '', '')
  call <SID>X('rubyInteger', s:orange, '', '')
  call <SID>X('rubyAccess', s:purple, '', '')

  " Python Highlighting
  call <SID>X('pythonInclude', s:purple, '', '')
  call <SID>X('pythonStatement', s:purple, '', '')
  call <SID>X('pythonConditional', s:purple, '', '')
  call <SID>X('pythonRepeat', s:purple, '', '')
  call <SID>X('pythonException', s:purple, '', '')
  call <SID>X('pythonFunction', s:blue, '', '')

  " CoffeeScript Highlighting
  call <SID>X('coffeeKeyword', s:purple, '', '')
  call <SID>X('coffeeRepeat', s:purple, '', '')
  call <SID>X('coffeeConditional', s:purple, '', '')
  call <SID>X('coffeeStatement', s:purple, '', '')
  call <SID>X('coffeeEscape', s:purple, '', '')
  call <SID>X('coffeeObject', s:yellow, '', '')
  call <SID>X('coffeeObjAssign', s:red, '', '')
  call <SID>X('coffeeBoolean', s:orange, '', '')
  call <SID>X('coffeeNumber', s:orange, '', '')

  " JavaScript Highlighting
  call <SID>X('javaScriptBraces', s:foreground, '', '')
  call <SID>X('javaScriptFunction', s:purple, '', '')
  call <SID>X('javaScriptStatement', s:purple, '', '')
  call <SID>X('javaScriptSpecial', s:purple, '', '')
  call <SID>X('javaScriptConditional', s:purple, '', '')
  call <SID>X('javaScriptRepeat', s:purple, '', '')
  call <SID>X('javaScriptBoolean', s:orange, '', '')
  call <SID>X('javaScriptNumber', s:orange, '', '')
  call <SID>X('javaScriptMember', s:foreground, '', '')

  " CSS Highlighting
  call <SID>X('cssBraces', s:foreground, '', '')
  call <SID>X('cssBoxProp', s:red, '', '')
  call <SID>X('cssBackgroundProp', s:red, '', '')
  call <SID>X('cssTextProp', s:red, '', '')
  call <SID>X('cssPositioningProp', s:red, '', '')
  call <SID>X('cssPositioningAttr', s:red, '', '')
  call <SID>X('cssDimensionProp', s:red, '', '')
  call <SID>X('cssTransitionProp', s:red, '', '')
  call <SID>X('cssBorderProp', s:red, '', '')
  call <SID>X('cssFlexibleBoxProp', s:red, '', '')
  call <SID>X('cssPageProp', s:red, '', '')
  call <SID>X('cssListProp', s:red, '', '')
  call <SID>X('cssColorProp', s:red, '', '')
  call <SID>X('cssUIProp', s:red, '', '')
  call <SID>X('cssUIAttr', s:red, '', '')
  call <SID>X('cssFontProp', s:red, '', '')
  call <SID>X('cssTransformProp', s:red, '', '')
  call <SID>X('cssIdentifier', s:red, '', '')
  call <SID>X('cssClassName', s:blue, '', '')
  call <SID>X('cssColor', s:orange, '', '')
  call <SID>X('cssValueAngle', s:orange, '', '')
  call <SID>X('cssValueTime', s:orange, '', '')
  call <SID>X('cssValueLength', s:orange, '', '')
  call <SID>X('cssValueNumber', s:orange, '', '')
  call <SID>X('cssUnitDecorators', s:foreground, '', '')
  call <SID>X('cssAttributeSelector', s:purple, '', '')
  call <SID>X('cssFunctionName', s:aqua, '', '')
  call <SID>X('cssImportant', s:red, '', '')

  " Sass Highlighting
  call <SID>X('scssIf', s:purple, '', '')
  call <SID>X('scssElseIf', s:purple, '', '')
  call <SID>X('scssElse', s:purple, '', '')
  call <SID>X('scssFor', s:purple, '', '')
  call <SID>X('scssReturn', s:purple, '', '')

  " HTML Highlighting
  call <SID>X('htmlTag', s:comment, '', '')
  call <SID>X('htmlEndTag', s:comment, '', '')
  call <SID>X('htmlTagName', s:orange, '', '')
  call <SID>X('htmlSpecialTagName', s:orange, '', '')
  call <SID>X('htmlTagN', s:orange, '', '')
  call <SID>X('htmlArg', s:red, '', '')
  call <SID>X('htmlScriptTag', s:orange, '', '')
  call <SID>X('htmlLink', s:blue, '', 'underline')
  call <SID>X('htmlTitle', s:foreground, '', '')
  call <SID>X('htmlH1', s:foreground, '', '')
  call <SID>X('htmlH2', s:foreground, '', '')
  call <SID>X('htmlH3', s:foreground, '', '')
  call <SID>X('htmlH4', s:foreground, '', '')
  call <SID>X('htmlH5', s:foreground, '', '')
  call <SID>X('htmlH6', s:foreground, '', '')

  " XML Highlighting
  call <SID>X('xmlTag', s:comment, '', '')
  call <SID>X('xmlEndTag', s:comment, '', '')
  call <SID>X('xmlTagName', s:orange, '', '')
  call <SID>X('xmlAttrib', s:red, '', '')
  call <SID>X('xmlEqual', s:comment, '', '')

  " Markdown Highlighting
  call <SID>X('markdownH1', s:purple, '', '')
  call <SID>X('markdownH2', s:purple, '', '')
  call <SID>X('markdownH3', s:purple, '', '')
  call <SID>X('markdownH4', s:purple, '', '')
  call <SID>X('markdownH5', s:purple, '', '')
  call <SID>X('markdownH6', s:purple, '', '')
  call <SID>X('markdownLineBreak', '', s:blue, '')
  call <SID>X('markdownBold', s:red, '', '')
  call <SID>X('markdownItalic', s:red, '', '')
  call <SID>X('markdownListMarker', s:orange, '', '')
  call <SID>X('markdownOrderedListMarker', s:orange, '', '')
  call <SID>X('markdownCode', s:green, '', '')
  call <SID>X('markdownCodeBlock', s:green, '', '')
  call <SID>X('markdownUrl', s:comment, '', '')

  " Diff Highlighting
  call <SID>X('diffAdded', s:green, '', '')
  call <SID>X('diffRemoved', s:red, '', '')

  " Delete Functions
  delf <SID>X
  delf <SID>rgb
  delf <SID>colour
  delf <SID>rgb_colour
  delf <SID>rgb_level
  delf <SID>rgb_number
  delf <SID>grey_colour
  delf <SID>grey_level
  delf <SID>grey_number
endif
