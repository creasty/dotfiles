command! -nargs=0 -range=% ConvertProtoRpc
  \ <line1>,<line2>s/\v<rpc\s+((\w|[.])+)\s*\(((\w|[.])+)\)\s+returns\s+\(((\w|[.])+)\).*/\l\1(input: \3Input!): \5!/g

command! -nargs=0 -range=% ConvertQM
  \ <line1>,<line2>s/\v<(\w+)\(\_s*input: (\w+)!\_s*\): (\w+)!/query \u\1($input: \2!) {\r  \1(input: $input) {}\r}/g

let b:switch_custom_definitions = [
  \ vimrc#plugin#switch#keywords(['query', 'mutation']),
  \ vimrc#plugin#switch#keywords(['Query', 'Mutation']),
\ ]
