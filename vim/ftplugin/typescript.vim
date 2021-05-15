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

command! -nargs=0 -range=% SwapSwitchCase
  \ silent keeppatterns <line1>,<line2>s/\v<case\s+([^:]+):((\s|\n)*)return\s+([^;]+);/case \4:\2return \1;/g

command! -nargs=0 -range=% ConvertApiDef
  \ silent keeppatterns <line1>,<line2>s/\v(\w{-})API/\l\1: () => new \0(clientAuth, forwardedIps).promise/g

command! -nargs=0 -range=% ConvertProtoToType
  \ silent keeppatterns <line1>,<line2>s/\v__typename\?: '(\w+)';/__typename: "\1",/ge |
  \ silent keeppatterns <line1>,<line2>s/\v(\w+)\?: Maybe\<Scalars\['(\w+)'\]\>;/\1: pb.get\u\1(),/ge |
  \ silent keeppatterns <line1>,<line2>s/\v(\w+): Array\<Scalars\['(\w+)'\]\>;/\1: pb.get\u\1List(),/ge |
  \ silent keeppatterns <line1>,<line2>s/\v(\w+): Array\<(\w+)\>;/\1: pb.get\u\1List().map(\l\2ToType),/ge |
  \ silent keeppatterns <line1>,<line2>s/\v(\w+)\?: Maybe\<Array\<(\w+)\>\>;/\1: pb.get\u\1List().map(\l\2ToType),/ge |
  \ silent keeppatterns <line1>,<line2>s/\v(\w+): Scalars\['(\w+)'\];/\1: pb.get\u\1(),/ge |
  \ silent keeppatterns <line1>,<line2>s/\v(\w+): (\w+);/\1: \l\2ToType(requireNotNull(pb.get\u\1(), "\1")),/ge |
  \ silent keeppatterns <line1>,<line2>s/\v(\w+)\?: Maybe\<(\w+)\>;/\1: fmap(pb.get\u\1(), \l\2ToType),/ge

command! -nargs=0 -range=% ConvertInputToProto
  \ silent keeppatterns <line1>,<line2>s/\v\s*(\S+)\s*\?\s*(\w+)\(\1\)\s*:\s*undefined>/fmap(\1, \2)/g

command! -nargs=+ GenAdaptor
  \ call <SID>gen_adaptor(<f-args>)

function! s:gen_adaptor(...) abort
  let l:proto_ns = ''
  let @x = ''

  for l:name in a:000
    let l:m = matchlist(l:name, '^-ns=\(.\+\)')
    if !empty(l:m)
      let l:proto_ns = l:m[1]
      continue
    endif

    " CONVERSION TYPE:
    "   M - message (proto)
    "   E - enum (proto)
    "   t - type (graphql)
    "   i - input (graphql)
    "   e - enum (graphql)
    let l:type = ''
    let l:m = matchlist(l:name, '\(.\+\):\([MEtie]\)$')
    if !empty(l:m)
      let l:name = l:m[1]
      let l:type = l:m[2]
    endif
    if empty(l:type)
      let l:type = (l:name =~# 'Input$') ? 'i' : 'M'
    endif

    let l:body = ''
    if l:type ==# 'i'
      let l:body = ''
        \ . "export function {funcName}ToPb(\n"
        \ . "  input: graphql.{GraphqlType}\n"
        \ . "): {ProtoType} {\n"
        \ . "  return new {ProtoType}();\n"
        \ . "}\n"
    elseif l:type ==# 't'
      let l:body = ''
        \ . "export function {funcName}ToPb(\n"
        \ . "  type: graphql.{GraphqlType}\n"
        \ . "): {ProtoType} {\n"
        \ . "  return new {ProtoType}();\n"
        \ . "}\n"
    elseif l:type ==# 'M'
      let l:body = ''
        \ . "export function {funcName}ToType(\n"
        \ . "  pb: {ProtoType}\n"
        \ . "): Named<graphql.{GraphqlType}> {\n"
        \ . "  return {};\n"
        \ . "}\n"
    elseif l:type ==# 'E'
      let l:body = ''
        \ . "export function {funcName}ToType(\n"
        \ . "  pb: {ProtoType}\n"
        \ . "): graphql.{GraphqlType} {\n"
        \ . "  switch (pb) {\n"
        \ . "    case {ProtoType}.UNSPECIFIED:\n"
        \ . "      return graphql.{GraphqlType}.Unspecified;\n"
        \ . "  }\n"
        \ . "}\n"
    elseif l:type ==# 'e'
      let l:body = ''
        \ . "export function {funcName}ToPb(\n"
        \ . "  type: graphql.{GraphqlType}\n"
        \ . "): {ProtoType} {\n"
        \ . "  switch (type) {\n"
        \ . "    case graphql.{GraphqlType}.Unspecified:\n"
        \ . "      return {ProtoType}.UNSPECIFIED;\n"
        \ . "  }\n"
        \ . "}\n"
    endif

    let l:func_name = substitute(
      \ substitute(l:name, '^.', '\l\0', ''),
      \ '\.\(.\)', '\U\1', 'g')

    let l:proto_type = substitute(substitute(l:name, 'Input$', '', ''), '_', '.', 'g')
    let l:proto_type = empty(l:proto_ns) ? l:proto_type : l:proto_ns . '.' . l:proto_type

    let l:body = substitute(l:body, '{funcName}', l:func_name, 'g')
    let l:body = substitute(l:body, '{GraphqlType}', l:name, 'g')
    let l:body = substitute(l:body, '{ProtoType}', l:proto_type, 'g')

    let @x .= l:body
  endfor
  call feedkeys('"xp', 'n')
endfunction
