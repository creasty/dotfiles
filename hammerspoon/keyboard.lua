-- The key bindings of creasty/Keyboard (https://github.com/creasty/Keyboard), all but its mouse keys and its guard on
-- Cmd-Q. README.md lists them, with what they need from System Settings.
local superkey = require('superkey')

local M = {}

local log = hs.logger.new('keyboard', 'warning')
local types = hs.eventtap.event.types
local props = hs.eventtap.event.properties

-- Marks the events posted here, for the tap to let them through
local MARK = 0x4b4244 -- 'KBD'

-- Virtual key codes (Carbon's kVK_*), as Keyboard's: keys by their place, whatever the layout
local key = {
  a = 0x00, s = 0x01, d = 0x02, f = 0x03, h = 0x04, c = 0x08, b = 0x0b, e = 0x0e, t = 0x11, p = 0x23, l = 0x25,
  j = 0x26, k = 0x28, [';'] = 0x29, n = 0x2d, m = 0x2e,
  enter = 0x24, tab = 0x30, backspace = 0x33, escape = 0x35, command = 0x37, eisu = 0x66, forward_delete = 0x75,
  left = 0x7b, right = 0x7c, down = 0x7d, up = 0x7e,
}

local function set(list)
  local t = {}
  for _, v in ipairs(list) do t[v] = true end
  return t
end

--  Events
--------------------------------------------------
-- The events to post ahead of the one the tap is handling, while it is: posted from its callback, they would come
-- after it
local ahead

local function emit(event)
  event:setProperty(props.eventSourceUserData, MARK)
  if ahead then
    table.insert(ahead, event)
  else
    event:post()
  end
end

local function key_event(code, is_down, mods)
  return hs.eventtap.event.newKeyEvent(mods or {}, code, is_down)
end

local function stroke(code, mods)
  emit(key_event(code, true, mods))
  emit(key_event(code, false, mods))
end

-- Command going down or up on its own, as the keyboard reports it
local function command_event(is_down)
  local event = hs.eventtap.event.newKeyEvent(key.command, is_down)
  event:setType(types.flagsChanged)
  event:setFlags(is_down and { cmd = true } or {})
  return event
end

--  Actions
--------------------------------------------------
-- The application switcher stays open while Command is down: S+J and S+K keep it down until S is released, as if S
-- were Command
local switching = false

local function switch_app(mods)
  if not switching then
    emit(command_event(true))
    switching = true
  end
  stroke(key.tab, mods)
end

local function next_app() switch_app({ 'cmd' }) end
local function previous_app() switch_app({ 'cmd', 'shift' }) end

local function close_switcher()
  if not switching then return end
  emit(command_event(false))
  switching = false
end

local function move_window(unit)
  local win = hs.window.focusedWindow()
  if win then win:moveToUnit(unit, 0) end
end

-- Focuses the app's next window, or its previous one (step -1): going around its windows on the current space in the
-- order they opened, skipping panels and the like
local function focus_window(step)
  local focused = hs.window.focusedWindow()
  if not focused then return end
  local windows = {}
  for _, win in ipairs(focused:application():visibleWindows()) do
    if win:isStandard() or win == focused then table.insert(windows, win) end
  end
  -- Window IDs grow as windows open
  table.sort(windows, function(a, b) return a:id() < b:id() end)
  for i, win in ipairs(windows) do
    if win == focused then
      windows[(i - 1 + step) % #windows + 1]:focus()
      return
    end
  end
end

-- Brings the app to the front, launching it if needed, or hides it when it's already there
local function toggle_app(bundle_id)
  local app = hs.application.frontmostApplication()
  if app and app:bundleID() == bundle_id then
    app:hide()
  else
    hs.application.launchOrFocusByBundleID(bundle_id)
  end
end

-- Selects the next input source of the input menu, taking keyboard layouts before input methods
local function select_next_input_source()
  local layouts, sources, cjkv = hs.keycodes.layouts(true), {}, {}
  for _, id in ipairs(layouts) do table.insert(sources, id) end
  for _, id in ipairs(hs.keycodes.methods(true)) do
    table.insert(sources, id)
    cjkv[id] = true
  end
  local current = hs.keycodes.currentSourceID()
  for i, id in ipairs(sources) do
    if id == current then
      local following = sources[i % #sources + 1]
      -- As Keyboard: switching to a CJKV input method from a layout (TIS) may only change the menu's icon, unless a
      -- layout was selected just before
      if not cjkv[current] and cjkv[following] then hs.keycodes.currentSourceID(layouts[1]) end
      hs.keycodes.currentSourceID(following)
      return
    end
  end
end

--  Super keys: the super key, and the keys held with it
--------------------------------------------------
local shortcuts = {
  -- Window/space navigation. Moving a space strokes Mission Control's shortcut, as macOS has no public API for it:
  -- hs.spaces.gotoSpace clicks the space in Mission Control, showing it
  ['S+H'] = function() stroke(key.left, { 'ctrl', 'fn' }) end, -- Move left a space
  ['S+L'] = function() stroke(key.right, { 'ctrl', 'fn' }) end, -- Move right a space
  ['S+J'] = next_app,
  ['S+K'] = previous_app,
  ['S+N'] = function() focus_window(1) end,
  ['S+B'] = function() focus_window(-1) end,
  ['S+M'] = function() hs.spaces.toggleMissionControl() end,

  -- Window resizing/positioning
  ['S+D+F'] = function() move_window({ 0, 0, 1, 1 }) end,
  ['S+D+H'] = function() move_window({ 0, 0, 0.5, 1 }) end,
  ['S+D+J'] = function() move_window({ 0, 0.5, 1, 0.5 }) end,
  ['S+D+K'] = function() move_window({ 0, 0, 1, 0.5 }) end,
  ['S+D+L'] = function() move_window({ 0.5, 0, 0.5, 1 }) end,

  -- Word motions
  ['A+D'] = function() stroke(key.forward_delete, { 'alt' }) end,
  ['A+H'] = function() stroke(key.backspace, { 'alt' }) end,
  ['A+B'] = function() stroke(key.left, { 'alt' }) end,
  ['A+F'] = function() stroke(key.right, { 'alt' }) end,

  -- Switch between apps
  [';+F'] = function() toggle_app('com.apple.finder') end,
  [';+M'] = function() toggle_app('net.kovidgoyal.kitty') end,
  [';+T'] = function() toggle_app('com.culturedcode.ThingsMac') end,
  [';+N'] = function() toggle_app('net.shinyfrog.bear') end,
}

-- A chord of key codes as a string, the same whatever their order
local function chord_id(codes)
  table.sort(codes)
  return table.concat(codes, ',')
end

-- [super key][chord id] = action
local actions = {}
for keys, action in pairs(shortcuts) do
  local codes = {}
  for name in keys:gmatch('[^+]+') do
    table.insert(codes, key[name:lower()] or error('no key ' .. name))
  end
  local super = table.remove(codes, 1)
  actions[super] = actions[super] or {}
  actions[super][chord_id(codes)] = action
end

local function perform(super, chord)
  local codes = {}
  for code in pairs(chord) do table.insert(codes, code) end
  local action = actions[super][chord_id(codes)]
  if not action then return end
  if action ~= next_app and action ~= previous_app then close_switcher() end
  local ok, err = pcall(action)
  if not ok then log.e(err) end
end

local supers = superkey.new({
  keys = actions,
  perform = perform,
  finish = close_switcher,
  now = function() return hs.timer.absoluteTime() / 1e9 end,
  after = hs.timer.doAfter,
})

--  Emacs mode, and switching the input source
--------------------------------------------------
-- Apps that keep their own Ctrl-C: terminals and Vim
local escape_key_disabled_apps = set({
  'com.apple.Terminal',
  'net.sourceforge.iTerm',
  'com.googlecode.iterm2',
  'co.zeit.hyperterm',
  'co.zeit.hyper',
  'io.alacritty',
  'org.alacritty',
  'net.kovidgoyal.kitty',
  'com.mitchellh.ghostty',
  'com.ident.goneovim',
  'com.qvacua.VimR',
})

-- Apps that keep their own Ctrl-D, Ctrl-H, Ctrl-A and Ctrl-E
local advanced_cursor_keys_disabled_apps = set({
  'com.microsoft.VSCode',
})

-- Apps that keep their own Emacs keys
local all_cursor_keys_disabled_apps = set({
  -- Eclipse
  'org.eclipse.eclipse',
  'org.eclipse.platform.ide',
  'org.eclipse.sdk.ide',
  'com.springsource.sts',
  'org.springsource.sts.ide',

  -- Emacs
  'org.gnu.Emacs',
  'org.gnu.AquamacsEmacs',
  'org.gnu.Aquamacs',
  'org.pqrs.unknownapp.conkeror',

  -- Remote desktops
  'com.microsoft.rdc',
  'com.microsoft.rdc.mac',
  'com.microsoft.rdc.osx.beta',
  'net.sf.cord',
  'com.thinomenon.RemoteDesktopConnection',
  'com.itap-mobile.qmote',
  'com.nulana.remotixmac',
  'com.p5sys.jump.mac.viewer',
  'com.p5sys.jump.mac.viewer.web',
  'com.vmware.horizon',
  'com.2X.Client.Mac',
  'karabiner.remotedesktop.microsoft',
  'karabiner.remotedesktop',

  -- Terminals
  'com.apple.Terminal',
  'iTerm',
  'net.sourceforge.iTerm',
  'com.googlecode.iterm2',
  'co.zeit.hyperterm',
  'co.zeit.hyper',
  'io.alacritty',
  'org.alacritty',
  'net.kovidgoyal.kitty',
  'com.mitchellh.ghostty',

  -- Vim
  'org.vim.MacVim',
  'com.ident.goneovim',
  'com.qvacua.VimR',

  -- Virtual machines
  'com.vmware.fusion',
  'com.vmware.view',
  'com.parallels.desktop',
  'com.parallels.vm',
  'com.parallels.desktop.console',
  'org.virtualbox.app.VirtualBoxVM',

  -- X11
  'org.x.X11',
  'com.apple.x11',
  'org.macosforge.xquartz.X11',
  'org.macports.X11',
})

-- Ctrl-<key> to key: `mods` added to it; `shift`: Shift-Ctrl-<key> too, adding Shift; `advanced`: not for the apps
-- that keep the advanced ones
local emacs_keys = {
  [key.d] = { to = key.forward_delete, advanced = true },
  [key.h] = { to = key.backspace, advanced = true },
  [key.j] = { to = key.enter },
  [key.p] = { to = key.up, shift = true },
  [key.n] = { to = key.down, shift = true },
  [key.b] = { to = key.left, shift = true },
  [key.f] = { to = key.right, shift = true },
  [key.a] = { to = key.left, mods = { 'cmd' }, shift = true, advanced = true }, -- beginning of line
  [key.e] = { to = key.right, mods = { 'cmd' }, shift = true, advanced = true }, -- end of line
}

local function eisu() stroke(key.eisu) end

local function frontmost_app()
  local app = hs.application.frontmostApplication()
  return app and app:bundleID()
end

-- Handles a key the super keys let through: returns whether to swallow it
local function remap(code, is_down, is_repeat, flags)
  if flags.alt or flags.cmd then return false end

  if not flags.ctrl then
    -- Escape switches to English first (EISUU), for Vim's normal mode
    if code == key.escape and is_down and not flags.shift then eisu() end
    return false
  end

  if code == key[';'] and not flags.shift then
    if not is_down then return false end
    if not is_repeat then select_next_input_source() end
    return true
  end

  if code == key.c and not flags.shift then
    if is_down then eisu() end
    -- Ctrl-C is Escape, but where it's Ctrl-C's own
    if escape_key_disabled_apps[frontmost_app()] then return false end
    emit(key_event(key.escape, is_down))
    return true
  end

  local emacs = emacs_keys[code]
  if not emacs or (flags.shift and not emacs.shift) then return false end
  local app = frontmost_app()
  if all_cursor_keys_disabled_apps[app] then return false end
  if emacs.advanced and advanced_cursor_keys_disabled_apps[app] then return false end
  local mods = { table.unpack(emacs.mods or {}) }
  if flags.shift then table.insert(mods, 'shift') end
  emit(key_event(emacs.to, is_down, mods))
  return true
end

--  Event tap
--------------------------------------------------
local function handle(event)
  if event:getProperty(props.eventSourceUserData) == MARK then return false end

  local code = event:getKeyCode()
  local is_down = event:getType() == types.keyDown
  local is_repeat = event:getProperty(props.keyboardEventAutorepeat) ~= 0
  local flags = event:getFlags()
  local plain = not (flags.cmd or flags.alt or flags.ctrl or flags.shift)

  local swallow, keys = supers:handle(code, is_down, is_repeat, plain)
  for _, k in ipairs(keys or {}) do
    emit(key_event(k[1], k[2]))
  end
  if not swallow then swallow = remap(code, is_down, is_repeat, flags) end
  return swallow
end

local function on_event(event)
  ahead = {}
  local ok, swallow = pcall(handle, event)
  local events = ahead
  ahead = nil
  if ok then return swallow, events end
  -- Hammerspoon drops the event of a failing callback: let it through instead, and start over
  log.e(swallow)
  supers:reset()
  close_switcher()
  return false, events
end

function M.start()
  M.stop()
  M.tap = hs.eventtap.new({ types.keyDown, types.keyUp }, on_event)
  M.tap:start()
end

function M.stop()
  if M.tap then M.tap:stop() end
  M.tap = nil
  supers:reset()
  close_switcher()
end

return M
