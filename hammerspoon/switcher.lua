-- The application switcher (S+J, S+K)
local key = require('keycodes')
local events = require('events')

local M = {}

local types = hs.eventtap.event.types

-- Command going down or up on its own, as the keyboard reports it
local function command_event(is_down)
  local event = hs.eventtap.event.newKeyEvent(key.command, is_down)
  event:setType(types.flagsChanged)
  event:setFlags(is_down and { cmd = true } or {})
  return event
end

-- The application switcher stays open while Command is down: S+J and S+K keep it down until S is released, as if S
-- were Command
local switching = false

local function switch_app(mods)
  if not switching then
    events.emit(command_event(true))
    switching = true
  end
  events.stroke(key.tab, mods)
end

function M.next() switch_app({ 'cmd' }) end
function M.previous() switch_app({ 'cmd', 'shift' }) end

function M.close()
  if not switching then return end
  events.emit(command_event(false))
  switching = false
end

-- Closes the switcher before another shortcut acts: S+J and S+K go on through it
function M.before(action)
  if action ~= M.next and action ~= M.previous then M.close() end
end

return M
