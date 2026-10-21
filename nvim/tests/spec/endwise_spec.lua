-- <CR> after the line that opens a block adds the line that closes it
-- (user/plugin/treesitter/endwise.lua), in each language that has an endwise
-- query. A case is { name, lines, lines after <CR>, options }: █ marks where
-- <CR> is typed, with 'expandtab' and 'shiftwidth' 2 unless the options say
-- otherwise; `undo` types a second <CR> and undoes.
local t = require('t')

local EXTENSIONS = { bash = 'sh', lua = 'lua', ruby = 'rb', vim = 'vim' }

local CASES = {
  bash = {
    { 'if', { 'if true; then█' }, { 'if true; then', '  ', 'fi' } },
    { 'for', { 'for x in a b; do█' }, { 'for x in a b; do', '  ', 'done' } },
    { 'case', { 'case $x in█' }, { 'case $x in', '  ', 'esac' } },
  },
  lua = {
    { 'global function', { 'function foo()█' }, { 'function foo()', '  ', 'end' } },
    { 'local function', { 'local function foo()█' }, { 'local function foo()', '  ', 'end' } },
    { 'var function', { 'local foo = function()█' }, { 'local foo = function()', '  ', 'end' } },
    { 'table value function', { 'function M.foo()█' }, { 'function M.foo()', '  ', 'end' } },
    { 'do block', { 'do█' }, { 'do', '  ', 'end' } },
    { 'while loop', { 'while true do█' }, { 'while true do', '  ', 'end' } },
    { 'for loop generic clause', { 'for var=exp1,exp2,exp3 do█' }, { 'for var=exp1,exp2,exp3 do', '  ', 'end' } },
    { 'for loop numeric clause', { 'for i=10,1,-1 do print(i) do█' }, { 'for i=10,1,-1 do print(i) do', '  ', 'end' } },
    { 'if stmt', { 'if foo then█' }, { 'if foo then', '  ', 'end' } },
    {
      'nested global function',
      { 'function foobarbaz()', '  function foo()█', 'end' },
      { 'function foobarbaz()', '  function foo()', '    ', '  end', 'end' },
    },
    {
      'nested local function',
      { 'function foobarbaz()', '  local function foo()█', 'end' },
      { 'function foobarbaz()', '  local function foo()', '    ', '  end', 'end' },
    },
    {
      'nested var function',
      { 'function foobarbaz()', '  local foo = function()█', 'end' },
      { 'function foobarbaz()', '  local foo = function()', '    ', '  end', 'end' },
    },
    {
      'nested table value function',
      { 'function foobarbaz()', '  function M.foo()█', 'end' },
      { 'function foobarbaz()', '  function M.foo()', '    ', '  end', 'end' },
    },
    {
      'nested do block',
      { 'function foobarbaz()', '  do█', 'end' },
      { 'function foobarbaz()', '  do', '    ', '  end', 'end' },
    },
    {
      'nested while loop',
      { 'function foobarbaz()', '  while true do█', 'end' },
      { 'function foobarbaz()', '  while true do', '    ', '  end', 'end' },
    },
    {
      'nested for loop generic clause',
      { 'function foobarbaz()', '  for var=exp1,exp2,exp3 do█', 'end' },
      { 'function foobarbaz()', '  for var=exp1,exp2,exp3 do', '    ', '  end', 'end' },
    },
    {
      'nested for loop numeric clause',
      { 'function foobarbaz()', '  for i=10,1,-1 do print(i) do█', 'end' },
      { 'function foobarbaz()', '  for i=10,1,-1 do print(i) do', '    ', '  end', 'end' },
    },
    {
      'nested if stmt',
      { 'function foobarbaz()', '  if foo then█', 'end' },
      { 'function foobarbaz()', '  if foo then', '    ', '  end', 'end' },
    },
    {
      'end node with different indentation picked up on same line',
      { "foo(function foo()█ print('hello') end)" },
      { 'foo(function foo()', "  print('hello') end)" },
    },
    {
      'trailing text that belongs to parent',
      { 'foo(vim.schedule_wrap(function()█))' },
      { 'foo(vim.schedule_wrap(function()', '  ', 'end))' },
    },
    {
      'mix trailing text that belongs to parent and endable node',
      { "foo(vim.schedule_wrap(function()█print('')))" },
      { 'foo(vim.schedule_wrap(function()', "  print('')", 'end))' },
    },
    {
      'issue #19',
      { 'if true then', "  print('true')", 'elseif true then█', 'else', "  print('false')", 'end' },
      { 'if true then', "  print('true')", 'elseif true then', '  ', 'else', "  print('false')", 'end' },
    },
    {
      'trailing non-alphanumeric text',
      {
        'foo(function()█)',
        "foo.bar.baz('foo', {",
        '    foo = bar,',
        "    baz = 'bin',",
        '})',
        "foo.bar.baz('foo', {",
        '    foo = bar,',
        "    baz = 'bin',",
        '    callback = function()',
        '        a.b.c = 2',
        '        a.b.c = 2',
        '        a.b.c = 2',
        '    end,',
        '})',
      },
      {
        'foo(function()',
        '  ',
        'end)',
        "foo.bar.baz('foo', {",
        '    foo = bar,',
        "    baz = 'bin',",
        '})',
        "foo.bar.baz('foo', {",
        '    foo = bar,',
        "    baz = 'bin',",
        '    callback = function()',
        '        a.b.c = 2',
        '        a.b.c = 2',
        '        a.b.c = 2',
        '    end,',
        '})',
      },
    },
    {
      'undo, clean undo-block after multiple <CR>s before end of file',
      { 'function foo()█', '' },
      { 'function foo()', '' },
      { undo = true },
    },
    {
      'undo, clean undo-block after multiple <CR>s at end of file',
      { '', 'function foo()█' },
      { '', 'function foo()' },
      { undo = true },
    },
  },
  ruby = {
    { 'outside of syntax tree works', { '█', '', '"foobar"' }, { '', '', '', '"foobar"' } },
    { 'normal cr works', { '"foobar"█' }, { '"foobar"', '' } },
    {
      'sequence, indentation is kept',
      { '  module Foo█', 'def foo', 'end' },
      { '  module Foo', '    ', '  end', 'def foo', 'end' },
    },
    {
      'sequence, tailing text is kept with indentation',
      { '  module Foo█bar', 'def foo', 'end' },
      { '  module Foo', '    bar', '  end', 'def foo', 'end' },
    },
    {
      'sequence, tailing text is kept with indentation but leading whitespace is stripped',
      { '  module Foo█ bar', 'def foo', 'end' },
      { '  module Foo', '    bar', '  end', 'def foo', 'end' },
    },
    {
      'sequence, unindented text indents newline',
      { 'module Foo█', 'def foo', 'end' },
      { 'module Foo', '  ', 'end', 'def foo', 'end' },
    },
    {
      'sequence, we search back to closest non-whitespace',
      { 'module Foo', '', '█', 'def foo', 'end' },
      { 'module Foo', '', '', '  ', 'end', 'def foo', 'end' },
    },
    { 'subtree, basic example works', { 'module Foo█' }, { 'module Foo', '  ', 'end' } },
    { 'subtree', { 'module Foo█bar' }, { 'module Foo', '  bar', 'end' } },
    { 'subtree, trailing text works as expected', { 'module Foo█ bar' }, { 'module Foo', '  bar', 'end' } },
    {
      'subtree, realizes end belongs to parent',
      { 'module Foo', '  def foo█', 'end' },
      { 'module Foo', '  def foo', '    ', '  end', 'end' },
    },
    { 'valid syntax is no-op', { 'module Foo█', 'end' }, { 'module Foo', '  ', 'end' } },
    { 'subtree, module works', { 'module Foo█' }, { 'module Foo', '  ', 'end' } },
    { 'subtree, class works', { 'class Foo█' }, { 'class Foo', '  ', 'end' } },
    { 'subtree, method works', { 'def foo█' }, { 'def foo', '  ', 'end' } },
    { 'subtree, singleton_method works', { 'def foo.bar█' }, { 'def foo.bar', '  ', 'end' } },
    { 'sequence, module works', { 'module Foo█', 'def foo', 'end' }, { 'module Foo', '  ', 'end', 'def foo', 'end' } },
    { 'sequence, class works', { 'class Foo█', 'def foo', 'end' }, { 'class Foo', '  ', 'end', 'def foo', 'end' } },
    { 'sequence, method works', { 'def foo█', 'def foo', 'end' }, { 'def foo', '  ', 'end', 'def foo', 'end' } },
    {
      'sequence, singleton_method works',
      { 'def foo.bar█', 'def foo', 'end' },
      { 'def foo.bar', '  ', 'end', 'def foo', 'end' },
    },
    { 'while <cond>', { "while puts('hello')█" }, { "while puts('hello')", '  ', 'end' } },
    { 'while <cond> do', { "while puts('hello') do█" }, { "while puts('hello') do", '  ', 'end' } },
    {
      'while <cond> do as sequence',
      { "while puts('hello') do█", 'def foo', 'end' },
      { "while puts('hello') do", '  ', 'end', 'def foo', 'end' },
    },
    { 'until <cond>', { "until puts('hello')█" }, { "until puts('hello')", '  ', 'end' } },
    { 'until <cond> do', { "until puts('hello') do█" }, { "until puts('hello') do", '  ', 'end' } },
    {
      'until <cond> do as sequence',
      { "until puts('hello') do█", 'def foo', 'end' },
      { "until puts('hello') do", '  ', 'end', 'def foo', 'end' },
    },
    { 'for loop without do', { 'for foo in 1..5█' }, { 'for foo in 1..5', '  ', 'end' } },
    { 'for loop with do', { 'for foo in 1..5 do█' }, { 'for foo in 1..5 do', '  ', 'end' } },
    {
      'sequence, for loop without do',
      { 'for foo in 1..5█', 'def fun', 'end' },
      { 'for foo in 1..5', '  ', 'end', 'def fun', 'end' },
    },
    {
      'sequence, for loop with do',
      { 'for foo in 1..5 do█', 'def fun', 'end' },
      { 'for foo in 1..5 do', '  ', 'end', 'def fun', 'end' },
    },
    { 'do block', { 'foo.each do█' }, { 'foo.each do', '  ', 'end' } },
    { 'do block with args', { 'foo.each do |bar, baz|█' }, { 'foo.each do |bar, baz|', '  ', 'end' } },
    { 'sequence, do block', { 'foo.each do█', 'def foo', 'end' }, { 'foo.each do', '  ', 'end', 'def foo', 'end' } },
    {
      'sequence, do block with args',
      { 'foo.each do |bar, baz|█', 'def foo', 'end' },
      { 'foo.each do |bar, baz|', '  ', 'end', 'def foo', 'end' },
    },
    { 'if stmt', { 'if true█' }, { 'if true', '  ', 'end' } },
    { 'sequence, if stmt', { 'if true█', 'def foo', 'end' }, { 'if true', '  ', 'end', 'def foo', 'end' } },
    { 'if stmt then', { 'if true then█' }, { 'if true then', '  ', 'end' } },
    {
      'sequence, if stmt then',
      { 'if true then█', 'def foo', 'end' },
      { 'if true then', '  ', 'end', 'def foo', 'end' },
    },
    { 'unless stmt', { 'unless true█' }, { 'unless true', '  ', 'end' } },
    { 'sequence, unless stmt', { 'unless true█', 'def foo', 'end' }, { 'unless true', '  ', 'end', 'def foo', 'end' } },
    { 'unless stmt then', { 'unless true then█' }, { 'unless true then', '  ', 'end' } },
    {
      'sequence, unless stmt then',
      { 'unless true then█', 'def foo', 'end' },
      { 'unless true then', '  ', 'end', 'def foo', 'end' },
    },
    { 'case stmt', { 'case foo█' }, { 'case foo', '', 'end' } },
    {
      'nested case stmt',
      { 'case foo', 'when 0', '  case bar█', 'end' },
      { 'case foo', 'when 0', '  case bar', '  ', '  end', 'end' },
    },
    { 'begin stmt', { 'begin█' }, { 'begin', '  ', 'end' } },
    { 'begin stmt rescue', { 'begin', 'rescue█' }, { 'begin', 'rescue', '  ', 'end' } },
    { 'begin stmt rescue with exceptions', { 'begin', 'rescue String█' }, { 'begin', 'rescue String', '  ', 'end' } },
    {
      'begin stmt rescue ensure',
      { 'begin', 'rescue String', 'ensure█' },
      { 'begin', 'rescue String', 'ensure', '  ', 'end' },
    },
    { 'valueless case stmt', { 'case█' }, { 'case', '', 'end' } },
    { 'heredoc', { 'test "foo", <<~FOO█' }, { 'test "foo", <<~FOO', '', 'FOO' } },
    {
      'sequence, superclass works',
      { 'class Foo < self█', 'def foo', 'end' },
      { 'class Foo < self', '  ', 'end', 'def foo', 'end' },
    },
    { 'subtree, superclass works', { 'class Foo < self█' }, { 'class Foo < self', '  ', 'end' } },
    {
      'sequence, singleton class',
      { 'class << self█', 'def foo', 'end' },
      { 'class << self', '  ', 'end', 'def foo', 'end' },
    },
    { 'subtree, singleton class', { 'class << self█' }, { 'class << self', '  ', 'end' } },
    { 'inside function params, no end until they close', { 'def foo(█)' }, { 'def foo(', '  ', ')' } },
    { '2 spaces works', { '  module Foo█', 'def foo', 'end' }, { '  module Foo', '    ', '  end', 'def foo', 'end' } },
    {
      '4 spaces works',
      { '    module Foo█', 'def foo', 'end' },
      { '    module Foo', '        ', '    end', 'def foo', 'end' },
      { shiftwidth = 4 },
    },
    {
      'tabs works',
      { '\tmodule Foo█', 'def foo', 'end' },
      { '\tmodule Foo', '\t\t', '\tend', 'def foo', 'end' },
      { expandtab = false },
    },
    {
      'undo, clean undo-block after multiple <CR>s before end of file',
      { 'def foo█', '' },
      { 'def foo', '' },
      { undo = true },
    },
    {
      'undo, clean undo-block after multiple <CR>s at end of file',
      { '', 'def foo█' },
      { '', 'def foo' },
      { undo = true },
    },
  },
  vim = {
    { 'Lua in lua << EOF', { 'lua << EOF', 'function f()█', 'EOF' }, { 'lua << EOF', 'function f()', '  ', 'end', 'EOF' } },
    { 'global function', { 'function Foo()█' }, { 'function Foo()', '  ', 'endfunction' } },
    { 'script local function', { 'function s:foo()█' }, { 'function s:foo()', '  ', 'endfunction' } },
    { 'function overwrite', { 'function! Foo()█' }, { 'function! Foo()', '  ', 'endfunction' } },
    { 'ranged function', { 'function Foo() range█' }, { 'function Foo() range', '  ', 'endfunction' } },
    { 'dictionary function', { 'function Foo() dict█' }, { 'function Foo() dict', '  ', 'endfunction' } },
    { 'closure', { 'function Foo() closure█' }, { 'function Foo() closure', '  ', 'endfunction' } },
    { 'abort function', { 'function Foo() abort█' }, { 'function Foo() abort', '  ', 'endfunction' } },
    { 'abort closure', { 'function Foo() closure abort█' }, { 'function Foo() closure abort', '  ', 'endfunction' } },
    { 'if stmt', { 'if foo█' }, { 'if foo', '  ', 'endif' } },
    { 'for loop', { 'for foo in bar█' }, { 'for foo in bar', '  ', 'endfor' } },
    { 'while loop', { 'while foo█' }, { 'while foo', '  ', 'endwhile' } },
    { 'try', { 'try█' }, { 'try', '  ', 'endtry' } },
    {
      'nested global function',
      { 'function Foo()', '  function Bar()█', 'endfunction' },
      { 'function Foo()', '  function Bar()', '    ', '  endfunction', 'endfunction' },
    },
    {
      'nested script local function',
      { 'function s:foo()', '  function s:bar()█', 'endfunction' },
      { 'function s:foo()', '  function s:bar()', '    ', '  endfunction', 'endfunction' },
    },
    {
      'nested while loop',
      { 'while true', '  while true█', 'endwhile' },
      { 'while true', '  while true', '    ', '  endwhile', 'endwhile' },
    },
    {
      'nested for loop',
      { 'for foo in bar', '  for baz in qux█', 'endfor' },
      { 'for foo in bar', '  for baz in qux', '    ', '  endfor', 'endfor' },
    },
    { 'nested if stmt', { 'if foo', '  if bar█', 'endif' }, { 'if foo', '  if bar', '    ', '  endif', 'endif' } },
    { 'nested try', { 'try', '  try█', 'endtry' }, { 'try', '  try', '    ', '  endtry', 'endtry' } },
    {
      'nested global function has dynamic end text',
      { 'func! Foo()', '  fun Bar()█', 'endfunc' },
      { 'func! Foo()', '  fun Bar()', '    ', '  endfun', 'endfunc' },
    },
    { 'global function has dynamic end text', { 'fun Bar()█' }, { 'fun Bar()', '  ', 'endfun' } },
  },
}

