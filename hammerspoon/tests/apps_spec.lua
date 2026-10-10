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

-- 1Password's settings, with what clicking its menu bar icon does
local ONEPASSWORD_SETTINGS = '~/Library/Group Containers/2BUA8C4S2C.com.1password'
  .. '/Library/Application Support/1Password/Data/settings/settings.json'
local function tray_action(action) fake.json_files[ONEPASSWORD_SETTINGS] = { ['app.trayAction'] = action } end

it(';+1 clicks the menu bar icon of 1Password, which shows its Quick Access or hides it', function()
  fake.menu_bar_icons['com.1password.1password'] = true
  tray_action('quickAccess')
  keys(';↓ 200ms 1↓ 1↑ 200ms 1↓ 1↑ ;↑')
  did('click com.1password.1password menu bar icon, click com.1password.1password menu bar icon')
  received('')
end)

it(';+1 starts 1Password with --quick-access when its settings do not say the icon shows Quick Access', function()
  fake.menu_bar_icons['com.1password.1password'] = true
  -- Unreadable, then set to show a menu
  keys(';↓ 200ms 1↓ 1↑ 200ms ;↑')
  tray_action('menu')
  keys(';↓ 200ms 1↓ 1↑ 200ms ;↑')
  did('1Password --quick-access, 1Password --quick-access')
end)

it(';+1 starts 1Password with --quick-access when it has no menu bar icon', function()
  tray_action('quickAccess')
  keys(';↓ 200ms 1↓ 1↑ 200ms ;↑')
  did('1Password --quick-access')
end)

it(';+1 launches 1Password when it is not running', function()
  fake.stopped['com.1password.1password'] = true
  keys(';↓ 200ms 1↓ 1↑ 200ms ;↑')
  did('focus com.1password.1password')
end)
