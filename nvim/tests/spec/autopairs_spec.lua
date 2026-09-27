-- Auto-pairing while typing (nvim-autopairs and user.plugin.autopairs today).
-- Each case types one burst of keys, like a person typing without pausing for
-- popups.
local t = require('t')
local describe, it = t.describe, t.it

local function nvim_with(filetype)
  local nvim = t.nvim()
  if filetype then
    nvim:cmd('setfiletype ' .. filetype)
  end
  return nvim
end

describe('Auto-pairs', function()
  describe('brackets and quotes', function()
    for _, pair in ipairs({ { '(', ')' }, { '[', ']' }, { '{', '}' }, { '"', '"' }, { "'", "'" }, { '`', '`' } }) do
      local open, close = pair[1], pair[2]
      it(('%s inserts %s%s with the cursor inside'):format(open, open, close), function()
        local nvim = nvim_with('text')
        nvim:type('ix = ' .. open)
        t.buffer(nvim, 'x = ' .. open .. '|' .. close)
      end)

      it(('typing %s before an auto-inserted %s steps over it'):format(close, close), function()
        local nvim = nvim_with('text')
        nvim:type('ix = ' .. open .. 'y' .. close)
        t.buffer(nvim, 'x = ' .. open .. 'y' .. close .. '|')
      end)

      it(('<BS> between %s%s deletes both'):format(open, close), function()
        local nvim = nvim_with('text')
        nvim:type('ix = ' .. open .. '<BS>')
        t.buffer(nvim, 'x = |')
      end)
    end

    it('( right after a word is paired too (function calls)', function()
      local nvim = nvim_with('text')
      nvim:type('ifoo(')
      t.buffer(nvim, 'foo(|)')
    end)

    it("an apostrophe after a word is not paired (don't)", function()
      local nvim = nvim_with('text')
      nvim:type("idon't")
      t.buffer(nvim, "don't|")
    end)

    it('an escaped quote is not paired', function()
      local nvim = nvim_with('text')
      nvim:type('i"a\\"')
      t.buffer(nvim, '"a\\"|"')
    end)

    it('<CR> between brackets opens an indented line and puts the closer below', function()
      local nvim = nvim_with('typescript')
      nvim:type('iif (x) {<CR>')
      t.buffer(nvim, { 'if (x) {', '  |', '}' })
    end)

    it('<Space> between brackets pads both sides; <BS> removes both spaces', function()
      local nvim = nvim_with('text')
      nvim:type('i(<Space>')
      t.buffer(nvim, '( | )')
      nvim:type('<BS>')
      t.buffer(nvim, '(|)')
    end)

    it('. repeats the whole insertion including the auto-inserted closer', function()
      local nvim = nvim_with('text')
      nvim:set_buffer({ '|', '' })
      nvim:type('ifoo(bar<Esc>')
      t.eq({ 'foo(bar)', '' }, nvim:lines())
      nvim:type('j.')
      t.eq({ 'foo(bar)', 'foo(bar)' }, nvim:lines())
    end)

    it('is disabled in buftype=nofile buffers', function()
      local nvim = nvim_with('text')
      nvim:cmd('setlocal buftype=nofile')
      nvim:type('i(')
      t.buffer(nvim, '(|')
    end)
  end)

  describe('newline after arrows', function()
    for _, arrow in ipairs({ '->', '=>', '<-', '<=' }) do
      it(('<CR> after %s indents the next line one level deeper'):format(arrow), function()
        local nvim = nvim_with('text')
        nvim:type('ix ' .. arrow:gsub('<', '<lt>') .. '<CR>y')
        t.buffer(nvim, { 'x ' .. arrow, '  y|' })
      end)
    end

    it('<CR> after "-> " (trailing space) drops the space and indents', function()
      local nvim = nvim_with('text')
      nvim:type('ix -> <CR>y')
      t.buffer(nvim, { 'x ->', '  y|' })
    end)

    for _, ft in ipairs({ 'javascript', 'typescript', 'javascriptreact', 'typescriptreact' }) do
      it(('%s: <CR> after => adds braces for a function body, with the cursor inside'):format(ft), function()
        local nvim = nvim_with(ft)
        nvim:type('iconst f = () =><CR>')
        t.buffer(nvim, { 'const f = () => {', '  |', '}' })
        nvim:type('<Esc>')
        nvim:set_buffer('|')
        nvim:type('iconst g = () => <CR>')
        t.buffer(nvim, { 'const g = () => {', '  |', '}' })
      end)
    end
  end)

  describe('<C-l>', function()
    it('does nothing by default', function()
      local nvim = nvim_with('text')
      nvim:type('iabc<C-l>')
      t.buffer(nvim, 'abc|')
    end)

    it('closes the tag before the cursor', function()
      local nvim = nvim_with('text')
      nvim:type('i<lt>div class="a"><C-l>')
      t.buffer(nvim, '<div class="a">|</div>')
    end)

    it('toggles an empty element between <x></x> and <x />', function()
      local nvim = nvim_with('text')
      nvim:type('i<lt>br><C-l>')
      t.buffer(nvim, '<br>|</br>')
      nvim:type('<C-l>')
      t.buffer(nvim, '<br />|')
      nvim:type('<C-l>')
      t.buffer(nvim, '<br>|</br>')
    end)

    it('tsx: turns an auto-closed tag into a self-closing one', function()
      local nvim = nvim_with('typescriptreact')
      nvim:type('i<lt>Foo a={1}>')
      t.buffer(nvim, '<Foo a={1}>|</Foo>')
      nvim:type('<C-l>')
      t.buffer(nvim, '<Foo a={1} />|')
    end)

    it('go: cycles chan -> <-chan -> chan<-', function()
      local nvim = nvim_with('go')
      nvim:type('ivar c chan<C-l>')
      t.buffer(nvim, 'var c <-chan|')
      nvim:type('<C-l>')
      t.buffer(nvim, 'var c chan<-|')
      nvim:type('<C-l>')
      t.buffer(nvim, 'var c chan|')
    end)
  end)

  describe('angle brackets', function()
    for _, ft in ipairs({ 'html', 'eruby', 'xml', 'markdown' }) do
      it(ft .. ': < inserts <>', function()
        local nvim = nvim_with(ft)
        nvim:type('i<lt>')
        t.buffer(nvim, '<|>')
      end)
    end

    it('< is not paired in other filetypes', function()
      local nvim = nvim_with('typescript')
      nvim:type('iArray<lt>')
      t.buffer(nvim, 'Array<|')
    end)

    it('<BS> inside <> deletes both', function()
      local nvim = nvim_with('html')
      nvim:type('i<lt><BS>')
      t.buffer(nvim, '|')
    end)

    it('"< " followed by > becomes <>, and > steps over it', function()
      local nvim = nvim_with('text')
      nvim:type('ia <lt> >')
      t.buffer(nvim, 'a <|>')
      nvim:type('b>')
      t.buffer(nvim, 'a <b>|')
    end)

    it('> typed right after "< " before text becomes "<> "', function()
      local nvim = nvim_with('text')
      nvim:type('ia <lt> x<Left><Left>>')
      t.buffer(nvim, 'a <>| x')
    end)

    it('<Space> right after an auto-inserted < steps out of the pair', function()
      local nvim = nvim_with('html')
      nvim:type('i<lt><Space>')
      t.buffer(nvim, '<>|')
      nvim:type('<Esc>')
      nvim:set_buffer('|')
      nvim:type('ia <lt><Space>')
      t.buffer(nvim, 'a <> |')
    end)

    it('<CR> inside <> puts the cursor on its own line', function()
      local nvim = nvim_with('html')
      nvim:type('i<lt><CR>')
      t.buffer(nvim, { '<', '|', '>' })
    end)

    it('<CR> after a trailing < puts the closing > on the next line', function()
      local nvim = nvim_with('typescript')
      nvim:type('itype A = B<lt><CR>')
      t.buffer(nvim, { 'type A = B<', '|', '>' })
    end)

    t.quirk('html/markdown: typing a tag leaves a stray >', 'the auto-pairs rules pair < with >, then nvim-ts-autotag (its own buffer-local > mapping) closes the tag without consuming the auto-inserted >', function()
      for _, ft in ipairs({ 'html', 'markdown' }) do
        local nvim = nvim_with(ft)
        nvim:type('i<lt>b>')
        t.buffer(nvim, '<b>|</b>>', ft)
        nvim:close()
      end
    end)

    t.quirk('xml/eruby: > does not step over the auto-inserted >', 'nvim-ts-autotag maps > for the buffer: it inserts a > instead of stepping over the auto-inserted one, and closes no tag in these filetypes', function()
      for _, ft in ipairs({ 'xml', 'eruby' }) do
        local nvim = nvim_with(ft)
        nvim:type('i<lt>b>')
        t.buffer(nvim, '<b>|>', ft)
        nvim:close()
      end
    end)

    it('html: an escaped \\< is not paired', function()
      local nvim = nvim_with('html')
      nvim:type('i\\<lt>')
      t.buffer(nvim, '\\<|')
    end)
  end)

  describe('ruby block parameters', function()
    it('| after { inserts a pair of bars (inside the auto-closed braces)', function()
      local nvim = nvim_with('ruby')
      nvim:type('ixs.each { |')
      t.buffer(nvim, 'xs.each { |‸| }', { marker = '‸' })
      nvim:type('x|')
      t.buffer(nvim, 'xs.each { |x|‸ }', { marker = '‸' })
    end)

    it('| after do inserts a pair of bars, also in rspec files', function()
      local nvim = nvim_with('ruby.rspec')
      nvim:type('ixs.each do |')
      t.buffer(nvim, 'xs.each do |‸|', { marker = '‸' })
    end)
  end)

  describe('doc comments', function()
    it('/ after "* " closes the comment as */', function()
      local nvim = nvim_with('text')
      nvim:type('i * /')
      t.buffer(nvim, ' */|')
    end)
  end)
end)
