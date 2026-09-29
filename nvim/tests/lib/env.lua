-- Builds the isolated environment every child Neovim boots in.
--
-- The children run the real config (this repo's nvim/ directory) exactly the
-- way `nvim` does, with XDG_CONFIG_HOME pointing at a tree of symlinks to it,
-- and every XDG directory and the sandboxes in a throwaway run directory.
-- Tests never touch your real state, shada, clipboard, Trash or caches.
-- Installed plugins are *linked*, never installed or updated.
--
-- This is the only file that knows about the plugin manager (lazy.nvim) and
-- the plugins' on-disk layout. If you switch plugin managers, adapt prepare().

local M = {}

local uv = vim.uv

local function script_dir()
  return vim.fs.dirname(vim.fs.normalize(debug.getinfo(1, 'S').source:sub(2)))
end

M.lib_dir = script_dir()
M.tests_dir = vim.fs.dirname(M.lib_dir)
M.config_dir = vim.fs.dirname(M.tests_dir)
M.repo_dir = vim.fs.dirname(M.config_dir)

local function realpath(path)
  return uv.fs_realpath(path) or path
end

local function mkdir(path)
  vim.fn.mkdir(path, 'p')
  return realpath(path)
end

local function symlink(target, link)
  local ok, err = uv.fs_symlink(target, link)
  if not ok then
    error(('symlink %s -> %s: %s'):format(link, target, err))
  end
end

local function write_file(path, content, mode)
  local f = assert(io.open(path, 'w'))
  f:write(content)
  f:close()
  if mode then
    uv.fs_chmod(path, mode)
  end
end

local function read_file(path)
  local f = io.open(path, 'r')
  if not f then
    return nil
  end
  local s = f:read('*a')
  f:close()
  return s
end

M.read_file = read_file
M.write_file = write_file

--- Where the plugins are installed: $E2E_PLUGINS, or lazy.nvim's root.
function M.plugins_root()
  local root = os.getenv('E2E_PLUGINS')
  if root and root ~= '' then
    return root
  end
  local data = os.getenv('XDG_DATA_HOME')
  return (data and data ~= '' and data or vim.fs.normalize('~/.local/share')) .. '/nvim/lazy'
end

function M.find_plugins()
  local root = M.plugins_root()
  if uv.fs_stat(root) then
    return realpath(root)
  end
  error(('Cannot find the installed plugins in %s. Set E2E_PLUGINS to where they are installed.'):format(root))
end

--- mise's global config on this machine, which it trusts only at that path.
--- XDG_CONFIG_HOME below moves the path, so mise takes the machine's config
--- for an untrusted local one and every tool it manages (erb, for the file
--- templates) prints a trust error instead of running.
function M.mise_config()
  local config = os.getenv('XDG_CONFIG_HOME')
  return (config and config ~= '' and config or vim.fs.normalize('~/.config')) .. '/mise/config.toml'
end

--- Environment variables for a child process.
function M.child_env(ctx, extra)
  local env = {
    XDG_CONFIG_HOME = ctx.xdg.config,
    XDG_DATA_HOME = ctx.xdg.data,
    XDG_STATE_HOME = ctx.xdg.state,
    XDG_CACHE_HOME = ctx.xdg.cache,
    PATH = table.concat({ ctx.bin_dir, M.repo_dir .. '/bin', os.getenv('PATH') }, ':'),
    MISE_TRUSTED_CONFIG_PATHS = M.mise_config(),
    E2E_CONTEXT = ctx.context_file,
    E2E_TRASH = ctx.trash_dir,
    GHQ_ROOT = ctx.run_dir .. '/ghq',
    NVIM_GUI = '',
    NVIM_APPNAME = '',
    NVIM = '',
    NVIM_LISTEN_ADDRESS = '',
    MYVIMRC = '',
    VIMINIT = '',
  }
  for k, v in pairs(extra or {}) do
    env[k] = v
  end
  return env
end

local function run(ctx, args, timeout_ms)
  local cmd = { ctx.nvim, '--headless', '-i', 'NONE' }
  vim.list_extend(cmd, args)
  local res = vim.system(cmd, { env = M.child_env(ctx), cwd = ctx.run_dir, text = true }):wait(timeout_ms or 120000)
  return res
end

--- $XDG_CONFIG_HOME/nvim mirrors this repo's nvim/ (not ~/.config/nvim, so
--- the working tree under test is what boots).
local function link_config(config_home)
  local nvim_dir = mkdir(config_home .. '/nvim')
  for name in vim.fs.dir(M.config_dir) do
    if name ~= 'tests' and name ~= '.DS_Store' then
      symlink(M.config_dir .. '/' .. name, nvim_dir .. '/' .. name)
    end
  end
end

