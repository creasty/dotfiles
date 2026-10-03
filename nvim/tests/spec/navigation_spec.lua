-- Getting around: alternate files, project root, hop, git, file tree, runner.
local t = require('t')
local probe = require('probe')
local describe, it = t.describe, t.it

--- Runs git in the sandbox, isolated from the user's git config. A last
--- argument `true` lets it fail (a merge that conflicts).
local function git(nvim, ...)
  local args = { ... }
  local allow_failure = args[#args] == true
  if allow_failure then
    table.remove(args)
  end
  local res = vim.system(vim.list_extend({ 'git' }, args), {
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
  assert(allow_failure or res.code == 0, 'git ' .. table.concat(args, ' ') .. ': ' .. (res.stderr or ''))
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

    it('config pairs: .env variants, locales, go.mod <-> go.sum', function()
      local nvim = t.nvim()
      nvim:files({
        ['.env'] = 'x', ['.env.sample'] = 'x',
        ['locales/en.yml'] = 'x', ['locales/ja.yml'] = 'x',
        ['go.mod'] = 'x', ['go.sum'] = 'x',
        ['c/x.c'] = 'x', ['c/x.h'] = 'x',
      })
      for from, to in pairs({
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

    it('recognizes .git, Gemfile, Rakefile, build.sbt, .vimprojectroot and an Xcode project', function()
      local nvim = t.nvim()
      for _, marker in ipairs({ '.git/', 'Gemfile', 'Rakefile', 'build.sbt', '.vimprojectroot', 'App.xcodeproj/' }) do
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

    --- Waits for `count` hop labels: { { line, col, label }, ... }
    local function hop_labels(nvim, count)
      return nvim:wait_for(function()
        local marks = nvim:lua([[
          local out = {}
          for _, m in ipairs(vim.api.nvim_buf_get_extmarks(0, -1, 0, -1, { details = true })) do
            if m[4].virt_text then
              out[#out + 1] = { m[2] + 1, m[3], m[4].virt_text[1][1] }
            end
          end
          return out
        ]])
        return #marks >= count and marks
      end, { message = count .. ' hop labels' })
    end

    it('s{char} labels several matches; typing a label jumps there', function()
      local nvim = t.nvim()
      nvim:set_buffer({ '|a x1 x2', 'x3' })
      nvim:type('sx')
      local target
      for _, l in ipairs(hop_labels(nvim, 3)) do
        if l[1] == 2 then
          target = l
        end
      end
      nvim:type(target[3])
      t.eq({ 2, 0 }, nvim:cursor())
    end)

    it('s{char} does not label the match under the cursor', function()
      local nvim = t.nvim()
      nvim:set_buffer({ '|x1 x2', 'x3' })
      nvim:type('sx')
      hop_labels(nvim, 2)
      nvim:sleep(200)
      local labels = hop_labels(nvim, 2)
      t.eq({ { 1, 3 }, { 2, 0 } }, vim.tbl_map(function(l)
        return { l[1], l[2] }
      end, labels))
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

    it(':GBrowse! ignores a hash-like word under the cursor (a long number)', function()
      local nvim = t.nvim()
      repo(nvim, { ['a.txt'] = { 'at = 1790723329' } }, 'git@github.com:acme/app.git')
      nvim:edit('a.txt')
      nvim:set_cursor(1, 7)
      nvim:cmd('GBrowse!')
      t.eq('https://github.com/acme/app/blob/main/a.txt', nvim:getreg('+'))
    end)

    it(':GBrowse opens the URL in the browser', function()
      local nvim = t.nvim()
      repo(nvim, { ['a.txt'] = { 'x' } }, 'git@github.com:acme/app.git')
      nvim:edit('a.txt')
      nvim:lua('vim.ui.open = function(url) vim.g.e2e_opened = url end')
      nvim:cmd('GBrowse')
      t.eq('https://github.com/acme/app/blob/main/a.txt', nvim:eval('g:e2e_opened'))
    end)

    it(':GBlame shows who changed each line beside the file, o the commit of one, and q closes each', function()
      local nvim = t.nvim()
      local sha = repo(nvim, { ['a.txt'] = { 'x' } })
      nvim:edit('a.txt')
      probe.wait_git(nvim)
      nvim:cmd('GBlame')
      local lines = nvim:wait_for(function()
        return probe.blame_view(nvim)
      end, { message = 'the blame view' })
      t.match('e2e', lines[1])
      local function commit_shown()
        return nvim:lua(
          [[
          for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
            if vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(w)):find(..., 1, true) then
              return true
            end
          end
          return false
        ]],
          sha
        )
      end
      nvim:type('o')
      nvim:wait_for(commit_shown, { message = "a window with the line's commit" })
      nvim:type('q')
      nvim:wait_for(function()
        return not commit_shown()
      end, { message = 'the commit to close' })
      -- (the blame is the leftmost window)
      nvim:cmd('wincmd t')
      nvim:type('q')
      nvim:wait_for(function()
        return probe.blame_view(nvim) == nil
      end, { message = 'the blame to close' })
    end)

    it(':GBlame shows the lines of the commit under the cursor as faintly as a changed line in a diff', function()
      local nvim = t.nvim()
      repo(nvim, { ['a.txt'] = { 'x', 'y' } })
      nvim:edit('a.txt')
      probe.wait_git(nvim)
      nvim:cmd('GBlame')
      nvim:wait_for(function()
        return probe.blame_view(nvim)
      end, { message = 'the blame view' })
      nvim:type('jk')
      local last
      local ok = pcall(nvim.wait_for, nvim, function()
        last = probe.blame_backgrounds(nvim)
        return last and last.line == last.changed
      end)
      t.ok(ok, 'backgrounds: ' .. vim.inspect(last))
    end)

    it(':DiffviewOpen lists the unstaged and the staged changes, and diffs the first', function()
      local nvim = t.nvim()
      repo(nvim, { ['a.txt'] = { 'a' }, ['b.txt'] = { 'b' } })
      nvim:write_file('a.txt', { 'a changed' })
      nvim:write_file('b.txt', { 'b changed' })
      git(nvim, 'add', 'b.txt')
      nvim:cmd('DiffviewOpen')
      local view = probe.wait_diff_view(nvim, function(v)
        return v.files:find('b%.txt') and #v.sides == 2
      end)
      -- a.txt among the changes, b.txt among the staged ones after them
      local a, staged, b = view.files:find('a%.txt'), view.files:find('[Ss]taged'), view.files:find('b%.txt')
      t.ok(a and staged and b and a < staged and staged < b, view.files)
      t.eq({ { 'a' }, { 'a changed' } }, view.sides)
      -- no fold column beside the diff
      t.eq({ '0', '0' }, nvim:lua([[
        local columns = {}
        for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
          if vim.wo[w].diff then
            columns[#columns + 1] = vim.wo[w].foldcolumn
          end
        end
        return columns
      ]]))
    end)

    it(':DiffviewOpen closes on q, from the file list and from the diff', function()
      local nvim = t.nvim()
      repo(nvim, { ['a.txt'] = { 'a' } })
      nvim:write_file('a.txt', { 'a changed' })
      for _, from_diff in ipairs({ false, true }) do
        nvim:cmd('DiffviewOpen')
        probe.wait_diff_view(nvim, function(v)
          return #v.sides == 2
        end)
        if from_diff then
          nvim:cmd('wincmd l')
        end
        nvim:type('q')
        nvim:wait_for(function()
          return probe.diff_view(nvim) == nil
        end, { message = 'the view to close' })
      end
    end)

    it(':DiffviewOpen main...HEAD lists what the branch changed since it forked', function()
      local nvim = t.nvim()
      repo(nvim, { ['a.txt'] = { 'a' }, ['b.txt'] = { 'b' } })
      git(nvim, 'checkout', '-q', '-b', 'feature')
      nvim:write_file('b.txt', { 'b on feature' })
      nvim:write_file('c.txt', { 'c' })
      git(nvim, 'add', '-A')
      git(nvim, 'commit', '-q', '-m', 'feature')
      git(nvim, 'checkout', '-q', 'main')
      nvim:write_file('d.txt', { 'd' })
      git(nvim, 'add', '-A')
      git(nvim, 'commit', '-q', '-m', 'main moves on')
      git(nvim, 'checkout', '-q', 'feature')
      nvim:cmd('DiffviewOpen main...HEAD')
      local view = probe.wait_diff_view(nvim, function(v)
        return v.files:find('b%.txt') and v.files:find('c%.txt')
      end)
      t.no_match('a%.txt', view.files)
      t.no_match('d%.txt', view.files)
    end)

    it(':DiffviewOpen shows a merge conflict as ours | the file | theirs', function()
      local nvim = t.nvim()
      repo(nvim, { ['a.txt'] = { 'a', 'x', 'b' } })
      git(nvim, 'checkout', '-q', '-b', 'other')
      nvim:write_file('a.txt', { 'a', 'X-other', 'b' })
      git(nvim, 'commit', '-q', '-am', 'other')
      git(nvim, 'checkout', '-q', 'main')
      nvim:write_file('a.txt', { 'a', 'X-main', 'b' })
      git(nvim, 'commit', '-q', '-am', 'main')
      git(nvim, 'merge', '-q', 'other', true)
      nvim:cmd('DiffviewOpen')
      local view = probe.wait_diff_view(nvim, function(v)
        return #v.sides == 3
      end)
      t.match('a%.txt', view.files)
      t.eq({ 'a', 'X-main', 'b' }, view.sides[1])
      t.contains(view.sides[2], '<<<<<<< HEAD')
      t.eq({ 'a', 'X-other', 'b' }, view.sides[3])
    end)
  end)

  describe('explorer', function()
    it(':e {dir} opens it, showing dotfiles but not .git or backup files', function()
      local nvim = t.nvim()
      nvim:files({ ['.git/'] = true, ['.env'] = 'x', ['notes.txt~'] = 'x', ['visible.txt'] = 'x' })
      nvim:cmd('edit .')
      local picker = probe.wait_picker(nvim, function(p)
        return p.source == 'explorer' and #p.items > 1
      end)
      local text = table.concat(picker.items, '\n')
      t.match('%.env', text)
      t.match('visible%.txt', text)
      t.no_match('%.git', text)
      t.no_match('notes%.txt~', text)
    end)

    it('nvim {dir} opens it in a sidebar 40 columns wide, focused', function()
      local nvim = t.nvim({ args = { '.' } })
      local picker = probe.wait_picker(nvim, function(p)
        return p.source == 'explorer'
      end)
      t.eq('list', picker.focus)
      t.eq(40, nvim:lua('return vim.api.nvim_win_get_width(0)'))
    end)
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

  it(',r runs the current file and shows its output in a split 15 lines high, across the bottom', function()
    local nvim = t.nvim()
    nvim:edit('hello.sh', { 'echo hello-from-quickrun' })
    nvim:type(',r')
    local win = quickrun_window(nvim)
    t.eq(15, win.height)
    t.eq(0, win.col)
    t.ok(win.row > 0, 'below the file')
  end)
end)
