-- Converted from UltiSnips' go.snippets
local ls = require('luasnip')
local fmta = require('luasnip.extras.fmt').fmta
local S = require('user.snippets')

local i = ls.insert_node

-- The package a file belongs to: its directory's name.
local function package_var()
  return { PACKAGE = vim.fn.expand('%:h:t') }
end

return {
  S.snip('func', 'Function', 'b', fmta([[
func <>(<>)<><> {
	<><>
}]], {
    i(1, 'name'),
    i(2, 'params'),
    -- a space before the result type, if any
    S.mirror(3, function(result)
      return result ~= '' and ' ' or ''
    end),
    i(3, 'type'),
    S.selection('\t'),
    i(0),
  })),
  S.snip('holder', 'Define holder field', 'b', [[
${1:name} struct {
	result ${2:Type}
	err    error
	once   sync.Once
}]]),
  S.snip('holderdo', 'Initialize holder', 'b', [[
holder := &c.${1:name}
holder.once.Do(func() {
	holder.result, holder.err = $0
})
return holder.result, holder.err]]),
  S.snip('if', 'if expr', 'b', [[
if $1 {
	$0
}]]),
  S.snip('for', 'for expr', 'b', [[
for $1 {
	$0
}]]),
  S.snip('package', 'Define package', 'b', [[
package $PACKAGE]], { vars = package_var }),
  S.snip('mockgen', 'go:generate mockgen', 'b', [[
//go:generate mockgen -source=$TM_FILENAME_BASE.go -package $PACKAGE -destination=${TM_FILENAME_BASE}_mock.go]], {
    vars = package_var,
  }),
  S.snip('stringer', 'go:generate stringer', 'b', [[
//go:generate stringer -type=${1:Type}]]),
}
