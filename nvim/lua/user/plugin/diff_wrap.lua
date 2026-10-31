-- Keeps the sides of a diff aligned where lines wrap: under a line, as many
-- rows of filler as its counterpart takes more (CLAUDE.md).

local M = {}

local api = vim.api

--- A window's own namespace: its fillers stay out of the buffer's other
--- windows, such as those of the file itself.
local function namespace(win)
  local ns = api.nvim_create_namespace('user_diff_wrap_' .. win)
  api.nvim__ns_set(ns, { wins = { win } })
  return ns
end

--- The width of a window's text, 1 where its columns leave no room for any.
local function text_width(win)
  return math.max(api.nvim_win_get_width(win) - vim.fn.getwininfo(win)[1].textoff, 1)
end

--- What the current window shows from the top, one entry to a row before
--- wrapping, so that an entry lines up with the same one of the other sides:
--- { lnum, rows } for a line, and for a filler line lnum is the line above it.
local function entries()
  local width = text_width(api.nvim_get_current_win())
  local last = api.nvim_buf_line_count(0)
  local list = {}
  for lnum = 1, last + 1 do
    for _ = 1, vim.fn.diff_filler(lnum) do
      list[#list + 1] = { lnum = lnum - 1, rows = 1 }
    end
    if lnum <= last then
      -- (not nvim_win_text_height(): it counts a closed fold as a row, and no
      -- event tells when one opens)
      local cells = vim.fn.virtcol({ lnum, '$' }) - 1
      list[#list + 1] = { lnum = lnum, rows = math.max(math.ceil(cells / width), 1) }
    end
  end
  return list
end

--- Fills a window's rows: `missing` has how many under each line, 0 being above
--- the first.
local function fill(win, missing)
  local buf, ns = api.nvim_win_get_buf(win), namespace(win)
  api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  -- (as Neovim's filler lines look in Diffview, enhanced_diff_hl on)
  local row = { { vim.opt_global.fillchars:get().diff:rep(text_width(win)), 'DiffviewDiffDeleteDim' } }
  for lnum, count in pairs(missing) do
    local rows = {}
    for i = 1, count do
      rows[i] = row
    end
    api.nvim_buf_set_extmark(buf, ns, math.max(lnum - 1, 0), 0, { virt_lines = rows, virt_lines_above = lnum == 0 })
  end
  -- (what's above the first line shows only once a window scrolls up to it)
  if missing[0] and vim.fn.getwininfo(win)[1].topline == 1 then
    api.nvim_win_call(win, function()
      vim.fn.winrestview({ topfill = vim.fn.diff_filler(1) + missing[0] })
    end)
  end
end

local function align()
  local wins = vim.tbl_filter(function(win)
    return vim.wo[win].diff and vim.wo[win].wrap
  end, api.nvim_tabpage_list_wins(0))
  local sides, missing = {}, {}
  for i, win in ipairs(wins) do
    sides[i], missing[i] = api.nvim_win_call(win, entries), {}
  end
  for row in ipairs(sides[1] or {}) do
    local height = 0
    for _, side in ipairs(sides) do
      height = math.max(height, side[row] and side[row].rows or 0)
    end
    for i, side in ipairs(sides) do
      local entry = side[row]
      if entry and entry.rows < height then
        missing[i][entry.lnum] = (missing[i][entry.lnum] or 0) + height - entry.rows
      end
    end
  end
  for i, win in ipairs(wins) do
    fill(win, missing[i])
  end
end

function M.setup()
  local scheduled = false
  api.nvim_create_autocmd({ 'DiffUpdated', 'WinResized' }, {
    group = api.nvim_create_augroup('user_diff_wrap', {}),
    callback = function()
      -- (once a redraw is over, and once for all the events until then)
      if not scheduled then
        scheduled = true
        vim.schedule(function()
          scheduled = false
          align()
        end)
      end
    end,
  })
end

return M
