-- Posting key events
local M = {}

local props = hs.eventtap.event.properties

-- Marks the events posted here, for the tap to let them through
local MARK = 0x4b4244 -- 'KBD'

-- The events to post ahead of the one the tap is handling, while it is: posted from its callback, they would come
-- after it
local ahead

function M.emit(event)
  event:setProperty(props.eventSourceUserData, MARK)
  if ahead then
    table.insert(ahead, event)
  else
    event:post()
  end
end

function M.key_event(code, is_down, mods)
  return hs.eventtap.event.newKeyEvent(mods or {}, code, is_down)
end

function M.stroke(code, mods)
  M.emit(M.key_event(code, true, mods))
  M.emit(M.key_event(code, false, mods))
end

-- Holds the events emitted from now on, while the tap handles an event
function M.hold() ahead = {} end

-- Stops holding them, returning them
function M.release()
  local events = ahead
  ahead = nil
  return events
end

-- Whether the event is one posted here
function M.emitted(event) return event:getProperty(props.eventSourceUserData) == MARK end

return M
