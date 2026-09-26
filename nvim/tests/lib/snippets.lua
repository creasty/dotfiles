-- Reads the snippet library (nvim/ultisnips/*.snippets) the way UltiSnips
-- parses snippet headers, so the library spec can pin every snippet.

local env = require('env')

local M = {}

M.dir = env.config_dir .. '/ultisnips'

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
  gitattributes = 'gitattributes.toml',
}

--- File extension used for the buffer, so snippets reading the file name
--- (`expand('%:t')`) see a realistic one.
M.extension = {
  c = 'c',
  css = 'css',
  go = 'go',
  haml = 'haml',
  javascript = 'js',
  javascriptreact = 'jsx',
  lua = 'lua',
  markdown = 'md',
  proto = 'proto',
  ruby = 'rb',
  sh = 'sh',
  snippets = 'snippets',
  sql = 'sql',
  ['sql.bq'] = 'bq.sql',
  ['sql.pg'] = 'pg.sql',
  tex = 'tex',
  text = 'txt',
  tla = 'tla',
  typescript = 'ts',
  typescriptreact = 'tsx',
  vim = 'vim',
  ['gitattributes.toml'] = 'gitattributes',
}

-- Mirrors UltiSnips' _handle_snippet_or_global header parsing.
local function parse_header(head)
  head = vim.trim(head)
  local opts = ''
  local words = vim.split(head, '%s+')
  if #words > 2 and not words[#words]:find('"', 1, true) and words[#words - 1]:sub(-1) == '"' then
    opts = words[#words]
    head = vim.trim(head:sub(1, #head - #opts))
  end
  local descr = ''
  if head:sub(-1) == '"' then
    local left = head:sub(1, -2):match('.*()"')
    if left and left ~= 1 then
      descr = head:sub(left)
      head = head:sub(1, left - 1)
    end
  end
  local trigger = vim.trim(head)
  if #vim.split(trigger, '%s+') > 1 or opts:find('r', 1, true) then
    trigger = trigger:sub(2, -2)
  end
  return trigger, descr:sub(2, -2), opts
end

--- Snippets of one file: { trigger, description, options, line, regex, auto, context }.
function M.read(name)
  local path = ('%s/%s.snippets'):format(M.dir, name)
  local result = {}
  local pending_context = false
  for lnum, line in ipairs(vim.fn.readfile(path)) do
    if line:match('^context ') or line:match('^pre_expand ') or line:match('^post_jump ') or line:match('^post_expand ') then
      pending_context = line:match('^(%S+)')
    elseif line:match('^snippet ') then
      local trigger, descr, opts = parse_header(line:sub(#'snippet ' + 1))
      table.insert(result, {
        trigger = trigger,
        description = descr,
        options = opts,
        line = lnum,
        regex = opts:find('r', 1, true) ~= nil,
        auto = opts:find('A', 1, true) ~= nil,
        hook = pending_context or nil,
      })
      pending_context = false
    end
  end
  return result
end

--- Names of all snippet files with at least one snippet.
function M.files()
  local names = {}
  for name, type in vim.fs.dir(M.dir) do
    if type == 'file' and name:match('%.snippets$') then
      names[#names + 1] = name:gsub('%.snippets$', '')
    end
  end
  table.sort(names)
  return names
end

return M