--- lazy.nvim's root in $XDG_DATA_HOME is a link to the installed plugins (as
--- a whole: it takes only directories for installed plugins, not links).
local function link_plugins(data_home)
  symlink(M.find_plugins(), mkdir(data_home .. '/nvim') .. '/lazy')
end

--- Per-child XDG state/cache directories, so children never share plugin
--- state. (XDG_DATA_HOME stays per run: lazy.nvim's root is there.)
function M.child_dirs(ctx, id)
  local root = mkdir(vim.fs.joinpath(ctx.run_dir, 'children', id))
  return {
    XDG_STATE_HOME = mkdir(root .. '/state'),
    XDG_CACHE_HOME = mkdir(root .. '/cache'),
  }
end

--- Returns the context table that workers and children read back.
function M.prepare()
  local base = realpath(os.getenv('E2E_TMPDIR') or os.getenv('TMPDIR') or '/tmp')
  -- Sandboxes must not live inside a project: plugin/project_dir.vim takes the
  -- outermost-priority marker it finds walking up (an enclosing .git wins),
  -- and language servers would take that project as their root.
  local markers = { '.git', 'Rakefile', 'Gemfile', 'package.json', '.vimprojectroot', 'build.sbt' }
  local project = vim.fs.find(markers, { upward = true, path = base, limit = 1 })[1]
  if project then
    error(('the temporary directory %s is inside the project %s; set E2E_TMPDIR elsewhere'):format(base, vim.fs.dirname(project)))
  end
  local run_dir = mkdir(vim.fs.joinpath(base, ('nvim-e2e-%d-%d'):format(os.time(), uv.os_getpid())))

  local ctx = {
    run_dir = run_dir,
    nvim = vim.v.progpath,
    tests_dir = M.tests_dir,
    config_dir = M.config_dir,
    repo_dir = M.repo_dir,
    xdg = {
      config = mkdir(run_dir .. '/xdg/config'),
      data = mkdir(run_dir .. '/xdg/data'),
      state = mkdir(run_dir .. '/xdg/state'),
      cache = mkdir(run_dir .. '/xdg/cache'),
    },
    bin_dir = mkdir(run_dir .. '/bin'),
    trash_dir = mkdir(run_dir .. '/trash'),
    sandbox_dir = mkdir(run_dir .. '/sandbox'),
    context_file = run_dir .. '/context.json',
    fakes = {
      lsp = M.tests_dir .. '/fakes/lsp.lua',
      copilot = M.tests_dir .. '/fakes/copilot.lua',
    },
  }
  mkdir(run_dir .. '/ghq')
  -- Shared by the workers, which create their children's directories in them
  -- at the same time (mkdir -p fails when it loses that race).
  mkdir(run_dir .. '/children')
  mkdir(run_dir .. '/servers')
  link_config(ctx.xdg.config)
  link_plugins(ctx.xdg.data)

  -- Fake executables shadowing real ones.
  write_file(ctx.bin_dir .. '/trash', '#!/bin/sh\nfor f in "$@"; do mv -- "$f" "$E2E_TRASH/"; done\n', 493)
  write_file(
    ctx.bin_dir .. '/copilot-language-server',
    ('#!/bin/sh\nexec %s --clean -l %s "$@"\n'):format(vim.fn.shellescape(ctx.nvim), vim.fn.shellescape(ctx.fakes.copilot)),
    493
  )

  write_file(ctx.context_file, vim.json.encode(ctx))

  -- Boot once for the messages of a startup (the runner shows them).
  local messages_file = run_dir .. '/startup-messages.txt'
  local res = run(ctx, {
    '-c', ('call writefile(split(execute("messages"), "\\n"), %s)'):format(vim.fn.string(messages_file)),
    '-c', 'qa!',
  })
  if res.code ~= 0 then
    error('the config failed to boot: ' .. (res.stderr or ''))
  end
  ctx.startup_messages = read_file(messages_file) or ''

  write_file(ctx.context_file, vim.json.encode(ctx))
  return ctx
end

function M.load()
  local path = os.getenv('E2E_CONTEXT')
  if not path then
    error('E2E_CONTEXT is not set; run the suite through nvim/tests/run')
  end
  return vim.json.decode(assert(read_file(path)))
end

local sandbox_seq = 0

--- A fresh empty directory for one test.
function M.sandbox(ctx, name)
  sandbox_seq = sandbox_seq + 1
  local slug = (name or 'case'):gsub('[^%w]+', '-'):sub(1, 40)
  local dir = ('%s/%d-%d-%s'):format(ctx.sandbox_dir, uv.os_getpid(), sandbox_seq, slug)
  return mkdir(dir)
end

--- Deletes the run directory, unless `keep`.
function M.cleanup(ctx, keep)
  if not ctx then
    return
  end
  if not keep and ctx.run_dir and ctx.run_dir:match('nvim%-e2e%-%d') then
    vim.fn.delete(ctx.run_dir, 'rf')
  end
end

return M
