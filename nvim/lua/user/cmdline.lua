-- Command-line shortcuts, expanded as you type them:
--
--   :'          :'<,'>                    (the visual range)
--   :w!!        :w !sudo tee % > /dev/null
--   :ee         :e <dir of the current file>/
--   :ef         :e <current file>
--   :er         :Rename <current file>
--   :eh :eg :ev :e ~/  ~/go/src/github.com/  $VIMRUNTIME/
--   :s/         :s/\v|//g, with any of / ~ ! @ # % : as the delimiter,
--               after % or '<,'> too; :sc/ adds \C, :si/ \c, and :sm/
--               starts a case-preserving :Subs/|/ (text-case.nvim)
--   / and ?     escaped inside a search for / and ? respectively

local M = {}

local k = vim.keycode

local DELIMITERS = { '/', '~', '!', '@', '#', '%', ':' }

local DIRECTORIES = {
  h = '~',
  g = '~/go/src/github.com',
  v = vim.env.VIMRUNTIME,
}

--- Literal text for the command line (no key notation inside).
local function text(s)
  return s
end

--- The command line up to the cursor, when typing an Ex command.
local function before_cursor()
  if vim.fn.getcmdtype() ~= ':' then
    return nil
  end
  return vim.fn.getcmdline():sub(1, vim.fn.getcmdpos() - 1)
end

local function substitute(char, before)
  local range = before:match("^(%%?)s(%a?)$") and { before:match("^(%%?)s(%a?)$") }
    or before:match("^('<,'>)s(%a?)$") and { before:match("^('<,'>)s(%a?)$") }
  if not range then
    return nil
  end
  local flag = range[2]
  local after = char .. char .. 'g' .. k(('<Left>'):rep(3))
  if flag == '' then
    return char .. '\\v' .. after
  elseif flag == 'c' then
    return k('<BS>') .. char .. '\\C\\v' .. after
  elseif flag == 'i' then
    return k('<BS>') .. char .. '\\c\\v' .. after
  elseif flag == 'm' then
    return k('<BS><BS>') .. 'Subs' .. char .. char .. k('<Left>')
  end
end

local function expand(char)
  local before = before_cursor()
  if not before then
    return char
  end
  if char == "'" and before == '' then
    return "'<,'>"
  end
  if char == '!' and before == 'w!' then
    return k('<C-u>') .. 'w !sudo tee % > /dev/null'
  end
  if before == 'e' then
    if char == 'e' then
      return text(' ' .. vim.fn.fnameescape(vim.fn.expand('%:p:h')) .. '/')
    elseif char == 'f' then
      return text(' ' .. vim.fn.fnameescape(vim.fn.expand('%:p')))
    elseif char == 'r' then
      return k('<C-u>') .. text('Rename ' .. vim.fn.fnameescape(vim.fn.expand('%:p')))
    elseif DIRECTORIES[char] then
      return text(' ' .. DIRECTORIES[char] .. '/')
    end
  end
  if vim.tbl_contains(DELIMITERS, char) then
    return substitute(char, before) or char
  end
  return char
end

--- Escapes / in a / search and ? in a ? search.
local function escape_search(char)
  if vim.fn.getcmdtype() ~= char then
    return expand(char)
  end
  local before = vim.fn.getcmdline():sub(1, vim.fn.getcmdpos() - 1)
  if before:sub(-1) == '\\' then
    return char
  end
  return '\\' .. char
end

function M.setup()
  local chars = { "'", 'e', 'f', 'r', 'h', 'g', 'v' }
  vim.list_extend(chars, DELIMITERS)
  for _, char in ipairs(chars) do
    if char ~= '/' then
      vim.keymap.set('c', char, function()
        return expand(char)
      end, { expr = true, replace_keycodes = false })
    end
  end
  for _, char in ipairs({ '/', '?' }) do
    vim.keymap.set('c', char, function()
      return escape_search(char)
    end, { expr = true, replace_keycodes = false })
  end
end

return M
