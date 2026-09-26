-- File templates (mold.vim): `:Template` picks a template from the path and
-- filetype, `:Template {name}` by name; macros (FILE_NAME, FULL_NAME, ...)
-- and ERB are expanded, and the cursor lands on <+CURSOR+>.
-- Dynamic templates are pinned in golden/templates.txt (‸ = cursor); static
-- ones must equal their file.
local t = require('t')
local env = require('env')
local describe, it = t.describe, t.it

local TEMPLATES = env.config_dir .. '/template'

-- { template, file to create, [:Template argument], [filetype to force] }
local CASES = {
  { 'c/main.c', 'main.c' },
  { 'c/socket_server.c', 'socket_server.c' },
  { 'c/template.h', 'util.h' },
  { 'cpp/main.cpp', 'main.cpp' },
  { 'cpp/template.h', 'util.h', nil, 'cpp' },
  { 'go/template.go', 'pkg/user_repo.go' },
  { 'go/api/template.go', 'api/users_handler.go' },
  { 'graphql/fragments/template.graphql', 'graphql/fragments/user.graphql' },
  { 'graphql/mutations/template.graphql', 'graphql/mutations/create_user.graphql' },
  { 'graphql/queries/template.graphql', 'graphql/queries/get_user.graphql' },
  { 'html/base.html', 'base.html' },
  { 'license/mit', 'LICENSE', 'mit' },
  { 'license/apache2', 'LICENSE', 'apache2' },
  { 'license/gpl3', 'LICENSE', 'gpl3' },
  { 'make/Makefile', 'Makefile' },
  { 'markdown/README.md', 'README.md' },
  { 'ruby/app/controllers/template_controller.rb', 'app/controllers/admin/users_controller.rb' },
  { 'ruby/app/jobs/template_job.rb', 'app/jobs/sync_job.rb' },
  { 'ruby/app/models/template.rb', 'app/models/admin/user_profile.rb' },
  { 'ruby/app/services/template_service.rb', 'app/services/billing_service.rb' },
  { 'ruby/app/template_concern.rb', 'app/models/concerns/taggable_concern.rb' },
  { 'ruby/lib/template.rb', 'lib/acme/client.rb' },
  { 'ruby/lib/template/version.rb', 'lib/acme/version.rb' },
  { 'sh/template', 'bin/script.sh' },
  { 'tla/template.tla', 'Spec.tla' },
  { 'typescript/resolvers/mutations/template.ts', 'resolvers/mutations/createUser.ts' },
  { 'typescript/resolvers/queries/template.ts', 'resolvers/queries/getUser.ts' },
  { 'vim/template.vim', 'plugin/my_plugin.vim' },
  { '_/template.ssh/config.d/template', '.ssh/config.d/work' },
  { 'gitignore/template.gitignore', '.gitignore' },
  { 'gitignore/node.gitignore', '.gitignore', 'node' },
  { 'gitignore/go.gitignore', '.gitignore', 'go' },
}

local function is_dynamic(lines)
  local text = table.concat(lines, '\n')
  for _, marker in ipairs({ '<%', '<+CURSOR+>', 'FILE_PATH', 'FILE_NAME', 'FILE_BASE_NAME', 'FULL_NAME', 'USER_NAME' }) do
    if text:find(marker, 1, true) then
      return true
    end
  end
  return false
end

local function apply(nvim, file, arg, filetype)
  nvim:edit(file)
  if filetype then
    nvim:cmd('set filetype=' .. filetype)
  end
  nvim:cmd('Template' .. (arg and (' ' .. arg) or ''))
  local text = table.concat(nvim:buffer({ marker = '‸' }), '\n')
  text = text:gsub(vim.pesc(nvim.dir), '<SANDBOX>')
  text = text:gsub('%d%d%d%d%-%d%d%-%d%d', '<DATE>')
  text = text:gsub('20%d%d', '<YEAR>')
  return text
end

describe('Templates', function()
  for _, case in ipairs(CASES) do
    local template, file, arg, filetype = case[1], case[2], case[3], case[4]
    local label = (':Template%s in %s%s loads %s'):format(arg and (' ' .. arg) or '', file, filetype and (' (ft=' .. filetype .. ')') or '', template)
    it(label, function()
      local nvim = t.nvim()
      nvim:cmd('AutoSaveToggle')
      local source = vim.fn.readfile(TEMPLATES .. '/' .. template)
      local text = apply(nvim, file, arg, filetype)
      if is_dynamic(source) then
        t.golden_section('templates.txt', template .. ' @ ' .. file, text)
      else
        t.eq(table.concat(source, '\n'), (text:gsub('‸', '')))
      end
    end)
  end

  t.quirk(
    ':Template in Main.java inserts a Ruby error instead of the class',
    "template/java/main.java calls File.dirname('FILE_NAME', '.java'); it needs File.basename",
    function()
      local nvim = t.nvim()
      nvim:cmd('AutoSaveToggle')
      local text = apply(nvim, 'Main.java')
      t.match('Error', text)
      t.no_match('public class Main', text)
    end
  )

  t.quirk(
    ':Template in a *_spec.rb file finds no template',
    'mold looks templates up by &filetype, which is ruby.rspec for specs, and there is no template/ruby.rspec/',
    function()
      local nvim = t.nvim()
      nvim:cmd('AutoSaveToggle')
      local text = apply(nvim, 'spec/models/user_spec.rb')
      t.eq('‸', text)
    end
  )

  t.quirk(
    ':Template in a *.stories.tsx file finds no template',
    'mold looks templates up by &filetype, which is typescriptreact, while the template lives in template/typescript/',
    function()
      local nvim = t.nvim()
      nvim:cmd('AutoSaveToggle')
      local text = apply(nvim, 'src/Button.stories.tsx')
      t.eq('‸', text)
    end
  )

  it('every template is covered by a test', function()
    local covered = {}
    for _, case in ipairs(CASES) do
      covered[case[1]] = true
    end
    covered['java/main.java'] = true -- see the quirk above
    covered['ruby/spec/template_spec.rb'] = true -- see the quirk above
    covered['typescript/template.stories.tsx'] = true -- see the quirk above
    local missing = {}
    for name, type in vim.fs.dir(TEMPLATES, { depth = 10 }) do
      if type == 'file' and not covered[name] and not name:match('%.gitignore$') and not name:match('%.DS_Store$') then
        missing[#missing + 1] = name
      end
    end
    table.sort(missing)
    t.eq({}, missing, 'add these templates to CASES in spec/templates_spec.lua')
  end)
end)
