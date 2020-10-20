let b:switch_custom_definitions = [
  \ vimrc#plugin#switch#keywords(['const', 'let']),
  \ vimrc#plugin#switch#keywords(['onFocus', 'onBlur']),
  \ vimrc#plugin#switch#keywords(['onMouseOver', 'onMouseOut']),
  \ vimrc#plugin#switch#keywords(['onMouseEnter', 'onMouseLeave']),
  \ vimrc#plugin#switch#keywords(['onMouseDown', 'onMouseUp']),
  \ vimrc#plugin#switch#keywords(['onKeyUp', 'onKeyDown', 'onKeyPress']),
  \ vimrc#plugin#switch#keywords(['useState', 'useAdaptiveState']),
\ ]

command! -nargs=0 -range=% SwapSwitchCase
  \ <line1>,<line2>s/\v<case\s+([^:]+):((\s|\n)*)return\s+([^;]+);/case \4:\2return \1;/g
