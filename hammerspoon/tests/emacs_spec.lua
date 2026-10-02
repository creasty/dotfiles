-- emacs.lua: Emacs mode, and Escape switching to English
local fake = require('hs')
local t = require('t')
local it, keys, received = t.it, t.keys, t.received

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

it('Emacs and VS Code keep the Emacs keys, but Ctrl-C is Escape', function()
  for _, app in ipairs({ 'org.gnu.Emacs', 'com.microsoft.VSCode' }) do
    fake.front, fake.received = app, {}
    keys('ctrl+p↓ ctrl+p↑ ctrl+j↓ ctrl+j↑ ctrl+a↓ ctrl+a↑ ctrl+c↓ ctrl+c↑')
    received('ctrl+p↓ ctrl+p↑ ctrl+j↓ ctrl+j↑ ctrl+a↓ ctrl+a↑ eisu↓ eisu↑ escape↓ escape↑')
  end
end)

--  Switch input source with Escape key
--------------------------------------------------
it('Escape switches to English (EISUU) first', function()
  keys('escape↓ escape↑ shift+escape↓ shift+escape↑')
  received('eisu↓ eisu↑ escape↓ escape↑ shift+escape↓ shift+escape↑')
end)
