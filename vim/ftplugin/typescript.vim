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

command! -nargs=+ GenAdaptor
  \ call <SID>gen_adaptor(<f-args>)

function! s:gen_adaptor(...) abort
  let l:proto_ns = ''
  let @x = ''

  for l:name in a:000
    if l:name =~ '^-ns=\(.\+\)'
      let l:proto_ns = substitute(l:name, '^-ns=\(.\+\)', '\1', '')
      continue
    endif

    let l:body = ''
    if l:name =~# 'Input$'
      let l:body = ''
        \ . "export function {funcName}ToPb(\n"
        \ . "  input: graphql.{GraphqlType}\n"
        \ . "): {ProtoType} {\n"
        \ . "  return new {ProtoType}();\n"
        \ . "}\n"
    else
      let l:body = ''
        \ . "export function {funcName}ToType(\n"
        \ . "  pb: {ProtoType}\n"
        \ . "): Named<graphql.{GraphqlType}> {\n"
        \ . "  return {};\n"
        \ . "}\n"
    endif

    let l:proto_type = substitute(l:name, 'Input$', '', '')
    let l:func_name = substitute(l:proto_type, '^.', '\l\0', '')
    let l:proto_type_with_ns = empty(l:proto_ns) ? l:proto_type : l:proto_ns . '.' . l:proto_type

    let l:body = substitute(l:body, '{funcName}', l:func_name, 'g')
    let l:body = substitute(l:body, '{GraphqlType}', l:name, 'g')
    let l:body = substitute(l:body, '{ProtoType}', l:proto_type_with_ns, 'g')

    let @x .= l:body
  endfor
  call feedkeys('"xp', 'n')
endfunction
