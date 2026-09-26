-- Text operators and objects.
local t = require('t')
local describe, it = t.describe, t.it

local function nvim_ft(filetype)
  local nvim = t.nvim()
  if filetype then
    nvim:cmd('setfiletype ' .. filetype)
  end
  return nvim
end

describe('Text operations', function()
  describe('surround', function()
    it('ysiw" / cs"\' / ds( add, change and delete surroundings', function()
      local nvim = t.nvim()
      nvim:set_buffer('say |hello (there)')
      nvim:type('ysiw"')
      t.eq({ 'say "hello" (there)' }, nvim:lines())
      nvim:type("cs\"'")
      t.eq({ "say 'hello' (there)" }, nvim:lines())
      nvim:type('f(ds(')
      t.eq({ "say 'hello' there" }, nvim:lines())
    end)

    it('visual S surrounds the selection', function()
      local nvim = t.nvim()
      nvim:set_buffer('|word')
      nvim:type('veS)')
      t.eq({ '(word)' }, nvim:lines())
    end)

    it('. repeats a surround change', function()
      local nvim = t.nvim()
      nvim:set_buffer({ '|"a"', '"b"' })
      nvim:type("cs\"'")
      nvim:type('j.')
      t.eq({ "'a'", "'b'" }, nvim:lines())
    end)
  end)

  describe('indent text object', function()
    it('ii / ai select the lines of the current indentation block', function()
      local nvim = t.nvim()
      nvim:set_buffer({ 'def x', '  |a', '  b', 'end' })
      nvim:type('dii')
      t.eq({ 'def x', 'end' }, nvim:lines())
    end)
  end)

  describe('replace operator (r / R)', function()
    it('r{motion} replaces the text with the register', function()
      local nvim = t.nvim()
      nvim:set_buffer('|foo bar baz')
      nvim:type('yiwwriw')
      t.eq({ 'foo foo baz' }, nvim:lines())
      nvim:type('wviwr')
      t.eq({ 'foo foo foo' }, nvim:lines())
    end)

    it('R replaces single characters (the original r)', function()
      local nvim = t.nvim()
      nvim:set_buffer('|abc')
      nvim:type('RX')
      t.eq({ 'Xbc' }, nvim:lines())
      nvim:type('lvlRY')
      t.eq({ 'XYY' }, nvim:lines())
    end)
  end)

  it('visual L aligns the selection (easy-align)', function()
    local nvim = t.nvim()
    nvim:set_buffer({ '|a = 1', 'bbb = 2', 'cc = 3' })
    nvim:type('VjjL=')
    t.eq({ 'a   = 1', 'bbb = 2', 'cc  = 3' }, nvim:lines())
  end)

  describe('move / duplicate selections (visual m)', function()
    it('mj / mk move lines, repeating while you hold the submode', function()
      local nvim = t.nvim()
      nvim:set_buffer({ '|a', 'b', 'c', 'd' })
      nvim:type('Vmj')
      t.eq({ 'b', 'a', 'c', 'd' }, nvim:lines())
      nvim:type('<Esc>')
      nvim:set_buffer({ '|a', 'b', 'c', 'd' })
      nvim:type('Vmjj')
      t.eq({ 'b', 'c', 'a', 'd' }, nvim:lines())
      nvim:type('<Esc>')
      nvim:set_buffer({ '|a', 'b', 'c', 'd' })
      nvim:type('Vmjjk')
      t.eq({ 'b', 'a', 'c', 'd' }, nvim:lines())
    end)

    it('mJ duplicates the selection below', function()
      local nvim = t.nvim()
      nvim:set_buffer({ '|a', 'b' })
      nvim:type('VmJ')
      t.eq({ 'a', 'a', 'b' }, nvim:lines())
    end)

    it('ml / mh move the selected text sideways', function()
      local nvim = t.nvim()
      nvim:set_buffer('|ab cd')
      nvim:type('vlml')
      t.eq({ ' abcd' }, nvim:lines())
      nvim:type('<Esc>')
      nvim:set_buffer('|ab cd')
      nvim:type('vlmllh')
      t.eq({ ' abcd' }, nvim:lines())
    end)
  end)

  describe('switch (-)', function()
    for _, case in ipairs({
      { 'true', 'false' },
      { 'True', 'False' },
      { 'on', 'off' },
      { 'yes', 'no' },
      { 'and', 'or' },
      { 'if', 'unless' },
      { 'public', 'protected' },
      { 'protected', 'private' },
    }) do
      it(('%s -> %s'):format(case[1], case[2]), function()
        local nvim = nvim_ft('text')
        nvim:set_buffer('x = |' .. case[1])
        nvim:type('-')
        t.eq({ 'x = ' .. case[2] }, nvim:lines())
      end)
    end

    it('javascript: const -> let, onFocus -> onBlur, useState -> useAdaptiveState', function()
      local nvim = nvim_ft('javascript')
      for from, to in pairs({ const = 'let', onFocus = 'onBlur', useState = 'useAdaptiveState', onKeyUp = 'onKeyDown' }) do
        nvim:set_buffer('|' .. from)
        nvim:type('-')
        t.eq({ to }, nvim:lines(), from)
      end
    end)

    it('ruby: symbol -> string, new hash -> rocket hash, it -> xit', function()
      local nvim = nvim_ft('ruby')
      nvim:set_buffer('|:name')
      nvim:type('-')
      t.eq({ "'name'" }, nvim:lines())
      nvim:set_buffer('|key: 1')
      nvim:type('-')
      t.eq({ "'key' => 1" }, nvim:lines())
      nvim:set_buffer('|it "works"')
      nvim:type('-')
      t.eq({ 'xit "works"' }, nvim:lines())
    end)

    it('graphql: query -> mutation', function()
      local nvim = nvim_ft('graphql')
      nvim:set_buffer('|query Foo')
      nvim:type('-')
      t.eq({ 'mutation Foo' }, nvim:lines())
    end)

    it('proto: OPTIONAL -> REQUIRED, string -> google.protobuf.StringValue', function()
      local nvim = nvim_ft('proto')
      nvim:set_buffer('|OPTIONAL')
      nvim:type('-')
      t.eq({ 'REQUIRED' }, nvim:lines())
      nvim:set_buffer('|string name = 1;')
      nvim:type('-')
      t.eq({ 'google.protobuf.StringValue name = 1;' }, nvim:lines())
    end)
  end)

  it(':RengBang numbers lines sequentially from the first number', function()
    local nvim = t.nvim()
    nvim:set_buffer({ '|item 5', 'item 5', 'item 5' })
    nvim:type('Vjj:RengBang<CR>')
    t.eq({ 'item 5', 'item 6', 'item 7' }, nvim:lines())
  end)

  describe('case conversion (ge + case, then a motion)', function()
    for _, case in ipairs({
      { 'ge_', 'foo_bar_baz' },
      { 'ge-', 'foo-bar-baz' },
      { 'ge.', 'foo.bar.baz' },
      { 'ge/', 'foo/bar/baz' },
      { 'gec', 'fooBarBaz' },
      { 'gep', 'FooBarBaz' },
      { 'gek', 'FOO_BAR_BAZ' },
    }) do
      it(('%s converts to %s'):format(case[1], case[2]), function()
        local nvim = t.nvim()
        nvim:set_buffer('|fooBar_baz')
        nvim:type(case[1] .. 'iw')
        t.eq({ case[2] }, nvim:lines())
      end)
    end

    it('also works on a visual selection', function()
      local nvim = t.nvim()
      nvim:set_buffer('x |fooBar y')
      nvim:type('viwge_')
      t.eq({ 'x foo_bar y' }, nvim:lines())
    end)
  end)

  describe('paste with indentation', function()
    it('p adjusts the indentation of pasted lines to the destination', function()
      local nvim = nvim_ft('ruby')
      nvim:set_buffer({ '|z', 'if x', '  y', 'end' })
      nvim:type('yyjjp')
      t.eq({ 'z', 'if x', '  y', '  z', 'end' }, nvim:lines())
    end)

    it('keeps the indentation as-is in python, markdown and yaml', function()
      for _, ft in ipairs({ 'python', 'markdown', 'yaml' }) do
        local nvim = nvim_ft(ft)
        nvim:set_buffer({ '|z', 'a:', '    y' })
        nvim:type('yyjjp')
        t.eq({ 'z', 'a:', '    y', 'z' }, nvim:lines(), ft)
        nvim:close()
      end
    end)
  end)
end)
