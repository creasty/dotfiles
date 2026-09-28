-- The 'super key' of creasty/Keyboard: a letter key held down on its own turns the keys pressed with it into
-- shortcuts, while it still types when tapped, or when typing rolls over it.
--
-- Holding S and pressing H is S+H, and holding S and D and pressing F is S+D+F: a shortcut is the chord of keys held
-- with the super key as one of them goes down. The first chord waits for the super key to stay down for `delay`
-- after its last key; the chords after it act at once, and so do their keys' repeats. Typing stays typing:
--
-- * A key pressed within `rollover` of the super key types both.
-- * Releasing the super key before the first chord acts types it and the keys pressed with it, in order.
-- * A key pressed with modifiers ends it, and types what it held back first.
--
-- The apps get neither the super key nor the keys a chord took, their releases and repeats included.
local M = {}
M.__index = M

-- opts:
--   keys      the super keys, as a set of key codes
--   perform   function(key, chord), running the shortcut of a chord (a set of key codes) held with a super key
--   finish    function(key), called when a super key stops acting after it performed
--   now       function() -> seconds
--   after     function(seconds, fn) -> timer, which :stop() cancels
--   rollover  seconds (default: Keyboard's 50 ms)
--   delay     seconds (default: Keyboard's 150 ms)
function M.new(opts)
  local self = setmetatable({
    keys = opts.keys,
    perform = opts.perform,
    finish = opts.finish or function() end,
    now = opts.now,
    after = opts.after,
    rollover = opts.rollover or 0.05,
    delay = opts.delay or 0.15,
    taken = {}, -- the keys chords took, until their release
  }, M)
  self:reset()
  return self
end

-- Forgets the super key held. The states:
--   idle     none held
--   held     held, with no other key yet
--   pending  keys pressed with it, their chord waiting for `delay`
--   active   chords act as their keys go down
--   off      acting no more until its release: typing rolled over it, or a key with modifiers ended it
function M:reset()
  if self.timer then self.timer:stop() end
  self.timer = nil
  self.state = 'idle'
  self.key = nil
  self.down_at = nil
  self.pressed = {} -- the keys held with it
  self.typed = {} -- the keys pressed with it while pending, as {code, released}
  self.chord = nil -- the chord waiting while pending
end

local function copy(set)
  local t = {}
  for k in pairs(set) do t[k] = true end
  return t
end

-- Stops the super key acting until its release, returning the keys it held back, to type
function M:stop()
  local keys = {}
  if self.state == 'held' or self.state == 'pending' then
    keys = { { self.key, true }, { self.key, false } }
    for _, typed in ipairs(self.typed) do
      table.insert(keys, { typed.code, true })
      if typed.released then
        table.insert(keys, { typed.code, false })
      else
        -- Typed now, so the apps get its release
        self.taken[typed.code] = nil
      end
    end
    self.pressed = {}
  end
  if self.timer then self.timer:stop() end
  self.timer = nil
  if self.state == 'active' then self.finish(self.key) end
  self.state = 'off'
  return keys
end

-- The release of a key a chord took
function M:untake(code)
  self.taken[code] = nil
  self.pressed[code] = nil
  for i = #self.typed, 1, -1 do
    if self.typed[i].code == code then
      self.typed[i].released = true
      break
    end
  end
end

function M:schedule()
  if self.timer then self.timer:stop() end
  self.timer = self.after(self.delay, function()
    self.timer = nil
    self.state = 'active'
    self.typed = {}
    self.perform(self.key, self.chord)
  end)
end

-- Handles a key event: returns whether to swallow it, and the keys to type before it, as {code, is_down} pairs.
-- `plain`: without Command, Option, Control or Shift.
function M:handle(code, is_down, is_repeat, plain)
  if self.taken[code] then
    if is_down and not is_repeat then
      -- Pressed anew, as its release went unseen (e.g. while secure input was on)
      self.taken[code] = nil
    else
      if not is_down then
        self:untake(code)
      elseif self.state == 'active' and self.pressed[code] then
        self.perform(self.key, copy(self.pressed))
      end
      return true
    end
  end

  if self.state == 'idle' then
    if is_down and not is_repeat and plain and self.keys[code] then
      self.state, self.key, self.down_at = 'held', code, self.now()
      return true
    end
    return false
  end

  if code == self.key then
    if is_down and is_repeat then return true end
    local keys = self:stop()
    self:reset()
    if is_down then
      -- Pressed anew, as its release went unseen
      return self:handle(code, is_down, is_repeat, plain), keys
    end
    return true, keys
  end

  if self.state == 'off' or not is_down then return false end
  if not plain then return false, self:stop() end
  if is_repeat then return true end

  if self.state == 'held' then
    if self.now() - self.down_at < self.rollover then return false, self:stop() end
    self.state = 'pending'
  end

  self.taken[code] = true
  self.pressed[code] = true
  if self.state == 'pending' then
    table.insert(self.typed, { code = code })
    self.chord = copy(self.pressed)
    self:schedule()
  else
    self.perform(self.key, copy(self.pressed))
  end
  return true
end

return M
