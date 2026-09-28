local ls = require('luasnip')
local fmt = require('luasnip.extras.fmt').fmt
local S = require('user.snippets')

local i = ls.insert_node

-- `isOpen` -> `Open`, `count` -> `Count`: for setters and types.
local function capitalized(name)
  name = name:match('^is(.+)') or name:match('^has(.+)') or name
  return (name:gsub('^.', string.upper))
end

return {
  S.snip('useState', 'Variable for React.useState', 'b', fmt('const [{}, set{}] = useState<{}>({});', {
    i(1, 'state'),
    S.mirror(1, capitalized),
    S.placeholder(2, 1, capitalized),
    i(0),
  })),
  S.snip('useAdaptiveState', 'Variable for useAdaptiveState', 'b', fmt('const [{}, set{}] = useAdaptiveState<{}>({});', {
    i(1, 'state'),
    S.mirror(1, capitalized),
    S.placeholder(2, 1, capitalized),
    i(0),
  })),
  S.snip('useRef', 'Variable for React.useRef', 'b', fmt('const {} = useRef<{}>({});', {
    i(1, 'name'),
    S.placeholder(2, 1, capitalized),
    i(0),
  })),
  S.snip('useCallback', 'Variable for React.useCallback', 'b', [[
const ${1:name} = useCallback(() => $0, []);]]),
  S.snip('useMemo', 'Variable for React.useMemo', 'b', [[
const ${1:name} = useMemo(() => $0, []);]]),
  S.snip('useEffect', 'Variable for React.useEffect', 'b', [[
useEffect(() => $0, []);]]),
  S.snip('useLayoutEffect', 'Variable for React.useLayoutEffect', 'b', [[
useLayoutEffect(() => $0, []);]]),
  S.snip('fetchPolicy', 'Useful pair of fetchPolicy and nextFetchPolicy', 'b', [[
fetchPolicy: "cache-and-network",
nextFetchPolicy: "cache-first",]]),
}
