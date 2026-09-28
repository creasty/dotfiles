-- nvim-treesitter's build (user/plugins.lua): installs the parsers of
-- parsers.lua that are missing, and rebuilds those the checked-out
-- nvim-treesitter pins at other revisions (as :TSUpdate). lazy.nvim runs it
-- in nvim-treesitter's directory, in a Neovim of its own:
--
--   nvim --clean -l nvim/lua/user/plugin/treesitter/build.lua
--
-- nvim-treesitter echoes a few messages for each parser it builds: dozens at
-- once would stop a Neovim with a UI at a prompt, even before it has started.

local dir = vim.uv.cwd()
vim.opt.rtp:prepend(dir)
local ts = require('nvim-treesitter')
-- (where user/plugin/treesitter has them)
local install_dir = vim.fs.joinpath(dir, 'site')
ts.setup({ install_dir = install_dir })

local here = vim.fs.dirname(vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p'))
local missing = vim.tbl_filter(function(lang)
  return not vim.uv.fs_stat(vim.fs.joinpath(install_dir, 'parser', lang .. '.so'))
end, dofile(vim.fs.joinpath(here, 'parsers.lua')))

-- (one build per CPU: it would run them all at once)
local opts = { summary = true, max_jobs = vim.uv.available_parallelism() }
local timeout = 30 * 60 * 1000
-- (forced: nvim-treesitter counts a language whose queries are there as installed)
local installed = ts.install(missing, vim.tbl_extend('force', opts, { force = true })):wait(timeout)
local updated = ts.update(nil, opts):wait(timeout)
if not (installed and updated) then
  os.exit(1)
end
