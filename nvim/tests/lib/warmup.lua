-- One-time warm-up after env.prepare(): exercises slow first-use paths so
-- individual tests measure workflows, not compile time or cold caches.
-- Steps are independent and best-effort: after a plugin swap some simply
-- no longer apply. (None is needed today: the Lua plugins start fast.)

local Child = require('child')

local M = {}

local STEPS = {}

--- Returns true, or false plus a description of the steps that failed.
function M.run(ctx)
  if #STEPS == 0 then
    return true
  end
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
