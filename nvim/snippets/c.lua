local S = require('user.snippets')

-- `main.c` -> `MAIN_C`
local function guard_name()
  return (vim.fn.expand('%:t'):gsub('[^%w_]+', '_'):upper())
end

return {
  S.snip('def', 'ifndef define', 'b', [[
#ifndef ${1:SYMBOL}
#define $1 ${2:value}
#endif$0]]),
  S.snip('do', 'do { } while (expr)', 'b', [[
do {
	$0
} while ($1);]]),
  S.snip('enum', 'typedef enum', 'b', [[
typedef enum {
	$0
} ${1:name};]]),
  S.snip('struct', 'typedef struct', 'b', [[
typedef struct ${1:tag_name} {
	$0
} ${2:name};]]),
  S.snip('main', 'Create main()', 'b', [[
int
main(int argc, const char *argv[])
{
	$0
	return 0;
}]]),
  S.snip('guard', 'Include guard', 'b', [[
#ifndef __${1:${GUARD}_LOADED}
#define __$1

$0

#endif /* end of include guard: __$1 */]], {
    vars = function()
      return { GUARD = guard_name() }
    end,
  }),
  S.snip('#include ', 'Include', 'brA', [[
#include <$0>]]),
  S.snip([[\v(\w+)\.\.(\w)]], 'Description', 'rA', [[
$LS_CAPTURE_1->$LS_CAPTURE_2]]),
}
