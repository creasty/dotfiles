-- windows.lua: focusing and moving the app's windows
local fake = require('hs')
local t = require('t')
local it, keys, received, did = t.it, t.keys, t.received, t.did

--  Window/space navigation
--------------------------------------------------
it('S+N and S+B focus the next window of the app and the previous one, in the order they opened', function()
  -- Front to back, with a panel
  fake.windows = { { id = 12 }, { id = 10 }, { id = 13, standard = false }, { id = 11 } }
  keys('s↓ 200ms n↓ n↑ 200ms n↓ n↑ n↓ n↑ b↓ b↑ s↑')
  did('focus window 10, focus window 11, focus window 12, focus window 11')
  received('')
end)

it('from a focused panel, S+N and S+B go on from where it opened', function()
  fake.windows = { { id = 11, standard = false }, { id = 10 }, { id = 12 } }
  keys('s↓ 200ms n↓ n↑ 200ms b↓ b↑ s↑')
  did('focus window 12, focus window 10')
end)

--  Window resizing/positioning
--------------------------------------------------
it('S+D+F, H, J, K and L fill the screen, its left, bottom, top and right halves', function()
  keys('s↓ 200ms d↓ 200ms f↓ f↑ h↓ h↑ j↓ j↑ k↓ k↑ l↓ l↑ d↑ s↑')
  did('move 0,0,1,1, move 0,0,0.5,1, move 0,0.5,1,0.5, move 0,0,1,0.5, move 0.5,0,0.5,1')
  received('')
end)

it('with no window focused, window chords do nothing', function()
  fake.windows = {}
  keys('s↓ 200ms d↓ 200ms f↓ f↑ d↑ n↓ n↑ b↓ b↑ s↑')
  did('')
end)
