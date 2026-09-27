-- Converted from UltiSnips' go_postfix.snippets
local S = require('user.snippets')

-- A variable name for an expression: its last word, singular and lowercase
-- (`$user.Items()` -> `item`), or `name`.
local function var_name(expr)
  local word = vim.fn.matchlist((expr:gsub('^[$@]+', '')), [[\C\v(\a\w{-1,})s?\W*$]])[2]
  return word and word:lower() or 'name'
end

local function name_var(snip)
  return { NAME = var_name(snip.captures[1]) }
end

return {
  S.snip([[\v(\S+)\.var]], 'name := expr', 'r', [[
${1:$NAME} := $LS_CAPTURE_1]], { vars = name_var }),
  S.snip([[\v(\S+)\.varr]], 'var name T = expr', 'r', [[
var ${1:$NAME} ${2:Type} = $LS_CAPTURE_1]], { vars = name_var }),
  S.snip([[\v(\S+)\.const]], 'const name = expr', 'r', [[
const ${1:$NAME} = $LS_CAPTURE_1]], { vars = name_var }),
  S.snip([[\v(\S+)\.par]], '(expr)', 'r', [[
($LS_CAPTURE_1)]]),
  S.snip([[\v(\S+)\.if]], 'if expr', 'r', [[
if $LS_CAPTURE_1 {
	$0
}]]),
  S.snip([[\v(\S+)\.else]], 'if !expr', 'r', [[
if !$LS_CAPTURE_1 {
	$0
}]]),
  S.snip([[\v(\S+)\.(null|nil)]], 'if expr == nil', 'r', [[
if $LS_CAPTURE_1 == nil {
	$0
}]]),
  S.snip([[\v(\S+)\.(notnull|notnil|nn)]], 'if expr != nil', 'r', [[
if $LS_CAPTURE_1 != nil {
	$0
}]]),
  S.snip([[\v(\S+)\.for]], 'for item := range expr', 'r', [[
for ${1:item} := range $LS_CAPTURE_1 {
	$0
}]]),
  S.snip([[\v(\S+)\.fori]], 'for k, v := range expr', 'r', [[
for ${1:k}, ${2:v} := range $LS_CAPTURE_1 {
	$0
}]]),
  S.snip([[\v(\S+)\.forv]], 'for _, v := range expr', 'r', [[
for _, ${1:v} := range $LS_CAPTURE_1 {
	$0
}]]),
  S.snip([[\v(\S+)\.while]], 'for expr', 'r', [[
for $LS_CAPTURE_1 {
	$0
}]]),
  S.snip([[\v(\S+)\.switch]], 'switch expr', 'r', [[
switch $LS_CAPTURE_1 {
	$0
}]]),
  S.snip([[\v(\S+)\.append]], 'expr = append(expr, _)', 'r', [[
$LS_CAPTURE_1 = append($LS_CAPTURE_1, $1)]]),
}
