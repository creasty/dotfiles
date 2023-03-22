setlocal et
setlocal tabstop=2 shiftwidth=2

let b:switch_custom_definitions = [
  \ switch#Words(['const', 'let']),
  \ switch#Words(['onFocus', 'onBlur']),
  \ switch#Words(['onMouseOver', 'onMouseOut']),
  \ switch#Words(['onMouseEnter', 'onMouseLeave']),
  \ switch#Words(['onMouseDown', 'onMouseUp']),
  \ switch#Words(['onKeyUp', 'onKeyDown', 'onKeyPress']),
  \ switch#Words(['useState', 'useAdaptiveState']),
  \ switch#Words(['useCallback', 'useCurriedCallback']),
\ ]

command! -buffer -nargs=0 -range=% SwapSwitchCase
  \ silent keeppatterns <line1>,<line2>s/\v<case\s+([^:]+):((\s|\n)*)return\s+([^;]+);/case \4:\2return \1;/g

command! -buffer -nargs=0 -range=% ConvertApiDef
  \ silent keeppatterns <line1>,<line2>s/\v(\w{-})API/\l\1: () => new \0(clientAuth, forwardedIps).promise/g
