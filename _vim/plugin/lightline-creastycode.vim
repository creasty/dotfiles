
if has('gui_running')
  let s:red    = '#ae7071'
  let s:orange = '#bb8d6f'
  let s:yellow = '#cdb384'
  let s:green  = '#a3a371'
  let s:aqua   = '#8baaa5'
  let s:blue   = '#8397a8'
  let s:purple = '#9d90a8'
else
  let s:red    = '#cc6666'
  let s:orange = '#de935f'
  let s:yellow = '#f0c674'
  let s:green  = '#b5bd68'
  let s:aqua   = '#8abeb7'
  let s:blue   = '#81a2be'
  let s:purple = '#b294bb'
endif

let s:p = {'normal': {}, 'inactive': {}, 'insert': {}, 'replace': {}, 'visual': {}, 'tabline': {}}

let s:p.normal.left = [ ['gray0', s:green, 'bold'], ['gray8', 'gray2'] ]
let s:p.normal.middle = [ [ 'gray6', 'gray1' ] ]
let s:p.normal.right = [ ['gray4', 'gray9'], ['gray8', 'gray2'], ['gray6', 'gray1'] ]
let s:p.normal.error = [ [ 'gray0', s:red ] ]
let s:p.normal.warning = [ [ 'gray0', s:yellow ] ]

let s:p.inactive.right = [ ['gray1', 'gray5'], ['gray5', 'gray2'], ['gray4', 'gray0'] ]
let s:p.inactive.left = s:p.inactive.right[1:]

let s:p.insert.left = [ ['gray0', s:blue, 'bold'], ['gray8', 'gray2'] ]

let s:p.replace.left = [ ['gray0', s:purple, 'bold'], ['gray8', 'gray2'] ]
let s:p.replace.middle = s:p.normal.middle
let s:p.replace.right = s:p.normal.right

let s:p.visual.left = [ ['gray0', s:orange, 'bold'], ['gray8', 'gray2'] ]

let s:p.tabline.left = [ ['gray6', 'gray2'] ]
let s:p.tabline.tabsel = [ ['gray2', 'gray8'] ]
let s:p.tabline.middle = [ ['gray6', 'gray1'] ]
let s:p.tabline.right = [ ['gray6', 'gray2'] ]

let g:lightline#colorscheme#creastycode#palette = lightline#colorscheme#fill(s:p)

