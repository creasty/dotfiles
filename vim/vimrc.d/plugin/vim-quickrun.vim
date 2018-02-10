let g:quickrun_config = {}
let g:quickrun_config['_'] = {
  \ 'runner':                        'job',
  \ 'outputter/buffer/split':        ':botright 15sp',
  \ 'outputter/buffer/running_mark': '',
\ }
let g:quickrun_config['ruby.rspec'] = {
  \ 'type':    'ruby.rspec',
  \ 'command': 'rspec',
  \ 'cmdopt':  'bundle exec',
  \ 'exec':    '%o %c %s',
\ }
let g:quickrun_config['markdown'] = {
  \ 'outputter': 'null',
  \ 'command':   'open',
  \ 'cmdopt':    '-a',
  \ 'args':      'Marked',
  \ 'exec':      '%c %o %a %s',
\ }
let g:quickrun_config['javascript'] = {
  \ 'command': 'node',
\ }
let g:quickrun_config['coffee'] = {
  \ 'command': 'coffee',
  \ 'exec':    ['%c -cbp %s | node'],
\ }
let g:quickrun_config['swift'] = {
  \ 'command': 'xcrun',
  \ 'cmdopt':  'swift',
  \ 'exec':    '%c %o %s',
\ }
let g:quickrun_config['scala'] = {
  \ 'command': 'scala',
  \ 'cmdopt':  '-deprecation -feature',
  \ 'exec':    '%c %o %s %a',
\ }

nmap <Leader>r <Plug>(quickrun)
