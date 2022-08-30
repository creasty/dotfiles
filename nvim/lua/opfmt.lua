local parsers = require 'nvim-treesitter.parsers'

local M = {}

function M.init()
  require 'nvim-treesitter'.define_modules {
    opfmt = {
      module_path = 'opfmt.internal',
      is_supported = function(lang)
        return parsers.has_parser(lang)
      end
    }
  }
end

return M
