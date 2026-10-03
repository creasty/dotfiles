local t = require('t')
local probe = require('probe')
local describe, it = t.describe, t.it

describe('Startup', function()
  it('boots quietly: no messages or notification popups once services are up', function()
    local nvim = t.nvim()
    nvim:edit('main.go', { 'package main', '' })
    probe.wait_lsp(nvim)
    probe.wait_picker_ready(nvim)
    nvim:sleep(300)
    t.eq('', nvim:messages())
    t.eq({}, vim.tbl_map(function(f)
      return f.lines
    end, nvim:floats()))
  end, { timeout = 40000 })

  it('starts fast (min of 3 boots under the budget, with warm caches)', function()
    local budget = tonumber(os.getenv('E2E_STARTUP_BUDGET_MS')) or 150
    -- The boots share their caches (lazy.nvim's, and the byte code of the Lua
    -- modules), as your starts do: a first boot fills them.
    local caches = vim.fn.tempname()
    local function boot()
      local nvim = t.nvim({ env = { XDG_CACHE_HOME = caches .. '/cache', XDG_STATE_HOME = caches .. '/state' } })
      local ms = nvim.startup_ms
      nvim:close()
      return ms
    end
    boot()
    local best = math.huge
    for _ = 1, 3 do
      best = math.min(best, boot())
    end
    t.ok(best < budget, ('startup took %.0fms (budget %dms, set E2E_STARTUP_BUDGET_MS)'):format(best, budget))
  end)

  it('uses the candle colorscheme with 24-bit colors', function()
    local nvim = t.nvim()
    t.eq('candle', nvim:eval('g:colors_name'))
    t.eq(1, nvim:eval('&termguicolors'))
  end)

  it('uses "," as <Leader>', function()
    local nvim = t.nvim()
    t.eq(',', nvim:eval('g:mapleader'))
  end)

  it('keeps the editor options set in init.vim', function()
    local nvim = t.nvim()
    local expected = {
      writebackup = 0,
      swapfile = 0,
      autowrite = 1,
      modelines = 0,
      clipboard = 'unnamed',
      nrformats = 'alpha',
      suffixesadd = '.ts,.d.ts,.tsx',
      ignorecase = 1,
      smartcase = 1,
      wildignorecase = 1,
      cindent = 1,
      shiftround = 1,
      expandtab = 1,
      tabstop = 2,
      shiftwidth = 2,
      softtabstop = 0,
      whichwrap = 'b,s,h,l,<,>,[,]',
      virtualedit = 'block',
      splitright = 1,
      splitbelow = 1,
      splitkeep = 'screen',
      showmode = 0,
      laststatus = 3,
      showtabline = 2,
      number = 1,
      signcolumn = 'yes:2',
      colorcolumn = '90',
      showmatch = 1,
      list = 1,
      listchars = 'tab:──⏵,lead:·,trail:·,nbsp:∙,extends:❯,precedes:❮',
      breakindent = 1,
      showbreak = '↳',
      pumblend = 10,
      guicursor = 'n-c-sm:block-Cursor,i-ci-ve-t:ver25-Cursor,v-r-cr-o:hor20-Cursor',
      scrolloff = 5,
      updatetime = 200,
      foldmethod = 'indent',
      foldlevel = 20,
      foldlevelstart = 20,
      title = 1,
      titlestring = '%{UserTitleString()}',
    }
    local actual = {}
    for name in pairs(expected) do
      actual[name] = nvim:eval('&' .. name)
    end
    t.eq(expected, actual)
    -- Appended flags (the rest are Neovim defaults).
    t.match('l', nvim:eval('&formatoptions'))
    t.match('m', nvim:eval('&formatoptions'))
    t.match('%]', nvim:eval('&formatoptions'))
    t.match('I', nvim:eval('&shortmess'))
    t.match('uhex', nvim:eval('&display'))
    t.match('%*%.so', nvim:eval('&wildignore'))
    t.match('%*%.swp', nvim:eval('&wildignore'))
  end)

  it('disables the unused built-in plugins (netrw, zip, tar)', function()
    local nvim = t.nvim()
    for _, name in ipairs({ 'netrwPlugin', 'zipPlugin', 'tarPlugin' }) do
      t.eq(1, nvim:eval('get(g:, "loaded_' .. name .. '", 0)'), name)
    end
    t.eq(0, nvim:eval('exists(":Explore")'), ':Explore (netrw) should not exist')
  end)

  it('provides the user commands', function()
    local nvim = t.nvim()
    local commands = nvim:request('nvim_get_commands', {})
    for _, name in ipairs({
      -- init.vim
      'Encoding', 'SoftTab', 'HardTab', 'ProfStart', 'ProfStop', 'ProfOpen', 'Capture', 'CleanBuffers',
      -- user.plugins (lazy.nvim)
      'Lazy', 'LazyGotoRepo',
      -- plugin/
      'AutoSaveToggle', 'Rename', 'Delete', 'NextFile', 'PrevFile',
      -- user.cmdline, user.text_ops
      'Norm', 'G', 'V', 'Subs', 'RengBang',
      -- plugin configuration
      'Format', 'Import', 'Open', 'Search', 'GBlame', 'GBrowse',
      -- plugin commands used directly
      'DiffviewOpen', 'DiffviewFileHistory', 'Switch', 'Template',
    }) do
      t.ok(commands[name], (':%s is missing'):format(name))
    end
  end)
end)
