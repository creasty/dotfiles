source <sfile>:h/javascript.vim

command! -buffer -nargs=0 -range=% ConvertProtoToType
  \ silent keeppatterns <line1>,<line2>s/\v__typename\?: '(\w+)';/__typename: "\1",/ge |
  \ silent keeppatterns <line1>,<line2>s/\v(\w+)\?: Maybe\<Scalars\['(\w+)'\]\['\w+'\]\>;/\1: pb.get\u\1(),/ge |
  \ silent keeppatterns <line1>,<line2>s/\v(\w+): Array\<Scalars\['(\w+)'\]\['\w+'\]\>;/\1: pb.get\u\1List(),/ge |
  \ silent keeppatterns <line1>,<line2>s/\v(\w+): Array\<(\w+)\>;/\1: pb.get\u\1List().map(\l\2ToType),/ge |
  \ silent keeppatterns <line1>,<line2>s/\v(\w+)\?: Maybe\<Array\<(\w+)\>\>;/\1: pb.get\u\1List().map(\l\2ToType),/ge |
  \ silent keeppatterns <line1>,<line2>s/\v(\w+): Scalars\['(\w+)'\]\['\w+'\];/\1: pb.get\u\1(),/ge |
  \ silent keeppatterns <line1>,<line2>s/\v(\w+): (\w+);/\1: \l\2ToType(requireNotNull(pb.get\u\1(), "\1")),/ge |
  \ silent keeppatterns <line1>,<line2>s/\v(\w+)\?: Maybe\<(\w+)\>;/\1: fmap(pb.get\u\1(), \l\2ToType),/ge |
  \ silent keeppatterns <line1>,<line2>s/\v(\w+) \= '(\w+)',?/case PB.\2: return GQ.\1;/ge

command! -buffer -nargs=0 -range=% ConvertInputToProto
  \ silent keeppatterns <line1>,<line2>s/\v(\w+)\?: InputMaybe\<Scalars\['(\w+)'\]\['\w+'\]\>;/.set\u\1(input.\1)/ge |
  \ silent keeppatterns <line1>,<line2>s/\v(\w+): Array\<Scalars\['(\w+)'\]\['\w+'\]\>;/.set\u\1List(input.\1)/ge |
  \ silent keeppatterns <line1>,<line2>s/\v(\w+): Array\<(\w+)\>;/.set\u\1List(input.\1.map(\l\2ToPb))/ge |
  \ silent keeppatterns <line1>,<line2>s/\v(\w+)\?: InputMaybe\<Array\<(\w+)\>\>;/.set\u\1List(input.\1.map(\l\2ToPb))/ge |
  \ silent keeppatterns <line1>,<line2>s/\v(\w+): Scalars\['(\w+)'\]\['\w+'\];/.set\u\1(input.\1)/ge |
  \ silent keeppatterns <line1>,<line2>s/\v(\w+): (\w+);/.set\u\1(\l\2ToPb(input.\1))/ge |
  \ silent keeppatterns <line1>,<line2>s/\v(\w+)\?: InputMaybe\<(\w+)\>;/.set\u\1(fmap(input.\1, \l\2ToPb))/ge |
  \ silent keeppatterns <line1>,<line2>s/\v(\w+) \= '(\w+)',?/case GQ.\1: return PB.\2;/ge

command! -buffer -nargs=+ GenAdaptor
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
    "   pm - proto message
    "   pe - proto enum
    "   gt - graphql type
    "   gi - graphql input
    "   ge - graphql enum
    let l:type = ''
    let l:m = matchlist(l:name, '\v(.+):(pm|pe|gt|gi|ge)$')
    if !empty(l:m)
      let l:name = l:m[1]
      let l:type = l:m[2]
    endif
    if empty(l:type)
      let l:type = (l:name =~# 'Input$') ? 'gi' : 'pm'
    endif

    let l:body = ''
    if l:type ==# 'gi'
      let l:body = ''
        \ . "export function {funcName}ToPb(\n"
        \ . "  input: graphql.{GraphqlType}\n"
        \ . "): {ProtoType} {\n"
        \ . "  return new {ProtoType}();\n"
        \ . "}\n"
    elseif l:type ==# 'gt'
      let l:body = ''
        \ . "export function {funcName}ToPb(\n"
        \ . "  type: graphql.{GraphqlType}\n"
        \ . "): {ProtoType} {\n"
        \ . "  return new {ProtoType}();\n"
        \ . "}\n"
    elseif l:type ==# 'pm'
      let l:body = ''
        \ . "export function {funcName}ToType(\n"
        \ . "  pb: {ProtoType}\n"
        \ . "): Named<graphql.{GraphqlType}> {\n"
        \ . "  return {};\n"
        \ . "}\n"
    elseif l:type ==# 'pe'
      let l:body = ''
        \ . "export function {funcName}ToType(\n"
        \ . "  pb: {ProtoType}\n"
        \ . "): graphql.{GraphqlType} {\n"
        \ . "  switch (pb) {\n"
        \ . "    case {ProtoType}.UNSPECIFIED:\n"
        \ . "      return graphql.{GraphqlType}.Unspecified;\n"
        \ . "  }\n"
        \ . "}\n"
    elseif l:type ==# 'ge'
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

    let l:func_name = substitute(l:name, '^.', '\l\0', '')
    let l:func_name = substitute(l:func_name, '\.\(.\)', '\U\1', 'g')
    let l:func_name = substitute(l:func_name, '_', '', 'g')

    let l:proto_type = substitute(l:name, 'Input$', '', '')
    let l:proto_type = substitute(l:proto_type, '_', '.', 'g')
    let l:proto_type = empty(l:proto_ns) ? l:proto_type : l:proto_ns . '.' . l:proto_type

    let l:body = substitute(l:body, '{funcName}', l:func_name, 'g')
    let l:body = substitute(l:body, '{GraphqlType}', l:name, 'g')
    let l:body = substitute(l:body, '{ProtoType}', l:proto_type, 'g')

    let @x .= l:body
  endfor
  call feedkeys('"xP', 'n')
endfunction
