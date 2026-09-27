-- nvim-treesitter's master branch and nvim-treesitter-endwise register their
-- query predicates and directives with `all = false`: handlers that get one
-- node per capture. Neovim 0.12 dropped the option and always passes a list
-- of nodes, which breaks them (e.g. markdown code blocks, as in hover docs).
-- This brings the option back, as Neovim 0.11 had it, until the tree-sitter
-- stack moves to nvim-treesitter's `main`. Load it before nvim-treesitter.

if vim.fn.has('nvim-0.12') == 0 then
  return
end

local query = vim.treesitter.query

--- `handler` called with the last node of each capture.
local function last_nodes(handler, numbered_only)
  return function(match, ...)
    local m = {}
    for k, v in pairs(match) do
      if not numbered_only or type(k) == 'number' then
        m[k] = v[#v]
      end
    end
    return handler(m, ...)
  end
end

local add_predicate = query.add_predicate
query.add_predicate = function(name, handler, opts)
  if type(opts) == 'table' and opts.all == false then
    handler = last_nodes(handler, true)
  end
  return add_predicate(name, handler, opts)
end

local add_directive = query.add_directive
query.add_directive = function(name, handler, opts)
  if type(opts) == 'table' and opts.all == false then
    handler = last_nodes(handler, false)
  end
  return add_directive(name, handler, opts)
end
