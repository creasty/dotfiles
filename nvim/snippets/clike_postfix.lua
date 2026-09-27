-- Converted from UltiSnips' clike_postfix.snippets
local S = require('user.snippets')

return {
  S.snip([[\v(\S+)\.par]], '(expr)', 'r', [[
($LS_CAPTURE_1)$0]]),
  S.snip([[\v(\S+)\.if]], 'if (expr)', 'r', [[
if ($LS_CAPTURE_1) {
	$0
}]]),
  S.snip([[\v(\S+)\.else]], 'if (!expr)', 'r', [[
if (!$LS_CAPTURE_1) {
	$0
}]]),
  S.snip([[\v(\S+)\.(null|nil)]], 'if (expr == null)', 'r', [[
if ($LS_CAPTURE_1 == null) {
	$0
}]]),
  S.snip([[\v(\S+)\.(notnull|notnil|nn)]], 'if (expr != null)', 'r', [[
if ($LS_CAPTURE_1 != null) {
	$0
}]]),
  S.snip([[\v(\S+)\.while]], 'while (expr)', 'r', [[
while ($LS_CAPTURE_1) {
	$0
}]]),
  S.snip([[\v(\S+)\.switch]], 'switch (expr)', 'r', [[
switch ($LS_CAPTURE_1) {
	$0
}]]),
}
