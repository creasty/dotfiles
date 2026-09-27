-- Converted from UltiSnips' markdown.snippets
local S = require('user.snippets')

-- `2x3` -> a table of 3 columns and 2 rows, a tabstop in each cell.
local function create_table(size)
  local rows, columns = size:match('(%d+)x(%d+)')
  rows, columns = tonumber(rows), tonumber(columns)
  local function row(first)
    local cells = {}
    for column = 1, columns do
      cells[column] = '$' .. (first + column - 1)
    end
    return '| ' .. table.concat(cells, ' | ') .. ' |\n'
  end
  local lines = { row(1), '|' .. ('---|'):rep(columns) .. '\n' }
  for n = 1, rows do
    lines[#lines + 1] = row(n * columns + 1)
  end
  return table.concat(lines)
end

-- Width on screen (east asian wide characters take 2 cells).
local function screen_len(text)
  return vim.api.nvim_strwidth(text)
end

-- The line above the cursor (nil on the first line).
local function previous_line()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  return row > 1 and vim.api.nvim_buf_get_lines(0, row - 2, row - 1, true)[1] or nil
end

return {
  S.snip([[\vtb(\d+x\d+)]], 'Customizable table', 'br', {
    S.anon(function(snip)
      return create_table(snip.captures[1])
    end),
  }, { docTrig = 'tb2x3' }),
  S.snip('details', '<details> tag', 'b', [[
<details><summary>${1:See details}</summary>
$0
</details><br>]]),
  S.snip([[^-\{3,}]], 'Horizontal rule', 'r', ('-'):rep(80)),
  -- Underlines the heading on the line above as wide as it is.
  S.snip('^[\\-=]', 'Headering', 'rA', '$RULE\n', {
    condition = function()
      return (previous_line() or ''):match('^[^%-=%s]') ~= nil
    end,
    vars = function(snip)
      return { RULE = snip.trigger:rep(screen_len(previous_line())) }
    end,
  }),
  S.snip([[\v(<|\s+)br]], 'Break line', 'r', '<br>'),
}
