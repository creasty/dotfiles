-- Converted from UltiSnips' tex.snippets
local S = require('user.snippets')

-- `3` -> `$1 & $2 & $3`
local function row_placeholders(count)
  local placeholders = {}
  for n = 1, tonumber(count) do
    placeholders[n] = '$' .. n
  end
  return table.concat(placeholders, ' & ')
end

return {
  S.snip([[\vtr(\d+)]], 'latex table row variable', 'br', {
    S.anon(function(snip)
      return row_placeholders(snip.captures[1])
    end),
  }, { docTrig = 'tr3' }),
  S.snip([[%\@<!%]], 'Heading 1', 'br', '%=== $0\n%' .. ('='):rep(94)),
  S.snip([[%\@<!%%]], 'Heading 2', 'br', '%  $0\n%' .. ('-'):rep(47)),
}
