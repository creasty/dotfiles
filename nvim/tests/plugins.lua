-- Pins the plugins the suite runs against. nvim/lazy-lock.json, lazy.nvim's
-- lockfile, pins the plugins it installs; nvim/tests/lock.json pins the rest
-- of what is installed on your machine: the commit of each plugin lazy.nvim
-- loads from your working copy (`dev` in nvim/lua/user/plugins.lua), and the
-- revision of every tree-sitter parser nvim-treesitter compiled. CI installs
-- exactly those.
--
-- Run through nvim/tests/plugins (see usage below).

local lib_dir = vim.fs.joinpath(vim.fs.dirname(vim.fs.normalize(debug.getinfo(1, 'S').source:sub(2))), 'lib')
package.path = lib_dir .. '/?.lua;' .. package.path
local env = require('env')

local USAGE = [[
Usage: nvim/tests/plugins lock | check | install

  lock      pin what is installed: the plugins lazy.nvim installs in
            nvim/lazy-lock.json (the way it does itself), your working copies
            and the tree-sitter parsers in nvim/tests/lock.json
  check     compare the installed plugins with both (exit 1 if they differ)
  install   install what they pin that is missing: plugins into
            $E2E_PLUGINS (default: lazy.nvim's, ~/.local/share/nvim/lazy)
            and their tree-sitter parsers. An installed plugin at another
            commit is reported, never changed.]]

local LAZY_LOCK = env.config_dir .. '/lazy-lock.json'
local LOCK_FILE = env.tests_dir .. '/lock.json'
local LAZY_URL = 'https://github.com/folke/lazy.nvim.git'

local function fail(msg)
  io.stderr:write(msg, '\n')
  os.exit(1)
end

local function say(msg)
  io.stdout:write(msg, '\n')
  io.stdout:flush()
end

local function git(dir, ...)
  if not vim.uv.fs_stat(dir .. '/.git') then
    return nil
  end
  local result = vim.system({ 'git', '-C', dir, ... }, { text = true }):wait()
  return result.code == 0 and vim.trim(result.stdout) or nil
end

local function read_json(path)
  local text = env.read_file(path)
  if not text then
    fail(('%s does not exist; run: nvim/tests/plugins lock'):format(path))
  end
  return vim.json.decode(text)
end

local function read_lock()
  local lock = read_json(LOCK_FILE)
  lock.dev = lock.dev or {}
  lock.treesitter = lock.treesitter or {}
  return lock
end

--- The plugins of nvim/lua/user/plugins.lua as lazy.nvim resolves them, by
--- name: `url`, `dir` (in `root`, or your working copy when `_.is_local`).
local function declared(root)
  vim.opt.rtp:prepend(root .. '/lazy.nvim')
  vim.opt.rtp:prepend(env.config_dir)
  local opts = vim.deepcopy(require('user.plugins').opts)
  opts.root = root
  opts.lockfile = LAZY_LOCK
  require('lazy.core.config').setup(opts)
  require('lazy.core.plugin').load()
  return require('lazy.core.config').plugins
end

--- The commit a plugin is pinned at: { branch, commit }.
local function pin(lazy_lock, lock, name)
  return lock.dev[name] or lazy_lock[name]
end

--- Parsers nvim-treesitter compiled into its own directory, with the revision
--- each was built from (only those it still knows how to build).
local function installed_parsers(ts)
  local parsers = {}
  for name, type in vim.fs.dir(ts .. '/parser-info') do
    local lang = name:match('^(.*)%.revision$')
    if type == 'file' and lang and vim.uv.fs_stat(('%s/parser/%s.so'):format(ts, lang)) then
      parsers[lang] = vim.trim(env.read_file(ts .. '/parser-info/' .. name))
    end
  end
  return parsers
end

local function buildable(ts, langs)
  vim.opt.rtp:prepend(ts)
  local configs = require('nvim-treesitter.parsers').get_parser_configs()
  return vim.tbl_filter(function(lang)
    return configs[lang] ~= nil
  end, langs)
end

local function encode(lock)
  local function str(s)
    return (vim.json.encode(s):gsub('\\/', '/'))
  end
  local function section(name, map, last, value)
    local keys = vim.tbl_keys(map)
    table.sort(keys)
    if #keys == 0 then
      return ('  %s: {}%s'):format(str(name), last and '' or ',')
    end
    local out = { ('  %s: {'):format(str(name)) }
    for i, key in ipairs(keys) do
      out[#out + 1] = ('    %s: %s%s'):format(str(key), value(map[key]), i < #keys and ',' or '')
    end
    out[#out + 1] = last and '  }' or '  },'
    return table.concat(out, '\n')
  end
  return table.concat({
    '{',
    section('dev', lock.dev, false, function(plugin)
      return ('{ "branch": %s, "commit": %s }'):format(str(plugin.branch), str(plugin.commit))
    end),
    section('treesitter', lock.treesitter, true, str),
    '}',
    '',
  }, '\n')
end

local commands = {}
local run_all

function commands.lock()
  local plugins = declared(env.find_plugins())
  local lock = { dev = {}, treesitter = {} }
  local errors = {}
  local reachable = {}
  for name, plugin in pairs(plugins) do
    if not plugin._.installed then
      errors[#errors + 1] = name .. ': not installed'
    elseif plugin._.is_local then
      local commit = git(plugin.dir, 'rev-parse', 'HEAD')
      local branch = commit and require('lazy.manage.git').get_branch(plugin)
      if not commit then
        errors[#errors + 1] = name .. ': not a git clone'
      elseif not branch then
        errors[#errors + 1] = name .. ': cannot tell its branch (no origin/HEAD, and HEAD is detached)'
      else
        lock.dev[name] = { branch = branch, commit = commit }
        if git(plugin.dir, 'status', '--porcelain', '--untracked-files=no') ~= '' then
          say(('warning: %s has local changes; pinning its HEAD'):format(name))
        end
        if git(plugin.dir, 'branch', '--remotes', '--contains', commit) == '' then
          say(('warning: %s is at %s, which no remote branch contains; CI may not be able to fetch it'):format(name, commit:sub(1, 12)))
        end
      end
    end
    if plugin.url then
      reachable[#reachable + 1] = { name = name, cmd = { 'git', 'ls-remote', '--exit-code', plugin.url, 'HEAD' } }
    end
  end
  if #errors > 0 then
    table.sort(errors)
    fail(table.concat(errors, '\n'))
  end
  for _, failure in ipairs(run_all(reachable, 8)) do
    say(('warning: cannot reach %s\n  point its spec at a fork or mirror that has its commit'):format(failure))
  end
  local ts = plugins['nvim-treesitter'].dir
  local parsers = installed_parsers(ts)
  for _, lang in ipairs(buildable(ts, vim.tbl_keys(parsers))) do
    lock.treesitter[lang] = parsers[lang]
  end
  require('lazy.manage.lock').update()
  env.write_file(LOCK_FILE, encode(lock))
  local working_copies = vim.tbl_keys(lock.dev)
  table.sort(working_copies)
  say(('wrote nvim/lazy-lock.json and nvim/tests/lock.json: %d plugins, %d parsers; working copies: %s'):format(
    vim.tbl_count(read_json(LAZY_LOCK)) + #working_copies,
    vim.tbl_count(lock.treesitter),
    #working_copies > 0 and table.concat(working_copies, ', ') or 'none'
  ))
end

--- Differences between the locks and what is installed.
local function differences(lazy_lock, lock, plugins)
  local problems = {}
  for name, plugin in pairs(plugins) do
    local pinned = pin(lazy_lock, lock, name)
    local commit = git(plugin.dir, 'rev-parse', 'HEAD')
    if not pinned then
      problems[#problems + 1] = name .. ': not pinned (run: nvim/tests/plugins lock)'
    elseif not commit then
      problems[#problems + 1] = name .. ': not installed'
    elseif commit ~= pinned.commit then
      problems[#problems + 1] = ('%s: at %s, pinned at %s'):format(name, commit:sub(1, 12), pinned.commit:sub(1, 12))
    end
  end
  for _, pins in ipairs({ lazy_lock, lock.dev }) do
    for name in pairs(pins) do
      if not plugins[name] then
        problems[#problems + 1] = name .. ': pinned, but no longer in nvim/lua/user/plugins.lua'
      end
    end
  end
  local ts = plugins['nvim-treesitter'].dir
  local parsers = installed_parsers(ts)
  for lang, revision in pairs(lock.treesitter) do
    if not parsers[lang] then
      problems[#problems + 1] = ('parser %s: not installed'):format(lang)
    elseif parsers[lang] ~= revision then
      problems[#problems + 1] = ('parser %s: at %s, locked at %s'):format(lang, parsers[lang]:sub(1, 12), revision:sub(1, 12))
    end
  end
  for lang in pairs(parsers) do
    if not lock.treesitter[lang] and #buildable(ts, { lang }) > 0 then
      problems[#problems + 1] = ('parser %s: installed, but not in nvim/tests/lock.json'):format(lang)
    end
  end
  table.sort(problems)
  return problems
end

function commands.check()
  local problems = differences(read_json(LAZY_LOCK), read_lock(), declared(env.find_plugins()))
  if #problems > 0 then
    fail('The installed plugins differ from nvim/lazy-lock.json and nvim/tests/lock.json:\n  ' .. table.concat(problems, '\n  '))
  end
  say('The installed plugins match nvim/lazy-lock.json and nvim/tests/lock.json.')
end

--- Runs commands, `limit` at a time; returns "name: first error line" for
--- each that failed.
function run_all(jobs, limit)
  local failed, running, next_job = {}, 0, 1
  local function start()
    while running < limit and next_job <= #jobs do
      local job = jobs[next_job]
      next_job = next_job + 1
      running = running + 1
      vim.system(job.cmd, { text = true }, function(result)
        if result.code ~= 0 then
          failed[#failed + 1] = ('%s: %s'):format(job.name, vim.split(vim.trim(result.stderr), '\n')[1])
        end
        running = running - 1
        vim.schedule(start)
      end)
    end
  end
  start()
  vim.wait(30 * 60 * 1000, function()
    return running == 0 and next_job > #jobs
  end, 50)
  return failed
end

-- Clones a commit, with the branch lazy.nvim takes a plugin to follow (as in
-- a clone of its own).
local CLONE = [[
set -e
mkdir -p "$1"
cd "$1"
git init -q
git remote add origin "$2"
git fetch -q --depth 1 origin "$3"
git -c advice.detachedHead=false checkout -q FETCH_HEAD
git update-ref "refs/remotes/origin/$4" FETCH_HEAD
git symbolic-ref refs/remotes/origin/HEAD "refs/remotes/origin/$4"
]]

local function clone_job(name, dir, url, pinned)
  return { name = name, cmd = { 'sh', '-c', CLONE, 'clone', dir, url, pinned.commit, pinned.branch } }
end

function commands.install()
  local lazy_lock, lock = read_json(LAZY_LOCK), read_lock()
  local root = env.plugins_root()
  vim.fn.mkdir(root, 'p')

  -- lazy.nvim first, which tells where the others go
  if not vim.uv.fs_stat(root .. '/lazy.nvim') then
    local failed = run_all({ clone_job('lazy.nvim', root .. '/lazy.nvim', LAZY_URL, lazy_lock['lazy.nvim']) }, 1)
    if #failed > 0 then
      fail('Failed to clone:\n  ' .. failed[1])
    end
  end
  local plugins = declared(root)

  local clones, unpinned = {}, {}
  for name, plugin in pairs(plugins) do
    if not vim.uv.fs_stat(plugin.dir) then
      local pinned = pin(lazy_lock, lock, name)
      if pinned then
        clones[#clones + 1] = clone_job(name, plugin.dir, plugin.url, pinned)
      else
        unpinned[#unpinned + 1] = name
      end
    end
  end
  if #unpinned > 0 then
    table.sort(unpinned)
    fail('Not pinned: ' .. table.concat(unpinned, ' ') .. ' (run: nvim/tests/plugins lock)')
  end
  table.sort(clones, function(a, b)
    return a.name < b.name
  end)
  say(('Cloning %d plugins into %s'):format(#clones, root))
  local failed = run_all(clones, 8)
  if #failed > 0 then
    fail('Failed to clone:\n  ' .. table.concat(failed, '\n  '))
  end

  local ts = plugins['nvim-treesitter'].dir
  local installed = installed_parsers(ts)
  local missing = {}
  for lang in pairs(lock.treesitter) do
    if not installed[lang] then
      missing[#missing + 1] = lang
    end
  end
  table.sort(missing)
  if #missing > 0 then
    say(('Compiling %d tree-sitter parsers'):format(#missing))
    vim.opt.rtp:prepend(ts)
    local configs = require('nvim-treesitter.parsers').get_parser_configs()
    for _, lang in ipairs(missing) do
      configs[lang].install_info.revision = lock.treesitter[lang]
    end
    local ts_install = require('nvim-treesitter.install')
    ts_install.ensure_installed_sync(missing)
    -- Some hosts answer a tarball download with a bot check; git gets through.
    local retry = vim.tbl_filter(function(lang)
      return not installed_parsers(ts)[lang]
    end, missing)
    if #retry > 0 then
      say('Retrying with git: ' .. table.concat(retry, ' '))
      ts_install.prefer_git = true
      ts_install.ensure_installed_sync(retry)
    end
  end

  local problems = differences(lazy_lock, lock, plugins)
  if #problems > 0 then
    fail('Installed, but these differ from nvim/lazy-lock.json and nvim/tests/lock.json:\n  ' .. table.concat(problems, '\n  '))
  end
  say('Installed exactly what nvim/lazy-lock.json and nvim/tests/lock.json pin.')
end

local command = commands[arg[1] or '']
if not command then
  say(USAGE)
  os.exit(arg[1] and arg[1] ~= '-h' and arg[1] ~= '--help' and 1 or 0)
end
command()
