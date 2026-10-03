-- While a window's directory is $HOME (Neovim started from a new terminal or
-- the Dock), sets it to the root of the project of the file it shows: the
-- nearest directory above the file with .git, or failing that a Rakefile, and
-- so on down the markers. The root joins the buffer's 'path' too.

local markers = {
  '.git',
  'Rakefile',
  'Gemfile',
  'package.json',
  '.vimprojectroot',
  function(name)
    return name:match('%.xcodeproj$') ~= nil
  end,
  'build.sbt',
}

vim.api.nvim_create_autocmd({ 'BufRead', 'BufEnter', 'WinEnter', 'TabEnter' }, {
  group = vim.api.nvim_create_augroup('project_dir', {}),
  callback = function()
    -- (a file, not a URL such as a terminal's term://...)
    if vim.bo.buftype ~= '' or vim.api.nvim_buf_get_name(0):match('^%w+://') or vim.fn.getcwd() ~= vim.env.HOME then
      return
    end
    local root = vim.fs.root(0, markers)
    if root then
      vim.opt_local.path:append(root)
      vim.cmd('lcd ' .. vim.fn.fnameescape(root))
    end
  end,
})
