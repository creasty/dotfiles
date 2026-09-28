local S = require('user.snippets')

-- A variable name for an expression: its last word, singular and lowercase
-- (`@user.items` -> `item`), or `name`.
local function var_name(expr)
  local word = vim.fn.matchlist((expr:gsub('^[$@]+', '')), [[\C\v(\a\w{-1,})s?\W*$]])[2]
  return word and word:lower() or 'name'
end

return {
  S.snip([[\v(\S+)\.var]], 'name = expr', 'r', [[
${1:$NAME} = $LS_CAPTURE_1]], {
    vars = function(snip)
      return { NAME = var_name(snip.captures[1]) }
    end,
  }),
  S.snip([[\v(\S+)\.par]], '(expr)', 'r', [[
($LS_CAPTURE_1)]]),
  S.snip([[\v(\S+)\.if]], 'if expr', 'r', [[
if $LS_CAPTURE_1
	$0
end]]),
  S.snip([[\v(\S+)\.else]], 'if !expr', 'r', [[
if !$LS_CAPTURE_1
	$0
end]]),
  S.snip([[\v(\S+)\.format]], 'format(expr)', 'r', [[
format($LS_CAPTURE_1, $0)]]),
}
