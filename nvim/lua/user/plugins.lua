-- Plugins, installed and loaded by lazy.nvim (:Lazy), each at the commit
-- nvim/flake.lock pins. Dependabot bumps the pins in pull requests; after
-- pulling one, `:Lazy update` checks out the new commits. A plugin added here
-- needs an input in nvim/flake.nix as well.
--
-- A plugin with an event, a command or keys loads on the first of them, the
-- others at startup. `init` runs at startup either way, `config` once the
-- plugin has loaded.

local M = {}

M.spec = {
  { -- a modern plugin manager for Neovim, which manages itself too
    'folke/lazy.nvim',
  },

  --  Editing
  -----------------------------------------------
  { -- create your own text objects
    'kana/vim-textobj-user',
  },

  { -- text objects for indented blocks of lines
    'kana/vim-textobj-indent',
    dependencies = { 'kana/vim-textobj-user' },
  },

  { -- deleting, changing, and adding surroundings
    'tpope/vim-surround',
  },

  { -- enable repeating supported plugin maps with dot
    'tpope/vim-repeat',
  },

  { -- pasting with indentation adjusted to paste destination
    'ku1ik/vim-pasta',
    init = function()
      vim.g.pasta_disabled_filetypes = {
        'python', 'markdown', 'yaml',
        'nerdtree', 'dirvish',
        'snacks_picker_list', 'snacks_picker_input',
      }
    end,
  },

  { -- a genius template engine
    'creasty/mold.vim',
    init = function()
      local group = vim.api.nvim_create_augroup('user_plugin_mold', {})
      vim.api.nvim_create_autocmd('User', {
        group = group,
        pattern = 'MoldTemplateLoadPre',
        command = 'call user#plugin#mold#before_load()',
      })
      vim.api.nvim_create_autocmd('User', {
        group = group,
        pattern = 'MoldTemplateLoadPost',
        command = 'call user#plugin#mold#after_load()',
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

  { -- sequencial numbering with pattern
    'deris/vim-rengbang',
    init = function()
      vim.g.rengbang_default_usefirst = 1
      vim.g.rengbang_default_pattern = [[\(\<\d\+\>\)]]
    end,
  },

  { -- operator to replace text with register content
    'kana/vim-operator-replace',
    dependencies = {
      'kana/vim-operator-user', -- define your own operator easily
    },
    keys = {
      { 'r', '<Plug>(operator-replace)', mode = { 'n', 'x', 'o' }, remap = true },
    },
    init = function()
      vim.keymap.set({ 'n', 'x', 'o' }, 'R', 'r')
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
      vim.fn['user#plugin#textmanip#init']()
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

  { -- Fully featured & enhanced replacement for copilot.vim complete with API for interacting with Github Copilot
    'zbirenbaum/copilot.lua',
    event = 'InsertEnter',
    cmd = 'Copilot',
    config = function()
      require('user.plugin.copilot').setup()
    end,
  },

  { -- The easiest way to create previewable commands in Neovim.
    'smjonas/live-command.nvim',
    event = 'CmdlineEnter',
    config = function()
      require('live-command').setup({
        commands = {
          Norm = { cmd = 'norm' },
          G = { cmd = 'g' },
          V = { cmd = 'v' },
        },
      })
    end,
  },

  { -- An all in one plugin for converting text case in Neovim
    'johmsalas/text-case.nvim',
    cmd = 'Subs',
    init = function()
      -- (require() loads the plugin)
      for lhs, method in pairs({
        ['ge_'] = 'to_snake_case',
        ['ge-'] = 'to_dash_case',
        ['ge.'] = 'to_dot_case',
        ['ge/'] = 'to_path_case',
        ['gec'] = 'to_camel_case',
        ['gep'] = 'to_pascal_case',
        ['gek'] = 'to_constant_case',
      }) do
        vim.keymap.set('n', lhs, function()
          require('textcase').operator(method)
        end, { silent = true })
        vim.keymap.set('x', lhs, function()
          require('textcase').visual(method)
        end, { silent = true })
      end
    end,
  },

  --  Treesitter
  -----------------------------------------------
  { -- Treesitter configurations and abstraction layer for Neovim
    'nvim-treesitter/nvim-treesitter',
    branch = 'master', -- `main` is an incompatible rewrite (no nvim-treesitter.configs, which opfmt also relies on)
    build = ':TSUpdate',
    config = function()
      require('user.plugin.treesitter')
    end,
  },

  { -- Show code context
    'nvim-treesitter/nvim-treesitter-context',
  },

  { -- A plugin for Neovim that helps you surf through your document and move elements around using the nvim-treesitter API.
    'ziontee113/syntax-tree-surfer',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    init = function()
      vim.fn['user#plugin#syntax_tree_surfer#init']()
    end,
  },

  { -- Use treesitter to autoclose and autorename html tag
    'windwp/nvim-ts-autotag',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
  },

  { -- Yet another tree-sitter powered indent plugin for Neovim
    'yioneko/nvim-yati',
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
  },

  --  UI
  -----------------------------------------------
  { -- toggle, display and navigate marks
    'kshenoy/vim-signature',
    init = function()
      vim.g.SignatureIncludeMarks = 'abcdefghijklmnopqrtuvwxyz'
      vim.g.SignatureMarkTextHL = 'Statement'
    end,
  },

  { -- a tree explorer
    'preservim/nerdtree',
    init = function()
      vim.g.NERDSpaceDelims = 1
      vim.g.NERDShutUp = 1
      vim.g.NERDTreeShowHidden = 1
      vim.g.NERDTreeIgnore = { [[\~$]], [[\.git$]] }
      vim.g.NERDTreeAutoDeleteBuffer = 1

      vim.g.loaded_nerdtree_fs_menu = 1
    end,
  },

  --  LSP, completion and snippets
  -----------------------------------------------
  { -- Quickstart configs for Nvim LSP
    'neovim/nvim-lspconfig',
    config = function()
      require('user.plugin.lsp').setup()
    end,
  },

  { -- Performant, batteries-included completion plugin for Neovim
    'saghen/blink.cmp',
    branch = 'v1', -- v2 requires Neovim 0.12
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
  { -- A collection of QoL plugins for Neovim (its picker)
    'folke/snacks.nvim',
    config = function()
      require('user.plugin.picker').setup()
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
      vim.fn['user#plugin#altr#lazy_init']()
    end,
  },

  { -- A Git wrapper so awesome, it should be illegal
    'tpope/vim-fugitive',
    cmd = { 'Git', 'GBrowse' },
    init = function()
      vim.cmd([[let g:fugitive_browse_handlers = [function('user#plugin#fugitive#browse_handler')] ]])
      vim.api.nvim_create_user_command('GBlame', 'Git blame', {})
    end,
  },

  --  Runner
  -----------------------------------------------
  { -- run commands quickly
    'thinca/vim-quickrun',
    init = function()
      vim.g.quickrun_config = {
        _ = {
          runner = 'nvim_job',
          ['outputter/buffer/split'] = ':botright 15sp',
        },
      }
      vim.keymap.set('n', '<Leader>r', '<Plug>(quickrun)', { remap = true })
    end,
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
