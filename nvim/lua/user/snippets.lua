-- Helpers the snippet library (nvim/snippets/<filetype>.lua) is written with.
--
--   local S = require('user.snippets')
--   return {
--     S.snip('if', 'if (expr)', 'b', [[
--   if ($1) {
--   	$0
--   }]]),
--   }
--
-- Bodies use the LSP snippet syntax ($1, ${1:default}, $0, $TM_SELECTED_TEXT
-- for what <Tab> cut from a selection, $LS_CAPTURE_1 for a regex group); a
-- body can also be a list of LuaSnip nodes. Options keep UltiSnips' meaning:
--
--   (none)  the trigger follows whitespace or starts the line
--   w       the trigger follows a non-word character
--   i       anywhere, even inside a word
--   b       only at the beginning of a line
--   r       the trigger is a Vim regex (matched case-sensitively, up to the
--           cursor); its groups are in snip.captures
--   A       expands as soon as the trigger is typed

local ls = require('luasnip')
local expand_conds = require('luasnip.extras.conditions.expand')
local make_condition = require('luasnip.extras.conditions').make_condition

local M = {}

local after_space = expand_conds.trigger_not_preceded_by('%S')

local parse_opts = { trim_empty = false, dedent = false }

local function line_begin_show(line_to_cursor)
  return line_to_cursor:match('^%s*%S*$') ~= nil
end

--- A snippet: `trigger`, `description`, UltiSnips-like `options`, and a body
--- (LSP snippet syntax, or LuaSnip nodes). `context` adds LuaSnip context
--- fields (e.g. `condition`, `priority`), and `vars`: a function of the
--- matched `{ trigger, captures }` returning variables for the body
--- (`{ NAME = text }` for $NAME), computed when the snippet expands.
function M.snip(trigger, description, options, body, context)
  context = vim.tbl_extend('force', {
    trig = trigger,
    name = description,
    dscr = description,
  }, context or {})
  options = options or ''

  local conditions = {}
  if options:find('r', 1, true) then
    context.trig = '\\C' .. trigger
    context.trigEngine = 'vim'
    context.wordTrig = false
    context.hidden = true
  elseif options:find('i', 1, true) then
    context.wordTrig = false
  elseif options:find('w', 1, true) then
    context.wordTrig = true
  else
    context.wordTrig = false
    conditions[#conditions + 1] = after_space
  end
  if options:find('b', 1, true) then
    conditions[#conditions + 1] = expand_conds.line_begin
    context.show_condition = context.show_condition or line_begin_show
  end
  if options:find('A', 1, true) then
    context.snippetType = 'autosnippet'
    context.hidden = true
  end
  if context.condition then
    conditions[#conditions + 1] = make_condition(context.condition)
  end
  if #conditions > 0 then
    local condition = conditions[1]
    for i = 2, #conditions do
      condition = condition * conditions[i]
    end
    context.condition = condition
  end
  if context.vars then
    local vars = context.vars
    context.vars = nil
    context.resolveExpandParams = function(_, _, matched, captures)
      local env = {}
      for name, value in pairs(vars({ trigger = matched, captures = captures })) do
        env[name] = M.lines(value)
      end
      return { env_override = env }
    end
  end

  local snippet
  if type(body) == 'string' then
    snippet = ls.parser.parse_snippet(context, body, parse_opts)
  else
    snippet = ls.snippet(context, body)
  end
  -- as written, for the library's tests (nvim/tests/lib/snippets.lua)
  snippet.definition = { trigger = trigger, description = description, options = options }
  return snippet
end

--- Lines of a string or list, for text nodes.
function M.lines(text)
  return type(text) == 'table' and text or vim.split(text, '\n', { plain = true })
end

--- A regex group of the expanded trigger, as a function node.
function M.capture(n, transform)
  return ls.function_node(function(_, snip)
    local value = snip.captures[n] or ''
    return transform and transform(value, snip) or value
  end)
end

--- Text computed when the snippet expands (like UltiSnips' `!v` / `!p`).
function M.eval(fn)
  return ls.function_node(function(_, snip)
    return M.lines(fn(snip))
  end)
end

--- A copy of tabstop `n` through `transform` (like UltiSnips'
--- ${n/regex/format/}), updated as you type.
function M.mirror(n, transform)
  return ls.function_node(function(args)
    return M.lines(transform(table.concat(args[1], '\n')))
  end, { n })
end

--- Tabstop `n` whose text follows tabstop `from` through `transform` until
--- you change it (like UltiSnips' ${n:${from/regex/format/}}).
function M.placeholder(n, from, transform)
  return ls.dynamic_node(n, function(args, _, old)
    local text = M.lines(transform(table.concat(args[1], '\n')))
    local edited = old ~= nil and (old.edited or not vim.deep_equal(old.node:get_static_text(), old.text))
    if edited then
      text = old.node:get_static_text()
    end
    local node = ls.insert_node(1, text)
    local snip = ls.snippet_node(nil, node)
    snip.old_state = { node = node, text = text, edited = edited }
    return snip
  end, { from })
end

--- The text <Tab> cut from a selection (like UltiSnips' ${VISUAL}) in a node
--- body; `indent` is added to its lines after the first.
function M.selection(indent)
  return ls.function_node(function(_, snip)
    local lines = vim.deepcopy(M.lines(snip.snippet.env.LS_SELECT_DEDENT))
    for i = 2, #lines do
      lines[i] = indent .. lines[i]
    end
    return #lines > 0 and lines or { '' }
  end)
end

--- A body generated when the snippet expands: `fn(snip)` returns it as LSP
--- snippet text (like UltiSnips' snip.expand_anon). Give a regex snippet a
--- `docTrig` (sample trigger) for its documentation.
function M.anon(fn)
  return ls.dynamic_node(1, function(_, snip)
    return ls.snippet_node(nil, ls.parser.parse_snippet(nil, fn(snip.snippet), parse_opts))
  end)
end

return M
