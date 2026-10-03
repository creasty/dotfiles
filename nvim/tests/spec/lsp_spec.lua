-- Language server workflows (Neovim's LSP client today) against fakes/lsp.lua.
-- See the header of that file for the fake's (deterministic) semantics.
local t = require('t')
local probe = require('probe')
local describe, it = t.describe, t.it

local GO = {
  ['.git/'] = true,
  ['main.go'] = {
    'package main', -- 1
    '', -- 2
    'type Config struct {', -- 3
    '	Name string', -- 4
    '}', -- 5
    '', -- 6
    'func load() Config {', -- 7
    '	return Config{}', -- 8
    '}', -- 9
    '', -- 10
    'func main() {', -- 11
    '	var cfg Config = load()', -- 12
    '	println(cfg.Name, load())', -- 13
    '}', -- 14
  },
  ['util.go'] = {
    'package main', -- 1
    '', -- 2
    'func name() string {', -- 3
    '	return load().Name', -- 4
    '}', -- 5
  },
}

local TS = {
  ['.git/'] = true,
  ['app.ts'] = {
    'import { z } from "z";', -- 1
    'import { a } from "a";', -- 2
    '', -- 3
    'interface Store {}', -- 4
    'class FileStore implements Store {}', -- 5
    '', -- 6
    'function helper(first: number, second: number) {', -- 7
    '  return first;  // WARNING', -- 8
    '}', -- 9
    '', -- 10
    'const x  =  helper(1, 2);  // ERROR', -- 11
    'const longValue = x;', -- 12
    'helper(x, x);  // INFO HINT', -- 13
  },
}

local function project(files, open, opts)
  local nvim = t.nvim(opts)
  nvim:files(files)
  nvim:edit(open)
  probe.wait_lsp(nvim)
  return nvim
end

--- The character of one side of a float's border (as nvim_win_get_config
--- gives it: a string, or a character with its highlight).
local function border_char(side)
  return type(side) == 'table' and side[1] or side
end

--- Where the cursor is on the screen.
local function cursor_on_screen(nvim)
  return nvim:lua([[
    local pos = vim.fn.screenpos(0, vim.fn.line('.'), vim.fn.col('.'))
    return { row = pos.row, col = pos.col }
  ]])
end

local function picker_project(files, open)
  local nvim = project(files, open)
  probe.wait_picker_ready(nvim)
  return nvim
end

