local S = require('user.snippets')

return {
  S.snip('FC', 'Define FC', 'b', [[
const ${1:Name}: React.FC$2 = ($3) => {
	$0
};]]),
}
