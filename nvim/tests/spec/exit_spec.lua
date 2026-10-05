local t = require('t')
local env = require('env')
local describe, it = t.describe, t.it

describe('Exit', function()
  it('closing the window saves the history and quits', function()
    local shada = env.sandbox(env.load(), 'shada') .. '/main.shada'
    local nvim = t.nvim({ tui = true, shada = shada })
    nvim:call('histadd', ':', 'echo "e2e"')
    t.ok(nvim:close_terminal(), 'Neovim still runs')
    t.contains(env.read_file(shada) or '', 'echo "e2e"', 'the ShaDa file')
  end, { timeout = 30000 })

  it('closing the window quits even when the history cannot be saved', function()
    -- (read-only: writing it fails, as it does while another Neovim replaces it)
    local shada = env.sandbox(env.load(), 'shada') .. '/main.shada'
    env.write_file(shada, '', tonumber('400', 8))
    local nvim = t.nvim({ tui = true, shada = shada })
    t.ok(nvim:close_terminal(), 'Neovim still runs, waiting for Enter on an error no one sees')
  end, { timeout = 30000 })
end)
