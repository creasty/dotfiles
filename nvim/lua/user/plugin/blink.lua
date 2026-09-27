-- Completion with blink.cmp: language server items, paths, snippets and words
-- from the buffers, in a menu that opens as you type. Its keys are mapped in
-- user.intelligence, together with snippets, auto-pairs and AI suggestions.

local M = {}

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
      providers = {
        -- words from the buffers alongside the language server's items
        lsp = { fallbacks = {} },
        snippets = { opts = { show_autosnippets = false } },
      },
    },
    fuzzy = { implementation = 'lua' },
    cmdline = { enabled = false },
    term = { enabled = false },
  })
end

return M
