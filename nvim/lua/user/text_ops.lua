-- Operators and commands on text:
--
--   r{motion}    put a register over the text (rr the line), in Visual mode
--                too, keeping the register; R is Vim's r
--   ge_ ge- ge. ge/ gec gep gek {motion}
--                the words in snake_case, dash-case, dot.case, path/case,
--                camelCase, PascalCase or CONSTANT_CASE, in Visual mode too
--   :Subs/{from}/{to}/
--                each case variant of the word {from} replaced with the same
--                variant of {to} (fooBar, foo_bar, FOO_BAR -> bazQux,
--                baz_qux, BAZ_QUX), previewed as you type; :sm/ starts one
--   :RengBang    the numbers in the lines renumbered in order, from the first

local M = {}

---------------------------------------------------------------------------
-- Operators
---------------------------------------------------------------------------

local operate -- the function of the last operator, which . repeats

--- (the 'operatorfunc')
function M.operatorfunc(type)
  operate(type)
end

--- Keys starting an operator (g@) that calls `fn(type)` for the text it
--- covers, from the '[ mark to the '] mark; `motion` follows them.
local function operator(fn, motion)
  return function()
    operate = fn
    vim.o.operatorfunc = "v:lua.require'user.text_ops'.operatorfunc"
    return 'g@' .. (motion or '')
  end
end

