local ts_highlighter = require 'vim.treesitter.highlighter'
local rules = require 'user.opfmt.rules'

local M = {
  max_path_level = 3,
}

function M.get_space_count(mode)
  if mode == 3 then
    return 2
  elseif mode > 0 then
    return 1
  end
  return 0
end

function M.get_space_mode(left, right)
  if left and right then
    return 3
  elseif right then
    return 2
  elseif left then
    return 1
  end
  return 0
end

function M.format_space(token, mode)
  if mode == 1 or mode == 3 then
    token = ' ' .. token
  end
  if mode == 2 or mode == 3 then
    token = token .. ' '
  end
  return token
end

function M.match_patterns(str, patterns)
  if #patterns == 0 then
    return true
  end
  for _, pattern in ipairs(patterns) do
    if str:match(pattern) then
      return true
    end
  end
  return false
end

function M.match_rule(info, rule)
  if rule.tokens and not M.match_patterns(info.token, rule.tokens) then
    return false
  end
  if rule.ignore_paths and M.match_patterns(info.path, rule.ignore_paths) then
    return false
  end
  if rule.paths and not M.match_patterns(info.path, rule.paths) then
    return false
  end
  return true
end

function M.apply_rules(info)
  for _, lang in ipairs({info.lang, '*'}) do
    local lang_rules = rules[lang] or {}
    for _, rule in ipairs(lang_rules) do
      if M.match_rule(info, rule) then
        info.space_old = info.space
        info.space = rule.space
        return info
      end
    end
  end
  return info
end

function M.retrive_token_info_list(buf, line, row)
  local info_list = {}

  local buf_hl = ts_highlighter.active[buf]
  if not buf_hl then
    return info_list
  end

  buf_hl.tree:for_each_tree(function(tstree, tree)
    if not tstree then
      return
    end

    local root = tstree:root()

    local root_start_row, _, root_end_row, _ = root:range()
    if root_start_row > row or root_end_row < row then
      return
    end

    local lang = tree:lang()
    local hl_query = buf_hl:get_query(lang)
    local query = hl_query:query()
    if not query then
      return
    end

    for id, node in query:iter_captures(root, buf, row, row + 1) do
      local hl = hl_query.hl_cache[id]
      if not hl then
        goto continue
      end

      local node_row = node:start()
      if node_row ~= row then
        goto continue
      end

      local hl_name = hl_query._query.captures[id]
      if not (hl_name == 'operator' or hl_name == 'punctuation.delimiter') then
        goto continue
      end

      local info = M.build_token_info(line, node)
      if info then
        info.lang = lang
        table.insert(info_list, info)
      end

      ::continue::
    end
  end, true)

  return info_list
end

function M.build_token_info(line, node)
  local row1, col1, row2, col2 = node:range()
  if row1 ~= row2 then
    return
  end

  local token = string.sub(line, col1 + 1, col2)

  local sp_left = string.sub(line, col1, col1) == ' '
  local sp_right = string.sub(line, col2 + 1, col2 + 1) == ' '
  if sp_left then
    col1 = col1 - 1
  end
  if sp_right then
    col2 = col2 + 1
  end

  return {
    token = token,
    col_start = col1,
    col_end = col2,
    space = M.get_space_mode(sp_left, sp_right),
    path = M.get_node_path(node, M.max_path_level),
    error = node:parent() and node:parent():has_error(),
  }
end

function M.get_node_path(node, max)
  local paths = {}

  while node and max >= 0 do
    if node:named() then
      table.insert(paths, 1, node:type())
    end
    node = node:parent()
    max = max - 1
  end

  return table.concat(paths, '/')
end

function M.format_line(line, col, info_list)
  local formatted = line
  for i = #info_list, 1, -1 do
    local info = info_list[i]
    local token = M.format_space(info.token, info.space)
    if info.space_old and info.col_end <= col then
      local shift = M.get_space_count(info.space) - M.get_space_count(info.space_old)
      col = col + shift
    end
    formatted = string.sub(formatted, 0, info.col_start) .. token .. string.sub(formatted, info.col_end + 1)
  end
  return formatted, col
end

function M.get_current_line()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
  return line, row - 1, col
end

function M.debug()
  local line, row = M.get_current_line()
  local buf = vim.api.nvim_get_current_buf()
  local info_list = M.retrive_token_info_list(buf, line, row)
  local formatted = M.format_line(line, info_list)

  for i = 1, #info_list do
    info_list[i] = M.apply_rules(info_list[i])
  end

  local lines = {formatted, ''}
  for l in vim.inspect(info_list):gmatch("([^\n]*)\n?") do
    table.insert(lines, l)
  end

  vim.lsp.util.open_floating_preview(lines, "lua")
end

function M.format_current_line()
  local line, row, col = M.get_current_line()
  local buf = vim.api.nvim_get_current_buf()
  local info_list = M.retrive_token_info_list(buf, line, row)

  for i = 1, #info_list do
    info_list[i] = M.apply_rules(info_list[i])
  end

  local formatted, new_col = M.format_line(line, col, info_list)
  vim.api.nvim_buf_set_lines(0, row, row + 1, true, {formatted})
  vim.api.nvim_win_set_cursor(0, {row + 1, new_col})
end

return M
