-- Neovim as the terminal: shells and commands in terminals, their keys, the bottom one (<C-/>), and the files that
-- programs in them open with nvim (flatten.nvim).
local t = require('t')
local probe = require('probe')
local describe, it = t.describe, t.it

local function text(nvim, buf)
  return table.concat(nvim:lines(buf), '\n')
end

--- Waits for `cond`, failing with what the terminal `buf` shows.
local function wait_showing(nvim, buf, cond, opts)
  local ok, result = pcall(nvim.wait_for, nvim, cond, opts)
  if not ok then
    error(('%s; the terminal shows:\n%s'):format(result, text(nvim, buf)), 2)
  end
  return result
end

--- Runs `cmd` with sh in a terminal in the current window, and waits for `ready` in its output.
local function terminal(nvim, cmd, ready)
  nvim:cmd('set shell=/bin/sh')
  nvim:cmd('terminal ' .. cmd)
  local buf = nvim:call('bufnr')
  wait_showing(nvim, buf, function()
    return text(nvim, buf):find(ready, 1, true)
  end, { message = ready })
  return buf
end

local function window_count(nvim)
  return #nvim:request('nvim_tabpage_list_wins', 0)
end

local function is_running(nvim, buf)
  return nvim:lua('return vim.fn.jobwait({ vim.bo[...].channel }, 0)[1] == -1', buf)
end

--- The window showing the file `name` in the sandbox, or nil. (bufwinnr() takes a pattern, which the terminal's
--- name matches too: it holds the command.)
local function window_of(nvim, name)
  return nvim:lua(
    [[
    local path = vim.fn.fnamemodify(..., ':p')
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win)) == path then
        return win
      end
    end
  ]],
    name
  )
end

