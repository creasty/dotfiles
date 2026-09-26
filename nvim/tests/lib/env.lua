-- Builds the isolated environment every child Neovim boots in.
--
-- The children run the real config (this repo's nvim/ directory) exactly the
-- way `nvim` does, with XDG_CONFIG_HOME pointing at a tree of symlinks to it
-- (cached per working tree, see acquire_plugin_tree) and every other XDG
-- directory, coc's data and the sandboxes in a throwaway run directory. Tests
-- never touch your real state, shada, clipboard, Trash or caches. Installed
-- plugins are *linked*, never installed or updated.
--
-- This is the only file that knows about the plugin manager (dein) and the
-- plugins' on-disk layout. If you switch plugin managers, adapt prepare().

local M = {}

local uv = vim.uv

local function script_dir()
  return vim.fs.dirname(vim.fs.normalize(debug.getinfo(1, 'S').source:sub(2)))
end

M.lib_dir = script_dir()
M.tests_dir = vim.fs.dirname(M.lib_dir)
M.config_dir = vim.fs.dirname(M.tests_dir)
M.repo_dir = vim.fs.dirname(M.config_dir)

-- coc extensions linked into the test coc data home. Only deterministic ones:
-- no AI (tabnine), no network-backed language servers.
M.coc_extensions = { 'coc-snippets', 'coc-git' }

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

local function first_existing(candidates)
  for i = 1, candidates.n do
    local dir = candidates[i]
    if dir and dir ~= '' and uv.fs_stat(dir) then
      return realpath(dir)
    end
  end
end

function M.find_dein_repos()
  local found = first_existing(vim.F.pack_len(
    os.getenv('E2E_DEIN_REPOS'),
    M.config_dir .. '/dein/repos',
    vim.fs.normalize('~/.config/nvim/dein/repos')
  ))
  if found then
    return found
  end
  error('Cannot find installed dein plugins. Set E2E_DEIN_REPOS to the dein repos directory.')
end

function M.find_coc_extensions()
  return first_existing(vim.F.pack_len(
    os.getenv('E2E_COC_EXTENSIONS'),
    vim.fs.normalize('~/.config/coc/extensions/node_modules')
  ))
end

--- Environment variables for a child process.
function M.child_env(ctx, extra)
  local env = {
    XDG_CONFIG_HOME = ctx.xdg.config,
    XDG_DATA_HOME = ctx.xdg.data,
    XDG_STATE_HOME = ctx.xdg.state,
    XDG_CACHE_HOME = ctx.xdg.cache,
    PATH = table.concat({ ctx.bin_dir, M.repo_dir .. '/bin', os.getenv('PATH') }, ':'),
    E2E_CONTEXT = ctx.context_file,
    E2E_TRASH = ctx.trash_dir,
    GHQ_ROOT = ctx.run_dir .. '/ghq',
    -- Deno would otherwise follow XDG_CACHE_HOME into the per-run directory
    -- and re-download/compile the denops plugins on every run.
    DENO_DIR = ctx.deno_dir,
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

-- The plugin tree (XDG_CONFIG_HOME/nvim with dein's merged runtimepath)
-- lives at a stable, per-working-tree path so Deno's compile cache (keyed by
-- path) stays warm across runs. A lock keeps concurrent runs apart; a run
-- that cannot take it builds a throwaway tree instead.
local function acquire_plugin_tree(base, run_dir)
  local key = vim.fn.sha256(M.config_dir):sub(1, 12)
  local dir = vim.fs.joinpath(base, 'nvim-e2e-cache', key)
  vim.fn.mkdir(vim.fs.dirname(dir), 'p')
  local lock = dir .. '.lock'
  for _ = 1, 2 do
    if uv.fs_mkdir(lock, 448) then
      write_file(lock .. '/pid', tostring(uv.os_getpid()))
      return mkdir(dir), lock
    end
    local pid = tonumber(read_file(lock .. '/pid') or '')
    if pid and pid ~= uv.os_getpid() and uv.kill(pid, 0) == nil then
      -- Stale lock left by a run that died.
      vim.fn.delete(lock, 'rf')
    else
      break
    end
  end
  return mkdir(run_dir .. '/plugin-tree'), nil
end

--- Rebuilds the links in the plugin tree (keeping dein's caches).
local function link_config(config_home)
  local nvim_dir = mkdir(config_home .. '/nvim')
  for name in vim.fs.dir(nvim_dir) do
    if name ~= 'dein' then
      vim.fn.delete(nvim_dir .. '/' .. name)
    end
  end
  -- $XDG_CONFIG_HOME/nvim mirrors this repo's nvim/ (not ~/.config/nvim, so
  -- the working tree under test is what boots).
  for name in vim.fs.dir(M.config_dir) do
    if name ~= 'dein' and name ~= 'tests' and name ~= '.DS_Store' then
      symlink(M.config_dir .. '/' .. name, nvim_dir .. '/' .. name)
    end
  end
  -- dein: config from the repo, plugins from the real installation.
  local dein_dir = mkdir(nvim_dir .. '/dein')
  for name in vim.fs.dir(dein_dir) do
    if name ~= '.cache' then
      vim.fn.delete(dein_dir .. '/' .. name)
    end
  end
  for name in vim.fs.dir(M.config_dir .. '/dein') do
    if name:match('%.toml$') then
      symlink(M.config_dir .. '/dein/' .. name, dein_dir .. '/' .. name)
    end
  end
  symlink(M.find_dein_repos(), dein_dir .. '/repos')
end

--- Creates the run directory and warms the plugin manager cache.
--- Per-child XDG state/cache and coc data directories, so children never
--- share plugin state. (XDG_DATA_HOME stays per run: its site directory is
--- on the runtimepath, which dein's state cache must see unchanged.)
function M.child_dirs(ctx, id)
  local root = mkdir(vim.fs.joinpath(ctx.run_dir, 'children', id))
  local coc = mkdir(root .. '/coc')
  local ext_dir = mkdir(coc .. '/extensions/node_modules')
  local shared = ctx.coc_data_home .. '/extensions'
  for _, name in ipairs(ctx.coc_extensions) do
    symlink(shared .. '/node_modules/' .. name, ext_dir .. '/' .. name)
  end
  write_file(coc .. '/extensions/package.json', read_file(shared .. '/package.json') or '{}')
  return {
    XDG_STATE_HOME = mkdir(root .. '/state'),
    XDG_CACHE_HOME = mkdir(root .. '/cache'),
    E2E_COC_DATA_HOME = coc,
  }
end

--- Returns the context table that workers and children read back.
function M.prepare()
  local base = realpath(os.getenv('E2E_TMPDIR') or os.getenv('TMPDIR') or '/tmp')
  local run_dir = mkdir(vim.fs.joinpath(base, ('nvim-e2e-%d-%d'):format(os.time(), uv.os_getpid())))
  local tree, lock = acquire_plugin_tree(base, run_dir)

  local ctx = {
    run_dir = run_dir,
    plugin_tree = tree,
    lock = lock,
    nvim = vim.v.progpath,
    tests_dir = M.tests_dir,
    config_dir = M.config_dir,
    repo_dir = M.repo_dir,
    xdg = {
      config = mkdir(tree .. '/config'),
      data = mkdir(run_dir .. '/xdg/data'),
      state = mkdir(run_dir .. '/xdg/state'),
      cache = mkdir(run_dir .. '/xdg/cache'),
    },
    coc_data_home = mkdir(run_dir .. '/coc'),
    deno_dir = mkdir(tree .. '/deno'),
    bin_dir = mkdir(run_dir .. '/bin'),
    trash_dir = mkdir(run_dir .. '/trash'),
    sandbox_dir = mkdir(run_dir .. '/sandbox'),
    context_file = run_dir .. '/context.json',
    fakes = {
      lsp = M.tests_dir .. '/fakes/lsp.lua',
      copilot = M.tests_dir .. '/fakes/copilot.lua',
    },
    coc_extensions = {},
  }
  mkdir(run_dir .. '/ghq')
  link_config(ctx.xdg.config)

  -- coc data home (per run) with a curated, deterministic set of extensions.
  local coc_src = M.find_coc_extensions()
  local ext_dir = mkdir(ctx.coc_data_home .. '/extensions/node_modules')
  local deps = {}
  if coc_src then
    for _, name in ipairs(M.coc_extensions) do
      if uv.fs_stat(coc_src .. '/' .. name) then
        symlink(coc_src .. '/' .. name, ext_dir .. '/' .. name)
        deps[name] = '*'
        table.insert(ctx.coc_extensions, name)
      end
    end
  end
  write_file(
    ctx.coc_data_home .. '/extensions/package.json',
    vim.json.encode({ dependencies = next(deps) and deps or vim.empty_dict(), disabled = {}, locked = {}, lastUpdate = os.time() * 1000 })
  )

  -- Fake executables shadowing real ones.
  write_file(ctx.bin_dir .. '/trash', '#!/bin/sh\nfor f in "$@"; do mv -- "$f" "$E2E_TRASH/"; done\n', 493)

  write_file(ctx.context_file, vim.json.encode(ctx))

  -- Warm up: build dein's merged runtimepath, then generate its state cache.
  local res = run(ctx, { '--cmd', 'let g:coc_start_at_startup = 0', '-c', 'call dein#recache_runtimepath() | call dein#clear_state()', '-c', 'qa!' })
  if res.code ~= 0 then
    error('warm-up failed (recache): ' .. (res.stderr or ''))
  end
  local messages_file = run_dir .. '/startup-messages.txt'
  res = run(ctx, {
    '--cmd', 'let g:coc_start_at_startup = 0',
    '-c', ('call writefile(split(execute("messages"), "\\n"), %s)'):format(vim.fn.string(messages_file)),
    '-c', 'qa!',
  })
  if res.code ~= 0 then
    error('warm-up failed (boot): ' .. (res.stderr or ''))
  end
  ctx.startup_messages = read_file(messages_file) or ''

  -- Resolve the Python host once (the same interpreter Neovim would detect);
  -- detection on every child's first insert-mode keystroke costs ~300ms.
  local python_file = run_dir .. '/python3-host.txt'
  run(ctx, {
    '--cmd', 'let g:coc_start_at_startup = 0',
    '-c', ('lua vim.fn.writefile({ vim.g.python3_host_prog or require("vim.provider.python").detect_by_module("neovim") or "" }, %q)'):format(python_file),
    '-c', 'qa!',
  })
  ctx.python3_host_prog = vim.trim(read_file(python_file) or '')

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

--- Releases the plugin tree lock; with `keep` the run directory stays.
function M.cleanup(ctx, keep)
  if not ctx then
    return
  end
  if ctx.lock then
    vim.fn.delete(ctx.lock, 'rf')
  end
  if not keep and ctx.run_dir and ctx.run_dir:match('nvim%-e2e%-%d') then
    vim.fn.delete(ctx.run_dir, 'rf')
  end
end

return M
