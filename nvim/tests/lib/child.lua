-- A child Neovim running the real config, driven over msgpack-RPC.
--
-- Keys go through nvim_input() (see type() for <C-c>), i.e. they are *typed*:
-- mappings, abbreviations, <expr> maps and autocommands behave exactly as when
-- you type them. Each type() call is a burst of keystrokes followed by a pause
-- (see settle()).

local env = require('env')

local Child = {}
Child.__index = Child

local DEFAULT_TIMEOUT = 8000
local spawned = 0

--- Spawns a child.
--- opts.cwd        working directory (default: a fresh sandbox directory)
--- opts.args       extra command line arguments (e.g. files to open)
--- opts.env        extra environment variables (or a function of the
---                 sandbox directory returning them)
--- opts.shada      shada file path (default: none, like `-i NONE`)
--- opts.lines / opts.columns   screen size (default 40x120)
--- opts.name       used to name the sandbox directory
function Child.new(opts)
  opts = opts or {}
  local ctx = env.load()
  local self = setmetatable({ ctx = ctx, opts = opts }, Child)
  self.dir = opts.cwd or env.sandbox(ctx, opts.name)

  local args = {
    ctx.nvim,
    '--embed',
    '--headless',
    '-i', opts.shada or 'NONE',
    '--cmd', ('set lines=%d columns=%d'):format(opts.lines or 40, opts.columns or 120),
    '--cmd', 'luafile ' .. vim.fn.fnameescape(env.lib_dir .. '/prelude.lua'),
  }
  vim.list_extend(args, opts.args or {})

  -- The fake servers report which documents they have open here.
  local state_dir = ctx.run_dir .. '/servers/' .. vim.fs.basename(self.dir)
  vim.fn.mkdir(state_dir, 'p')
  self.lsp_state = state_dir .. '/lsp.json'
  self.copilot_state = state_dir .. '/copilot.json'
  spawned = spawned + 1
  local extra_env = type(opts.env) == 'function' and opts.env(self.dir) or opts.env or {}
  local child_env = vim.tbl_extend('force', env.child_dirs(ctx, ('%d-%d'):format(vim.uv.os_getpid(), spawned)), {
    E2E_FAKE_LSP_STATE = self.lsp_state,
    E2E_FAKE_COPILOT_STATE = self.copilot_state,
  }, extra_env)

  local started = vim.uv.hrtime()
  self.chan = vim.fn.jobstart(args, {
    rpc = true,
    cwd = self.dir,
    env = env.child_env(ctx, child_env),
  })
  if self.chan <= 0 then
    error('failed to spawn nvim: ' .. vim.inspect(args))
  end
  self.pid = vim.fn.jobpid(self.chan)
  self:request('nvim_get_mode')
  self.startup_ms = (vim.uv.hrtime() - started) / 1e6
  return self
end

function Child:request(method, ...)
  if not self.chan then
    error('child is closed', 2)
  end
  local ok, result = pcall(vim.rpcrequest, self.chan, method, ...)
  if not ok then
    error(('%s: %s'):format(method, tostring(result)), 2)
  end
  return result
end

function Child:close()
  if not self.chan then
    return
  end
  local chan = self.chan
  self.chan = nil
  pcall(vim.rpcnotify, chan, 'nvim_command', 'qa!')
  if vim.fn.jobwait({ chan }, 1000)[1] == -1 then
    vim.fn.jobstop(chan)
    vim.fn.jobwait({ chan }, 1000)
  end
end

---------------------------------------------------------------------------
-- Input
---------------------------------------------------------------------------

--- After a burst of keys, wait until the child has consumed them. A pending,
--- ambiguous key sequence (e.g. `ge` vs `ge_`, or a "submode" such as
--- `ge<SID>(word)` that never times out) is resolved with <Ignore>, exactly
--- as if you had paused and moved on. Prompts such as input() or getchar()
--- are left alone: they are not "blocking" and wait for more keys.
function Child:settle()
  -- One <Ignore> resolves a pending sequence, but keys a plugin feeds while
  -- it starts up can keep one pending a little longer: back off, then give up.
  local deadline = vim.uv.now() + 2000
  local pause = 0
  while true do
    local mode = self:request('nvim_get_mode')
    if not mode.blocking then
      return mode
    end
    if vim.uv.now() > deadline then
      error('child stays blocked on a pending key sequence')
    end
    self:request('nvim_input', '<Ignore>')
    if pause > 0 then
      vim.wait(pause)
    end
    pause = math.min(pause * 2 + 1, 50)
  end
end

