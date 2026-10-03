local ts = require('nvim-treesitter')

-- Parsers and their queries go into nvim-treesitter's own directory: with the
-- plugins lazy.nvim keeps, where the e2e tests find them
-- (nvim/tests/plugins.lua).
local install_dir = vim.fs.joinpath(require('lazy.core.config').plugins['nvim-treesitter'].dir, 'site')
ts.setup { install_dir = install_dir }

-- nvim-treesitter's build installs the parsers of parsers.lua (build.lua).
-- When one is missing (added since, or the build failed), lazy.nvim runs the
-- build again, as it installs missing plugins: at startup, in its window. Not
-- without a UI (scripts, the e2e suite), nor without the tree-sitter CLI it
-- builds them with (nix/modules/neovim.nix): it would fail at every startup.
-- (What is missing is checked here: nvim-treesitter takes milliseconds to find
-- nothing is.)
local missing = vim.tbl_filter(function(lang)
  return not vim.uv.fs_stat(vim.fs.joinpath(install_dir, 'parser', lang .. '.so'))
end, require('user.plugin.treesitter.parsers'))
if #missing > 0 and #vim.api.nvim_list_uis() > 0 and vim.fn.executable('tree-sitter') == 1 then
  require('lazy').build({ plugins = { 'nvim-treesitter' }, wait = true })
end

--- Selects the syntax node under the cursor.
local function select_node()
  vim.treesitter.get_parser():parse({ vim.fn.line('w0') - 1, vim.fn.line('w$') })
  local node = vim.treesitter.get_node({ ignore_injections = false })
  if not node then
    return
  end
  local srow, scol, erow, ecol = node:range()
  if ecol == 0 then
    -- (it ends with a line break: up to the end of the line before)
    erow = erow - 1
    ecol = #vim.api.nvim_buf_get_lines(0, erow, erow + 1, true)[1]
  end
  vim.api.nvim_win_set_cursor(0, { srow + 1, scol })
  vim.cmd('normal! v')
  vim.api.nvim_win_set_cursor(0, { erow + 1, math.max(ecol - 1, 0) })
end

-- Highlighting and indentation, where there are a parser and queries for them
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('user_treesitter', {}),
  callback = function(ev)
    local lang = vim.treesitter.language.get_lang(ev.match)
    if not lang or not vim.treesitter.language.add(lang) then
      -- (the buffer's filetype had one before)
      if vim.b[ev.buf].user_treesitter then
        vim.b[ev.buf].user_treesitter = nil
        vim.treesitter.stop(ev.buf)
        vim.keymap.del({ 'n', 'x' }, 'gs', { buffer = ev.buf })
      end
      return
    end
    vim.b[ev.buf].user_treesitter = true
    local function has(query)
      return #vim.treesitter.query.get_files(lang, query) > 0
    end
    if has('highlights') then
      vim.treesitter.start(ev.buf, lang)
    end
    -- (nvim/queries/typescript/indents.scm adds the shapes prettier gives
    -- TypeScript and TSX)
    if has('indents') then
      vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
    -- gs selects the node under the cursor, then the one around the selection
    vim.keymap.set('n', 'gs', select_node, { buffer = ev.buf })
    vim.keymap.set('x', 'gs', 'an', { buffer = ev.buf, remap = true })
  end,
})

-- The scopes around the cursor at the top of the window, one line each
require('treesitter-context').setup { multiline_threshold = 1 }

-- Closes and renames tags in markup, and closes them on </ too
require('nvim-ts-autotag').setup { opts = { enable_close_on_slash = true } }
