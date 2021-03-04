let b:switch_custom_definitions = [
  \ switch#Words(['OPTIONAL', 'REQUIRED']),
  \ switch#Words(['INPUT_ONLY', 'OUTPUT_ONLY']),
  \ switch#Words(['double', 'google.protobuf.DoubleValue']),
  \ switch#Words(['float', 'google.protobuf.FloatValue']),
  \ switch#Words(['int64', 'google.protobuf.Int64Value']),
  \ switch#Words(['uint64', 'google.protobuf.UInt64Value']),
  \ switch#Words(['int32', 'google.protobuf.Int32Value']),
  \ switch#Words(['uint32', 'google.protobuf.UInt32Value']),
  \ switch#Words(['bool', 'google.protobuf.BoolValue']),
  \ switch#Words(['bytes', 'google.protobuf.BytesValue']),
  \ switch#Words(['string', 'google.protobuf.StringValue']),
  \ switch#Words(['field_mask', 'update_mask']),
\ ]

command! -nargs=0 -range=% ConvertProtoField
  \ keeppatterns <line1>,<line2>s!``!!ge |
  \ keeppatterns <line1>,<line2>s!` `! !ge |
  \ keeppatterns <line1>,<line2>s!\v^(\s*)- (Add: )?`(\w+): ([^`]+)`\s+(.+)!\1// \5\r\1\4 \3 = 1;!ge |
  \ keeppatterns <line1>,<line2>s!\v^- (Create|Alt): `(\w+)`\s+(.+)!// \3\rmessage \2 {\r}!ge
