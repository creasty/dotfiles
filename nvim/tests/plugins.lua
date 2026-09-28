-- Installs and checks the plugins the suite runs against: the commits
-- nvim/flake.lock pins (which Dependabot bumps), and the tree-sitter parsers
-- of user/plugin/treesitter/parsers.lua at the revisions the pinned
-- nvim-treesitter's table of parsers pins. CI installs exactly those.
--
-- Run through nvim/tests/plugins (see usage below).

local lib_dir = vim.fs.joinpath(vim.fs.dirname(vim.fs.normalize(debug.getinfo(1, 'S').source:sub(2))), 'lib')
package.path = lib_dir .. '/?.lua;' .. package.path
local env = require('env')

vim.opt.rtp:prepend(env.config_dir)
local config = require('user.plugins')
local PARSERS = require('user.plugin.treesitter.parsers')

local USAGE = [[
Usage: nvim/tests/plugins check | install

  check     compare the installed plugins and parsers with what nvim/flake.lock
            pins (exit 1 if they differ)
  install   install what it pins that is missing: plugins into $E2E_PLUGINS
            (default: lazy.nvim's, ~/.local/share/nvim/lazy) and their
            tree-sitter parsers. An installed plugin at another commit is
            reported, never changed.]]

local FLAKE_LOCK = env.config_dir .. '/flake.lock'

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

local function read_pins()
  local ok, pins = pcall(config.pins, FLAKE_LOCK)
  if not ok then
    fail(('Cannot read %s: %s'):format(FLAKE_LOCK, pins))
  end
  return pins
end

--- The plugins of nvim/lua/user/plugins.lua as lazy.nvim resolves them, by
--- name: `url`, `dir` (in `root`, or your working copy when `_.is_local`).
local function declared(root)
  vim.opt.rtp:prepend(root .. '/lazy.nvim')
  local opts = vim.deepcopy(config.opts)
  opts.root = root
  require('lazy.core.config').setup(opts)
  require('lazy.core.plugin').load()
  return require('lazy.core.config').plugins
end

--- Where the config has nvim-treesitter install the parsers: its own
--- directory's site/ (user/plugin/treesitter).
local function site(ts)
  return ts .. '/site'
end

--- Parsers nvim-treesitter built, with the revision each was built from.
local function installed_parsers(ts)
  local parsers = {}
  for name, type in vim.fs.dir(site(ts) .. '/parser-info') do
    local lang = name:match('^(.*)%.revision$')
    if type == 'file' and lang and vim.uv.fs_stat(('%s/parser/%s.so'):format(site(ts), lang)) then
      parsers[lang] = vim.trim(env.read_file(site(ts) .. '/parser-info/' .. name))
    end
  end
  return parsers
end

--- nvim-treesitter's table of parsers: how to build each, at which revision.
local function parser_table(ts)
  vim.opt.rtp:prepend(ts)
  return require('nvim-treesitter.parsers')
end

--- The revision of each parser that nvim-treesitter pins.
local function pinned_parsers(ts)
  local known = parser_table(ts)
  local parsers = {}
  for _, lang in ipairs(PARSERS) do
    parsers[lang] = known[lang] and known[lang].install_info and known[lang].install_info.revision
  end
  return parsers
end

local function buildable(ts, langs)
  local known = parser_table(ts)
  return vim.tbl_filter(function(lang)
    return known[lang] ~= nil and known[lang].install_info ~= nil
  end, langs)
end

local function same_repository(a, b)
  local function normalize(url)
    return (url:lower():gsub('%.git$', ''):gsub('/$', ''))
  end
  return normalize(a) == normalize(b)
end

--- Differences between nvim/flake.lock and what is installed. Your working
--- copies (lazy.nvim's `dev`) are yours to keep at any commit.
local function differences(pins, plugins)
  local problems = {}
  for name, plugin in pairs(plugins) do
    local pinned = pins[name]
    if not pinned then
      problems[#problems + 1] = name .. ': not pinned (add an input to nvim/flake.nix, then: nix flake lock ./nvim)'
    elseif not same_repository(plugin.url, pinned.url) then
      problems[#problems + 1] = ('%s: installed from %s, pinned from %s'):format(name, plugin.url, pinned.url)
    elseif not plugin._.is_local then
      local commit = git(plugin.dir, 'rev-parse', 'HEAD')
      if not commit then
        problems[#problems + 1] = name .. ': not installed'
      elseif commit ~= pinned.commit then
        problems[#problems + 1] = ('%s: at %s, pinned at %s'):format(name, commit:sub(1, 12), pinned.commit:sub(1, 12))
      end
    end
  end
  -- (a plugin the spec switches off with `cond`, which lazy.nvim neither
  -- installs nor loads, keeps its pin for when it is back on)
  local off = require('lazy.core.config').spec.disabled
  for name in pairs(pins) do
    if not plugins[name] and not (off[name] and off[name]._.cond == false) then
      problems[#problems + 1] = name .. ': pinned, but no longer in nvim/lua/user/plugins.lua'
    end
  end
  local ts = plugins['nvim-treesitter'].dir
  local installed = installed_parsers(ts)
  for lang, revision in pairs(pinned_parsers(ts)) do
    if not installed[lang] then
      problems[#problems + 1] = ('parser %s: not installed'):format(lang)
    elseif installed[lang] ~= revision then
      problems[#problems + 1] = ('parser %s: at %s, nvim-treesitter pins %s (run: :Lazy build nvim-treesitter)'):format(
        lang, installed[lang]:sub(1, 12), (revision or '?'):sub(1, 12))
    end
  end
  for lang in pairs(installed) do
    if not vim.tbl_contains(PARSERS, lang) and #buildable(ts, { lang }) > 0 then
      problems[#problems + 1] = ('parser %s: installed, but not in user/plugin/treesitter/parsers.lua'):format(lang)
    end
  end
  table.sort(problems)
  return problems
end

--- Runs commands, `limit` at a time; returns "name: first error line" for
--- each that failed.
local function run_all(jobs, limit)
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
-- a clone of its own) when the lock tells it.
local CLONE = [[
set -e
mkdir -p "$1"
cd "$1"
git init -q
git remote add origin "$2"
git fetch -q --depth 1 origin "$3"
git -c advice.detachedHead=false checkout -q FETCH_HEAD
if [ -n "$4" ]; then
  git update-ref "refs/remotes/origin/$4" FETCH_HEAD
  git symbolic-ref refs/remotes/origin/HEAD "refs/remotes/origin/$4"
fi
]]

local function clone_job(name, dir, pinned)
  return { name = name, cmd = { 'sh', '-c', CLONE, 'clone', dir, pinned.url, pinned.commit, pinned.branch or '' } }
end

local commands = {}

function commands.check()
  local problems = differences(read_pins(), declared(env.find_plugins()))
  if #problems > 0 then
    fail('The installed plugins differ from nvim/flake.lock:\n  ' .. table.concat(problems, '\n  '))
  end
  say('The installed plugins match nvim/flake.lock.')
end

function commands.install()
  local pins = read_pins()
  local root = env.plugins_root()
  vim.fn.mkdir(root, 'p')

  -- lazy.nvim first, which tells where the others go
  if not vim.uv.fs_stat(root .. '/lazy.nvim') then
    local failed = run_all({ clone_job('lazy.nvim', root .. '/lazy.nvim', pins['lazy.nvim']) }, 1)
    if #failed > 0 then
      fail('Failed to clone:\n  ' .. failed[1])
    end
  end
  local plugins = declared(root)

  local clones, unpinned = {}, {}
  for name, plugin in pairs(plugins) do
    if not vim.uv.fs_stat(plugin.dir) then
      if pins[name] then
        clones[#clones + 1] = clone_job(name, plugin.dir, pins[name])
      else
        unpinned[#unpinned + 1] = name
      end
    end
  end
  if #unpinned > 0 then
    table.sort(unpinned)
    fail('Not pinned in nvim/flake.lock: ' .. table.concat(unpinned, ' '))
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
  local missing = vim.tbl_filter(function(lang)
    return not installed[lang]
  end, PARSERS)
  if #missing > 0 then
    say(('Compiling %d tree-sitter parsers'):format(#missing))
    vim.opt.rtp:prepend(ts)
    local nvim_treesitter = require('nvim-treesitter')
    nvim_treesitter.setup({ install_dir = site(ts) })
    -- (one build per CPU: it would run them all at once)
    nvim_treesitter.install(missing, { summary = true, max_jobs = vim.uv.available_parallelism() }):wait(30 * 60 * 1000)
  end

  local problems = differences(pins, plugins)
  if #problems > 0 then
    fail('Installed, but these differ from nvim/flake.lock:\n  ' .. table.concat(problems, '\n  '))
  end
  say('Installed exactly what nvim/flake.lock pins.')
end

local command = commands[arg[1] or '']
if not command then
  say(USAGE)
  os.exit(arg[1] and arg[1] ~= '-h' and arg[1] ~= '--help' and 1 or 0)
end
command()
