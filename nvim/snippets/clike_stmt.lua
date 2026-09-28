local S = require('user.snippets')

return {
  S.snip('if', 'if (expr)', 'b', [[
if ($1) {
	$0
}]], { priority = 999 }),
  S.snip('for', 'for (expr)', 'b', [[
for ($1) {
	$0
}]], { priority = 999 }),
  S.snip('while', 'while (expr)', 'b', [[
while ($1) {
	$0
}]], { priority = 999 }),
}
