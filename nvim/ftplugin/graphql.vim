let b:switch_custom_definitions = [
  \ switch#NormalizedCaseWords(['query', 'mutation']),
  \ switch#Words(['queries', 'mutations']),
\ ]

command! -buffer -nargs=0 -range=% ConvertProtoRpc
  \ silent keeppatterns <line1>,<line2>s/\v<rpc\s+((\w|[.])+)\s*\(((\w|[.])+)\)\s+returns\s+\(((\w|[.])+)\).*/\l\1(input: \3Input!): \5!/ge

command! -buffer -nargs=0 -range=% ConvertQM
  \ silent keeppatterns <line1>,<line2>s/\v<(\w+)\(\_s*input: (\w+)!\_s*\): (\w+)!/query \u\1($input: \2!) {\r  \1(input: $input) {}\r}/ge

command! -buffer -nargs=0 -range=% ConvertFragment
  \ silent keeppatterns <line1>,<line2>s/\v(\w+)\?: Maybe\<Scalars\['(\w+)'\]\>;/\1/ge |
  \ silent keeppatterns <line1>,<line2>s/\v(\w+): Array\<Scalars\['(\w+)'\]\>;/\1/ge |
  \ silent keeppatterns <line1>,<line2>s/\v(\w+): Array\<((String|UInt32|Int32|Bool)Value|Frac10+)\>;/\1 { value }/ge |
  \ silent keeppatterns <line1>,<line2>s/\v(\w+): Array\<(\w+)\>;/\1 { ...\2 }/ge |
  \ silent keeppatterns <line1>,<line2>s/\v(\w+)\?: Maybe\<Array\<(\w+)\>\>;/\1 { ...\2 }/ge |
  \ silent keeppatterns <line1>,<line2>s/\v(\w+)\?: Maybe\<Array\<((String|UInt32|Int32|Bool)Value|Frac10+)\>\>;/\1 { value }/ge |
  \ silent keeppatterns <line1>,<line2>s/\v(\w+): Scalars\['(\w+)'\];/\1/ge |
  \ silent keeppatterns <line1>,<line2>s/\v(\w+): ((String|UInt32|Int32|Bool)Value|Frac10+);/\1 { value }/ge |
  \ silent keeppatterns <line1>,<line2>s/\v(\w+): (\w+);/\1 { ...\2 }/ge |
  \ silent keeppatterns <line1>,<line2>s/\v(\w+)\?: Maybe\<((String|UInt32|Int32|Bool)Value|Frac10+)\>;/\1 { value }/ge |
  \ silent keeppatterns <line1>,<line2>s/\v(\w+)\?: Maybe\<(\w+)\>;/\1 { ...\2 }/ge |
  \ silent keeppatterns <line1>,<line2>s/\v: ((String|UInt32|Int32|Bool)Value|Frac10+)!?/ { value }/ge |
  \ silent keeppatterns <line1>,<line2>s/\v: \[((String|UInt32|Int32|Bool)Value|Frac10+)!?\]!?/ { value }/ge |
  \ silent keeppatterns <line1>,<line2>s/\v: (String|Boolean|Int)!?//ge |
  \ silent keeppatterns <line1>,<line2>s/\v: \[(String|Boolean|Int)!?\]!?//ge |
  \ silent keeppatterns <line1>,<line2>s/\v: (\w+)!?/ { ...\1 }/ge |
  \ silent keeppatterns <line1>,<line2>s/\v: \[(\w+)!?\]!?/ { ...\1 }/ge
