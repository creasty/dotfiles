-- Completion with blink.cmp: language server items, paths, snippets and words
-- from the buffers, in a menu that opens as you type. Its keys are mapped in
-- user.intelligence, together with snippets, auto-pairs and AI suggestions.

local M = {}

--- Whether an item is a snippet whose whole trigger is typed before the
--- cursor (`import empty`, `items.each`).
local function trigger_typed(item)
  if item.source_id ~= 'snippets' then
    return false
  end
  local before = vim.api.nvim_get_current_line():sub(1, vim.api.nvim_win_get_cursor(0)[2])
  return before:sub(-#item.label) == item.label
end

--- Such a snippet first, the longest of them first, ahead of words and server
--- items that match as well or better (`Empty` and `resource` for `import
--- empty` and `import resource`, a word `each` elsewhere in the file): it is
--- what was typed, and <Tab> accepts the first item.
local function typed_trigger_first(a, b)
  local typed_a, typed_b = trigger_typed(a), trigger_typed(b)
  if typed_a ~= typed_b then
    return typed_a
  elseif typed_a and #a.label ~= #b.label then
    return #a.label > #b.label
  end
end

function M.setup()
  require('blink.cmp').setup({
    keymap = { preset = 'none' },
    appearance = { nerd_font_variant = 'mono' },
    completion = {
      list = { selection = { preselect = true, auto_insert = false } },
      accept = { auto_brackets = { enabled = false } },
      menu = { winblend = 10 },
      documentation = { auto_show = true, window = { winblend = 10 } },
      ghost_text = { enabled = true },
    },
    signature = { enabled = true, window = { winblend = 10 } },
    snippets = { preset = 'luasnip' },
    sources = {
      default = { 'lsp', 'path', 'snippets', 'buffer' },
      -- no menu after a lone `-`, which blink.cmp takes for a word of no
      -- letters (for the arrow and rule snippets); a trigger character such as
      -- `.` still opens it
      min_keyword_length = 1,
      providers = {
        -- words from the buffers alongside the language server's items
        lsp = { fallbacks = {} },
        snippets = { opts = { show_autosnippets = false } },
      },
    },
    fuzzy = { implementation = 'lua', sorts = { typed_trigger_first, 'score', 'sort_text' } },
    cmdline = { enabled = false },
    term = { enabled = false },
  })
end

return M
