-- keyboard.lua: what reaches the apps as keys are typed, and what else happens
local fake = require('hs')

local function keys(line) fake.type(line) end

local function expect(actual, expected)
  if actual ~= expected then error(('\nexpected: %s\nactual:   %s'):format(expected, actual), 2) end
end

-- What reached the apps
local function received(expected) expect(table.concat(fake.received, ' '), expected) end

-- What else happened
local function did(expected) expect(table.concat(fake.calls, ', '), expected) end

local function it(name, fn)
  test(name, function()
    require('keyboard').start()
    fn()
  end)
end

--  Super keys
--------------------------------------------------
it('a super key tapped types itself', function()
  keys('s↓ 30ms s↑')
  received('s↓ s↑')
end)

it('a super key held on its own types itself once, as it is released', function()
  keys('s↓ 300ms s⟳ s⟳ 100ms s↑')
  received('s↓ s↑')
end)

it('a super key pressed with modifiers types', function()
  keys('shift+s↓ shift+s↑ 30ms s↓ 30ms s↑')
  received('shift+s↓ shift+s↑ s↓ s↑')
end)

it('typing rolls over a super key, however long it is held after', function()
  keys('s↓ 30ms t↓')
  received('s↓ s↑ t↓')
  keys('200ms t⟳ t↑ s↑')
  received('s↓ s↑ t↓ t↓ t↑')
end)

it('typing rolls over a super key onto another', function()
  keys('a↓ 30ms s↓ 20ms a↑ 30ms s↑')
  received('a↓ a↑ s↓ s↑')
end)

it('released, a super key leaves the keys after it alone', function()
  keys('s↓ 200ms h↓ h↑ 200ms s↑ h↓ h↑')
  received('ctrl+fn+left↓ ctrl+fn+left↑ h↓ h↑')
end)

it('releasing a super key before a chord acts types all, in order', function()
  keys('s↓ 80ms t↓ 50ms r↓ 20ms s↑ t↑ r↑')
  received('s↓ s↑ t↓ r↓ t↑ r↑')
end)

it('keys released before the super key type as they were', function()
  keys('s↓ 80ms t↓ t↑ 20ms s↑')
  received('s↓ s↑ t↓ t↑')
end)

it('keys pressed before a super key pass', function()
  keys('t↓ s↓ 80ms t↑ 30ms s↑')
  received('t↓ t↑ s↓ s↑')
end)

it('keys typed fast past a super key type, even when a chord of theirs has a shortcut', function()
  -- S+D+K
  keys('s↓ 70ms d↓ 60ms k↓ 20ms s↑ d↑ k↑')
  received('s↓ s↑ d↓ k↓ d↑ k↑')
  did('')
end)

it('a chord acts once the super key has been held past its last key', function()
  keys('s↓ 200ms d↓ 50ms f↓ 140ms')
  did('')
  keys('10ms')
  did('move 0,0,1,1')
end)

it('keys held with a super key make a chord even with no shortcut, and type nothing', function()
  keys('s↓ 200ms g↓ 200ms g↑ s↑')
  received('')
end)

it('a key taken by a chord stays with it past the super key', function()
  keys('s↓ 200ms g↓ 200ms s↑ g⟳ g⟳ g↑')
  received('')
end)

it('a key with modifiers ends a super key, typing it first', function()
  keys('s↓ 80ms cmd+v↓ cmd+v↑ 30ms v↓ v↑ s↑')
  received('s↓ s↑ cmd+v↓ cmd+v↑ v↓ v↑')
end)

it('a key with modifiers ends a super key after a chord, typing nothing', function()
  keys('s↓ 200ms h↓ h↑ 200ms cmd+v↓ cmd+v↑ s↑')
  received('ctrl+fn+left↓ ctrl+fn+left↑ cmd+v↓ cmd+v↑')
end)

it('a super key pressed again, its release unseen, starts over', function()
  keys('s↓ 80ms t↓ 20ms s↓ 30ms s↑ t↑')
  received('s↓ s↑ t↓ s↓ s↑ t↑')
end)

it('a super key is a key of the chords of another', function()
  keys('a↓ 30ms a↑ s↓ 200ms a↓ a↑ 200ms s↑')
  received('a↓ a↑')
end)

--  Window/space navigation
--------------------------------------------------
it('S+H and S+L move to the space on the left and on the right', function()
  keys('s↓ 200ms h↓ h↑ 200ms l↓ l↑ s↑')
  received('ctrl+fn+left↓ ctrl+fn+left↑ ctrl+fn+right↓ ctrl+fn+right↑')
end)

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

