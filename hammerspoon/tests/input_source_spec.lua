-- input_source.lua: Ctrl-; selecting the next input source
local fake = require('hs')
local t = require('t')
local it, keys, received, did = t.it, t.keys, t.received, t.did

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
