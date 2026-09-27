-- Pins the plugins the suite runs against. nvim/dein/lock.json records, as
-- installed on your machine: the commit of every dein plugin and the revision
-- of every tree-sitter parser nvim-treesitter compiled. CI installs exactly
-- those.
--
-- A plugin whose repository is gone can get a "mirror" in lock.json to fetch
-- the same commit from; `lock` keeps it.
--
-- Run through nvim/tests/plugins (see usage below).

local lib_dir = vim.fs.joinpath(vim.fs.dirname(vim.fs.normalize(debug.getinfo(1, 'S').source:sub(2))), 'lib')
package.path = lib_dir .. '/?.lua;' .. package.path
local env = require('env')

local USAGE = [[
Usage: nvim/tests/plugins lock | check | install

  lock      write nvim/dein/lock.json from the installed plugins
  check     compare the installed plugins with lock.json (exit 1 if they differ)
  install   install what lock.json pins that is missing: dein plugins into
            $E2E_DEIN_REPOS (default: nvim/dein/repos) and their tree-sitter
            parsers. An installed plugin at another commit is reported, never
            changed.]]

local LOCK_FILE = env.config_dir .. '/dein/lock.json'
local TOML_FILES = { env.config_dir .. '/dein/default.toml', env.config_dir .. '/dein/lazy.toml' }
-- dein appends the plugin's `rev` (default.toml pins nvim-treesitter to master)
local TREESITTER = 'github.com/nvim-treesitter/nvim-treesitter_master'

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

--- Where a locked plugin lives: `key` is relative to the repos directory, or
--- absolute for plugins with an explicit `path`.
local function locate(repos, key)
  return key:sub(1, 1) == '/' and key or (repos .. '/' .. key)
end

