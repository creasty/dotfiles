-- Auto-pairs: nvim-autopairs pairs brackets and quotes, steps over closers
-- and deletes pairs; the rules below add the rest. The keys are mapped in
-- user.intelligence, which asks these handlers what to type.
--
--   <CR>      after -> => <- <= indents one level deeper; after => in
--             JavaScript it adds a function body; between <> or after a
--             trailing < it puts the > on its own line
--   <Space>   inside empty brackets pads both sides; <BS> removes both
--   <C-l>     closes the tag before the cursor, toggles <x></x> / <x />,
--             cycles chan / <-chan / chan<- in Go
--   < >       <> pairs in markup; "< " then > becomes <>
--   |         block parameters in Ruby: { |x| } / do |x|
--   /         after "* " closes a doc comment

local M = {}

local ANGLE_FILETYPES = { html = true, eruby = true, xml = true, markdown = true }
local JS_FILETYPES = { javascript = true, typescript = true, javascriptreact = true, typescriptreact = true }
local PADDED = { ['()'] = true, ['[]'] = true, ['{}'] = true }

local k = vim.keycode
local LEFT = '<C-g>U<Left>'
local RIGHT = '<C-g>U<Right>'

--- Text before and after the cursor on its line.
local function around()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  return line:sub(1, col), line:sub(col + 1)
end

local function vmatch(str, pattern)
  return vim.fn.match(str, pattern) >= 0
end

local function filetype_is(set)
  for _, ft in ipairs(vim.split(vim.bo.filetype, '.', { plain = true })) do
    if set[ft] then
      return true
    end
  end
  return false
end

--- Off in scratch and prompt buffers, and while stopped (blockwise insert).
function M.enabled()
  if vim.b.user_intelligence_stopped then
    return false
  end
  local buftype = vim.bo.buftype
  return buftype ~= 'nofile' and buftype ~= 'prompt'
end

local function autopairs()
  local ap = package.loaded['nvim-autopairs']
  if ap and not ap.state.disabled then
    return ap
  end
end

--- Stops or resumes nvim-autopairs (it loads on the first InsertEnter).
function M.set_stopped(stopped)
  local ap = package.loaded['nvim-autopairs']
  if ap then
    if stopped then
      ap.disable()
    else
      ap.enable()
    end
  end
end

---------------------------------------------------------------------------
-- <CR>
---------------------------------------------------------------------------

--- Called right after a <CR>: moves the text after the cursor (or `text`)
--- to a line of its own below, without indentation.
function M.close_below(text)
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  local rest = text or vim.trim(line:sub(col + 1))
  vim.api.nvim_buf_set_lines(0, row - 1, row, false, { line:sub(1, col), rest })
  vim.api.nvim_win_set_cursor(0, { row, col })
end

local function close_below_keys(text)
  local arg = text and vim.fn.string(text) or ''
  return k('<CR><Cmd>lua require("user.plugin.autopairs").close_below(' .. arg .. ')<CR>')
end