--- Types keys (Neovim key notation; a literal "<" is "<lt>").
---
--- Keys with a <C-c> go to the typeahead instead (nvim_feedkeys(), as typed),
--- which Neovim reads when it next waits for a key. Through nvim_input(), a
--- <C-c> that arrives while Neovim works through its queued events is an
--- interrupt, and runs no mapping (:help map_CTRL-C).
function Child:type(keys, opts)
  opts = opts or {}
  if keys:find('<[Cc]%-[Cc]>') then
    self:request('nvim_feedkeys', self:request('nvim_replace_termcodes', keys, true, true, true), 't', false)
  else
    self:request('nvim_input', keys)
  end
  if opts.settle ~= false then
    self:settle()
  end
  if opts.wait then
    self:sleep(opts.wait)
  end
  return self
end

---------------------------------------------------------------------------
-- Evaluation helpers
---------------------------------------------------------------------------

function Child:cmd(command)
  return self:request('nvim_command', command)
end

--- Runs Ex commands and returns their output.
function Child:exec(src)
  return self:request('nvim_exec2', src, { output = true }).output
end

function Child:eval(expr)
  return self:request('nvim_eval', expr)
end

--- Runs Lua in the child: nvim:lua('return vim.bo.filetype').
function Child:lua(code, ...)
  return self:request('nvim_exec_lua', code, { ... })
end

function Child:call(fname, ...)
  return self:request('nvim_call_function', fname, { ... })
end

function Child:sleep(ms)
  vim.wait(ms)
  return self
end

--- Polls `cond` (a function receiving the child, or a Vim expression) until it
--- returns a truthy value (not 0, '', vim.NIL). Returns that value.
function Child:wait_for(cond, opts)
  opts = opts or {}
  local timeout = opts.timeout or DEFAULT_TIMEOUT
  local check = type(cond) == 'string' and function()
    return self:eval(cond)
  end or function()
    return cond(self)
  end
  local value
  local ok = vim.wait(timeout, function()
    local status, result = pcall(check)
    if status and result ~= nil and result ~= false and result ~= 0 and result ~= '' and result ~= vim.NIL then
      value = result
      return true
    end
    return false
  end, opts.interval or 20)
  if not ok then
    local what = opts.message or (type(cond) == 'string' and cond) or 'condition'
    error(('timed out after %dms waiting for %s'):format(timeout, what), 2)
  end
  return value
end

---------------------------------------------------------------------------
-- Buffer & editor state
---------------------------------------------------------------------------

function Child:mode()
  return self:request('nvim_get_mode').mode
end

--- Waits until the mode is `mode` (e.g. 's' once a snippet placeholder is
--- selected by an asynchronous expansion).
function Child:wait_mode(mode, opts)
  opts = opts or {}
  self:wait_for(function()
    return self:mode() == mode
  end, { timeout = opts.timeout or DEFAULT_TIMEOUT, message = 'mode ' .. mode })
  return self
end

function Child:lines(buf)
  return self:request('nvim_buf_get_lines', buf or 0, 0, -1, false)
end

function Child:line(lnum)
  return self:lines()[lnum or self:cursor()[1]]
end

--- {row, col}: 1-based row, 0-based byte column (like nvim_win_get_cursor).
function Child:cursor()
  return self:request('nvim_win_get_cursor', 0)
end

function Child:set_cursor(row, col)
  self:request('nvim_win_set_cursor', 0, { row, col })
end

local MARKER = '|'

