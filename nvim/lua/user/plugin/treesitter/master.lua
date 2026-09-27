-- nvim-yati and syntax-tree-surfer, both unmaintained, were written for
-- nvim-treesitter's master branch and call into modules its main branch
-- dropped: yati reads its settings through nvim-treesitter.configs and
-- registers itself as one of its modules, syntax-tree-surfer uses helpers of
-- nvim-treesitter.ts_utils. They get what they call here, only while they
-- load, so that no other plugin mistakes nvim-treesitter for master.

local M = {}

--- Requires `name` while `stand_ins` (module name: table) can be required.
local function require_with(stand_ins, name)
  for module, stand_in in pairs(stand_ins) do
    package.loaded[module] = stand_in
  end
  local ok, result = pcall(require, name)
  for module in pairs(stand_ins) do
    package.loaded[module] = nil
  end
  if not ok then
    error(result, 0)
  end
  return result
end

--- Loads nvim-yati, for its indentexpr: v:lua.require'nvim-yati.indent'.indentexpr()
function M.load_yati()
  -- Its plugin script would register it as a module (with define_modules)
  package.loaded['nvim-yati'] = { init = function() end }
  -- Its settings: the defaults
  local settings = {}
  require_with({
    ['nvim-treesitter.configs'] = {
      get_module = function()
        return settings
      end,
    },
  }, 'nvim-yati.config')
end

--- The helpers of nvim-treesitter.ts_utils that syntax-tree-surfer calls, as
--- master has them.
local ts_utils = {}

local function set_jump()
  vim.cmd("normal! m'")
end

function ts_utils.get_vim_range(range, buf)
  local srow, scol, erow, ecol = unpack(range)
  srow = srow + 1
  scol = scol + 1
  erow = erow + 1

  if ecol == 0 then
    -- Use the value of the last col of the previous row instead.
    erow = erow - 1
    if not buf or buf == 0 then
      ecol = vim.fn.col({ erow, '$' }) - 1
    else
      ecol = #vim.api.nvim_buf_get_lines(buf, erow - 1, erow, false)[1]
    end
    ecol = math.max(ecol, 1)
  end
  return srow, scol, erow, ecol
end

function ts_utils.get_root_for_node(node)
  local parent = node
  local result = node

  while parent ~= nil do
    result = parent
    parent = result:parent()
  end

  return result
end

function ts_utils.goto_node(node, goto_end, avoid_set_jump)
  if not node then
    return
  end
  if not avoid_set_jump then
    set_jump()
  end
  local range = { ts_utils.get_vim_range({ node:range() }) }
  local position
  if not goto_end then
    position = { range[1], range[2] }
  else
    position = { range[3], range[4] }
  end

  -- Enter visual mode if we are in operator pending mode
  -- If we don't do this, it will miss the last character.
  if vim.api.nvim_get_mode().mode == 'no' then
    vim.cmd('normal! v')
  end

  -- Position is 1, 0 indexed.
  vim.api.nvim_win_set_cursor(0, { position[1], position[2] - 1 })
end

--- The text of a node or a range, as lines.
local function get_node_text(node, bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not node then
    return {}
  end

  -- We have to remember that end_col is end-exclusive
  local start_row, start_col, end_row, end_col = vim.treesitter.get_node_range(node)

  if start_row ~= end_row then
    local lines = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row + 1, false)
    if next(lines) == nil then
      return {}
    end
    lines[1] = string.sub(lines[1], start_col + 1)
    -- end_row might be just after the last line. In this case the last line is not truncated.
    if #lines == end_row - start_row + 1 then
      lines[#lines] = string.sub(lines[#lines], 1, end_col)
    end
    return lines
  else
    local line = vim.api.nvim_buf_get_lines(bufnr, start_row, start_row + 1, false)[1]
    -- If line is nil then the line is empty
    return line and { string.sub(line, start_col + 1, end_col) } or {}
  end
end

local function node_to_lsp_range(node)
  local start_line, start_col, end_line, end_col = vim.treesitter.get_node_range(node)
  return {
    start = { line = start_line, character = start_col },
    ['end'] = { line = end_line, character = end_col },
  }
end

function ts_utils.swap_nodes(node_or_range1, node_or_range2, bufnr, cursor_to_second)
  if not node_or_range1 or not node_or_range2 then
    return
  end
  local range1 = node_to_lsp_range(node_or_range1)
  local range2 = node_to_lsp_range(node_or_range2)

  local text1 = get_node_text(node_or_range1, bufnr)
  local text2 = get_node_text(node_or_range2, bufnr)

  local edit1 = { range = range1, newText = table.concat(text2, '\n') }
  local edit2 = { range = range2, newText = table.concat(text1, '\n') }
  bufnr = bufnr == 0 and vim.api.nvim_get_current_buf() or bufnr
  vim.lsp.util.apply_text_edits({ edit1, edit2 }, bufnr, 'utf-8')

  if cursor_to_second then
    set_jump()

    local char_delta = 0
    local line_delta = 0
    if
      range1['end'].line < range2.start.line
      or (range1['end'].line == range2.start.line and range1['end'].character <= range2.start.character)
    then
      line_delta = #text2 - #text1
    end

    if range1['end'].line == range2.start.line and range1['end'].character <= range2.start.character then
      if line_delta ~= 0 then
        char_delta = #text2[#text2] - range1['end'].character

        -- add range1.start.character if last line of range1 (now text2) does not start at 0
        if range1.start.line == range2.start.line + line_delta then
          char_delta = char_delta + range1.start.character
        end
      else
        char_delta = #text2[#text2] - #text1[#text1]
      end
    end

    vim.api.nvim_win_set_cursor(0, { range2.start.line + 1 + line_delta, range2.start.character + char_delta })
  end
end

--- Loads syntax-tree-surfer, for its :STS commands.
function M.load_syntax_tree_surfer()
  require_with({ ['nvim-treesitter.ts_utils'] = ts_utils }, 'syntax-tree-surfer')
end

return M
