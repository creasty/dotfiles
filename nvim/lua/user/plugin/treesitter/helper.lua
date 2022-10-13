local ts_highlighter = require "vim.treesitter.highlighter"
local nts_parsers = require "nvim-treesitter.parsers"
local nts_ts_utils = require "nvim-treesitter.ts_utils"

local M = {}

function M.get_treesitter_path()
  local paths = {}

  if not nts_parsers.has_parser() then
    return paths
  end

  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  row = row - 1

  local current_node = nts_ts_utils.get_node_at_cursor()
  local node = current_node
  while node do
    table.insert(paths, 1, node:type())
    if node == current_node then
      for child_node in node:iter_children() do
        if nts_ts_utils.is_in_node_range(child_node, row, col) then
          table.insert(paths, child_node:type())
        end
      end
    end
    node = node:parent()
  end

  return paths
end

function M.get_treesitter_hl()
  local buf = vim.api.nvim_get_current_buf()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  row = row - 1

  local buf_hl = ts_highlighter.active[buf]
  if not buf_hl then
    return {}
  end

  local matches = {}

  buf_hl.tree:for_each_tree(function(tstree, tree)
    if not tstree then
      return
    end

    local root = tstree:root()

    local root_start_row, _, root_end_row, _ = root:range()
    if root_start_row > row or root_end_row < row then
      return
    end

    local hl_query = buf_hl:get_query(tree:lang())
    local query = hl_query:query()
    if not query then
      return
    end

    for id, node, metadata in query:iter_captures(root, 0, row, row + 1) do
      local hl = hl_query.hl_cache[id]

      if hl and nts_ts_utils.is_in_node_range(node, row, col) then
        local c = hl_query._query.captures[id] -- name of the capture in the query
        if c ~= nil then
          local general_hl = hl_query:_get_hl_from_capture(id)
          local line = "- @" .. c .. " -> " .. hl
          if general_hl ~= hl then
            line = line .. " -> " .. general_hl
          end
          if metadata.priority then
            line = line .. " (" .. metadata.priority .. ")"
          end
          table.insert(matches, line)
        end
      end
    end
  end, true)

  return matches
end

function M.get_syntax_hl()
  local line = vim.fn.line "."
  local col = vim.fn.col "."
  local matches = {}
  for _, i1 in ipairs(vim.fn.synstack(line, col)) do
    local i2 = vim.fn.synIDtrans(i1)
    local n1 = vim.fn.synIDattr(i1, "name")
    local n2 = vim.fn.synIDattr(i2, "name")
    table.insert(matches, "- " .. n1 .. " -> " .. n2)
  end
  return matches
end

function M.show_hl_captures()
  local buf = vim.api.nvim_get_current_buf()
  local lines = {}

  local function show_matches(matches)
    if #matches == 0 then
      table.insert(lines, "No highlight groups found")
    end
    for _, line in ipairs(matches) do
      table.insert(lines, line)
    end
    table.insert(lines, "")
  end

  if ts_highlighter.active[buf] then
    table.insert(lines, "# Treesitter")

    local paths = M.get_treesitter_path()
    if paths ~= nil then
      table.insert(lines, "- " .. table.concat(paths, " -> "))
    end

    local matches = M.get_treesitter_hl()
    show_matches(matches)
  end

  if vim.b.current_syntax then
    table.insert(lines, "# Syntax")
    local matches = M.get_syntax_hl()
    show_matches(matches)
  end

  vim.lsp.util.open_floating_preview(lines, "markdown")
end

return M