it('S+N and S+B move the focus to the next window and back', function()
  keys('s↓ 200ms n↓ n↑ 200ms b↓ b↑ s↑')
  received('cmd+fn+f1↓ cmd+fn+f1↑ shift+cmd+fn+f1↓ shift+cmd+fn+f1↑')
end)

it('S+M shows Mission Control', function()
  keys('s↓ 200ms m↓ m↑ 200ms s↑')
  did('mission control')
  received('')
end)

it('holding S+H moves on at the pace of key repeat', function()
  keys('s↓ 200ms h↓ 200ms h⟳ h⟳ h↑ s↑')
  received(('ctrl+fn+left↓ ctrl+fn+left↑ '):rep(3):sub(1, -2))
end)

--  Window resizing/positioning
--------------------------------------------------
it('S+D+F, H, J, K and L fill the screen, its left, bottom, top and right halves', function()
  keys('s↓ 200ms d↓ 200ms f↓ f↑ h↓ h↑ j↓ j↑ k↓ k↑ l↓ l↑ d↑ s↑')
  did('move 0,0,1,1, move 0,0,0.5,1, move 0,0.5,1,0.5, move 0,0,1,0.5, move 0.5,0,0.5,1')
  received('')
end)

it('with no window focused, a window chord does nothing', function()
  fake.window = false
  keys('s↓ 200ms d↓ 200ms f↓ f↑ d↑ s↑')
  did('')
end)

--  Word motions
--------------------------------------------------
it('A+B and A+F move by word, A+H and A+D delete a word', function()
  keys('a↓ 200ms b↓ b↑ 200ms f↓ f↑ h↓ h↑ d↓ d↑ a↑')
  received('alt+left↓ alt+left↑ alt+right↓ alt+right↑ alt+delete↓ alt+delete↑ alt+forwarddelete↓ alt+forwarddelete↑')
end)

--  Switch between apps
--------------------------------------------------
it(';+F brings Finder to the front, or hides it when it is there', function()
  keys(';↓ 200ms f↓ f↑ 200ms f↓ f↑ ;↑')
  did('focus com.apple.finder, hide com.apple.finder')
  received('')
end)

it(';+M, ;+T and ;+N bring Alacritty, Things and Bear to the front', function()
  keys(';↓ 200ms m↓ m↑ 200ms t↓ t↑ n↓ n↑ ;↑')
  did('focus org.alacritty, focus com.culturedcode.ThingsMac, focus net.shinyfrog.bear')
end)

it('a semicolon types, before a return too', function()
  keys(';↓ 30ms ;↑ 30ms ;↓ 60ms return↓ ;↑ return↑')
  received(';↓ ;↑ ;↓ ;↑ return↓ return↑')
end)

--  Emacs mode
--------------------------------------------------
it('Ctrl-P, N, B and F are the arrow keys, with Shift too', function()
  keys('ctrl+p↓ ctrl+p↑ ctrl+shift+n↓ ctrl+shift+n↑ ctrl+b↓ ctrl+b⟳ ctrl+b↑ ctrl+f↓ ctrl+f↑')
  received('up↓ up↑ shift+down↓ shift+down↑ left↓ left↓ left↑ right↓ right↑')
end)

it('Ctrl-A and E go to the beginning and the end of the line, with Shift too', function()
  keys('ctrl+a↓ ctrl+a↑ ctrl+shift+e↓ ctrl+shift+e↑')
  received('cmd+left↓ cmd+left↑ shift+cmd+right↓ shift+cmd+right↑')
end)

it('Ctrl-D, H and J are Forward Delete, Delete and Return, but not with Shift', function()
  keys('ctrl+d↓ ctrl+d↑ ctrl+h↓ ctrl+h↑ ctrl+j↓ ctrl+j↑ ctrl+shift+h↓ ctrl+shift+h↑')
  received('forwarddelete↓ forwarddelete↑ delete↓ delete↑ return↓ return↑ ctrl+shift+h↓ ctrl+shift+h↑')
end)

it('Ctrl-C is Escape, switching to English (EISUU) first', function()
  keys('ctrl+c↓ ctrl+c↑')
  received('eisu↓ eisu↑ escape↓ escape↑')
end)

