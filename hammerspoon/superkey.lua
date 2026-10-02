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
local key = require('keycodes')

local M = {}
M.__index = M

-- Keyboard's timings, in seconds
local rollover, delay = 0.05, 0.15

-- A chord of key codes as a string, the same whatever their order
local function chord_id(codes)
  table.sort(codes)
  return table.concat(codes, ',')
end

-- opts:
--   shortcuts  { ['S+D+F'] = action, ... }: the actions, by their keys' names in keycodes.lua, the super key first
--   before     function(action), called before a shortcut's action runs
--   finish     function(key), called when a super key stops acting after it performed
--   log        function(message), given an action's error
--   now        function() -> seconds
--   after      function(seconds, fn) -> timer, which :stop() cancels
function M.new(opts)
  -- [super key][chord id] = action
  local actions = {}
  for keys, action in pairs(opts.shortcuts) do
    local codes = {}
    for name in keys:gmatch('[^+]+') do
      table.insert(codes, key[name:lower()] or error('no key ' .. name))
    end
    local super = table.remove(codes, 1)
    actions[super] = actions[super] or {}
    actions[super][chord_id(codes)] = action
  end
  local self = setmetatable({
    actions = actions,
    before = opts.before,
    finish = opts.finish,
    log = opts.log,
    now = opts.now,
    after = opts.after,
    taken = {}, -- the keys chords took, until their release
  }, M)
  self:reset()
  return self
end

-- Forgets the super key held, finishing it if it acts. The states:
--   idle     none held
--   held     held, with no other key yet
--   pending  keys pressed with it, their chord waiting for `delay`
--   active   chords act as their keys go down
--   off      acting no more until its release: typing rolled over it, or a key with modifiers ended it
function M:reset()
  if self.state == 'active' then self.finish(self.key) end
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

-- Runs the action of the chord (a set of key codes) held with the super key, if it has one
function M:perform(chord)
  local codes = {}
  for code in pairs(chord) do table.insert(codes, code) end
  local action = self.actions[self.key][chord_id(codes)]
  if not action then return end
  self.before(action)
  local ok, err = pcall(action)
  if not ok then self.log(err) end
end

function M:schedule()
  if self.timer then self.timer:stop() end
  self.timer = self.after(delay, function()
    self.timer = nil
    self.state = 'active'
    self.typed = {}
    self:perform(self.chord)
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
        self:perform(copy(self.pressed))
      end
      return true
    end
  end

  if self.state == 'idle' then
    if is_down and not is_repeat and plain and self.actions[code] then
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
    if self.now() - self.down_at < rollover then return false, self:stop() end
    self.state = 'pending'
  end

  self.taken[code] = true
  self.pressed[code] = true
  if self.state == 'pending' then
    table.insert(self.typed, { code = code })
    self.chord = copy(self.pressed)
    self:schedule()
  else
    self:perform(copy(self.pressed))
  end
  return true
end

return M