--- The plugins of the toml files, as dein names their directories (see
--- dein#parse#_dict() and the git type's init()).
local function declared(repos)
  vim.opt.rtp:append(repos .. '/github.com/Shougo/dein.vim')
  local keys = {}
  for _, file in ipairs(TOML_FILES) do
    for _, plugin in ipairs(vim.fn['dein#toml#parse_file'](file).plugins or {}) do
      local key
      if plugin.path then
        key = vim.fs.normalize(plugin.path)
      elseif plugin.repo:match('^[%w_.-]+/[%w_.-]+$') then
        key = 'github.com/' .. plugin.repo
      else
        key = plugin.repo:gsub('%.git$', ''):gsub('^https:/+', ''):gsub('^git@', ''):gsub(':', '/')
      end
      if plugin.rev and plugin.rev ~= '' then
        key = key .. '_' .. plugin.rev:gsub('[^%w.-]', '_')
      end
      keys[#keys + 1] = key
    end
  end
  table.sort(keys)
  return keys
end

--- Parsers nvim-treesitter compiled into its own directory, with the revision
--- each was built from (only those it still knows how to build).
local function installed_parsers(repos)
  local ts = repos .. '/' .. TREESITTER
  local parsers = {}
  for name, type in vim.fs.dir(ts .. '/parser-info') do
    local lang = name:match('^(.*)%.revision$')
    if type == 'file' and lang and vim.uv.fs_stat(('%s/parser/%s.so'):format(ts, lang)) then
      parsers[lang] = vim.trim(env.read_file(ts .. '/parser-info/' .. name))
    end
  end
  return parsers
end

local function buildable(repos, langs)
  vim.opt.rtp:prepend(repos .. '/' .. TREESITTER)
  local configs = require('nvim-treesitter.parsers').get_parser_configs()
  return vim.tbl_filter(function(lang)
    return configs[lang] ~= nil
  end, langs)
end

local function read_lock()
  local text = env.read_file(LOCK_FILE)
  if not text then
    fail(('%s does not exist; run: nvim/tests/plugins lock'):format(LOCK_FILE))
  end
  return vim.json.decode(text)
end

local function encode(lock)
  local function str(s)
    return (vim.json.encode(s):gsub('\\/', '/'))
  end
  local function section(name, map, last, value)
    local keys = vim.tbl_keys(map)
    table.sort(keys)
    local out = { ('  %s: {'):format(str(name)) }
    for i, key in ipairs(keys) do
      out[#out + 1] = ('    %s: %s%s'):format(str(key), value(map[key]), i < #keys and ',' or '')
    end
    out[#out + 1] = last and '  }' or '  },'
    return table.concat(out, '\n')
  end
  return table.concat({
    '{',
    section('dein', lock.dein, false, function(plugin)
      local mirror = plugin.mirror and (', "mirror": ' .. str(plugin.mirror)) or ''
      return ('{ "url": %s, "commit": %s%s }'):format(str(plugin.url), str(plugin.commit), mirror)
    end),
    section('treesitter', lock.treesitter, true, str),
    '}',
    '',
  }, '\n')
end

local commands = {}
local run_all

function commands.lock()
  local repos = env.find_dein_repos()
  local previous = env.read_file(LOCK_FILE) and vim.json.decode(env.read_file(LOCK_FILE)) or { dein = {} }
  local lock = { dein = {}, treesitter = {} }
  local errors = {}
  for _, key in ipairs(declared(repos)) do
    local dir = locate(repos, key)
    local commit, url = git(dir, 'rev-parse', 'HEAD'), git(dir, 'remote', 'get-url', 'origin')
    if not commit or not url then
      errors[#errors + 1] = key .. ': not installed (or not a git clone)'
    else
      local mirror = previous.dein[key] and previous.dein[key].mirror
      lock.dein[key] = { url = url, commit = commit, mirror = mirror }
      if git(dir, 'status', '--porcelain', '--untracked-files=no') ~= '' then
        say(('warning: %s has local changes; locking its HEAD'):format(key))
      end
      if git(dir, 'branch', '--remotes', '--contains', commit) == '' then
        say(('warning: %s is at %s, which no remote branch contains; CI may not be able to fetch it'):format(key, commit:sub(1, 12)))
      end
    end
  end
  local reachable = {}
  for key, plugin in pairs(lock.dein) do
    if not plugin.mirror then
      reachable[#reachable + 1] = { name = key, cmd = { 'git', 'ls-remote', '--exit-code', plugin.url, 'HEAD' } }
    end
  end
  for _, failure in ipairs(run_all(reachable, 8)) do
    say(('warning: cannot reach %s\n  add a "mirror" that has its commit to lock.json'):format(failure))
  end
  local parsers = installed_parsers(repos)
  for _, lang in ipairs(buildable(repos, vim.tbl_keys(parsers))) do
    lock.treesitter[lang] = parsers[lang]
  end
  if #errors > 0 then
    fail(table.concat(errors, '\n'))
  end
  env.write_file(LOCK_FILE, encode(lock))
  say(('wrote %s: %d plugins, %d parsers'):format(LOCK_FILE, vim.tbl_count(lock.dein), vim.tbl_count(lock.treesitter)))
end

--- Differences between lock.json and what is installed.
local function differences(lock, repos)
  local problems = {}
  local keys = declared(repos)
  for _, key in ipairs(keys) do
    local locked = lock.dein[key]
    local commit = git(locate(repos, key), 'rev-parse', 'HEAD')
    if not locked then
      problems[#problems + 1] = key .. ': not in lock.json (run: nvim/tests/plugins lock)'
    elseif not commit then
      problems[#problems + 1] = key .. ': not installed'
    elseif commit ~= locked.commit then
      problems[#problems + 1] = ('%s: at %s, locked at %s'):format(key, commit:sub(1, 12), locked.commit:sub(1, 12))
    end
  end
  for key in pairs(lock.dein) do
    if not vim.tbl_contains(keys, key) then
      problems[#problems + 1] = key .. ': locked, but no longer in the toml files'
    end
  end
  local parsers = installed_parsers(repos)
  for lang, revision in pairs(lock.treesitter) do
    if not parsers[lang] then
      problems[#problems + 1] = ('parser %s: not installed'):format(lang)
    elseif parsers[lang] ~= revision then
      problems[#problems + 1] = ('parser %s: at %s, locked at %s'):format(lang, parsers[lang]:sub(1, 12), revision:sub(1, 12))
    end
  end
  for lang in pairs(parsers) do
    if not lock.treesitter[lang] and #buildable(repos, { lang }) > 0 then
      problems[#problems + 1] = ('parser %s: installed, but not in lock.json'):format(lang)
    end
  end
  table.sort(problems)
  return problems
end

function commands.check()
  local problems = differences(read_lock(), env.find_dein_repos())
  if #problems > 0 then
    fail('The installed plugins differ from nvim/dein/lock.json:\n  ' .. table.concat(problems, '\n  '))
  end
  say('The installed plugins match nvim/dein/lock.json.')
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

local CLONE = [[
set -e
mkdir -p "$1"
cd "$1"
git init -q
git remote add origin "$2"
git fetch -q --depth 1 "$4" "$3"
git -c advice.detachedHead=false checkout -q FETCH_HEAD
]]

function commands.install()
  local lock = read_lock()
  local repos = os.getenv('E2E_DEIN_REPOS') or (env.config_dir .. '/dein/repos')
  vim.fn.mkdir(repos, 'p')

  local clones = {}
  for key, plugin in pairs(lock.dein) do
    local dir = locate(repos, key)
    if not vim.uv.fs_stat(dir) then
      clones[#clones + 1] = { name = key, cmd = { 'sh', '-c', CLONE, 'clone', dir, plugin.url, plugin.commit, plugin.mirror or plugin.url } }
    end
  end
  table.sort(clones, function(a, b)
    return a.name < b.name
  end)
  say(('Cloning %d plugins into %s'):format(#clones, repos))
  local failed = run_all(clones, 8)
  if #failed > 0 then
    fail('Failed to clone:\n  ' .. table.concat(failed, '\n  '))
  end

  local installed = installed_parsers(repos)
  local missing = {}
  for lang, revision in pairs(lock.treesitter) do
    if not installed[lang] then
      missing[#missing + 1] = lang
    end
  end
  table.sort(missing)
  if #missing > 0 then
    say(('Compiling %d tree-sitter parsers'):format(#missing))
    vim.opt.rtp:prepend(repos .. '/' .. TREESITTER)
    local configs = require('nvim-treesitter.parsers').get_parser_configs()
    for _, lang in ipairs(missing) do
      configs[lang].install_info.revision = lock.treesitter[lang]
    end
    local ts_install = require('nvim-treesitter.install')
    ts_install.ensure_installed_sync(missing)
    -- Some hosts answer a tarball download with a bot check; git gets through.
    local retry = vim.tbl_filter(function(lang)
      return not installed_parsers(repos)[lang]
    end, missing)
    if #retry > 0 then
      say('Retrying with git: ' .. table.concat(retry, ' '))
      ts_install.prefer_git = true
      ts_install.ensure_installed_sync(retry)
    end
  end

  local problems = differences(lock, repos)
  if #problems > 0 then
    fail('Installed, but these differ from nvim/dein/lock.json:\n  ' .. table.concat(problems, '\n  '))
  end
  say('Installed exactly what nvim/dein/lock.json pins.')
end

local command = commands[arg[1] or '']
if not command then
  say(USAGE)
  os.exit(arg[1] and arg[1] ~= '-h' and arg[1] ~= '--help' and 1 or 0)
end
command()
