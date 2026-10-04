local S = require('user.snippets')

-- `x-` -> `x -> `: the word before an arrow, spaced out.
local function spaced(word)
  return word ~= '' and word .. ' ' or ''
end

return {
  S.snip('lorem', 'Lorem (446 chars)', 'b', [[
Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.]], { priority = 999 }),
  S.snip([[\v(\S?)[<-]@<!(-{1,2})\s?]], 'Arrow', 'r', {
    S.eval(function(snip)
      return spaced(snip.captures[1] or '') .. (#snip.captures[2] == 1 and '-> ' or '<- ')
    end),
  }, { priority = 999 }),
  S.snip([[\v(\S?)[<=]@<!(\={1,2})\s?]], 'Fat arrow', 'r', {
    S.eval(function(snip)
      return spaced(snip.captures[1] or '') .. (#snip.captures[2] == 1 and '=> ' or '<= ')
    end),
  }, { priority = 999 }),
  S.snip([[\v([=-]\>|\<[=-])\s?]], 'Toggle arrow', 'r', {
    S.capture(1, function(arrow)
      return arrow:sub(1, 1) == '<' and arrow:sub(2, 2) .. '> ' or '<' .. arrow:sub(1, 1) .. ' '
    end),
  }, { priority = 999 }),
}
