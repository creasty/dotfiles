local core = require 'opfmt.core'
local parsers = require 'nvim-treesitter.parsers'

local tracking = {}
local state = {}
local M = {}

function M.get_current_line(bufnr)
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1]
  return line, row - 1, col
end

function M.debug(bufnr)
  local line, row, col = M.get_current_line(bufnr)
  local info_list = core.get_rule_applied_info_list(bufnr, line, row)
  local formatted = core.get_formatted_line(line, col, info_list)

  local lines = {'--[[', formatted, '--]]'}
  for _, info in ipairs(info_list) do
    table.insert(lines, info.path .. (info.error and ' (ERROR)' or ''))
    table.insert(lines, table.concat({
      '{ ',
      vim.inspect(info.token),
      ', ',
      (info.space_old and info.space_old .. ' -> ' or ''),
      info.space,
      ' }',
      ' -- ',
      info.col_start, ', ', info.col_end,
    }, ''))
  end

  vim.lsp.util.open_floating_preview(lines, 'lua')
end

function M.format(bufnr)
  local line, row, col = M.get_current_line(bufnr)
  local info_list, changes = core.get_rule_applied_info_list(bufnr, line, row)
  if not changes then
    return
  end

  local formatted, new_col = core.get_formatted_line(line, col, info_list)
  -- vim.api.nvim_buf_set_text(1, 0, 1, 0, 1, {"a"})
  vim.api.nvim_buf_set_lines(bufnr, row, row + 1, true, {formatted})
  vim.api.nvim_win_set_cursor(0, {row + 1, new_col})
end

function M.get_tick()
  local bufnr = vim.api.nvim_get_current_buf()
  return {
    bufnr = bufnr,
    changedtick = vim.api.nvim_buf_get_changedtick(bufnr),
  }
end

function M.verify_tick()
  if not state.tick then
    return true
  end

  local tick = M.get_tick()
  if state.tick.bufnr ~= tick.bufnr then
    return false
  end
  if math.abs(state.tick.changedtick - tick.changedtick) > 1 then
    return false
  end

  return true
end

function M.add_key_observer()
  if state.key_observer_id then return end

  local key_bs = vim.api.nvim_replace_termcodes('<BS>', true, false, true)
  local key_del = vim.api.nvim_replace_termcodes('<Del>', true, false, true)

  state.key_observer_id = vim.on_key(function (key)
    if vim.api.nvim_get_mode().mode ~= 'i' then
      state.skip = true
      return
    end

    state.tick = M.get_tick()

    if key == key_bs or key == key_del then
      state.skip = true
    else
      state.skip = false
    end
  end, nil)
end

function M.remove_key_observer()
  if state.key_observer_id then
    vim.on_key(nil, state.key_observer_id)
    state.key_observer_id = nil
  end
end

function M.attach(bufnr, lang)
  if tracking[bufnr] then
    return
  end
  if not parsers.has_parser(lang) then
    return
  end

  M.add_key_observer()

  local parser = parsers.get_parser(bufnr)

  local cbs = {
    on_changedtree = function (_tree_changes, _tree)
      vim.schedule_wrap(function ()
        if vim.api.nvim_get_mode().mode ~= 'i' then return end
        if state.skip then return end
        if not M.verify_tick() then return end
        M.format(bufnr)
      end)()
    end,
  }
  parser:register_cbs(cbs)

  local dispose = function ()
    for name, fn in pairs(cbs) do
      local refined_name = string.gsub(name, '^on_', '')
      local new_cbs = {}
      for _, cb in ipairs(parser._callbacks[refined_name]) do
        if cb ~= fn then
          table.insert(new_cbs, cb)
        end
      end
      parser._callbacks[refined_name] = new_cbs
    end
  end

  tracking[bufnr] = dispose
end

function M.detach(bufnr)
  if not tracking[bufnr] then
    return
  end
  tracking[bufnr]()
  tracking[bufnr] = nil
  M.remove_key_observer()
end

return M