--- True when a line below closes the < of the current line: `>` at the same
--- indentation, after only blank or more indented lines.
local function closed_below()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local indent = vim.api.nvim_get_current_line():match('^%s*')
  for _, line in ipairs(vim.api.nvim_buf_get_lines(0, row, -1, false)) do
    if line:sub(1, #indent + 1) == indent .. '>' then
      return true
    end
    if not (line:match('^%s*$') or (line:sub(1, #indent) == indent and line:sub(#indent + 1):match('^%s'))) then
      return false
    end
  end
  return false
end

function M.cr()
  if not M.enabled() then
    return k('<CR>')
  end
  local before, after = around()
  if filetype_is(JS_FILETYPES) and after == '' then
    if before:match('=>$') then
      return k(' {<CR>}<C-o>O')
    elseif before:match('=> $') then
      return k('{<CR>}<C-o>O')
    end
  end
  if vmatch(before, [[\v(\<[-=]|[-=]\>)$]]) then
    return k('<CR><Tab>')
  elseif vmatch(before, [[\v(\<[-=]|[-=]\>) $]]) then
    return k('<BS><CR><Tab>')
  end
  if before:match('<$') and after:match('^>') then
    return close_below_keys()
  elseif before:match('<$') and after == '' and not closed_below() then
    return close_below_keys('>')
  end
  local ap = autopairs()
  if ap then
    return ap.autopairs_cr()
  end
  return k('<CR>')
end

---------------------------------------------------------------------------
-- <Space> / <BS>
---------------------------------------------------------------------------

function M.space()
  if not M.enabled() then
    return ' '
  end
  local before, after = around()
  local pair = before:sub(-1) .. after:sub(1, 1)
  if PADDED[pair] then
    return k('  ' .. LEFT)
  elseif pair == '<>' then
    if before:match(' <$') then
      return k('<Del>> ')
    end
    return k(RIGHT)
  end
  return ' '
end

function M.bs()
  if not M.enabled() then
    return k('<BS>')
  end
  local before, after = around()
  local pair = before:sub(-2) .. after:sub(1, 2)
  if pair == '(  )' or pair == '[  ]' or pair == '{  }' then
    return k('<BS><Del>')
  elseif before:sub(-1) == '<' and after:sub(1, 1) == '>' then
    return k('<BS><Del>')
  end
  local ap = autopairs()
  if ap then
    return ap.autopairs_bs()
  end
  return k('<BS>')
end

---------------------------------------------------------------------------
-- <C-l>
---------------------------------------------------------------------------

local CHAN = { 'chan<-', '<-chan', 'chan' }
local CHAN_NEXT = { ['chan'] = '<-chan', ['<-chan'] = 'chan<-', ['chan<-'] = 'chan' }

function M.c_l()
  if not M.enabled() then
    return ''
  end
  local before, after = around()
  -- <x ...>|</x>  ->  <x ... />|
  local open_tag = before:match('<([%w_.-]+)[^>]*>$')
  if open_tag and vim.startswith(after, '</' .. open_tag .. '>') then
    return k('<BS>' .. ('<Del>'):rep(#open_tag + 3) .. ' />')
  end
  -- <x />|  ->  <x>|</x>
  local closed = before:match('<([%w_.-]+) />$')
  if closed then
    return k('<BS><BS><BS>>') .. '</' .. closed .. '>' .. k(LEFT:rep(#closed + 3))
  end
  -- <x ...>|  ->  <x ...>|</x>
  local tag = before:match('<([%w_.-]+)[^>/]*>$')
  if tag then
    return '</' .. tag .. '>' .. k(LEFT:rep(#tag + 3))
  end
  if filetype_is({ go = true }) then
    for _, word in ipairs(CHAN) do
      if vim.endswith(before, word) then
        return k(('<BS>'):rep(#word)) .. CHAN_NEXT[word]
      end
    end
  end
  return ''
end

---------------------------------------------------------------------------
-- Characters
---------------------------------------------------------------------------

function M.char(char)
  if not M.enabled() then
    return char
  end
  local before, after = around()
  if char == '<' then
    if filetype_is(ANGLE_FILETYPES) and not before:match('\\$') then
      return '<>' .. k(LEFT)
    end
  elseif char == '>' then
    if before:match('< $') then
      if after:match('^%S') then
        return k('<BS>> ' .. LEFT)
      end
      return k('<BS>>' .. LEFT)
    elseif after:match('^>') and not before:match('>$') then
      -- retyped rather than stepped over, so that tag closing sees the >
      return k('<Del>>')
    end
  elseif char == '|' then
    if filetype_is({ ruby = true }) then
      if vmatch(before, [[\v(\{|<do)\s*$]]) then
        return '||' .. k(LEFT)
      elseif vmatch(before, [[\v(\{|<do)\s*\|[^|]*$]]) and after:match('^|') then
        return k(RIGHT)
      end
    end
  elseif char == '/' then
    if vmatch(before, [[\*\s$]]) then
      return k('<BS>/')
    end
  end
  return char
end

function M.setup()
  require('nvim-autopairs').setup({
    -- <CR> and <BS> go through user.intelligence and the rules above
    map_cr = false,
    map_bs = false,
    disable_filetype = { 'TelescopePrompt', 'spectre_panel', 'snacks_picker_input' },
    enabled = function(buf)
      return vim.bo[buf].buftype ~= 'nofile'
    end,
  })
  -- ) ] } step over the padding and the closer of `( | )`
  local Rule = require('nvim-autopairs.rule')
  for _, pair in ipairs({ { '(', ')' }, { '[', ']' }, { '{', '}' } }) do
    local rule = Rule(pair[1] .. ' ', ' ' .. pair[2])
      :with_pair(function()
        return false
      end)
      :with_move(function(opts)
        return opts.char == pair[2]
      end)
      :with_del(function()
        return false
      end)
      :with_cr(function()
        return false
      end)
      :use_key(pair[2])
    -- (<Space> stays with the rules above)
    rule.key_end = pair[2]
    require('nvim-autopairs').add_rule(rule)
  end

  -- an escaped quote is typed as is: neither paired nor stepped over
  local function escaped()
    local col = vim.api.nvim_win_get_cursor(0)[2]
    if vim.api.nvim_get_current_line():sub(col, col) == '\\' then
      return false
    end
  end
  for _, quote in ipairs({ '"', "'", '`' }) do
    for _, rule in ipairs(require('nvim-autopairs').get_rules(quote)) do
      if type(rule.pair_cond) == 'table' and type(rule.move_cond) == 'table' then
        table.insert(rule.pair_cond, 1, escaped)
        table.insert(rule.move_cond, 1, escaped)
      end
    end
  end
  if vim.b.user_intelligence_stopped then
    M.set_stopped(true)
  end
end

return M
