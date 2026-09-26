-- Tiny test DSL: describe / it / before_each / after_each + assertions.

local Child = require('child')
local env = require('env')

local t = {}

local root = { name = nil, children = {}, before = {}, after = {} }
local current = root
local cases = {}
local active_children = {}

local SKIP = {}

math.randomseed(vim.uv.hrtime() + vim.uv.os_getpid())

function t.describe(name, fn)
  local group = { name = name, parent = current, children = {}, before = {}, after = {} }
  table.insert(current.children, group)
  local prev = current
  current = group
  fn()
  current = prev
end

local function full_name(group, name)
  local parts = { name }
  while group and group.name do
    table.insert(parts, 1, group.name)
    group = group.parent
  end
  return table.concat(parts, ' › ')
end

--- it(name, fn [, opts])
---   opts.timeout  ms, for slow workflows (default: the runner's --timeout)
---   opts.quirk    marks a test that pins a known oddity of today's setup
---                 rather than a requirement; if it starts failing after a
---                 change, review it: the new behavior may be an improvement.
---   opts.retry    extra attempts for workflows that race a plugin's own
---                 asynchronous internals (a real regression fails them all)
function t.it(name, fn, opts)
  opts = opts or {}
  table.insert(cases, { name = full_name(current, name), fn = fn, group = current, opts = opts })
end

--- Shorthand for it(name, fn, { quirk = reason }).
function t.quirk(name, reason, fn, opts)
  opts = vim.tbl_extend('force', opts or {}, { quirk = reason })
  t.it(name, fn, opts)
end

function t.before_each(fn)
  table.insert(current.before, fn)
end

function t.after_each(fn)
  table.insert(current.after, fn)
end

function t.skip(reason)
  error(setmetatable({ reason = reason }, SKIP), 0)
end

--- Spawns a child Neovim with the real config; closed after the test.
function t.nvim(opts)
  local child = Child.new(opts)
  table.insert(active_children, child)
  return child
end

---------------------------------------------------------------------------
-- Assertions
---------------------------------------------------------------------------

local fmt = vim.inspect

local function fail(msg, level)
  error(msg, (level or 1) + 2)
end

function t.eq(expected, actual, msg)
  if not vim.deep_equal(expected, actual) then
    fail(('%sexpected: %s\n  actual:   %s'):format(msg and (msg .. '\n  ') or '', fmt(expected), fmt(actual)))
  end
end

function t.neq(unexpected, actual, msg)
  if vim.deep_equal(unexpected, actual) then
    fail(('%sexpected a value other than %s'):format(msg and (msg .. '\n  ') or '', fmt(unexpected)))
  end
end

function t.ok(value, msg)
  if not value or value == 0 or value == vim.NIL then
    fail(msg or ('expected truthy, got ' .. fmt(value)))
  end
  return value
end

function t.no(value, msg)
  if value and value ~= 0 and value ~= vim.NIL then
    fail(msg or ('expected falsy, got ' .. fmt(value)))
  end
end

--- Lua pattern match (use t.contains for plain substrings).
function t.match(pattern, str, msg)
  if type(str) ~= 'string' or not str:find(pattern) then
    fail(('%sexpected %s to match %s'):format(msg and (msg .. '\n  ') or '', fmt(str), fmt(pattern)))
  end
end

function t.no_match(pattern, str, msg)
  if type(str) == 'string' and str:find(pattern) then
    fail(('%sexpected %s not to match %s'):format(msg and (msg .. '\n  ') or '', fmt(str), fmt(pattern)))
  end
end

--- Substring in a string, or element in a list.
function t.contains(haystack, needle, msg)
  local found = false
  if type(haystack) == 'string' then
    found = haystack:find(needle, 1, true) ~= nil
  elseif type(haystack) == 'table' then
    for _, v in ipairs(haystack) do
      if vim.deep_equal(v, needle) then
        found = true
        break
      end
    end
  end
  if not found then
    fail(('%sexpected %s to contain %s'):format(msg and (msg .. '\n  ') or '', fmt(haystack), fmt(needle)))
  end
end

--- Buffer text with the cursor marked by `|` (see Child:buffer()).
--- The third argument is a message, or { marker = '‸', message = ... }.
function t.buffer(nvim, expected, opts)
  if type(opts) == 'string' then
    opts = { message = opts }
  end
  opts = opts or {}
  local lines = type(expected) == 'string' and vim.split(expected, '\n', { plain = true }) or expected
  local marker = opts.marker or '|'
  t.eq(lines, nvim:buffer(opts), (opts.message and (opts.message .. ': ') or '') .. 'buffer (' .. marker .. ' = cursor)')
end

--- Like t.golden, but many cases share one file, one `=== key` section each.
function t.golden_section(name, key, actual)
  local text = type(actual) == 'table' and table.concat(actual, '\n') or actual
  -- Sections are separated by blank lines, so trailing ones cannot round-trip.
  text = text:gsub('\n+$', '')
  local path = env.tests_dir .. '/golden/' .. name
  local update = os.getenv('E2E_UPDATE_GOLDEN') == '1'
  local sections, order = {}, {}
  local existing = env.read_file(path)
  if existing then
    local current
    for _, line in ipairs(vim.split(existing, '\n', { plain = true })) do
      local header = line:match('^=== (.*)$')
      if header then
        current = header
        sections[current] = {}
        table.insert(order, current)
      elseif current then
        table.insert(sections[current], line)
      end
    end
    for k, lines in pairs(sections) do
      while #lines > 0 and lines[#lines] == '' do
        table.remove(lines)
      end
      sections[k] = table.concat(lines, '\n')
    end
  end
  local expected = sections[key]
  if update or expected == nil then
    if expected == nil then
      table.insert(order, key)
    end
    sections[key] = text
    local out = {}
    for _, k in ipairs(order) do
      table.insert(out, '=== ' .. k)
      table.insert(out, sections[k])
      table.insert(out, '')
    end
    vim.fn.mkdir(vim.fs.dirname(path), 'p')
    env.write_file(path, table.concat(out, '\n'))
    if not update then
      fail(('golden section created (re-run to compare): golden/%s [%s]'):format(name, key))
    end
    return
  end
  if expected ~= text then
    fail(('golden/%s [%s] mismatch\n  expected:\n    %s\n  actual:\n    %s'):format(
      name,
      key,
      expected:gsub('\n', '\n    '),
      text:gsub('\n', '\n    ')
    ))
  end
end

---------------------------------------------------------------------------
-- Execution (used by the runner's worker mode)
---------------------------------------------------------------------------

local function collect_hooks(group, kind)
  local chain = {}
  while group do
    table.insert(chain, 1, group)
    group = group.parent
  end
  local hooks = {}
  for _, g in ipairs(chain) do
    for _, h in ipairs(g[kind]) do
      table.insert(hooks, h)
    end
  end
  if kind == 'after' then
    local reversed = {}
    for i = #hooks, 1, -1 do
      reversed[#reversed + 1] = hooks[i]
    end
    return reversed
  end
  return hooks
end

function t.load(path)
  root.children, cases = {}, {}
  current = root
  local chunk = assert(loadfile(path))
  chunk()
  return cases
end

-- Runs in a libuv callback when a test exceeds its timeout: killing the
-- children makes any RPC request the test is blocked on fail at once.
local function kill_active()
  for _, child in ipairs(active_children) do
    if child.pid then
      pcall(vim.uv.kill, child.pid, 'sigkill')
    end
  end
end

--- Runs one case, retrying when opts.retry allows; returns
--- { status = 'pass'|'fail'|'skip', error, dump, ms, attempts }.
function t.run_case(case, default_timeout)
  local attempts = 1 + (case.opts.retry or 0)
  local result
  for attempt = 1, attempts do
    if attempt > 1 then
      -- Back off a random moment, so that tests retrying in parallel
      -- workers do not keep colliding in lockstep.
      vim.wait(math.random(200, 1500))
    end
    result = t.run_attempt(case, default_timeout)
    result.attempts = attempt
    if result.status ~= 'fail' then
      break
    end
  end
  return result
end

--- One attempt of a case: hooks, body, cleanup, with a watchdog.
function t.run_attempt(case, default_timeout)
  active_children = {}
  local started = vim.uv.hrtime()
  local timed_out = false
  local timeout = case.opts.timeout or default_timeout
  local watchdog = vim.uv.new_timer()
  watchdog:start(timeout, 0, function()
    timed_out = true
    kill_active()
  end)

  local result = { status = 'pass' }
  local function run(fn)
    return xpcall(fn, function(err)
      if getmetatable(err) == SKIP then
        return err
      end
      return debug.traceback(tostring(err), 2)
    end)
  end

  local ok, err = true, nil
  for _, hook in ipairs(collect_hooks(case.group, 'before')) do
    ok, err = run(hook)
    if not ok then
      break
    end
  end
  if ok then
    ok, err = run(case.fn)
  end
  for _, hook in ipairs(collect_hooks(case.group, 'after')) do
    local hook_ok, hook_err = run(hook)
    if ok and not hook_ok then
      ok, err = hook_ok, hook_err
    end
  end

  if not ok then
    if getmetatable(err) == SKIP then
      result.status = 'skip'
      result.error = err.reason
    else
      result.status = 'fail'
      result.error = timed_out and ('timed out after ' .. timeout .. 'ms\n' .. tostring(err)) or tostring(err)
      if not timed_out and active_children[#active_children] then
        local dump_ok, dump = pcall(active_children[#active_children].dump, active_children[#active_children])
        result.dump = dump_ok and dump or nil
      end
    end
  end

  if case.opts.quirk then
    result.quirk = case.opts.quirk
  end
  watchdog:stop()
  watchdog:close()
  for _, child in ipairs(active_children) do
    pcall(child.close, child)
  end
  active_children = {}
  result.ms = (vim.uv.hrtime() - started) / 1e6
  return result
end

return t
