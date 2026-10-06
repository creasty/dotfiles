-- apps.lua: bringing an app to the front, or hiding it
local fake = require('hs')
local t = require('t')
local it, keys, received, did = t.it, t.keys, t.received, t.did

it(';+F brings Finder to the front, or hides it when it is there', function()
  keys(';↓ 200ms f↓ f↑ 200ms f↓ f↑ ;↑')
  did('focus com.apple.finder, hide com.apple.finder')
  received('')
end)

it(';+M, ;+T and ;+N bring kitty, Toggl Track and Bear to the front', function()
  keys(';↓ 200ms m↓ m↑ 200ms t↓ t↑ n↓ n↑ ;↑')
  did('kitten ls, focus net.kovidgoyal.kitty, focus com.toggl.daneel, focus net.shinyfrog.bear')
end)

it(';+M brings kitty back with the window it had in front, when another space shows another', function()
  local one, two = { id = 1, kitty = 10 }, { id = 2, kitty = 20 }
  fake.front, fake.windows = 'net.kovidgoyal.kitty', { two, one }
  keys(';↓ 200ms m↓ m↑ 200ms ;↑')
  fake.space, fake.windows = 2, { one, two }
  keys(';↓ 200ms m↓ m↑ 200ms ;↑')
  did('hide net.kovidgoyal.kitty, kitten ls, focus net.kovidgoyal.kitty, focus window 2')
end)

it(';+M leaves the window in front alone once kitty was shown otherwise since it hid it', function()
  fake.front, fake.windows = 'net.kovidgoyal.kitty', { { id = 2, kitty = 20 }, { id = 1, kitty = 10 } }
  keys(';↓ 200ms m↓ m↑ 200ms ;↑')
  -- Shown with Cmd-Tab, then left for Chrome
  fake.hidden, fake.front = {}, 'com.google.Chrome'
  keys(';↓ 200ms m↓ m↑ 200ms ;↑')
  did('hide net.kovidgoyal.kitty, kitten ls, focus net.kovidgoyal.kitty')
end)
