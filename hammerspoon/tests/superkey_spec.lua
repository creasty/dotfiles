-- superkey.lua: what a super key types, and when the chords held with it act
local t = require('t')
local it, keys, received, did = t.it, t.keys, t.received, t.did

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

it('holding S+H moves on at the pace of key repeat', function()
  keys('s↓ 200ms h↓ 200ms h⟳ h⟳ h↑ s↑')
  received(('ctrl+fn+left↓ ctrl+fn+left↑ '):rep(3):sub(1, -2))
end)

it('a semicolon types, before a return too', function()
  keys(';↓ 30ms ;↑ 30ms ;↓ 60ms return↓ ;↑ return↑')
  received(';↓ ;↑ ;↓ ;↑ return↓ return↑')
end)
