-- Linters without a language server, through nvim-lint. A linter runs only
-- when its command is installed (nix/modules/neovim.nix and friends).

local M = {}

M.linters_by_ft = {
  go = { 'golangcilint' },
  sql = { 'sqlfluff' },
  vim = { 'vint' },
  yaml = { 'ansible_lint' },
}

-- Linters that apply only inside some projects.
local ROOT_MARKERS = {
  ansible_lint = { 'playbook.yml' },
}

local function runnable(name, buf)
  local linter = require('lint').linters[name]
  if type(linter) == 'function' then
    linter = linter()
  end
  local cmd = linter and linter.cmd
  if type(cmd) == 'function' then
    cmd = cmd()
  end
  if not cmd or vim.fn.executable(cmd) == 0 then
    return false
  end
  local markers = ROOT_MARKERS[name]
  return not markers or vim.fs.root(buf, markers) ~= nil
end

function M.lint(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  if vim.bo[buf].buftype ~= '' then
    return
  end
  local names = vim.tbl_filter(function(name)
    return runnable(name, buf)
  end, M.linters_by_ft[vim.bo[buf].filetype] or {})
  if #names > 0 then
    require('lint').try_lint(names)
  end
end

function M.setup()
  require('lint').linters_by_ft = M.linters_by_ft
  vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufWritePost', 'InsertLeave' }, {
    group = vim.api.nvim_create_augroup('user_plugin_lint', {}),
    callback = function(args)
      -- not when Insert mode's <C-o> (niI) leaves it for one command
      if args.event == 'InsertLeave' and vim.api.nvim_get_mode().mode ~= 'n' then
        return
      end
      M.lint(args.buf)
    end,
  })
end

return M