--- The byte past the character at `col` (0-based) of `line`, no further than
--- its end.
local function past(line, col)
  return math.min(col + #vim.fn.strcharpart(line:sub(col + 1), 0, 1), #line)
end

--- What an operator covers, from the '[ mark to the '] mark: the text, or
--- each line's part of a block, as { start row, start col, end row, end col },
--- 0-based with the end excluded (nvim_buf_get_text's).
local function ranges(type)
  local s, e = vim.api.nvim_buf_get_mark(0, '['), vim.api.nvim_buf_get_mark(0, ']')
  local lines = vim.api.nvim_buf_get_lines(0, s[1] - 1, e[1], true)
  if type == 'block' then
    local out = {}
    for i, line in ipairs(lines) do
      local start = math.min(s[2], #line)
      out[i] = { s[1] + i - 2, start, s[1] + i - 2, math.max(past(line, e[2]), start) }
    end
    return out
  elseif type == 'line' then
    return { { s[1] - 1, 0, e[1] - 1, #lines[#lines] } }
  end
  return { { s[1] - 1, s[2], e[1] - 1, past(lines[#lines], e[2]) } }
end

--- Puts the register over the text, keeping the register; each line of a
--- block gets the register's line of the same row, or its last.
local function replace(type)
  local text = vim.fn.getreg(vim.v.register, 1, true)
  if #text == 0 then
    return
  end
  local covered = ranges(type)
  for i, r in ipairs(covered) do
    vim.api.nvim_buf_set_text(0, r[1], r[2], r[3], r[4], type == 'block' and { text[math.min(i, #text)] } or text)
  end
  -- the cursor where P leaves it: on the first non-blank of the lines, at the
  -- start of the block, or on the last character of the text
  local r = covered[1]
  if type == 'line' then
    vim.api.nvim_win_set_cursor(0, { r[1] + 1, #text[1]:match('^%s*') })
  elseif type == 'block' then
    vim.api.nvim_win_set_cursor(0, { r[1] + 1, r[2] })
  else
    local last = text[#text]
    local col = (#text == 1 and r[2] or 0) + #last - #vim.fn.strcharpart(last, vim.fn.strchars(last) - 1)
    vim.api.nvim_win_set_cursor(0, { r[1] + #text, col })
  end
end

---------------------------------------------------------------------------
-- Case
---------------------------------------------------------------------------

local lower, upper = vim.fn.tolower, vim.fn.toupper

local function capitalize(word)
  return upper(vim.fn.strcharpart(word, 0, 1)) .. lower(vim.fn.strcharpart(word, 1))
end

--- A case style: the words joined by `sep`, the first through `first`, the
--- others through `rest`.
local function style(sep, first, rest)
  return function(words)
    local out = {}
    for i, word in ipairs(words) do
      out[i] = (i == 1 and first or rest)(word)
    end
    return table.concat(out, sep)
  end
end

-- (in the order :Subs prefers them, when variants are the same text)
local STYLES = {
  { 'snake', style('_', lower, lower) },
  { 'camel', style('', lower, capitalize) },
  { 'pascal', style('', capitalize, capitalize) },
  { 'constant', style('_', upper, upper) },
  { 'dash', style('-', lower, lower) },
  { 'dot', style('.', lower, lower) },
  { 'path', style('/', lower, lower) },
  -- (phrases, for :Subs)
  { 'title', style(' ', capitalize, capitalize) },
  { 'sentence', style(' ', capitalize, lower) },
  { 'lower', style(' ', lower, lower) },
  { 'upper', style(' ', upper, upper) },
}
local STYLE = {}
for _, s in ipairs(STYLES) do
  STYLE[s[1]] = s[2]
end

--- The words of an identifier or a phrase: fooBar_baz, HTTPServer, foo2Bar.
local function words(text)
  text = text:gsub('([%l%d\128-\255])(%u)', '%1 %2'):gsub('(%u)(%u%l)', '%1 %2')
  return vim.split(text, '[^%w\128-\255]+', { trimempty = true })
end

--- `text` in a case style, keeping what surrounds its words (spaces, quotes,
--- a leading _).
local function convert(text, to)
  local before, body, after = text:match('^([^%w\128-\255]*)(.-)([^%w\128-\255]*)$')
  return before .. to(words(body)) .. after
end

--- Converts the text to a case style, each line on its own.
local function convert_case(type, to)
  local start = vim.api.nvim_buf_get_mark(0, '[')
  for _, r in ipairs(ranges(type)) do
    local text = vim.api.nvim_buf_get_text(0, r[1], r[2], r[3], r[4], {})
    vim.api.nvim_buf_set_text(0, r[1], r[2], r[3], r[4], vim.tbl_map(function(line)
      return convert(line, to)
    end, text))
  end
  vim.api.nvim_win_set_cursor(0, start)
end

---------------------------------------------------------------------------
-- Commands
---------------------------------------------------------------------------

--- Sets each line from `line1` to `line2` to `fn(line)`, where it changes.
local function map_lines(line1, line2, fn)
  for i, line in ipairs(vim.api.nvim_buf_get_lines(0, line1 - 1, line2, true)) do
    local new = fn(line)
    if new ~= line then
      vim.api.nvim_buf_set_lines(0, line1 + i - 2, line1 + i - 1, true, { new })
    end
  end
end

local WORD = '[%w_\128-\255]'

--- :Subs/{from}/{to}/, with any separator.
local function subs(opts)
  local sep = opts.args:sub(1, 1)
  local from, to = unpack(vim.split(opts.args:sub(2), sep, { plain = true }))
  if from == '' then
    return
  end
  to = to or ''
  -- each variant of `from` and its replacement, `from` as typed first
  local replacements = { [from] = to }
  local from_words, to_words = words(from), words(to)
  for _, s in ipairs(STYLES) do
    local variant = s[2](from_words)
    if variant ~= '' and not replacements[variant] then
      replacements[variant] = s[2](to_words)
    end
  end
  local variants = vim.tbl_keys(replacements)
  table.sort(variants, function(a, b)
    return #a > #b
  end)
  map_lines(opts.line1, opts.line2, function(line)
    local out, i = {}, 1
    while i <= #line do
      local found
      -- (a whole word: no word character before or after it)
      if not line:sub(i - 1, i - 1):match(WORD) then
        for _, variant in ipairs(variants) do
          if line:sub(i, i + #variant - 1) == variant and not line:sub(i + #variant, i + #variant):match(WORD) then
            found = variant
            break
          end
        end
      end
      out[#out + 1] = found and replacements[found] or line:sub(i, i)
      i = i + (found and #found or 1)
    end
    return table.concat(out)
  end)
end

--- :RengBang: each number (a whole word) the first number plus how many
--- came before it.
local function renumber(opts)
  local n
  map_lines(opts.line1, opts.line2, function(line)
    return (line:gsub('%f[%w_]%d+%f[^%w_]', function(digits)
      n = n and n + 1 or tonumber(digits)
      return tostring(n)
    end))
  end)
end

function M.setup()
  vim.keymap.set({ 'n', 'x' }, 'r', operator(replace), { expr = true, desc = 'Put a register over' })
  vim.keymap.set('n', 'rr', operator(replace, '_'), { expr = true, desc = 'Put a register over the line' })
  vim.keymap.set({ 'n', 'x', 'o' }, 'R', 'r')

  for lhs, name in pairs({ _ = 'snake', ['-'] = 'dash', ['.'] = 'dot', ['/'] = 'path', c = 'camel', p = 'pascal', k = 'constant' }) do
    vim.keymap.set({ 'n', 'x' }, 'ge' .. lhs, operator(function(type)
      convert_case(type, STYLE[name])
    end), { expr = true, desc = ('To %s case'):format(name) })
  end

  vim.api.nvim_create_user_command('Subs', subs, {
    nargs = 1,
    range = '%',
    preview = function(opts)
      subs(opts)
      return 1
    end,
    desc = 'Substitute each case variant of a word',
  })
  vim.api.nvim_create_user_command('RengBang', renumber, { range = true, desc = 'Renumber in order' })
end

return M
