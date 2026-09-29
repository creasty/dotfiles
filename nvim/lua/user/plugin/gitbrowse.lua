-- :GBrowse opens the file on GitHub, on its branch; with a range, it links the
-- lines on the file's last commit. :GBrowse! copies the URL instead.

local M = {}

-- GitHub's URLs without the cursor's line that snacks adds by default, and
-- with #L3 for a single line
local github = {
  file = function(fields)
    if not fields.file then
      return ('/tree/%s'):format(fields.branch)
    end
    return ('/blob/%s/%s'):format(fields.branch, fields.file)
  end,
  permalink = function(fields)
    local lines = ('#L%d'):format(fields.line_start)
    if fields.line_end ~= fields.line_start then
      lines = ('%s-L%d'):format(lines, fields.line_end)
    end
    return ('/blob/%s/%s%s'):format(fields.commit, fields.file, lines)
  end,
}

function M.setup()
  vim.api.nvim_create_user_command('GBrowse', function(opts)
    local range = opts.range > 0
    Snacks.gitbrowse.open({
      what = range and 'permalink' or 'file',
      line_start = range and opts.line1 or nil,
      line_end = range and opts.line2 or nil,
      -- Given no commit, snacks takes a hash-like word under the cursor for
      -- one, and fails when it's not (a long number too)
      commit = not range and 'HEAD' or nil,
      url_patterns = { ['github%.com'] = github },
      notify = false,
      open = function(url)
        if opts.bang then
          vim.fn.setreg('+', url)
        else
          vim.ui.open(url)
        end
        vim.api.nvim_echo({ { url } }, false, {})
      end,
    })
  end, { range = true, bang = true, desc = 'Open the file on GitHub (! copies the URL)' })
end

return M
