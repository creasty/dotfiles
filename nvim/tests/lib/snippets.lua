-- Reads the snippet library (nvim/snippets/*.lua, LuaSnip snippets written
-- with user.snippets), so the library spec can pin every snippet.

local env = require('env')

local M = {}

M.dir = env.config_dir .. '/snippets'

--- Filetype that loads each snippet file (default: the file's base name).
M.filetype = {
  all = 'text',
  clike_stmt = 'c',
  clike_postfix = 'c',
  go_postfix = 'go',
  ruby_postfix = 'ruby',
  typescript_henry = 'typescript',
  bq = 'sql.bq',
  pg = 'sql.pg',
}

--- File extension used for the buffer, so snippets reading the file name
--- (`expand('%:t')`) see a realistic one.
M.extension = {
  c = 'c',
  go = 'go',
  javascript = 'js',
  javascriptreact = 'jsx',
  markdown = 'md',
  proto = 'proto',
  ruby = 'rb',
  sh = 'sh',
  sql = 'sql',
  ['sql.bq'] = 'bq.sql',
  ['sql.pg'] = 'pg.sql',
  tex = 'tex',
  text = 'txt',
  tla = 'tla',
  typescript = 'ts',
  typescriptreact = 'tsx',
  vim = 'vim',
}

local loaded = false

--- Puts LuaSnip and the config's Lua modules on the runtimepath.
local function load_luasnip()
  if loaded then
    return
  end
  loaded = true
  vim.opt.rtp:prepend(env.find_plugins() .. '/LuaSnip')
  vim.opt.rtp:prepend(env.config_dir)
end

--- Snippets of one file, in order: { trigger, description, options, line,
--- regex, auto }. `line` is where the snippet's definition starts.
function M.read(name)
  load_luasnip()
  local path = ('%s/%s.lua'):format(M.dir, name)
  local snippets, autosnippets = dofile(path)
  local all = vim.list_extend(vim.list_extend({}, snippets or {}), autosnippets or {})
  -- Line numbers of the definitions, in order of appearance.
  local lines = {}
  for lnum, line in ipairs(vim.fn.readfile(path)) do
    if line:match('S%.snip%(') then
      lines[#lines + 1] = lnum
    end
  end
  local result = {}
  for i, snippet in ipairs(all) do
    local def = snippet.definition or { trigger = snippet.trigger, description = snippet.name, options = '' }
    result[#result + 1] = {
      trigger = def.trigger,
      description = def.description,
      options = def.options,
      line = lines[i],
      regex = def.options:find('r', 1, true) ~= nil,
      auto = def.options:find('A', 1, true) ~= nil,
    }
  end
  return result
end

--- Names of all snippet files with at least one snippet.
function M.files()
  local names = {}
  for name, type in vim.fs.dir(M.dir) do
    if type == 'file' and name:match('%.lua$') then
      names[#names + 1] = name:gsub('%.lua$', '')
    end
  end
  table.sort(names)
  return names
end

return M
