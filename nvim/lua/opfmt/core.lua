local rules = require 'opfmt.rules'

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

function M.retrive_token_info_list(bufnr, line, row)
  local info_list = {}

  if bufnr == 0 then
    bufnr = vim.api.nvim_get_current_buf()
  end

  local buf_hl = vim.treesitter.highlighter.active[bufnr]
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

    for id, node in query:iter_captures(root, bufnr, row, row + 1) do
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
  if sp_left then
    col1 = col1 - 1
  end
  local sp_right = string.sub(line, col2 + 1, col2 + 1) == ' '
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

function M.get_formatted_line(line, col, info_list, only_around_cursor)
  local formatted = line

  for i = #info_list, 1, -1 do
    local info = info_list[i]

    if only_around_cursor and math.min(math.abs(info.col_start - col), math.abs(info.col_end - col)) > 1 then
      goto continue
    end

    local token = M.format_space(info.token, info.space)
    if info.space_old and info.col_end <= col then
      local shift = M.get_space_count(info.space) - M.get_space_count(info.space_old)
      col = col + shift
    end
    formatted = string.sub(formatted, 0, info.col_start) .. token .. string.sub(formatted, info.col_end + 1)

    ::continue::
  end

  return formatted, col
end

function M.get_rule_applied_info_list(bufnr, line, row)
  local info_list = M.retrive_token_info_list(bufnr, line, row)
  local changes = false

  for i = 1, #info_list do
    local applied = M.apply_rules(info_list[i])
    info_list[i] = applied
    changes = changes or (applied.space_old and applied.space ~= applied.space_old)
  end

  return info_list, changes
end

return M
