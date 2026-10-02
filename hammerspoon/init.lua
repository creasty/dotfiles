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

--  Super keys: the super key, and the keys held with it
--------------------------------------------------
local shortcuts = {
  -- Window/space navigation. Moving a space strokes Mission Control's shortcut, as macOS has no public API for it:
  -- hs.spaces.gotoSpace clicks the space in Mission Control, showing it
  ['S+H'] = function() events.stroke(key.left, { 'ctrl', 'fn' }) end, -- Move left a space
  ['S+L'] = function() events.stroke(key.right, { 'ctrl', 'fn' }) end, -- Move right a space
  ['S+J'] = switcher.next,
  ['S+K'] = switcher.previous,
  ['S+N'] = function() windows.focus(1) end,
  ['S+B'] = function() windows.focus(-1) end,
  ['S+M'] = function() hs.spaces.toggleMissionControl() end,

  -- Window resizing/positioning
  ['S+D+F'] = function() windows.move({ 0, 0, 1, 1 }) end,
  ['S+D+H'] = function() windows.move({ 0, 0, 0.5, 1 }) end,
  ['S+D+J'] = function() windows.move({ 0, 0.5, 1, 0.5 }) end,
  ['S+D+K'] = function() windows.move({ 0, 0, 1, 0.5 }) end,
  ['S+D+L'] = function() windows.move({ 0.5, 0, 0.5, 1 }) end,

  -- Word motions
  ['A+D'] = function() events.stroke(key.forward_delete, { 'alt' }) end,
  ['A+H'] = function() events.stroke(key.backspace, { 'alt' }) end,
  ['A+B'] = function() events.stroke(key.left, { 'alt' }) end,
  ['A+F'] = function() events.stroke(key.right, { 'alt' }) end,

  -- Switch between apps
  [';+F'] = function() apps.toggle('com.apple.finder') end,
  [';+M'] = function() apps.toggle('net.kovidgoyal.kitty') end,
  [';+T'] = function() apps.toggle('com.culturedcode.ThingsMac') end,
  [';+N'] = function() apps.toggle('net.shinyfrog.bear') end,
}

local supers = superkey.new({
  shortcuts = shortcuts,
  before = switcher.before,
  finish = switcher.close,
  log = log.e,
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
    events.emit(events.key_event(k[1], k[2]))
  end
  if not swallow then swallow = emacs.remap(code, is_down, is_repeat, flags) end
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
end

keyboard.start()
