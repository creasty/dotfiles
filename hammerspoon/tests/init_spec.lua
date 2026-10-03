-- init.lua: the shortcuts it acts on itself, its event tap, and starting at login
local fake = require('hs')
local t = require('t')
local it, keys, expect, received, did = t.it, t.keys, t.expect, t.received, t.did

--  Window/space navigation
--------------------------------------------------
it('S+H and S+L move to the space on the left and on the right', function()
  keys('s↓ 200ms h↓ h↑ 200ms l↓ l↑ s↑')
  received('ctrl+fn+left↓ ctrl+fn+left↑ ctrl+fn+right↓ ctrl+fn+right↑')
end)

it('S+M shows Mission Control', function()
  keys('s↓ 200ms m↓ m↑ 200ms s↑')
  did('mission control')
  received('')
end)

--  Word motions
--------------------------------------------------
it('A+B and A+F move by word, A+H and A+D delete a word', function()
  keys('a↓ 200ms b↓ b↑ 200ms f↓ f↑ h↓ h↑ d↓ d↑ a↑')
  received('alt+left↓ alt+left↑ alt+right↓ alt+right↑ alt+delete↓ alt+delete↑ alt+forwarddelete↓ alt+forwarddelete↑')
end)

--  The tap
--------------------------------------------------
it('Ctrl-; reaches macOS, for its shortcut that selects the next input source', function()
  keys('ctrl+;↓ ctrl+;⟳ ctrl+;↑')
  received('ctrl+;↓ ctrl+;↓ ctrl+;↑')
end)

it('an error in an action is logged, and the keys still act', function()
  hs.window.focusedWindow = function() error('AX timed out') end
  keys('s↓ 200ms d↓ 200ms f↓ f↑ d↑ s↑ ctrl+p↓ ctrl+p↑')
  expect(#fake.logged, 1)
  expect(fake.logged[1]:match('AX timed out') ~= nil, true)
  fake.logged = {}
  received('up↓ up↑')
end)

it('an error in the tap lets the key through, and starts over', function()
  hs.application.frontmostApplication = function() error('boom') end
  -- S forgotten, its release passes too
  keys('s↓ 200ms j↓ j↑ 200ms ctrl+p↓ ctrl+p↑ s↑ s↓ s↑')
  expect(#fake.logged, 2)
  fake.logged = {}
  received('cmd↓ cmd+tab↓ cmd+tab↑ cmd↑ ctrl+p↓ ctrl+p↑ s↑ s↓ s↑')
end)

it('starting again replaces the tap', function()
  keyboard.start()
  expect(#fake.taps, 1)
  keys('s↓ 30ms s↑')
  received('s↓ s↑')
end)

it('stopped, keys pass', function()
  keyboard.stop()
  keys('s↓ s↑ ctrl+p↓')
  received('s↓ s↑ ctrl+p↓')
end)

--  init.lua
--------------------------------------------------
test('init.lua starts Hammerspoon at login, and the keys', function()
  dofile(package.searchpath('init', package.path))
  expect(fake.autolaunch, true)
  fake.type('ctrl+p↓ ctrl+p↑')
  received('up↓ up↑')
end)
