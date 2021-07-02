setlocal iskeyword+=!,?

let b:switch_custom_definitions = [
  \ {
    \ ':\(\w\+\)': '''\1''',
  \ },
  \ {
    \ '\<\(\w\+\): \(\s*\)': '''\1'' \2=> ',
    \ '''\(\w\+\)'' \(\s*\)=> ': '\1: \2',
  \ },
  \ {
    \ '\<\(it\|describe\|context\|senario\)\>': 'x\1',
    \ '\<x\(it\|describe\|context\|senario\)\>': '\1',
  \ },
\ ]
