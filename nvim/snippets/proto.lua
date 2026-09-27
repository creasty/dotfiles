-- Converted from UltiSnips' proto.snippets
local ls = require('luasnip')
local fmt = require('luasnip.extras.fmt').fmt
local fmta = require('luasnip.extras.fmt').fmta
local S = require('user.snippets')

local i = ls.insert_node

-- `GetUser` -> `Get`, `User` (nil without a known verb)
local function split_verb(name)
  for _, verb in ipairs({ 'List', 'Search', 'Get', 'Create', 'UpdateMulti', 'Update', 'Delete' }) do
    local object = name:match('^' .. verb .. '([%w_]+)$')
    if object then
      return verb, object
    end
  end
end

-- `UserProfile` -> `user_profile`
local function snake_case(name)
  return (name:gsub('([a-z0-9])([A-Z])', '%1_%2'):lower())
end

-- The field name for a type: its last component in snake_case
-- (`google.protobuf.FieldMask` -> `field_mask`).
local function field_name(type_name)
  return snake_case(type_name:match('[^.]+$') or type_name)
end

-- `GetUser` -> `rpc GetUser (GetUserRequest) returns (User);`, with the
-- request and response types its verb calls for.
local function rpc_def(name)
  local verb, object = split_verb(name)
  local request, response = name .. 'Request', name .. 'Response'
  if verb == 'Get' or verb == 'Update' then
    response = object
  elseif verb == 'Create' then
    request, response = object, object
  elseif verb == 'Delete' then
    response = 'google.protobuf.Empty'
  end
  return ('rpc %s (%s) returns (%s);'):format(name, request, response)
end

