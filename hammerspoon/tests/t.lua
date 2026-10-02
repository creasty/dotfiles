-- What the specs share: tests with the config loaded, typing, and what they expect
local fake = require('hs')

local t = {}

function t.keys(line) fake.type(line) end

function t.expect(actual, expected)
  if actual ~= expected then error(('\nexpected: %s\nactual:   %s'):format(expected, actual), 2) end
end

-- What reached the apps
function t.received(expected) t.expect(table.concat(fake.received, ' '), expected) end

-- What else happened
function t.did(expected) t.expect(table.concat(fake.calls, ', '), expected) end

-- A test with the config loaded, as Hammerspoon loads it
function t.it(name, fn)
  test(name, function()
    dofile(package.searchpath('init', package.path))
    fn()
  end)
end

return t