describe('Terminals', function()
  it('open typing into the program, with no color column, and keep 15000 lines of history', function()
    local nvim = t.nvim()
    nvim:cmd('set colorcolumn=80')
    terminal(nvim, 'echo ready; cat', 'ready')
    t.eq('t', nvim:mode())
    t.eq({ '', 15000 }, nvim:eval('[&colorcolumn, &scrollback]'))
  end)

  it('<C-s> works the window keys, and <C-s><C-s> sends C-s to the program', function()
    local nvim = t.nvim()
    terminal(nvim, 'stty -ixon; echo ready; cat -v', 'ready')
    nvim:type('<C-s><C-s><CR>')
    nvim:wait_for(function()
      return text(nvim):find('^S', 1, true)
    end, { message = '^S' })
    nvim:type('<C-s>v')
    t.eq(2, window_count(nvim))
    t.eq({ '', 'n' }, { nvim:eval('&buftype'), nvim:mode() })
  end)

  it('Esc goes to the program; <C-y> is copy mode, scrolled a line up with the cursor on its row, until i', function()
    local nvim = t.nvim()
    terminal(nvim, 'seq 200; echo ready; cat -v', 'ready')
    nvim:type('<Esc><CR>')
    nvim:wait_for(function()
      return text(nvim):find('^[', 1, true)
    end, { message = '^[' })
    t.eq('t', nvim:mode())

    local top, row = nvim:call('line', 'w0'), nvim:call('winline')
    nvim:type('<C-y>')
    t.eq({ 'nt', top - 1, row }, { nvim:mode(), nvim:call('line', 'w0'), nvim:call('winline') })

    -- another window, and back: copy mode stays
    nvim:type('<C-s>s')
    nvim:type('<C-s>p')
    t.eq({ 'terminal', 'nt' }, { nvim:eval('&buftype'), nvim:mode() })

    -- after i, entering the window types into it again
    nvim:type('i')
    nvim:type('<C-s>w')
    t.eq({ '', 'n' }, { nvim:eval('&buftype'), nvim:mode() })
    nvim:type('<C-s>p')
    nvim:wait_mode('t')
    t.eq('terminal', nvim:eval('&buftype'))
  end)

  it('<C-/> shows and hides the shell at the bottom, which keeps running while hidden', function()
    local nvim = t.nvim()
    nvim:cmd('set shell=/bin/sh')
    nvim:type('<C-/>')
    nvim:wait_mode('t')
    local buf = nvim:call('bufnr')
    t.eq({ 2, 'terminal' }, { window_count(nvim), nvim:eval('&buftype') })
    -- on the editor's background (Normal has none), not the floats' darker one
    t.eq(
      { 'SnacksNormal', 'none' },
      nvim:lua([[
        local group = vim.wo.winhighlight:match('Normal:([%w_]+)')
        return { group, vim.api.nvim_get_hl(0, { name = group, link = false }).bg or 'none' }
      ]])
    )

    nvim:type('<C-/>')
    t.eq(1, window_count(nvim))
    t.eq(true, is_running(nvim, buf))

    nvim:type('<C-/>')
    nvim:wait_mode('t')
    t.eq({ 2, buf }, { window_count(nvim), nvim:call('bufnr') })
  end)

  it('<Space>t lists the terminals, hidden ones included', function()
    local nvim = t.nvim()
    terminal(nvim, 'echo ready; cat', 'ready')
    nvim:type('<C-/>')
    nvim:wait_mode('t')
    nvim:type('<C-/>')
    nvim:wait_mode('t')
    nvim:type('<C-\\><C-n>')
    probe.wait_picker_ready(nvim)
    nvim:type('<Space>t')
    local items = nvim:wait_for(function()
      local picker = probe.picker(nvim)
      return picker.open and not picker.loading and #picker.items == 2 and picker.items
    end, { message = 'two terminals in the picker' })
    for _, item in ipairs(items) do
      t.contains(item, 'term://')
    end
  end)

  it('are named in the tabline by $ and the title their program sets, or the command they run, with no flags', function()
    local nvim = t.nvim()
    terminal(nvim, [[sleep 0.2; printf '\033]2;bun\007'; echo ready; cat]], 'ready')
    nvim:wait_for("get(b:, 'term_title') ==# 'bun'")
    nvim:cmd('tabnew')
    terminal(nvim, '/bin/cat -v', '')
    -- (and entered again, where the files' flags are looked up)
    nvim:cmd('tabprevious')
    nvim:cmd('tabnext')
    t.eq(' $bun ∙ $cat', (nvim:tabline():gsub('%s+$', '')))
  end)

  it("titles the window with the shell's directory, from OSC 7", function()
    local nvim = t.nvim()
    nvim:files({ ['sub/.keep'] = '', ['osc7.sh'] = { [[cd sub && printf '\033]7;file://host%s\033\\' "$PWD"]], 'echo ready', 'cat' } })
    terminal(nvim, 'sh osc7.sh', 'ready')
    nvim:wait_for("exists('b:user_terminal_cwd')")
    t.eq(nvim:path('sub'), nvim:eval('UserTitleString()'))
  end)

  it("marks a tab whose terminal prints while another tab is the current one, until it's current again", function()
    local nvim = t.nvim()
    local function tab_highlights()
      local line = nvim:lua("return require('user.ui').tabline()")
      local groups = {}
      for group in line:gmatch('%%#(TabLine%a*)# ') do
        groups[#groups + 1] = group
      end
      return groups
    end
    terminal(nvim, 'echo ready; sleep 1; echo printed; cat', 'ready')
    nvim:cmd('tabnew')
    t.eq({ 'TabLine', 'TabLineSel' }, tab_highlights())
    nvim:wait_for(function()
      return tab_highlights()[1] == 'TabLineActivity'
    end, { message = 'the first tab marked' })
    nvim:cmd('tabprevious')
    nvim:cmd('tabnext')
    t.eq({ 'TabLine', 'TabLineSel' }, tab_highlights())
  end)
end)

describe('Files opened from a terminal (flatten.nvim)', function()
  it('nvim in a terminal opens the file in this Neovim, in another window', function()
    local nvim = t.nvim()
    nvim:files({ ['notes.txt'] = { 'x' } })
    nvim:cmd('set shell=/bin/sh')
    nvim:cmd('terminal ' .. nvim:eval('v:progpath') .. ' notes.txt; echo exited; cat')
    local term = nvim:call('bufnr')
    wait_showing(nvim, term, function()
      return window_of(nvim, 'notes.txt')
    end, { timeout = 20000, message = 'notes.txt in a window' })
    t.eq(true, nvim:call('bufwinnr', term) > 0, "the terminal's window stays")
    nvim:wait_for(function()
      return text(nvim, term):find('exited', 1, true)
    end, { message = 'the nvim in the terminal exits' })
  end)

  it('git commit waits for the message to be written and its window closed', function()
    local nvim = t.nvim()
    nvim:files({ ['COMMIT_EDITMSG'] = { '' } })
    nvim:cmd('set shell=/bin/sh')
    nvim:cmd('terminal ' .. nvim:eval('v:progpath') .. ' COMMIT_EDITMSG; echo done; cat')
    local term = nvim:call('bufnr')
    local win = wait_showing(nvim, term, function()
      return window_of(nvim, 'COMMIT_EDITMSG')
    end, { timeout = 20000, message = 'COMMIT_EDITMSG in a window' })
    t.eq(nil, text(nvim, term):find('done', 1, true), 'nvim waits in the terminal')

    nvim:request('nvim_set_current_win', win)
    nvim:set_buffer('message')
    nvim:cmd('wq')
    nvim:wait_for(function()
      return text(nvim, term):find('done', 1, true)
    end, { message = 'nvim in the terminal exits' })
    t.eq({ 'message' }, nvim:read_file('COMMIT_EDITMSG'))
  end)
end)
