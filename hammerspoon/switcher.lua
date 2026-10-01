-- The application switcher (S+J, S+K)
local key = require('keycodes')
local events = require('events')

local types = hs.eventtap.event.types
local emit, stroke = events.emit, events.stroke

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

return { next = next_app, previous = previous_app, close = close_switcher }
