let g:EasyMotion_leader_key = '<Space>'
let g:EasyMotion_keys = 'hjklasdfgyuiopqwertnmzxcvbHJKLASDFGYUIOPQWERTNMZXCVB'

if dein#tap('candle.vim')
  call candle#highlight('EasyMotionTarget', 'yellow', 'dark_yellow', 'underline')
endif