-- `GetUserRequest` -> the fields its verb calls for in a request or response.
local function message_fields(name)
  local kind = name:match('Request$') or name:match('Response$')
  local verb, object = split_verb(kind and name:sub(1, -#kind - 1) or '')
  if not verb then
    return ''
  end
  local field = ('%s %s = 1 [ (google.api.field_behavior) = REQUIRED ];'):format(object, snake_case(object))
  if kind == 'Request' then
    if verb == 'Search' then
      return '    string query = 1 [ (google.api.field_behavior) = REQUIRED ];'
    elseif verb == 'Get' or verb == 'Delete' then
      return '    string uuid = 1 [ (google.api.field_behavior) = REQUIRED ];'
    elseif verb == 'Update' then
      return {
        '    ' .. field,
        '    // マスク',
        '    google.protobuf.FieldMask update_mask = 2 [ (google.api.field_behavior) = REQUIRED ];',
      }
    elseif verb == 'UpdateMulti' then
      return {
        '    // 更新用レコード',
        '    repeated Record records = 1 [ (google.api.field_behavior) = REQUIRED ];',
        '',
        '    message Record {',
        '        ' .. field,
        '        // レコード操作',
        '        RecordOperation record_operation = 2 [ (google.api.field_behavior) = REQUIRED ];',
        '        // マスク',
        '        google.protobuf.FieldMask field_mask = 3 [ (google.api.field_behavior) = OPTIONAL ];',
        '    }',
      }
    end
  elseif verb == 'List' or verb == 'Search' or verb == 'UpdateMulti' then
    return '    repeated ' .. field
  elseif verb == 'Get' then
    return '    ' .. field
  end
  return ''
end

-- `3` -> `4`
local function next_number(number)
  return number:match('^%d+$') and tostring(tonumber(number) + 1) or ''
end

return {
  S.snip('syntax', 'syntax proto3', 'b', [[
syntax = "proto3";]]),
  S.snip('package', 'package', 'b', [[
package $1;]]),
  S.snip('import', 'import', 'b', [[
import "$1";]]),
  S.snip('option-java', 'java options', 'b', [[
option java_package = "$1";
option java_multiple_files = true;]]),
  S.snip('rpc', 'define a rpc', 'b', [[
rpc ${1:Name} (${2:$1Request}) returns (${3:$1Response});]]),
  S.snip([[\vrpc (\w+)]], 'define a rpc', 'br', { S.capture(1, rpc_def) }),
  S.snip('service', 'define a service', 'b', [[
service ${1:Name}Service {
	$0
}]]),
  S.snip('enum', 'define a enum', 'b', [[
enum $1 {
	$0
}]]),
  S.snip('message', 'define a message', 'b', [[
message $1 {
	$0
}]]),
  S.snip([[\v(msg|message) (\w+)]], 'define a message', 'br', [[
message $LS_CAPTURE_2 {
${FIELDS}$0
}]], {
    vars = function(snip)
      return { FIELDS = message_fields(snip.captures[2]) }
    end,
  }),
  S.snip('single', 'define a single field', 'b', fmt('{} {} = {};', {
    i(1, 'Type'),
    S.placeholder(2, 1, field_name),
    i(3),
  })),
  S.snip('repeated', 'define a repeated field', 'b', fmt('repeated {} {} = {};', {
    i(1, 'Type'),
    S.placeholder(2, 1, field_name),
    i(3),
  })),
  S.snip('import timestamp', 'import from google/protobuf', 'b', [[
import "google/protobuf/timestamp.proto";]]),
  S.snip('Timestamp', 'google.protobuf.Timestamp', 'b', [[
google.protobuf.Timestamp]]),
  S.snip('import wrappers', 'import from google/protobuf', 'b', [[
import "google/protobuf/wrappers.proto";]]),
  S.snip('DoubleValue', 'google.protobuf.DoubleValue', 'b', [[
google.protobuf.DoubleValue]]),
  S.snip('FloatValue', 'google.protobuf.FloatValue', 'b', [[
google.protobuf.FloatValue]]),
  S.snip('Int64Value', 'google.protobuf.Int64Value', 'b', [[
google.protobuf.Int64Value]]),
  S.snip('UInt64Value', 'google.protobuf.UInt64Value', 'b', [[
google.protobuf.UInt64Value]]),
  S.snip('Int32Value', 'google.protobuf.Int32Value', 'b', [[
google.protobuf.Int32Value]]),
  S.snip('UInt32Value', 'google.protobuf.UInt32Value', 'b', [[
google.protobuf.UInt32Value]]),
  S.snip('BoolValue', 'google.protobuf.BoolValue', 'b', [[
google.protobuf.BoolValue]]),
  S.snip('StringValue', 'google.protobuf.StringValue', 'b', [[
google.protobuf.StringValue]]),
  S.snip('BytesValue', 'google.protobuf.BytesValue', 'b', [[
google.protobuf.BytesValue]]),
  S.snip('import field_behavior', 'import from google/api', 'b', [[
import "google/api/field_behavior.proto";]]),
  S.snip('OPTIONAL', 'Specifically denotes a field as optional', 'w', [[
(google.api.field_behavior) = OPTIONAL]]),
  S.snip('REQUIRED', 'Denotes a field as required', 'w', [[
(google.api.field_behavior) = REQUIRED]]),
  S.snip('OUTPUT_ONLY', 'Denotes a field as output only', 'w', [[
(google.api.field_behavior) = OUTPUT_ONLY]]),
  S.snip('INPUT_ONLY', 'Denotes a field as input only.', 'w', [[
(google.api.field_behavior) = INPUT_ONLY]]),
  S.snip('IMMUTABLE', 'Denotes a field as immutable', 'w', [[
(google.api.field_behavior) = IMMUTABLE]]),
  S.snip('import empty', 'import from google/protobuf', 'b', [[
import "google/protobuf/empty.proto";]]),
  S.snip('Empty', 'google.protobuf.Empty', 'w', [[
google.protobuf.Empty]]),
  S.snip('import field_mask', 'import from google/protobuf', 'b', [[
import "google/protobuf/field_mask.proto";]]),
  S.snip('FieldMask', 'google.protobuf.FieldMask', 'w', [[
google.protobuf.FieldMask]]),
  S.snip('update_mask', 'define update_mask', 'b', [[
// マスク
google.protobuf.FieldMask update_mask = $1 [ (google.api.field_behavior) = REQUIRED ];]]),
  S.snip('import any', 'import from google/protobuf', 'b', [[
import "google/protobuf/any.proto";]]),
  S.snip('Any', 'google.protobuf.Any', 'w', [[
google.protobuf.Any]]),
  S.snip('import date', 'import from google/type', 'b', [[
import "google/type/date.proto";]]),
  S.snip('Date', 'google.type.Date', 'w', [[
google.type.Date]]),
  S.snip('pagination', 'pagination request fields', 'b', fmta([[
// ページサイズ
int32 page_size = <> [ (google.api.field_behavior) = REQUIRED ];
// ページトークン
string page_token = <> [ (google.api.field_behavior) = REQUIRED ];]], { i(1), S.mirror(1, next_number) })),
  S.snip('next_page_token', 'pagination response field', 'b', [[
// 次のページトークン
string next_page_token = $1 [ (google.api.field_behavior) = REQUIRED ];]]),
  S.snip('import proto2graphql.option', 'import from proto2graphql/option', 'b', [[
import "proto2graphql/option.proto";]]),
  S.snip('skip_on_type', 'proto2graphql.option', 'w', [[
(proto2graphql.option).skip_on_type = true]]),
  S.snip('skip_on_input', 'proto2graphql.option', 'w', [[
(proto2graphql.option).skip_on_input = true]]),
  S.snip('import string_map_option', 'import from henryapp/util', 'b', [[
import "henryapp/util/string_map.proto";]]),
  S.snip('display_name', 'henryapp.util.string_map_option', 'w', [[
(henryapp.util.string_map_option) = {display_name : "$1"}]]),
  S.snip('import resource', 'import from henryapp/util', 'b', [[
import "henryapp/util/resource.proto";]]),
  S.snip('resource', 'henryapp.util.resource', 'w', [[
(henryapp.util.resource) = {type : "$1"}]]),
}
