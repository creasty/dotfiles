-- quit.lua: the guard on Cmd-Q
local fake = require('hs')
local t = require('t')
local keys, received = t.keys, t.received

-- In an app that quits on Cmd-Q
local function it(name, fn)
  t.it(name, function()
    fake.front = 'com.apple.TextEdit'
    fn()
  end)
end

it('Cmd-Q pressed once is held back', function()
  keys('cmd+q↓ cmd+q↑')
  received('cmd+q↑')
end)

it('Cmd-Q pressed again within 300 ms quits', function()
  keys('cmd+q↓ cmd+q↑ 290ms cmd+q↓ cmd+q↑')
  received('cmd+q↑ cmd+q↓ cmd+q↑')
end)

it('Cmd-Q pressed again later, or a third time, is held back as a first', function()
  keys('cmd+q↓ cmd+q↑ 300ms cmd+q↓ cmd+q↑ 100ms cmd+q↓ cmd+q↑ 100ms cmd+q↓ cmd+q↑')
  received('cmd+q↑ cmd+q↑ cmd+q↓ cmd+q↑ cmd+q↑')
end)

it('Cmd-Q held down does not repeat', function()
  keys('cmd+q↓ 200ms cmd+q⟳ cmd+q⟳ cmd+q↑ 50ms cmd+q↓ 200ms cmd+q⟳ cmd+q↑')
  received('cmd+q↑ cmd+q↓ cmd+q↑')
end)

it('Q with Shift, Option or Control besides Command passes', function()
  keys('shift+cmd+q↓ shift+cmd+q↑ alt+cmd+q↓ alt+cmd+q↑ ctrl+cmd+q↓ ctrl+cmd+q↑')
  received('shift+cmd+q↓ shift+cmd+q↑ alt+cmd+q↓ alt+cmd+q↑ ctrl+cmd+q↓ ctrl+cmd+q↑')
end)

it('Chrome, which guards Cmd-Q itself, gets it as it is', function()
  fake.front = 'com.google.Chrome'
  keys('cmd+q↓ cmd+q↑ 500ms cmd+q↓ 200ms cmd+q⟳ cmd+q↑')
  received('cmd+q↓ cmd+q↑ cmd+q↓ cmd+q↓ cmd+q↑')
end)
