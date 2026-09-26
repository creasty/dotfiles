-- Getting around: alternate files, project root, hop, git, file tree, runner.
local t = require('t')
local describe, it = t.describe, t.it

--- Runs git in the sandbox, isolated from the user's git config.
local function git(nvim, ...)
  local res = vim.system({ 'git', ... }, {
    cwd = nvim.dir,
    text = true,
    env = {
      GIT_CONFIG_NOSYSTEM = '1',
      GIT_CONFIG_GLOBAL = '/dev/null',
      GIT_AUTHOR_NAME = 'e2e',
      GIT_AUTHOR_EMAIL = 'e2e@example.com',
      GIT_COMMITTER_NAME = 'e2e',
      GIT_COMMITTER_EMAIL = 'e2e@example.com',
    },
  }):wait()
  assert(res.code == 0, 'git ' .. table.concat({ ... }, ' ') .. ': ' .. (res.stderr or ''))
  return vim.trim(res.stdout or '')
end

local function repo(nvim, files, remote)
  nvim:files(files)
  git(nvim, 'init', '-q', '-b', 'main')
  git(nvim, 'add', '-A')
  git(nvim, 'commit', '-q', '-m', 'init')
  if remote then
    git(nvim, 'remote', 'add', 'origin', remote)
  end
  return git(nvim, 'rev-parse', 'HEAD')
end

local function current_file(nvim)
  return nvim:call('fnamemodify', nvim:bufname(), ':.')
end

