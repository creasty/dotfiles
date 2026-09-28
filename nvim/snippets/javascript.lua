local S = require('user.snippets')

return {
  S.snip('cdebug', 'console.debug()', 'b', [[
console.debug($0);]]),
  S.snip('clog', 'console.log()', 'b', [[
console.log($0);]]),
  S.snip('cerror', 'console.error()', 'b', [[
console.error($0);]]),
  S.snip('cwarn', 'console.warn()', 'b', [[
console.warn($0);]]),
  S.snip('times', '.times', '', [[
Array.from({ length: $1 }, (_, i) => i$0)]]),
  S.snip('iife', 'Immediately Invoked Function Expression', '', [[
(() => {
	$0
})();]]),
}
