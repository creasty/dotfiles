local S = require('user.snippets')

-- The index parameter of the `.map()` callback the cursor is in, as `index` in
-- `items.map((item, index) => <Row ...`; `i` outside one, or where the code
-- doesn't parse yet.
local function map_index()
  local parser = vim.treesitter.get_parser(0, nil, { error = false })
  if not parser then
    return 'i'
  end
  parser:parse()
  local node = vim.treesitter.get_node()
  while node do
    local args = node:parent()
    local call = args and args:type() == 'arguments' and args:parent()
    local callee = call and call:field('function')[1]
    local method = callee and callee:type() == 'member_expression' and callee:field('property')[1]
    if method and vim.treesitter.get_node_text(method, 0) == 'map' then
      local params = node:field('parameters')[1]
      local index = params and params:named_child(1)
      -- (TypeScript wraps each parameter, typed or not)
      index = index and (index:field('pattern')[1] or index)
      return index and index:type() == 'identifier' and vim.treesitter.get_node_text(index, 0) or 'i'
    end
    node = node:parent()
  end
  return 'i'
end

return {
  S.snip('keyi', 'Indexed-based component key', 'w', [[
key={${1:$INDEX} /* eslint-disable-line react/no-array-index-key */}]], {
    vars = function()
      return { INDEX = map_index() }
    end,
  }),
}