describe('Navigation', function()
  describe('alternate files (ga / gA)', function()
    it('go: toggles between x.go and x_test.go', function()
      local nvim = t.nvim()
      nvim:files({ ['svc.go'] = 'package x', ['svc_test.go'] = 'package x' })
      nvim:edit('svc.go')
      nvim:type('ga')
      t.eq('svc_test.go', current_file(nvim))
      nvim:type('ga')
      t.eq('svc.go', current_file(nvim))
      nvim:type('gA')
      t.eq('svc_test.go', current_file(nvim))
    end)

    t.quirk(
      'go: x_mock.go / x_ex_test.go are not reached from x.go or x_test.go',
      'x_test.go also matches the %.go pattern (as "x_test"), so the four-file rule collapses into a source/test toggle',
      function()
        local nvim = t.nvim()
        nvim:files({ ['svc.go'] = 'package x', ['svc_test.go'] = 'package x', ['svc_mock.go'] = 'package x' })
        nvim:edit('svc.go')
        local seen = {}
        for _ = 1, 3 do
          nvim:type('ga')
          seen[#seen + 1] = current_file(nvim)
        end
        t.eq({ 'svc_test.go', 'svc.go', 'svc_test.go' }, seen)
      end
    )

    it('rails: model -> spec -> factory', function()
      local nvim = t.nvim()
      nvim:files({ ['app/models/user.rb'] = 'x', ['spec/models/user_spec.rb'] = 'x', ['spec/factories/users.rb'] = 'x' })
      nvim:edit('app/models/user.rb')
      nvim:type('ga')
      t.eq('spec/models/user_spec.rb', current_file(nvim))
      nvim:type('ga')
      t.eq('spec/factories/users.rb', current_file(nvim))
    end)

    it('typescript: module -> test -> component -> story', function()
      local nvim = t.nvim()
      nvim:files({ ['ui/Button.ts'] = 'x', ['ui/Button.test.ts'] = 'x', ['ui/Button.tsx'] = 'x', ['ui/Button.stories.tsx'] = 'x' })
      nvim:edit('ui/Button.ts')
      local seen = {}
      for _ = 1, 4 do
        nvim:type('ga')
        seen[#seen + 1] = current_file(nvim)
      end
      t.eq({ 'ui/Button.test.ts', 'ui/Button.tsx', 'ui/Button.stories.tsx', 'ui/Button.ts' }, seen)
    end)

    it('config pairs: default.toml <-> lazy.toml, .env variants, locales, go.mod <-> go.sum', function()
      local nvim = t.nvim()
      nvim:files({
        ['dein/default.toml'] = 'x', ['dein/lazy.toml'] = 'x',
        ['.env'] = 'x', ['.env.sample'] = 'x',
        ['locales/en.yml'] = 'x', ['locales/ja.yml'] = 'x',
        ['go.mod'] = 'x', ['go.sum'] = 'x',
        ['c/x.c'] = 'x', ['c/x.h'] = 'x',
      })
      for from, to in pairs({
        ['dein/default.toml'] = 'dein/lazy.toml',
        ['.env'] = '.env.sample',
        ['locales/en.yml'] = 'locales/ja.yml',
        ['go.mod'] = 'go.sum',
        ['c/x.c'] = 'c/x.h',
      }) do
        nvim:edit(from)
        nvim:type('ga')
        t.eq(to, current_file(nvim), from)
      end
    end)
  end)

  describe('project root', function()
    it('opening a project file from $HOME sets the window directory to the project root', function()
      local nvim = t.nvim()
      nvim:files({ ['proj/package.json'] = '{}', ['proj/src/deep/file.ts'] = 'x' })
      nvim:cmd('cd ~')
      nvim:edit('proj/src/deep/file.ts')
      t.eq(nvim:path('proj'), nvim:call('getcwd'))
      t.eq(1, nvim:call('haslocaldir'))
      t.match(vim.pesc(nvim:path('proj')), nvim:eval('&l:path'))
    end)

    it('recognizes .git, Gemfile, Rakefile, build.sbt and .vimprojectroot', function()
      local nvim = t.nvim()
      for _, marker in ipairs({ '.git/', 'Gemfile', 'Rakefile', 'build.sbt', '.vimprojectroot' }) do
        local dir = 'p-' .. marker:gsub('[^%w]', '')
        nvim:files({ [dir .. '/' .. marker] = marker:sub(-1) == '/' or 'x', [dir .. '/a/b.txt'] = 'x' })
        nvim:cmd('cd ~')
        nvim:edit(dir .. '/a/b.txt')
        t.eq(nvim:path(dir), nvim:call('getcwd'), marker)
      end
    end)

    it('leaves the directory alone when not started from $HOME', function()
      local nvim = t.nvim()
      nvim:files({ ['proj/package.json'] = '{}', ['proj/src/file.ts'] = 'x' })
      nvim:edit('proj/src/file.ts')
      t.eq(nvim.dir, nvim:call('getcwd'))
    end)
  end)

  describe('hop', function()
    it('s{char} jumps straight to the only match on screen', function()
      local nvim = t.nvim()
      nvim:set_buffer({ '|aaa bbb', 'ccc Zdd eee' })
      nvim:type('sZ')
      t.eq({ 2, 4 }, nvim:cursor())
    end)

    it('s{char} labels several matches; typing a label jumps there', function()
      local nvim = t.nvim()
      nvim:set_buffer({ '|x1 x2', 'x3' })
      nvim:type('sx')
      local labels = nvim:wait_for(function()
        local marks = nvim:lua([[
          local out = {}
          for _, m in ipairs(vim.api.nvim_buf_get_extmarks(0, -1, 0, -1, { details = true })) do
            if m[4].virt_text then
              out[#out + 1] = { m[2] + 1, m[3], m[4].virt_text[1][1] }
            end
          end
          return out
        ]])
        return #marks >= 3 and marks
      end)
      local target
      for _, l in ipairs(labels) do
        if l[1] == 2 then
          target = l
        end
      end
      nvim:type(target[3])
      t.eq({ 2, 0 }, nvim:cursor())
    end)
  end)

  describe('git', function()
    it(':GBrowse! copies the GitHub URL of the file (branch) or of lines (permalink)', function()
      local nvim = t.nvim()
      local sha = repo(nvim, { ['lib/app.rb'] = { 'a', 'b', 'c', 'd' } }, 'git@github.com:acme/app.git')
      nvim:edit('lib/app.rb')
      nvim:cmd('GBrowse!')
      t.eq('https://github.com/acme/app/blob/main/lib/app.rb', nvim:getreg('+'))
      nvim:cmd('3GBrowse!')
      t.eq(('https://github.com/acme/app/blob/%s/lib/app.rb#L3'):format(sha), nvim:getreg('+'))
      nvim:cmd('2,4GBrowse!')
      t.eq(('https://github.com/acme/app/blob/%s/lib/app.rb#L2-L4'):format(sha), nvim:getreg('+'))
    end)

    it(':GBrowse! works with https remotes too', function()
      local nvim = t.nvim()
      repo(nvim, { ['a.txt'] = { 'x' } }, 'https://github.com/acme/app.git')
      nvim:edit('a.txt')
      nvim:cmd('GBrowse!')
      t.eq('https://github.com/acme/app/blob/main/a.txt', nvim:getreg('+'))
    end)

    it(':GBlame opens the blame view', function()
      local nvim = t.nvim()
      repo(nvim, { ['a.txt'] = { 'x' } })
      nvim:edit('a.txt')
      nvim:cmd('GBlame')
      nvim:wait_for(function()
        return nvim:lua([[
          for _, w in ipairs(vim.api.nvim_list_wins()) do
            if vim.bo[vim.api.nvim_win_get_buf(w)].filetype == 'fugitiveblame' then
              return true
            end
          end
        ]])
      end)
    end)
  end)

  it(':NERDTree shows dotfiles but hides .git and backup files', function()
    local nvim = t.nvim()
    nvim:files({ ['.git/'] = true, ['.env'] = 'x', ['notes.txt~'] = 'x', ['visible.txt'] = 'x' })
    nvim:cmd('NERDTree')
    local text = table.concat(nvim:lines(), '\n')
    t.match('%.env', text)
    t.match('visible%.txt', text)
    t.no_match('%.git/', text)
    t.no_match('notes%.txt~', text)
  end)

  local function quickrun_window(nvim)
    return nvim:wait_for(function()
      return nvim:lua([[
        for _, w in ipairs(vim.api.nvim_list_wins()) do
          local lines = vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(w), 0, -1, false)
          if table.concat(lines, '\n'):find('hello-from-quickrun', 1, true) and vim.bo[vim.api.nvim_win_get_buf(w)].buftype ~= '' then
            local pos = vim.api.nvim_win_get_position(w)
            return { height = vim.api.nvim_win_get_height(w), row = pos[1], col = pos[2] }
          end
        end
      ]])
    end)
  end

  it(',r runs the current file and shows its output in a split', function()
    local nvim = t.nvim()
    nvim:edit('hello.sh', { 'echo hello-from-quickrun' })
    nvim:type(',r')
    quickrun_window(nvim)
  end)

  t.quirk(
    ',r opens the output with quickrun\'s default layout, not :botright 15sp',
    "the config sets 'outputter/buffer/split', but quickrun's option is 'outputter/buffer/opener'",
    function()
      local nvim = t.nvim()
      nvim:edit('hello.sh', { 'echo hello-from-quickrun' })
      nvim:type(',r')
      local win = quickrun_window(nvim)
      t.neq(15, win.height)
    end
  )
end)
