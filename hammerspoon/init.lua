-- Hammerspoon's config (https://www.hammerspoon.org), linked as ~/.hammerspoon: the key bindings of creasty/Keyboard
-- (https://github.com/creasty/Keyboard), all but its mouse keys and its guard on Cmd-Q. README.md lists them, with what
-- they need from System Settings.

-- Starts at login
if not hs.autoLaunch() then hs.autoLaunch(true) end

local superkey = require('superkey')
local key = require('keycodes')
local events = require('events')
local switcher = require('switcher')
local windows = require('windows')
local apps = require('apps')
local emacs = require('emacs')

local log = hs.logger.new('keyboard', 'warning')
local types = hs.eventtap.event.types
local props = hs.eventtap.event.properties

local emit, key_event, stroke = events.emit, events.key_event, events.stroke
local next_app, previous_app, close_switcher = switcher.next, switcher.previous, switcher.close
local move_window, focus_window = windows.move, windows.focus
local toggle_app = apps.toggle
local remap = emacs.remap

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

--  Event tap
--------------------------------------------------
local function handle(event)
  if events.emitted(event) then return false end

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
  events.hold()
  local ok, swallow = pcall(handle, event)
  local ahead = events.release()
  if ok then return swallow, ahead end
  -- Hammerspoon drops the event of a failing callback: let it through instead, and start over
  log.e(swallow)
  supers:reset()
  close_switcher()
  return false, ahead
end

-- A global, for the console
keyboard = {}

function keyboard.start()
  keyboard.stop()
  keyboard.tap = hs.eventtap.new({ types.keyDown, types.keyUp }, on_event)
  keyboard.tap:start()
end

function keyboard.stop()
  if keyboard.tap then keyboard.tap:stop() end
  keyboard.tap = nil
  supers:reset()
  close_switcher()
end

keyboard.start()
