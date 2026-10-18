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
-- body can also be a list of LuaSnip nodes. Options have UltiSnips' meaning:
--
--   (none)  the trigger follows whitespace or starts the line
--   w       the trigger follows a non-word character
--   i       anywhere, even inside a word
--   b       only at the beginning of a line
--   r       the trigger is a Vim regex (matched case-sensitively, up to the
--           cursor); its groups are in snip.captures
--   A       expands as soon as the trigger is typed
--   p       postfix (not UltiSnips'): the trigger follows an expression and a
--           dot, which the snippet takes the place of too; the expression is
--           $POSTFIX (`count.times` -> `Array.from({ length: count })`)
--
-- The completion menu offers a snippet only where it expands, and neither a
-- regex nor an auto-trigger one.

local ls = require('luasnip')
local expand_conds = require('luasnip.extras.conditions.expand')
local make_condition = require('luasnip.extras.conditions').make_condition

local M = {}

local after_space = expand_conds.trigger_not_preceded_by('%S')

local parse_opts = { trim_empty = false, dedent = false }

--- The text before the word being typed, which the completion menu
--- (blink.cmp) offers snippets for: its words are letters, digits, _ and -,
--- without leading dashes. (It hands a show_condition the line up to the
--- character before the cursor: after a lone `-`, nothing.)
local function before_word()
  local before = vim.api.nvim_get_current_line():sub(1, vim.api.nvim_win_get_cursor(0)[2])
  local word = before:match('[%w_-]*$'):gsub('^%-+', '')
  return before:sub(1, #before - #word)
end

--- At the beginning of a line, after the trigger's words before the one being
--- typed, if any (`import ` of `import empty`).
local function line_begin_show(trigger)
  return function()
    return vim.startswith(trigger, before_word():match('^%s*(.*)$'))
  end
end

local function after_space_show()
  local before = before_word()
  return before == '' or before:match('%s$') ~= nil
end

--- The expression a postfix snippet follows, from the text before its
--- trigger: `items.length` from `items.length.`.
local function postfix_expr(before)
  return before:match('([%w_$.]*[%w_$])%.$')
end

local function postfix_show()
  return postfix_expr(before_word()) ~= nil
end

--- Expands a postfix snippet in place of the expression and the dot too:
--- after its trigger, or after the part of it typed when the menu expands it.
local function postfix_params(_, line_to_cursor, matched)
  local expr = postfix_expr(line_to_cursor:sub(1, #line_to_cursor - #matched))
  if not expr then
    return nil
  end
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  return {
    trigger = matched,
    clear_region = { from = { row - 1, col - #matched - 1 - #expr }, to = { row - 1, col } },
    env_override = { POSTFIX = { expr } },
  }
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
  local show
  if options:find('r', 1, true) then
    context.trig = '\\C' .. trigger
    context.trigEngine = 'vim'
    context.wordTrig = false
    context.hidden = true
  elseif options:find('p', 1, true) then
    context.wordTrig = false
    context.resolveExpandParams = postfix_params
    show = postfix_show
  elseif options:find('i', 1, true) then
    context.wordTrig = false
  elseif options:find('w', 1, true) then
    context.wordTrig = true
  else
    context.wordTrig = false
    conditions[#conditions + 1] = after_space
    show = after_space_show
  end
  if options:find('b', 1, true) then
    conditions[#conditions + 1] = expand_conds.line_begin
    show = line_begin_show(trigger)
  end
  context.show_condition = context.show_condition or show
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
