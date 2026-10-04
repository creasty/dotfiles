-- Filetype detection, per-filetype settings and ftplugin commands.
local t = require('t')
local describe, it = t.describe, t.it

describe('Filetypes', function()
  describe('detection', function()
    for name, filetype in pairs({
      ['.env'] = 'sh',
      ['.env.local'] = 'sh',
      ['shader.frag'] = 'glsl',
      ['shader.vert'] = 'glsl',
      ['.gitattributes'] = 'gitattributes',
      ['LICENSE'] = 'license',
      ['LICENSE.txt'] = 'license',
      ['user_spec.rb'] = 'ruby',
      ['query.bq.sql'] = 'sql.bq',
      ['query.pg.sql'] = 'sql.pg',
    }) do
      it(('%s is %s'):format(name, filetype), function()
        local nvim = t.nvim()
        nvim:edit('dir/' .. name)
        t.eq(filetype, nvim:filetype())
      end)
    end
  end)

  describe('settings', function()
    --- { expandtab, tabstop, effective shiftwidth }
    local function settings(nvim, name)
      nvim:edit(name)
      return nvim:eval('[&l:expandtab, &l:tabstop, shiftwidth()]')
    end

    it('indentation per filetype', function()
      local nvim = t.nvim()
      nvim:cmd('AutoSaveToggle')
      local expected = {
        ['a.go'] = { 0, 4, 4 },
        ['a.c'] = { 1, 4, 4 },
        ['A.java'] = { 1, 4, 4 },
        ['a.swift'] = { 1, 2, 4 },
        ['a.html'] = { 1, 2, 2 },
        ['a.js'] = { 1, 2, 2 },
        ['a.ts'] = { 1, 2, 2 },
        ['a.tsx'] = { 1, 2, 2 },
        ['a.rb'] = { 1, 2, 2 },
        ['a.py'] = { 1, 4, 4 },
        ['a.scala'] = { 1, 2, 2 },
      }
      local actual = {}
      for name in pairs(expected) do
        actual[name] = settings(nvim, name)
      end
      t.eq(expected, actual)
    end)

    it('ruby words include ! and ?; yaml words include -', function()
      local nvim = t.nvim()
      nvim:edit('a.rb', { 'valid? save!' })
      t.eq('valid?', nvim:call('expand', '<cword>'))
      nvim:edit('a.yml', { 'foo-bar: 1' })
      t.eq('foo-bar', nvim:call('expand', '<cword>'))
    end)

    it('yaml does not reindent a line when - starts it', function()
      local nvim = t.nvim()
      nvim:edit('a.yml')
      t.eq('!^F,o,O,0},0],<:>', nvim:eval('&l:indentkeys'))
    end)

    it('markdown folds by heading', function()
      local nvim = t.nvim()
      nvim:edit('a.md', { '# One', 'text', '## Two', 'more', 'Three', '=====', 'x' })
      t.eq('expr', nvim:eval('&l:foldmethod'))
      t.eq({ 1, 1, 2, 2, 1, 1, 1 }, nvim:lua([[
        local levels = {}
        for l = 1, vim.fn.line('$') do levels[l] = vim.fn.foldlevel(l) end
        return levels
      ]]))
    end)
  end)

  describe('ftplugin commands', function()
    it('javascriptreact :ReactAttrToExp turns attr="x" into attr={`x`}, in its buffer only', function()
      local nvim = t.nvim()
      nvim:edit('x.jsx', { '<div className="foo bar" />' })
      nvim:set_cursor(1, 17)
      nvim:cmd('ReactAttrToExp')
      t.eq({ '<div className={`foo bar`} />' }, nvim:lines())
      nvim:edit('x.txt')
      t.eq(0, nvim:call('exists', ':ReactAttrToExp'))
    end)
  end)
end)
