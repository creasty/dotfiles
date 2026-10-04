-- Plugins, installed and loaded by lazy.nvim (:Lazy), each at the commit
-- nvim/flake.lock pins. Dependabot bumps the pins in pull requests; after
-- pulling one, the next start checks out the new commits (M.sync). A plugin
-- added here needs an input in nvim/flake.nix as well.
--
-- A plugin with an event, a command or keys loads on the first of them, the
-- others at startup. `init` runs at startup either way, `config` once the
-- plugin has loaded.

local M = {}

M.spec = {
  { -- a modern plugin manager for Neovim, which manages itself too
    'folke/lazy.nvim',
    -- (before any plugin loads)
    init = function()
      M.sync()
    end,
  },

  --  Editing
  -----------------------------------------------
  { -- deleting, changing, and adding surroundings
    'tpope/vim-surround',
  },

  { -- enable repeating supported plugin maps with dot
    'tpope/vim-repeat',
  },

  { -- a genius template engine
    'creasty/mold.vim',
    init = function()
      local group = vim.api.nvim_create_augroup('user_plugin_mold', {})
      local cursor
      vim.api.nvim_create_autocmd('User', {
        group = group,
        pattern = 'MoldTemplateLoadPre',
        callback = function()
          cursor = vim.fn.getcurpos()
        end,
      })
      -- the template's macros replaced, its ERB run, and the cursor on
      -- <+CURSOR+>, or back where it was
      vim.api.nvim_create_autocmd('User', {
        group = group,
        pattern = 'MoldTemplateLoadPost',
        callback = function()
          local macros = {
            FILE_PATH = vim.fn.expand('%:p'),
            FILE_NAME = vim.fn.expand('%:t'),
            FILE_BASE_NAME = vim.fn.expand('%:t:r'),
            FULL_NAME = 'Yuki Iwanaga',
            USER_NAME = 'Creasty',
          }
          local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
          for i, line in ipairs(lines) do
            lines[i] = line:gsub('[%w_]+', macros)
          end
          vim.api.nvim_buf_set_lines(0, 0, -1, true, lines)
          vim.cmd([[silent! %!erb -T '-']])
          if vim.fn.search('<+CURSOR+>') > 0 then
            vim.cmd('normal! "_da>')
          else
            vim.fn.setpos('.', cursor)
          end
        end,
      })
    end,
  },

  { -- switch segments of text with predefined replacements
    'AndrewRadev/switch.vim',
    init = function()
      vim.g.switch_mapping = ''
      vim.keymap.set('n', '-', '<Cmd>Switch<CR>', { silent = true })
    end,
    config = function()
      vim.cmd([[
        let g:switch_custom_definitions = [
          \ switch#Words(['public', 'protected', 'private']),
          \ switch#Words(['and', 'or']),
          \ switch#Words(['if', 'unless']),
          \ switch#NormalizedCaseWords(['true', 'false']),
          \ switch#NormalizedCaseWords(['on', 'off']),
          \ switch#NormalizedCaseWords(['yes', 'no']),
        \ ]
      ]])
    end,
  },

  { -- a simple, easy-to-use Vim alignment plugin
    'junegunn/vim-easy-align',
    keys = {
      { 'L', '<Plug>(EasyAlign)', mode = 'x', remap = true, silent = true },
    },
  },

  { -- autopairs for neovim written in lua
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    config = function()
      require('user.plugin.autopairs').setup()
    end,
  },

  { -- maniplate selected text easily
    't9md/vim-textmanip',
    keys = vim.tbl_map(function(action)
      return { '<Plug>(textmanip-' .. action .. ')', mode = 'x' }
    end, {
      'move-down', 'move-up', 'move-left', 'move-right',
      'duplicate-down', 'duplicate-up', 'duplicate-left', 'duplicate-right',
    }),
    init = function()
      -- moved or duplicated characters (not lines) leave no whitespace at the
      -- ends of their lines (in Vim script: the plugin's helper takes its own
      -- state, which a Lua function gets a copy of)
      vim.cmd([[let g:textmanip_hooks = {'finish': {tm -> tm.linewise ? 0 : textmanip#helper#get().remove_trailing_WS(tm)}}]])

      -- in visual mode, m then h j k l moves the selection and H J K L
      -- duplicates it, as many times as typed
      vim.keymap.set('x', '<Plug>(user-textmanip)', '<Nop>')
      vim.keymap.set('x', 'm', '<Plug>(user-textmanip)', { remap = true })
      vim.keymap.set('x', '<Plug>(user-textmanip)m', '<Plug>(user-textmanip)', { remap = true })
      for key, action in pairs({
        j = 'move-down', k = 'move-up', h = 'move-left', l = 'move-right',
        J = 'duplicate-down', K = 'duplicate-up', H = 'duplicate-left', L = 'duplicate-right',
      }) do
        vim.keymap.set('x', '<Plug>(user-textmanip)' .. key, '<Plug>(textmanip-' .. action .. ')<Plug>(user-textmanip)', { remap = true })
      end
    end,
  },

  { -- Neovim motions on speed!
    'smoka7/hop.nvim',
    cmd = 'HopChar1',
    keys = {
      { 's', '<Cmd>HopChar1<CR>' },
    },
    config = function()
      require('hop').setup()
    end,
  },

  --  Treesitter
  -----------------------------------------------
  { -- Treesitter configurations and abstraction layer for Neovim
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    -- Installs and updates the parsers, in a Neovim of its own (see the file)
    build = ('%s --clean -l %s'):format(
      vim.fn.shellescape(vim.v.progpath),
      vim.fn.shellescape(vim.fn.stdpath('config') .. '/lua/user/plugin/treesitter/build.lua')
    ),
    config = function()
      require('user.plugin.treesitter')
    end,
  },

  { -- Show code context
    'nvim-treesitter/nvim-treesitter-context',
  },

  { -- Use treesitter to autoclose and autorename html tag
    'windwp/nvim-ts-autotag',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
  },

  { -- Wisely add "end" in Ruby, Vimscript, Lua, etc
    'RRethy/nvim-treesitter-endwise',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
  },

  { -- Format operators and delimiters as you type, using tree-sitter
    'creasty/opfmt',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    dev = true,
    cond = false, -- it needs nvim-treesitter's master branch (nvim-treesitter.configs): off until it moves to main
  },

  --  LSP, completion and snippets
  -----------------------------------------------
  { -- Quickstart configs for Nvim LSP
    'neovim/nvim-lspconfig',
    config = function()
      require('user.plugin.lsp').setup()
      require('user.plugin.copilot').setup()
    end,
  },

  { -- Performant, batteries-included completion plugin for Neovim
    'saghen/blink.cmp',
    branch = 'v1', -- v2, its main branch, has no release yet
    config = function()
      require('user.plugin.blink').setup()
    end,
  },

  { -- Snippet Engine for Neovim written in Lua
    'L3MON4D3/LuaSnip',
    config = function()
      require('user.plugin.luasnip').setup()
    end,
  },

  { -- Lightweight yet powerful formatter plugin for Neovim
    'stevearc/conform.nvim',
    config = function()
      require('user.plugin.format').setup()
    end,
  },

  { -- An asynchronous linter plugin for Neovim
    'mfussenegger/nvim-lint',
    config = function()
      require('user.plugin.lint').setup()
    end,
  },

  { -- Git integration for buffers
    'lewis6991/gitsigns.nvim',
    config = function()
      require('user.plugin.gitsigns').setup()
    end,
  },

  --  Picker
  -----------------------------------------------
  { -- A collection of QoL plugins for Neovim (its picker, explorer, gitbrowse and scope)
    'folke/snacks.nvim',
    config = function()
      require('snacks').setup({
        picker = require('user.plugin.picker').config,
        -- (the explorer, a picker, opens for a directory)
        explorer = { enabled = true },
        -- text objects for the lines of a scope, tree-sitter's (or the
        -- indentation's, without a parser): ii inside it, ai with its first and
        -- last lines; [i ]i jump to those
        scope = {
          enabled = true,
          keys = { textobject = { ii = { linewise = true }, ai = { linewise = true } } },
        },
      })
      require('user.plugin.picker').setup()
      require('user.plugin.gitbrowse').setup()
    end,
  },

  --  Navigation
  -----------------------------------------------
  { -- switch to the missing file without interaction
    'kana/vim-altr',
    keys = {
      { 'ga', '<Plug>(altr-forward)', remap = true },
      { 'gA', '<Plug>(altr-back)', remap = true },
    },
    config = function()
      local define = vim.fn['altr#define']
      -- header files
      define('%.c', '%.h', '%.m')
      -- Rails / Ruby
      define('app/models/%.rb', 'spec/models/%_spec.rb', 'spec/factories/%s.rb')
      define('app/%/%.rb', 'spec/%/%_spec.rb')
      define('lib/%.rb', 'spec/lib/%_spec.rb')
      define('Gemfile', 'Gemfile.lock')
      -- frontend
      define('%.js', '%.test.js', '%.jsx', '%.test.jsx', '%.stories.jsx')
      define('%.ts', '%.test.ts', '%.tsx', '%.test.tsx', '%.stories.tsx')
      -- Go
      define('%.go', '%_test.go', '%_mock.go', '%_ex_test.go')
      define('go.mod', 'go.sum')
      -- Docker
      define('docker-compose.yml', 'Dockerfile')
      -- config
      define('.env', '.env.sample', '.env.local', '.env.development', '.env.test')
      define('.env.%', '.env.%.local')
      define('default.properties', 'local.properties', 'test.properties')
      define('%.properties', '%.local.properties')
      -- TLA+
      define('%.tla', '%.cfg')
      -- translations, English and Japanese
      for _, file in ipairs({
        'locales/@.yml', 'locales/%.@.yml', 'locales/%/@.yml',
        'locales/@.json', 'locales/%.@.json', 'locales/%/@.json',
      }) do
        define((file:gsub('@', 'en')), (file:gsub('@', 'ja')))
      end
    end,
  },

  { -- Single tabpage interface for easily cycling through diffs for all modified files for any git rev
    'dlyongemallo/diffview-plus.nvim',
    cmd = { 'DiffviewOpen', 'DiffviewFileHistory' },
    config = function()
      local close = { 'n', 'q', '<Cmd>DiffviewClose<CR>', { desc = 'Close the view' } }
      require('diffview').setup({
        -- removed lines red on the old side too, rather than DiffAdd's green,
        -- and the lines a side lacks dim
        enhanced_diff_hl = true,
        keymaps = { view = { close }, file_panel = { close }, file_history_panel = { close } },
        hooks = {
          -- no fold column, which diffview opens (the folds stay)
          diff_buf_win_enter = function(_, winid)
            vim.wo[winid].foldcolumn = '0'
          end,
        },
      })
    end,
  },

  --  Terminal
  -----------------------------------------------
  { -- opens the files that a program in a terminal (user/terminal.lua) opens with nvim in this Neovim, rather than
    -- in another inside the terminal; git commit waits for its message's buffer to close
    'willothy/flatten.nvim',
    -- (before the other plugins, to hand the files over sooner)
    lazy = false,
    priority = 1001,
    opts = {
      -- in another window, keeping the terminal's
      window = { open = 'smart' },
    },
  },
}

--- lazy.nvim's options (nvim/tests/plugins.lua reads them too).
M.opts = {
  spec = M.spec,
  -- A plugin with `dev = true` (opfmt) loads from your working copy in ghq's
  -- root when there is one, and installs as usual otherwise.
  dev = {
    path = '~/go/src/github.com/creasty',
    fallback = true,
  },
  -- (only a record of what it installed: nvim/flake.lock pins the commits)
  lockfile = vim.fn.stdpath('state') .. '/lazy/lazy-lock.json',
}

--- Checks out the commits nvim/flake.lock pins where lazy.nvim recorded
--- others, as after pulling new pins: before the plugins load, since the
--- config may need the new ones. Otherwise it only reads that record, one
--- small file. Headless, as in scripts and the e2e suite, what is installed
--- stays.
function M.sync()
  if #vim.api.nvim_list_uis() == 0 then
    return
  end
  local ok, recorded = pcall(function()
    return vim.json.decode(table.concat(vim.fn.readfile(M.opts.lockfile), '\n'))
  end)
  if not ok then
    recorded = {}
  end
  local stale = {}
  for name, plugin in pairs(require('lazy.core.config').plugins) do
    if plugin.commit and plugin._.installed and not plugin._.is_local then
      -- (a plugin missing from the record is looked up in its checkout)
      local at = recorded[name] and recorded[name].commit
        or (require('lazy.manage.git').info(plugin.dir) or {}).commit
      if at ~= plugin.commit then
        stale[#stale + 1] = name
      end
    end
  end
  if #stale > 0 then
    require('lazy').update({ plugins = stale, wait = true })
  end
end

--- What a flake.lock pins, by plugin name (the end of the input's URL):
--- { url, branch, commit }.
function M.pins(lock_file)
  local lock = vim.json.decode(table.concat(vim.fn.readfile(lock_file), '\n'))
  local pins = {}
  for _, node in pairs(lock.nodes[lock.root].inputs) do
    local locked = lock.nodes[node].locked
    -- (git inputs have a URL, github: ones an owner and a repository)
    local url = locked.url or ('https://github.com/%s/%s'):format(locked.owner, locked.repo)
    pins[url:match('[^/]+$')] = {
      url = url,
      branch = locked.ref and (locked.ref:gsub('^refs/heads/', '')),
      commit = locked.rev,
    }
  end
  return pins
end

--- Sets the commit of each plugin of `spec`, dependencies included.
local function pin(spec, pins)
  for i, plugin in ipairs(spec) do
    if type(plugin) == 'string' then
      plugin = { plugin }
      spec[i] = plugin
    end
    local pinned = pins[plugin[1]:match('[^/]+$')]
    if pinned then
      plugin.commit = pinned.commit
    end
    pin(plugin.dependencies or {}, pins)
  end
end

--- Installs lazy.nvim when it is missing (it installs the plugins), and
--- loads the plugins.
function M.setup()
  local ok, pins = pcall(M.pins, vim.fn.stdpath('config') .. '/flake.lock')
  if not ok then
    vim.notify('The plugins are not pinned: ' .. pins, vim.log.levels.WARN)
    pins = {}
  end
  pin(M.spec, pins)

  local root = vim.fn.stdpath('data') .. '/lazy'
  local lazy = root .. '/lazy.nvim'
  if not vim.uv.fs_stat(lazy) then
    local out = vim.fn.system({ 'git', 'clone', '--filter=blob:none', 'https://github.com/folke/lazy.nvim.git', lazy })
    if vim.v.shell_error == 0 and pins['lazy.nvim'] then
      out = vim.fn.system({ 'git', '-C', lazy, 'checkout', '--quiet', pins['lazy.nvim'].commit })
    end
    if vim.v.shell_error ~= 0 then
      vim.fn.delete(lazy, 'rf')
      vim.api.nvim_echo({ { 'Failed to install lazy.nvim:\n', 'ErrorMsg' }, { out, 'WarningMsg' } }, true, {})
      return
    end
  end
  vim.opt.rtp:prepend(lazy)
  require('lazy').setup(M.opts)

  --- Plugin directories by name.
  local function plugin_dirs()
    local dirs = {}
    for _, plugin in ipairs(require('lazy').plugins()) do
      dirs[plugin.name] = plugin.dir
    end
    return dirs
  end

  -- The window's directory to a plugin's, or to where lazy.nvim installs them
  vim.api.nvim_create_user_command('LazyGotoRepo', function(opts)
    local dir = opts.args == '' and root or plugin_dirs()[opts.args]
    if not dir then
      return vim.notify(('No plugin named %s'):format(opts.args), vim.log.levels.ERROR)
    end
    vim.cmd.lcd(dir)
  end, {
    nargs = '?',
    complete = function(lead)
      local names = vim.tbl_filter(function(name)
        return name:find(lead, 1, true) ~= nil
      end, vim.tbl_keys(plugin_dirs()))
      table.sort(names)
      return names
    end,
    desc = 'Change the window directory to a plugin',
  })
end

return M