local function split_marker(lines, marker)
  local cursor
  local out = {}
  for i, line in ipairs(lines) do
    local s = cursor == nil and line:find(marker, 1, true) or nil
    if s then
      cursor = { i, s - 1 }
      line = line:sub(1, s - 1) .. line:sub(s + #marker)
    end
    out[i] = line
  end
  return out, cursor
end

local function as_lines(text)
  if type(text) == 'table' then
    return text
  end
  return vim.split(text, '\n', { plain = true })
end

--- Replaces the current buffer's text. A `|` marks the cursor position
--- (opts.marker overrides the marker for texts containing `|`).
function Child:set_buffer(text, opts)
  opts = opts or {}
  local lines, cursor = split_marker(as_lines(text), opts.marker or MARKER)
  self:request('nvim_buf_set_lines', 0, 0, -1, false, lines)
  if cursor then
    self:set_cursor(cursor[1], cursor[2])
  end
  return self
end

--- The current buffer's lines with the cursor marked by `|`.
function Child:buffer(opts)
  opts = opts or {}
  local marker = opts.marker or MARKER
  local lines = self:lines()
  local row, col = unpack(self:cursor())
  local line = lines[row] or ''
  lines[row] = line:sub(1, col) .. marker .. line:sub(col + 1)
  return lines
end

--- Absolute path inside this child's sandbox directory.
function Child:path(rel)
  if not rel or rel == '' then
    return self.dir
  end
  if rel:sub(1, 1) == '/' then
    return rel
  end
  return self.dir .. '/' .. rel
end

--- Writes a file (lines or string) relative to the sandbox.
function Child:write_file(rel, content)
  local path = self:path(rel)
  vim.fn.mkdir(vim.fs.dirname(path), 'p')
  vim.fn.writefile(as_lines(content), path)
  return path
end

function Child:read_file(rel)
  local path = self:path(rel)
  if vim.fn.filereadable(path) == 0 then
    return nil
  end
  return vim.fn.readfile(path)
end

function Child:exists(rel)
  return vim.uv.fs_stat(self:path(rel)) ~= nil
end

--- Creates files from a table { ['path'] = lines_or_string, ... }.
function Child:files(tree)
  for rel, content in pairs(tree) do
    if rel:sub(-1) == '/' then
      vim.fn.mkdir(self:path(rel), 'p')
    else
      self:write_file(rel, content)
    end
  end
  return self
end

--- Opens a file (creating it with `content` first when given).
function Child:edit(rel, content)
  if content ~= nil then
    self:write_file(rel, content)
  end
  self:cmd('edit ' .. vim.fn.fnameescape(self:path(rel)))
  return self
end

function Child:bufname()
  return self:call('expand', '%:p')
end

function Child:filetype()
  return self:eval('&filetype')
end

function Child:messages()
  return self:exec('messages')
end

function Child:getreg(name)
  return self:call('getreg', name or '"')
end

--- Floating windows: list of { win, buf, lines, config, filetype }.
function Child:floats()
  return self:lua([[
    local result = {}
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local config = vim.api.nvim_win_get_config(win)
      if config.relative ~= '' then
        local buf = vim.api.nvim_win_get_buf(win)
        result[#result + 1] = {
          win = win,
          buf = buf,
          focusable = config.focusable,
          lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false),
          filetype = vim.bo[buf].filetype,
          row = config.row, col = config.col, width = config.width, height = config.height,
          border = config.border,
        }
      end
    end
    return result
  ]])
end

--- Screen contents as a list of strings (what a TUI would show).
function Child:screen()
  return self:lua([[
    local rows = {}
    for r = 1, vim.o.lines do
      local cells = {}
      for c = 1, vim.o.columns do
        cells[#cells + 1] = vim.fn.screenstring(r, c)
      end
      rows[r] = table.concat(cells):gsub('%s+$', '')
    end
    return rows
  ]])
end

--- Evaluated statusline of a window (default: current).
function Child:statusline(win)
  return self:lua(
    [[
    local win = ...
    if win == 0 then
      win = vim.api.nvim_get_current_win()
    end
    local stl = vim.wo[win].statusline ~= '' and vim.wo[win].statusline or vim.o.statusline
    local ok, res = pcall(vim.api.nvim_eval_statusline, stl, { winid = win })
    return ok and res.str or ('<error: ' .. tostring(res) .. '>')
  ]],
    win or 0
  )
end

function Child:tabline()
  return self:lua([[
    local ok, res = pcall(vim.api.nvim_eval_statusline, vim.o.tabline, { use_tabline = true })
    return ok and res.str or ('<error: ' .. tostring(res) .. '>')
  ]])
end

--- Debug dump used by the runner when a test fails.
function Child:dump()
  if not self.chan then
    return '(child closed)'
  end
  local ok, mode = pcall(self.request, self, 'nvim_get_mode')
  if not ok then
    return '(child unavailable: ' .. tostring(mode) .. ')'
  end
  if mode.blocking then
    return '(child is blocked in mode ' .. mode.mode .. ')'
  end
  local parts = { ('mode: %s'):format(mode.mode) }
  local ok_screen, screen = pcall(self.screen, self)
  if ok_screen then
    -- Collapse the `~` filler lines below the buffer.
    local rows, tildes = {}, 0
    for _, row in ipairs(screen) do
      if row:match('^%s*~$') then
        tildes = tildes + 1
      else
        if tildes > 0 then
          rows[#rows + 1] = ('~ (x%d)'):format(tildes)
          tildes = 0
        end
        rows[#rows + 1] = row
      end
    end
    parts[#parts + 1] = 'screen:\n  ' .. table.concat(rows, '\n  ')
  end
  local ok_msg, msgs = pcall(self.messages, self)
  if ok_msg and msgs ~= '' then
    parts[#parts + 1] = 'messages:\n  ' .. msgs:gsub('\n', '\n  ')
  end
  return table.concat(parts, '\n')
end

return Child