describe('LSP', function()
  describe('navigation', function()
    it('gd jumps to the definition', function()
      local nvim = project(GO, 'main.go')
      nvim:set_cursor(12, 19)
      nvim:type('gd')
      nvim:wait_for(function()
        return nvim:cursor()[1] == 7
      end)
      t.eq({ 7, 5 }, nvim:cursor())
    end)

    it('<C-]> jumps to the definition, as the server gives it', function()
      local nvim = project(GO, 'main.go')
      nvim:set_cursor(12, 19)
      nvim:type('<C-]>')
      nvim:wait_for(function()
        return nvim:cursor()[1] == 7
      end)
      t.eq({ 7, 5 }, nvim:cursor())
    end)

    it('gd jumps into another file', function()
      local nvim = project(GO, 'util.go')
      nvim:set_cursor(4, 8)
      nvim:type('gd')
      nvim:wait_for(function()
        return nvim:call('expand', '%:t') == 'main.go'
      end)
      t.eq({ 7, 5 }, nvim:cursor())
    end)

    it('grt jumps to the type definition', function()
      local nvim = project(GO, 'main.go')
      nvim:set_cursor(13, 9)
      nvim:type('grt')
      nvim:wait_for(function()
        return nvim:cursor()[1] == 3
      end)
      t.eq({ 3, 5 }, nvim:cursor())
    end)

    it('gri jumps to the implementation', function()
      local nvim = project(TS, 'app.ts')
      nvim:set_cursor(4, 10)
      nvim:type('gri')
      nvim:wait_for(function()
        return nvim:cursor()[1] == 5
      end)
      t.eq({ 5, 6 }, nvim:cursor())
    end)

    it('grr lists references (without the declaration) in the picker; <CR> jumps', function()
      local nvim = picker_project(GO, 'main.go')
      nvim:set_cursor(7, 6)
      nvim:type('grr')
      local picker = probe.wait_picker(nvim, function(p)
        return #p.items == 3
      end)
      t.ok(picker.floating, 'floating picker')
      t.eq({ 'main.go 12:19 |\tvar cfg Config = load()', 'main.go 13:20 |\tprintln(cfg.Name, load())', 'util.go 4:9 |\treturn load().Name' }, picker.items)
      nvim:type('jj<CR>')
      probe.wait_picker_closed(nvim)
      t.eq('util.go', nvim:call('expand', '%:t'))
      t.eq({ 4, 8 }, nvim:cursor())
    end, { timeout = 40000 })

    it('gll reopens the last location list, then keeps your place to step through it', function()
      local nvim = picker_project(GO, 'main.go')
      nvim:set_cursor(7, 6)
      nvim:type('grr')
      probe.wait_picker(nvim, function(p)
        return #p.items == 3
      end)
      nvim:type('<CR>')
      probe.wait_picker_closed(nvim)
      t.eq({ 12, 18 }, nvim:cursor())
      -- Like a person: look at the list, move, check, then open.
      local function step(expected_current, next_item)
        nvim:type('gll')
        probe.wait_picker(nvim, function(p)
          return #p.items == 3 and p.current == expected_current
        end)
        nvim:type('j')
        probe.wait_picker(nvim, function(p)
          return p.current == next_item
        end)
        nvim:type('<CR>')
        probe.wait_picker_closed(nvim)
      end
      step('main.go 12:19 |\tvar cfg Config = load()', 'main.go 13:20 |\tprintln(cfg.Name, load())')
      t.eq({ 13, 19 }, nvim:cursor())
      -- The cursor is restored right after the items are drawn.
      step('main.go 13:20 |\tprintln(cfg.Name, load())', 'util.go 4:9 |\treturn load().Name')
      t.eq('util.go', nvim:call('expand', '%:t'))
    end, { timeout = 40000 })

    it('the first gll reopens at the item you opened', function()
      local nvim = picker_project(GO, 'main.go')
      nvim:set_cursor(7, 6)
      nvim:type('grr')
      probe.wait_picker(nvim, function(p)
        return #p.items == 3
      end)
      nvim:type('jj<CR>')
      probe.wait_picker_closed(nvim)
      nvim:type('gll')
      probe.wait_picker(nvim, function(p)
        return #p.items == 3 and p.current == 'util.go 4:9 |\treturn load().Name'
      end)
    end, { timeout = 40000 })

    it('gD shows the definition in the picker without jumping', function()
      local nvim = picker_project(GO, 'main.go')
      nvim:set_cursor(12, 19)
      nvim:type('gD')
      probe.wait_picker(nvim, function(p)
        return vim.deep_equal(p.items, { 'main.go 7:6 |func load() Config {' })
      end)
      nvim:type('<Esc>')
      probe.wait_picker_closed(nvim)
      t.eq({ 12, 19 }, nvim:cursor())
    end, { timeout = 40000 })
  end)

  describe('hover', function()
    it('gh shows the documentation in a float', function()
      local nvim = project(GO, 'main.go')
      nvim:set_cursor(12, 6)
      nvim:type('gh')
      local text = nvim:wait_for(function()
        for _, f in ipairs(nvim:floats()) do
          for _, line in ipairs(f.lines) do
            if line:find('e2e hover', 1, true) then
              return line
            end
          end
        end
      end)
      t.eq('cfg: e2e hover', text)
    end)

    it('gh renders the documentation as markdown, with a column of padding on each side', function()
      local nvim = project(GO, 'main.go')
      nvim:set_cursor(12, 6)
      nvim:type('gh')
      local float = nvim:wait_for(function()
        for _, f in ipairs(nvim:floats()) do
          if vim.tbl_contains(f.lines, 'cfg: e2e hover') then
            return f
          end
        end
      end)
      local screen = nvim:wait_for(function()
        local s = table.concat(nvim:screen(), '\n')
        return s:find('cfg: e2e hover', 1, true) and s
      end)
      t.no_match('```', screen, 'the code fence is hidden')
      t.eq({ ' ', ' ' }, { border_char(float.border[8]), border_char(float.border[4]) })
    end)

    it('<C-f> / <C-b> scroll a long hover, and page the buffer otherwise', function()
      local nvim = project(TS, 'app.ts')
      nvim:set_cursor(12, 8)
      nvim:type('gh')
      local function hover_topline()
        return nvim:lua([[
          for _, w in ipairs(vim.api.nvim_list_wins()) do
            local c = vim.api.nvim_win_get_config(w)
            local lines = vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(w), 0, -1, false)
            if c.relative ~= '' and #lines > 50 then
              return vim.fn.getwininfo(w)[1].topline
            end
          end
        ]])
      end
      nvim:wait_for(hover_topline)
      t.eq(1, hover_topline())
      nvim:type('<C-f>')
      nvim:wait_for(function()
        return (hover_topline() or 1) > 1
      end)
      t.eq({ 12, 8 }, nvim:cursor(), 'the cursor stays put')
      nvim:type('<C-b>')
      nvim:wait_for(function()
        return hover_topline() == 1
      end)
    end)
  end)

  it('<C-f> / <C-b> page the buffer when no float is open', function()
    local lines = {}
    for i = 1, 200 do
      lines[i] = 'line ' .. i
    end
    local nvim = t.nvim()
    nvim:edit('a.txt', lines)
    nvim:type('<C-f>')
    t.ok(nvim:call('line', 'w0') > 1, 'paged down')
    nvim:type('<C-b>')
    t.eq(1, nvim:call('line', 'w0'))
  end)

  describe('editing', function()
    it('grn renames the symbol everywhere through a prompt', function()
      local nvim = project(GO, 'main.go')
      nvim:set_cursor(7, 6)
      nvim:type('grn')
      probe.wait_input_prompt(nvim)
      nvim:type('<C-u>read<CR>')
      nvim:wait_for(function()
        return nvim:line(7) == 'func read() Config {'
      end)
      t.eq('\tvar cfg Config = read()', nvim:line(12))
      -- The other file is loaded into a hidden buffer and edited a moment later.
      nvim:wait_for(function()
        return nvim:lua([[
          local buf = vim.fn.bufnr('util.go')
          return buf > 0 and vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_buf_get_lines(buf, 3, 4, false)[1] or nil
        ]]) == '\treturn read().Name'
      end, { message = 'the rename to reach util.go' })
      nvim:cmd('wall')
      t.eq('\treturn read().Name', nvim:read_file('util.go')[4])
    end)

    it('gra applies a code action for the cursor', function()
      local nvim = project(TS, 'app.ts')
      nvim:set_cursor(7, 10)
      nvim:type('gra')
      probe.choose(nvim, 'e2e: uppercase')
      nvim:wait_for(function()
        return nvim:line(7):find('HELPER', 1, true)
      end)
      t.eq('function HELPER(first: number, second: number) {', nvim:line(7))
    end)

    it('gra lists the code actions just below the cursor', function()
      local nvim = project(TS, 'app.ts')
      nvim:set_cursor(7, 10)
      local cursor = cursor_on_screen(nvim)
      nvim:type('gra')
      probe.wait_choice_menu(nvim)
      local box = probe.picker_box(nvim)
      t.eq({ row = cursor.row + 1, col = cursor.col }, { row = box.row, col = box.col })
    end)

    it('gra lists them just above the cursor when there is no room below', function()
      local lines = {}
      for i = 1, 100 do
        lines[i] = ('const value%d = helper(%d);'):format(i, i)
      end
      local nvim = project({ ['.git/'] = true, ['long.ts'] = lines }, 'long.ts')
      nvim:type('Gw')
      local cursor = cursor_on_screen(nvim)
      nvim:type('gra')
      probe.wait_choice_menu(nvim)
      local box = probe.picker_box(nvim)
      t.eq({ last_row = cursor.row - 1, col = cursor.col }, { last_row = box.last_row, col = box.col })
    end)

    it('the list of code actions stays by the line when the screen is resized', function()
      local nvim = project(TS, 'app.ts')
      nvim:set_cursor(7, 10)
      nvim:type('gra')
      probe.wait_choice_menu(nvim)
      local box = probe.picker_box(nvim)
      nvim:type('upper')
      nvim:cmd('set columns=100')
      nvim:sleep(100)
      t.eq(box, probe.picker_box(nvim))
    end)

    it('<C-j> confirms the highlighted entry of a choice menu', function()
      local nvim = project(TS, 'app.ts')
      nvim:set_cursor(7, 10)
      nvim:type('gra')
      nvim:wait_for(function()
        for _, f in ipairs(nvim:floats()) do
          if table.concat(f.lines, '\n'):find('e2e: uppercase', 1, true) then
            return true
          end
        end
      end)
      probe.wait_choice_menu(nvim)
      nvim:type('<C-j>')
      nvim:wait_for(function()
        return nvim:line(7):find('HELPER', 1, true)
      end)
    end)

    it('visual gra applies a code action for the selection', function()
      local nvim = project(TS, 'app.ts')
      nvim:set_cursor(12, 6)
      nvim:type('vlll')
      nvim:type('gra')
      probe.choose(nvim, 'e2e: uppercase')
      nvim:wait_for(function()
        return nvim:line(12):find('LONGValue', 1, true)
      end)
      t.eq('const LONGValue = x;', nvim:line(12))
    end)

    it(':Format formats the buffer; :\'<,\'>Format only the selection', function()
      local nvim = project(TS, 'app.ts')
      nvim:type('11GV:Format<CR>')
      nvim:wait_for(function()
        return nvim:line(11) == 'const x = helper(1, 2); // ERROR'
      end)
      t.eq('  return first;  // WARNING', nvim:line(8), 'outside the range is untouched')
      nvim:cmd('Format')
      nvim:wait_for(function()
        return nvim:line(8) == '  return first; // WARNING'
      end)
    end)

    it(':Import organizes imports', function()
      local nvim = project(TS, 'app.ts')
      nvim:cmd('Import')
      nvim:wait_for(function()
        return nvim:line(1) == 'import { a } from "a";'
      end)
      t.eq('import { z } from "z";', nvim:line(2))
    end)

    it('Go files are formatted when the editor loses focus', function()
      local nvim = project({ ['.git/'] = true, ['main.go'] = { 'package main', '', 'var x  =  1' } }, 'main.go')
      nvim:cmd('doautocmd FocusLost')
      nvim:wait_for(function()
        return nvim:line(3) == 'var x = 1'
      end)
    end)

    it('...but not while you are typing', function()
      local nvim = project({ ['.git/'] = true, ['main.go'] = { 'package main', '', 'var x  =  1' } }, 'main.go')
      nvim:type('A')
      nvim:cmd('doautocmd FocusLost')
      nvim:sleep(500)
      t.eq('var x  =  1', nvim:line(3))
    end)

    it('leaving a Go buffer formats it', function()
      local nvim = project({
        ['.git/'] = true,
        ['a.go'] = { 'package main', '', 'var a  =  1' },
        ['b.go'] = { 'package main', '', 'var b  =  2' },
      }, 'b.go')
      nvim:cmd('edit a.go')
      probe.wait_lsp(nvim)
      nvim:wait_for(function()
        return nvim:call('getbufline', 'b.go', 3)[1] == 'var b = 2'
      end, { message = 'b.go to be formatted when left' })
      t.eq('var a  =  1', nvim:line(3), 'the buffer you switch to is not formatted')
      nvim:cmd('edit b.go')
      nvim:wait_for(function()
        return nvim:call('getbufline', 'a.go', 3)[1] == 'var a = 1'
      end, { message = 'a.go to be formatted when left' })
    end)

    it('other filetypes are not formatted on focus loss', function()
      local nvim = project(TS, 'app.ts')
      nvim:cmd('doautocmd FocusLost')
      nvim:sleep(500)
      t.eq('const x  =  helper(1, 2);  // ERROR', nvim:line(11))
    end)
  end)

  describe('diagnostics', function()
    it('are shown with ✕ ∆ □ * signs, without virtual text', function()
      local nvim = project(TS, 'app.ts')
      nvim:wait_for(function()
        return #probe.signs(nvim, 11) > 0
      end)
      t.contains(probe.signs(nvim, 11), '✕')
      t.contains(probe.signs(nvim, 8), '∆')
      local line13 = probe.signs(nvim, 13)
      t.ok(vim.tbl_contains(line13, '□') or vim.tbl_contains(line13, '*'), 'info/hint sign on line 13: ' .. vim.inspect(line13))
      local virt = nvim:lua([[
        local n = 0
        for _, m in ipairs(vim.api.nvim_buf_get_extmarks(0, -1, 0, -1, { details = true })) do
          for _, chunk in ipairs(m[4].virt_text or {}) do
            if chunk[1]:find('e2e') then n = n + 1 end
          end
        end
        return n
      ]])
      t.eq(0, virt, 'no diagnostic virtual text')
    end)

    it('are counted in the statusline', function()
      local nvim = project(TS, 'app.ts')
      nvim:wait_for(function()
        return probe.diagnostics(nvim).error > 0
      end)
      local stl = nvim:statusline()
      t.contains(stl, '✕ 1')
      t.contains(stl, '∆ 1')
      t.contains(stl, '□ 1')
      t.contains(stl, '* 1')
    end)

    it(']d / [d go to the next / previous diagnostic, ]e / [e to errors only', function()
      local nvim = project(TS, 'app.ts')
      nvim:wait_for(function()
        return probe.diagnostics(nvim).error > 0
      end)
      nvim:set_cursor(1, 0)
      nvim:type(']d')
      nvim:wait_for(function()
        return nvim:cursor()[1] == 8
      end)
      nvim:type(']d')
      nvim:wait_for(function()
        return nvim:cursor()[1] == 11
      end)
      nvim:type('[d')
      nvim:wait_for(function()
        return nvim:cursor()[1] == 8
      end)
      nvim:set_cursor(1, 0)
      nvim:type(']e')
      nvim:wait_for(function()
        return nvim:cursor()[1] == 11
      end)
      nvim:set_cursor(13, 0)
      nvim:type('[e')
      nvim:wait_for(function()
        return nvim:cursor()[1] == 11
      end)
    end)

    it('the diagnostics list opens in normal mode; <C-j> jumps to the entry', function()
      local nvim = project(TS, 'app.ts')
      nvim:wait_for(function()
        return probe.diagnostics(nvim).error > 0
      end)
      nvim:cmd('Diagnostics')
      local picker = probe.wait_picker(nvim, function(p)
        return table.concat(p.items, '\n'):find('e2e error', 1, true)
      end)
      t.eq('list', picker.focus)
      t.eq('n', nvim:mode())
      t.contains(table.concat(picker.items, '\n'), 'e2e warning')
      nvim:type('<C-j>')
      probe.wait_picker_closed(nvim)
      nvim:wait_for(function()
        return nvim:filetype() == 'typescript'
      end)
      t.ok(vim.tbl_contains({ 8, 11, 13 }, nvim:cursor()[1]))
    end)

    it('resting on a diagnostic shows its message in a float, with a column of padding on each side', function()
      local nvim = project(TS, 'app.ts')
      nvim:wait_for(function()
        return probe.diagnostics(nvim).error > 0
      end)
      nvim:set_cursor(1, 0)
      nvim:type(']e')
      local float = nvim:wait_for(function()
        for _, f in ipairs(nvim:floats()) do
          if table.concat(f.lines, '\n'):find('e2e error', 1, true) then
            return f
          end
        end
      end)
      t.eq({ ' ', ' ' }, { border_char(float.border[8]), border_char(float.border[4]) })
    end)
  end)

  describe('assistance', function()
    it('highlights other occurrences of the symbol under the cursor after a pause', function()
      local nvim = project(GO, 'main.go')
      nvim:type('12G0f(h')
      local positions = nvim:wait_for(function()
        local p = probe.reference_highlights(nvim)
        return #p > 0 and p
      end)
      t.eq({ { 7, 6 }, { 12, 19 }, { 13, 20 } }, positions)
    end)

    it('<C-s><C-s> shows the signature help in insert mode', function()
      local nvim = project(TS, 'app.ts')
      nvim:type('Go')
      nvim:type('helper(1, ')
      nvim:type('<C-s><C-s>')
      nvim:wait_for(function()
        for _, f in ipairs(nvim:floats()) do
          if table.concat(f.lines, '\n'):find('helper(first, second)', 1, true) then
            return true
          end
        end
      end)
      t.eq('i', nvim:mode())
    end)
  end)

  describe('TypeScript', function()
    -- TypeScript 7 is its own language server (`tsc --lsp`), and no longer
    -- ships the tsserver.js typescript-language-server (ts_ls) runs.
    local function ts_project(files)
      local nvim = t.nvim()
      nvim:files(vim.tbl_extend('force', { ['package-lock.json'] = { '{}' } }, files))
      return nvim
    end

    --- Whether the server would start for the current buffer.
    local function starts(nvim, name)
      return nvim:lua(
        [[
          local started = false
          vim.lsp.config[...].root_dir(0, function()
            started = true
          end)
          return started
        ]],
        name
      )
    end

    it('a project on TypeScript 7 gets its tsc, not ts_ls', function()
      local nvim = ts_project({ ['node_modules/.bin/tsc'] = { '#!/bin/sh', 'echo "Version 7.0.2"' } })
      vim.uv.fs_chmod(nvim:path('node_modules/.bin/tsc'), tonumber('755', 8))
      nvim:edit('app.ts', { '' })
      t.ok(starts(nvim, 'tsc'), 'tsc starts')
      t.no(starts(nvim, 'ts_ls'), 'ts_ls does not')
    end)

    it('a project on an older TypeScript gets ts_ls, not tsc', function()
      local nvim = ts_project({ ['node_modules/typescript/lib/tsserver.js'] = { '' } })
      nvim:edit('app.ts', { '' })
      t.ok(starts(nvim, 'ts_ls'), 'ts_ls starts')
      t.no(starts(nvim, 'tsc'), 'tsc does not')
    end)
  end)

  describe('spell checking', function()
    it('reports misspellings as hints', function()
      local nvim = t.nvim()
      t.eq('hint', nvim:lua('return vim.lsp.config.codebook.init_options.diagnosticSeverity'))
    end)
  end)
end)