--- Types <CR> at the █ in `lines`, as a new file `name`, and returns the lines after.
local function enter(nvim, name, lines, opts)
  opts = opts or {}
  local row, col
  lines = vim.deepcopy(lines)
  for i, line in ipairs(lines) do
    local at = line:find('█', 1, true)
    if at then
      row, col = i, at - 1
      lines[i] = line:sub(1, at - 1) .. line:sub(at + #'█')
    end
  end
  nvim:edit(name, lines)
  nvim:cmd(('setlocal %s shiftwidth=%d'):format(opts.expandtab == false and 'noexpandtab' or 'expandtab', opts.shiftwidth or 2))
  -- (after the character before █, or before the first one)
  nvim:set_cursor(row, math.max(col - 1, 0))
  nvim:type(col == 0 and 'i<CR>' or 'a<CR>')
  if opts.undo then
    nvim:type('<CR>')
    nvim:cmd('undo')
  end
  local after = nvim:lines()
  nvim:stopinsert()
  return after
end

t.describe('Endwise', function()
  for lang, cases in vim.spairs(CASES) do
    -- (one child for all the cases of a language; each in a file of its own)
    t.it(lang .. ': <CR> closes the blocks it opens', function()
      local nvim = t.nvim()
      local failures = {}
      for i, case in ipairs(cases) do
        local after = enter(nvim, ('case%d.%s'):format(i, EXTENSIONS[lang]), case[2], case[4])
        if not vim.deep_equal(case[3], after) then
          failures[#failures + 1] = ('%s\n  expected: %s\n  actual:   %s'):format(case[1], vim.inspect(case[3]), vim.inspect(after))
        end
      end
      if #failures > 0 then
        error(('%d of %d cases:\n%s'):format(#failures, #cases, table.concat(failures, '\n')), 0)
      end
    end)
  end
end)
