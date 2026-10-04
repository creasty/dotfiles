-- macOS's keyboard layout (ABC) in normal mode, not an input method (user/input_source.lua). CI's Mac has no input
-- method to switch from, so the tests record whether Neovim selects the layout.
local t = require('t')
local describe, it = t.describe, t.it

--- Waits until the child has run what it scheduled so far.
local function idle(nvim)
  nvim:lua([[
    local done = false
    vim.schedule(function()
      done = true
    end)
    vim.wait(1000, function()
      return done
    end)
  ]])
end

--- A child recording whether it selects the layout, from now on (not in the checks its start scheduled), with a UI
--- attached as kitty's is (`ui = false`: with none, as children run).
local function child(opts)
  local nvim = t.nvim()
  idle(nvim)
  nvim:lua(
    [[
    _G.selected = false
    require('user.input_source').select_layout = function()
      _G.selected = true
    end
    if ... then
      vim.api.nvim_list_uis = function()
        return { {} }
      end
    end
  ]],
    not opts or opts.ui ~= false
  )
  return nvim
end

--- Whether the child has selected the layout since last asked, once it has run what it scheduled.
local function selected(nvim)
  idle(nvim)
  return nvim:lua([[
    local selected = _G.selected
    _G.selected = false
    return selected
  ]])
end

--- Runs `cmd` with sh in a terminal in the current window, which opens typing into it.
local function terminal(nvim, cmd)
  nvim:cmd('set shell=/bin/sh')
  nvim:cmd('terminal ' .. cmd)
  nvim:wait_mode('t')
end

describe('Input source', function()
  it('leaving insert mode, by <Esc> or <C-c>, selects the keyboard layout', function()
    local nvim = child()
    nvim:type('ifoo')
    t.eq(false, selected(nvim))
    nvim:type('<Esc>')
    t.eq(true, selected(nvim))
    nvim:type('a<C-c>')
    t.eq({ 'n', true }, { nvim:mode(), selected(nvim) })
  end)

  it('ending a command line or a search selects it too', function()
    local nvim = child()
    nvim:set_buffer('|foo bar')
    nvim:type(':')
    t.eq(false, selected(nvim))
    nvim:type('<Esc>')
    t.eq(true, selected(nvim))
    nvim:type('/bar<CR>')
    t.eq({ 'n', true }, { nvim:mode(), selected(nvim) })
  end)

  it('copy mode in a terminal selects it, typing into the program does not', function()
    local nvim = child()
    terminal(nvim, 'cat')
    t.eq(false, selected(nvim))
    nvim:type('<C-y>')
    t.eq({ 'nt', true }, { nvim:mode(), selected(nvim) })
  end)

  it('starting or gaining focus in normal mode selects it, in insert mode does not', function()
    local nvim = child()
    nvim:cmd('doautocmd UIEnter')
    t.eq(true, selected(nvim))
    nvim:cmd('doautocmd FocusGained')
    t.eq(true, selected(nvim))
    nvim:type('i')
    t.eq(false, selected(nvim))
    nvim:cmd('doautocmd FocusGained')
    t.eq({ 'i', false }, { nvim:mode(), selected(nvim) })
  end)

  it("insert mode's keys that pass through normal mode keep the input method", function()
    local nvim = child()
    nvim:set_buffer('foo ba|r')
    -- <C-t> leaves insert mode and enters it again (<Esc>...a), <C-a> runs a command in it (<C-o>)
    nvim:type('i<C-t><C-a>')
    t.buffer(nvim, '|foo bra')
    t.eq({ 'i', false }, { nvim:mode(), selected(nvim) })
  end)

  it('without a UI, as scripts and tests run, nothing is selected', function()
    local nvim = child({ ui = false })
    nvim:type('ifoo<Esc>')
    nvim:cmd('doautocmd FocusGained')
    t.eq({ 'n', false }, { nvim:mode(), selected(nvim) })
  end)

  it("selects the layout through macOS's input sources, and tells each caller", function()
    -- (the real thing: on a Mac in an input method, this selects the layout)
    local nvim = t.nvim()
    nvim:lua([[
      _G.statuses = {}
      local input_source = require('user.input_source')
      for _ = 1, 2 do
        input_source.select_layout(function(status)
          table.insert(_G.statuses, status or 'error')
        end)
      end
    ]])
    nvim:wait_for(function()
      return #nvim:lua('return _G.statuses') == 2
    end, { message = 'both selections done' })
    t.eq({ 0, 0 }, nvim:lua('return _G.statuses'))
  end)
end)
