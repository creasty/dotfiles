-- kitty.lua: bringing kitty's windows on other spaces to the current one
local fake = require('hs')
local t = require('t')
local it, keys, did = t.it, t.keys, t.did

it(";+M brings kitty's windows on other spaces to the current one first, as kitty takes them off every space", function()
  local one = { id = 1, kitty = 10 }
  local two, three = { id = 2, kitty = 20, spaces = { 1 } }, { id = 3, kitty = 30, spaces = { 1 } }
  fake.front, fake.windows = 'net.kovidgoyal.kitty', { two, one, three }
  keys(';↓ 200ms m↓ m↑ 200ms ;↑')
  fake.space, fake.windows = 2, { one, two, three }
  keys(';↓ 200ms m↓ m↑ 200ms ;↑')
  did('hide net.kovidgoyal.kitty, kitten ls, kitten resize-os-window --match id:20 or id:30 --action hide, '
    .. 'kitten resize-os-window --match id:20 or id:30 --action show, focus net.kovidgoyal.kitty, focus window 2')
end)
