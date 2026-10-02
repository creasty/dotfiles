local t = require('t')
local env = require('env')
local describe, it = t.describe, t.it

local started = 0

--- Neovim with its terminal UI on a pty, as kitty runs it (config/kitty/kitty.conf), and its ShaDa file at `shada`.
--- `close()` closes the pty, as closing kitty's window does, and tells whether Neovim's server then exits.
local function start(shada)
  local ctx = env.load()
  started = started + 1
  local dirs = env.child_dirs(ctx, ('%d-ui-%d'):format(vim.uv.os_getpid(), started))
  -- (a short path: macOS takes about 104 bytes for a socket's)
  local sock = vim.fn.tempname() .. '.sock'
  local ui = vim.fn.jobstart({ ctx.nvim, '--listen', sock, '-i', shada }, {
    pty = true,
    width = 120,
    height = 40,
    cwd = env.sandbox(ctx, 'ui'),
    env = env.child_env(ctx, dirs),
  })
  local self, pid = {}, nil
  function self.close()
    if self.server then
      vim.fn.chanclose(self.server)
    end
    vim.fn.jobstop(ui)
    local exited = not pid or vim.wait(5000, function()
      return vim.uv.kill(pid, 0) ~= 0
    end, 50)
    if not exited then
      vim.uv.kill(pid, 'sigkill')
    end
    return exited
  end
  --- Fails the test, once the pty is closed
  local function check(ok, msg)
    if not ok then
      self.close()
    end
    t.ok(ok, msg)
  end

  vim.wait(10000, function()
    local ok, chan = pcall(vim.fn.sockconnect, 'pipe', sock, { rpc = true })
    self.server = ok and chan > 0 and chan or nil
    return self.server ~= nil
  end, 50)
  check(self.server, 'the server listens')
  pid = vim.rpcrequest(self.server, 'nvim_call_function', 'getpid', {})
  -- (the server sources the config once the UI has attached)
  check(vim.wait(10000, function()
    return vim.rpcrequest(self.server, 'nvim_get_vvar', 'vim_did_enter') == 1
  end, 50), 'Neovim starts')
  return self
end

describe('Exit', function()
  it('closing the window saves the history and quits', function()
    local shada = env.sandbox(env.load(), 'shada') .. '/main.shada'
    local nvim = start(shada)
    vim.rpcrequest(nvim.server, 'nvim_call_function', 'histadd', { ':', 'echo "e2e"' })
    t.ok(nvim.close(), 'Neovim still runs')
    t.contains(env.read_file(shada) or '', 'echo "e2e"', 'the ShaDa file')
  end, { timeout = 30000 })

  it('closing the window quits even when the history cannot be saved', function()
    -- (read-only: writing it fails, as it does while another Neovim replaces it)
    local shada = env.sandbox(env.load(), 'shada') .. '/main.shada'
    env.write_file(shada, '', tonumber('400', 8))
    t.ok(start(shada).close(), 'Neovim still runs, waiting for Enter on an error no one sees')
  end, { timeout = 30000 })
end)