it('with Command or Option, Control keys stay', function()
  keys('ctrl+cmd+p↓ ctrl+cmd+p↑ ctrl+alt+c↓ ctrl+alt+c↑ ctrl+shift+c↓ ctrl+shift+c↑')
  received('ctrl+cmd+p↓ ctrl+cmd+p↑ ctrl+alt+c↓ ctrl+alt+c↑ ctrl+shift+c↓ ctrl+shift+c↑')
end)

it('terminals keep Ctrl-C, still switching to English, and the Emacs keys', function()
  for _, terminal in ipairs({ 'net.kovidgoyal.kitty', 'org.alacritty', 'com.mitchellh.ghostty' }) do
    fake.front, fake.received = terminal, {}
    keys('ctrl+c↓ ctrl+c↑ ctrl+p↓ ctrl+p↑ ctrl+a↓ ctrl+a↑')
    received('eisu↓ eisu↑ ctrl+c↓ ctrl+c↑ ctrl+p↓ ctrl+p↑ ctrl+a↓ ctrl+a↑')
  end
end)

it('VS Code keeps Ctrl-D, H, A and E', function()
  fake.front = 'com.microsoft.VSCode'
  keys('ctrl+d↓ ctrl+d↑ ctrl+h↓ ctrl+h↑ ctrl+a↓ ctrl+a↑ ctrl+e↓ ctrl+e↑ ctrl+p↓ ctrl+p↑ ctrl+c↓ ctrl+c↑')
  received('ctrl+d↓ ctrl+d↑ ctrl+h↓ ctrl+h↑ ctrl+a↓ ctrl+a↑ ctrl+e↓ ctrl+e↑ up↓ up↑ eisu↓ eisu↑ escape↓ escape↑')
end)

it('Emacs keeps the Emacs keys, but Ctrl-C is Escape', function()
  fake.front = 'org.gnu.Emacs'
  keys('ctrl+p↓ ctrl+p↑ ctrl+c↓ ctrl+c↑')
  received('ctrl+p↓ ctrl+p↑ eisu↓ eisu↑ escape↓ escape↑')
end)

--  Switch input source
--------------------------------------------------
it('Ctrl-; selects the next input source, going through a layout to an input method', function()
  keys('ctrl+;↓ ctrl+;↑')
  did('select com.apple.keylayout.ABC, select com.google.inputmethod.Japanese.base')
  received('ctrl+;↑')
  fake.calls = {}
  keys('ctrl+;↓ ctrl+;↑')
  did('select com.apple.keylayout.ABC')
end)

it('Ctrl-; held selects once', function()
  keys('ctrl+;↓ ctrl+;⟳ ctrl+;⟳ ctrl+;↑')
  did('select com.apple.keylayout.ABC, select com.google.inputmethod.Japanese.base')
end)

it('Ctrl-; goes around the layouts, then the input methods', function()
  fake.layouts = { 'com.apple.keylayout.ABC', 'com.apple.keylayout.Dvorak' }
  fake.methods = { 'com.google.inputmethod.Japanese.base', 'com.google.inputmethod.Japanese.Katakana' }
  fake.source = 'com.google.inputmethod.Japanese.base'
  keys('ctrl+;↓ ctrl+;↑ ctrl+;↓ ctrl+;↑ ctrl+;↓ ctrl+;↑')
  did(
    'select com.google.inputmethod.Japanese.Katakana, select com.apple.keylayout.ABC, select com.apple.keylayout.Dvorak'
  )
end)

it('Ctrl-; does nothing from an input source not in the menu', function()
  fake.source = 'com.apple.CharacterPaletteIM'
  keys('ctrl+;↓ ctrl+;↑')
  did('')
end)

--  Switch input source with Escape key
--------------------------------------------------
it('Escape switches to English (EISUU) first', function()
  keys('escape↓ escape↑ shift+escape↓ shift+escape↑')
  received('eisu↓ eisu↑ escape↓ escape↑ shift+escape↓ shift+escape↑')
end)

--  The tap
--------------------------------------------------
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
  require('keyboard').start()
  expect(#fake.taps, 1)
  keys('s↓ 30ms s↑')
  received('s↓ s↑')
end)

it('stopped, keys pass', function()
  require('keyboard').stop()
  keys('s↓ s↑ ctrl+p↓')
  received('s↓ s↑ ctrl+p↓')
end)

--  init.lua
--------------------------------------------------
test('init.lua starts Hammerspoon at login, and the keys', function()
  dofile(package.searchpath('init', package.path))
  expect(fake.autolaunch, true)
  expect(keyboard, require('keyboard'))
  fake.type('ctrl+p↓ ctrl+p↑')
  received('up↓ up↑')
end)
