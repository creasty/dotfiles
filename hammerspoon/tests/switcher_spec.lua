-- switcher.lua: the application switcher, which S holds open
local fake = require('hs')
local t = require('t')
local it, keys, received = t.it, t.keys, t.received

it('S+J and S+K go through the application switcher, which the release of S closes', function()
  keys('s↓ 200ms j↓ j↑ 200ms j↓ j↑ k↓ k↑')
  received('cmd↓ cmd+tab↓ cmd+tab↑ cmd+tab↓ cmd+tab↑ shift+cmd+tab↓ shift+cmd+tab↑')
  fake.received = {}
  keys('s↑')
  received('cmd↑')
end)

it('another chord closes the application switcher first', function()
  keys('s↓ 200ms j↓ j↑ 200ms h↓ h↑ s↑')
  received('cmd↓ cmd+tab↓ cmd+tab↑ cmd↑ ctrl+fn+left↓ ctrl+fn+left↑')
end)

it('a key with modifiers closes the application switcher', function()
  keys('s↓ 200ms j↓ j↑ 200ms cmd+w↓ cmd+w↑ s↑')
  received('cmd↓ cmd+tab↓ cmd+tab↑ cmd↑ cmd+w↓ cmd+w↑')
end)
