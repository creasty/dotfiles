---@diagnostic disable: undefined-global

local actions = require('telescope.actions')
local actions_set = require('telescope.actions.set')
local conf = require('telescope.config').values
local finders = require('telescope.finders')
local from_entry = require('telescope.from_entry')
local path = require('telescope.path')
local pickers = require('telescope.pickers')
local previewers = require('telescope.previewers')
local utils = require('telescope.utils')

local function is_readable(filepath)
  local fd = vim.loop.fs_open(filepath, 'r', 438)
  local result = fd and true or false
  if result then
    vim.loop.fs_close(fd)
  end
  return result
end

local function search_readme(dir)
  for _, name in pairs{'README', 'README.md', 'README.markdown'} do
    local filepath = dir..path.separator..name
    if is_readable(filepath) then
      return filepath
    end
  end
  return nil
end

local function gen_from_ghq(opts)
  return function(line)
    return {
      value = line,
      ordinal = line,
      path = opts.root_path .. '/' .. line,
      display = line,
    }
  end
end

local function get_ghq_root(bin)
  local f = assert(io.popen(bin .. ' root', 'r'))
  local s = assert(f:read('*a'))
  f:close()
  s = string.gsub(s, '^%s+', '')
  s = string.gsub(s, '%s+$', '')
  return s
end

local function list(opts)
  opts = opts or {}
  opts.bin = opts.bin and vim.fn.expand(opts.bin) or 'ghq'
  opts.cwd = utils.get_lazy_default(opts.cwd, vim.loop.cwd)
  opts.root_path = get_ghq_root(opts.bin)
  opts.entry_maker = utils.get_lazy_default(opts.entry_maker, gen_from_ghq, opts)

  local bin = vim.fn.expand(opts.bin)
  pickers.new(opts, {
    prompt_title = 'Repositories managed by ghq',
    finder = finders.new_oneshot_job(
      {bin, 'list'},
      opts
    ),
    previewer = previewers.new_termopen_previewer{
      get_command = function(entry)
        local dir = from_entry.path(entry)
        local doc = search_readme(dir)
        if doc then
          if vim.fn.executable'bat' == 1 then
            return {'bat', '--style', 'header,grid', doc}
          end
          return {'cat', doc}
        end
        return {'echo', ''}
      end,
    },
    sorter = conf.file_sorter(opts),
    attach_mappings = function(prompt_bufnr)
      actions_set.select:replace(function(_, _)
        local entry = actions.get_selected_entry()
        actions.close(prompt_bufnr)
        local dir = from_entry.path(entry)
        vim.cmd('cd '..dir)
      end)
      return true
    end,
  }):find()
end

return require'telescope'.register_extension{
  exports = {
    list = list,
  },
}
