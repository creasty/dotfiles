-- nvim-treesitter-endwise registers its query directive with `all = false`:
-- a handler that gets one node per capture. Neovim 0.12 dropped the option and
-- always passes a list of nodes, which breaks it (e.g. no `endfunction` after
-- `function` in Vim script). This brings the option back for directives, as
-- Neovim 0.11 had it, until endwise takes lists. Load it before the
-- tree-sitter plugins.

local query = vim.treesitter.query

--- `handler` called with the last node of each capture.
local function last_nodes(handler)
  return function(match, ...)
    local m = {}
    for k, v in pairs(match) do
      m[k] = v[#v]
    end
    return handler(m, ...)
  end
end

local add_directive = query.add_directive
query.add_directive = function(name, handler, opts)
  if type(opts) == 'table' and opts.all == false then
    handler = last_nodes(handler)
  end
  return add_directive(name, handler, opts)
end
