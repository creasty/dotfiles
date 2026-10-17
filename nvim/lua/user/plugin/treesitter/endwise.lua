-- <CR> after the line that opens a block adds the line that closes it (`end`,
-- `fi`, `endfunction`...), for the languages with an endwise query
-- (nvim/queries/<lang>/endwise.scm). A pattern there captures
--
--   @cursor   what the opening line ends with (any of the nodes)
--   @indent   the node whose line's indentation the closing line takes
--   @endable  the block, which gets no closing line when it has one (none
--             where the parser gives an ERROR)
--
-- and sets
--
--   endwise.end       the closing keyword
--   endwise.suffix    the capture whose text follows the keyword, as #gsub! leaves it
--   endwise.end_type  the type of the block's closing node (default: the keyword)
--   endwise.shift     how many 'shiftwidth's the line in between is indented by (default: 1)

local M = {}

--- A line's indentation, and the text after it.
local function split_indent(line)
  return line:match('^(%s*)(.*)$')
end

--- The indentation of line `row` (0-based).
local function indent_of(row)
  return (split_indent(vim.fn.getline(row + 1)))
end

--- Whether (row, col) is in the range of one of the nodes, its end excluded.
local function contains(nodes, row, col)
  for _, node in ipairs(nodes) do
    local srow, scol, erow, ecol = node:range()
    if not (row < srow or row == srow and col < scol or row > erow or row == erow and col >= ecol) then
      return true
    end
  end
  return false
end

--- Whether the block lacks its closing node, the last child of type
--- `end_type`: it has none, a missing one, or one at another indentation that
--- an enclosing block lacks (the parser gave it to this one, around an error).
local function lacks_end(block, end_type, cursor_row)
  local last = block:child(block:child_count() - 1)
  if last == nil then
    return true
  elseif last:type() ~= end_type then
    return false
  elseif last:missing() then
    return true
  end
  local end_row, _, end_end_row = last:range()
  if indent_of(block:start()) == indent_of(end_row) or end_end_row == cursor_row then
    return false
  end
  local parent = block:parent()
  while parent ~= nil do
    if parent:has_error() then
      return true
    end
    parent = parent:parent()
  end
  return false
end

--- Puts the closing line below the cursor's, and the cursor indented in
--- between. The text after the cursor goes to the closing line, unless it
--- starts with a word (or the block ends on the cursor's line, after it).
local function add_end(indent_row, block, end_text, shift)
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local indent = indent_of(indent_row)
  local line = vim.fn.getline(row)
  local at_cursor, after_end
  local block_end_row, block_end_col
  if block then
    _, _, block_end_row, block_end_col = block:range()
  end
  if block_end_row == nil or row - 1 < block_end_row then
    local _, rest = split_indent(line)
    if rest:match('^[%a%d]') then
      at_cursor, after_end = rest, ''
    else
      at_cursor, after_end = '', rest
    end
  elseif row - 1 == block_end_row then
    _, at_cursor = split_indent(line:sub(1, block_end_col))
    _, after_end = split_indent(line:sub(block_end_col + 1))
  else
    at_cursor = ''
    _, after_end = split_indent(line)
  end

  local step = vim.bo.expandtab and string.rep(' ', vim.fn.shiftwidth()) or '\t'
  local cursor_indent = indent .. string.rep(step, shift)
  vim.fn.setline(row, cursor_indent .. at_cursor)
  vim.fn.append(row, indent .. end_text .. after_end)
  vim.fn.cursor(row, #cursor_indent + 1)
end

--- Called right after a <CR> in Insert mode.
function M.add()
  local buf = vim.api.nvim_get_current_buf()
  local parser = vim.treesitter.get_parser(buf, nil, { error = false })
  if not parser then
    return
  end
  -- the last character before the cursor: where the opening line ends
  local row, col = unpack(vim.fn.searchpos([[\S]], 'nbW'))
  row, col = row - 1, col - 1
  -- (a line that ends with an opening bracket opens no block yet, such as the
  -- parameters between the parentheses <CR> split)
  if row < 0 or vim.fn.getline(row + 1):sub(col + 1, col + 1):match('[%(%[{]') then
    return
  end
  parser:parse({ row, row + 1 })
  local tree = parser:language_for_range({ row, col, row, col })
  local query = vim.treesitter.query.get(tree:lang(), 'endwise')
  local node = query and tree:named_node_for_range({ row, col, row, col }, { ignore_injections = true })
  if not node then
    return
  end

  local cursor_row = vim.api.nvim_win_get_cursor(0)[1] - 1
  for _, match, metadata in query:iter_matches(node:tree():root(), buf, row, row + 1) do
    local captured, ids, cursors = {}, {}, {}
    for id, nodes in pairs(match) do
      local name = query.captures[id]
      captured[name], ids[name] = nodes[#nodes], id
      if name == 'cursor' then
        cursors = nodes
      end
    end
    local block = captured.endable
    if contains(cursors, row, col) then
      local end_text = metadata['endwise.end']
      if not block or lacks_end(block, metadata['endwise.end_type'] or end_text, cursor_row) then
        local suffix = metadata['endwise.suffix']
        if suffix then
          end_text = end_text .. vim.treesitter.get_node_text(captured[suffix], buf, { metadata = metadata[ids[suffix]] })
        end
        add_end(captured.indent:start(), block, end_text, tonumber(metadata['endwise.shift'] or 1))
        return
      end
    end
  end
end

return M
