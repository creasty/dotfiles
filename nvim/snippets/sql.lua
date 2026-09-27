-- Converted from UltiSnips' sql.snippets
local S = require('user.snippets')

return {
  S.snip('select', 'select statement', 'b', [[
select
	
from
	${1:table}]]),
  S.snip('date', 'Description', 'b', [[
date('$CURRENT_YEAR-$CURRENT_MONTH-$CURRENT_DATE')]]),
  S.snip('--', 'Heading', 'b', '-- $0\n--' .. ('-'):rep(47)),
}
