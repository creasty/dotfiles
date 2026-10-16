-- Filetypes Neovim doesn't detect, or detects otherwise
vim.filetype.add({
  filename = {
    ['.env'] = 'sh',
    -- (the templates' filetype: nvim/template/license)
    LICENSE = 'license',
    ['LICENSE.txt'] = 'license',
  },
  pattern = {
    -- (above Neovim's own pattern for env)
    ['%.env%..*'] = { 'sh', { priority = 1 } },
    -- compound filetypes
    ['.*%.bq%.sql'] = 'sql.bq',
    ['.*%.pg%.sql'] = 'sql.pg',
  },
})
