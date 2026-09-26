-- One-time warm-up after env.prepare(): exercises slow first-use paths so
-- individual tests measure workflows, not compile time. Deno compiles the
-- ddu plugin, UI, filters and each source on first use (cached by path; the
-- plugin tree path is stable across runs, so this is fast after the first).
-- Steps are independent and best-effort: after a plugin swap some simply
-- no longer apply.

local Child = require('child')
local probe = require('probe')

local M = {}

local STEPS = {
  {
    name = 'file finder',
    run = function(nvim)
      probe.wait_picker_ready(nvim, { timeout = 60000 })
      nvim:type('<C-q>')
      probe.wait_picker(nvim, nil, { timeout = 60000 })
      nvim:type('<C-q>')
      probe.wait_picker_closed(nvim, { timeout = 10000 })
    end,
  },
  {
    name = 'grep',
    run = function(nvim)
      nvim:type('<Space>/')
      nvim:type('needle<CR>')
      probe.wait_picker(nvim, nil, { timeout = 60000 })
      nvim:type('<Esc>')
      probe.wait_picker_closed(nvim, { timeout = 10000 })
    end,
  },
  {
    name = 'location list',
    run = function(nvim)
      nvim:lua([[
        vim.g.coc_jump_locations = { {
          filename = vim.fn.fnamemodify('notes.txt', ':p'), lnum = 1, end_lnum = 1, col = 1, end_col = 7,
          text = 'needle', bufnr = 0, uri = '', range = vim.empty_dict(),
        } }
      ]])
      nvim:cmd('doautocmd User CocLocationsChange')
      probe.wait_picker(nvim, nil, { timeout = 60000 })
      nvim:type('<Esc>')
      probe.wait_picker_closed(nvim, { timeout = 10000 })
    end,
  },
}

--- Returns true, or false plus a description of the steps that failed.
function M.run(ctx)
  vim.env.E2E_CONTEXT = ctx.context_file
  local nvim = Child.new({ name = 'warmup' })
  local failures = {}
  nvim:files({ ['.git/'] = true, ['notes.txt'] = { 'needle' } })
  for _, step in ipairs(STEPS) do
    local ok, err = pcall(step.run, nvim)
    if not ok then
      failures[#failures + 1] = step.name .. ': ' .. tostring(err):match('^[^\n]*')
      pcall(nvim.type, nvim, '<Esc><Esc>')
    end
  end
  nvim:close()
  if #failures > 0 then
    return false, table.concat(failures, '\n')
  end
  return true
end

return M
