-- Filetype detection, per-filetype settings and ftplugin commands.
local t = require('t')
local describe, it = t.describe, t.it

describe('Filetypes', function()
  describe('detection', function()
    for name, filetype in pairs({
      ['.env'] = 'sh',
      ['.env.local'] = 'sh',
      ['shader.frag'] = 'glsl',
      ['shader.vert'] = 'glsl',
      ['.gitattributes'] = 'gitattributes',
      ['LICENSE'] = 'license',
      ['LICENSE.txt'] = 'license',
      ['user_spec.rb'] = 'ruby',
      ['query.bq.sql'] = 'sql.bq',
      ['query.pg.sql'] = 'sql.pg',
    }) do
      it(('%s is %s'):format(name, filetype), function()
        local nvim = t.nvim()
        nvim:edit('dir/' .. name)
        t.eq(filetype, nvim:filetype())
      end)
    end
  end)

  describe('settings', function()
    --- { expandtab, tabstop, effective shiftwidth }
    local function settings(nvim, name)
      nvim:edit(name)
      return nvim:eval('[&l:expandtab, &l:tabstop, shiftwidth()]')
    end

    it('indentation per filetype', function()
      local nvim = t.nvim()
      nvim:cmd('AutoSaveToggle')
      local expected = {
        ['a.go'] = { 0, 4, 4 },
        ['a.c'] = { 1, 4, 4 },
        ['A.java'] = { 1, 4, 4 },
        ['a.swift'] = { 1, 4, 4 },
        ['a.html'] = { 1, 2, 2 },
        ['a.js'] = { 1, 2, 2 },
        ['a.ts'] = { 1, 2, 2 },
        ['a.tsx'] = { 1, 2, 2 },
        ['a.rb'] = { 1, 2, 2 },
        ['a.py'] = { 1, 4, 4 },
        ['a.scala'] = { 1, 4, 2 },
      }
      local actual = {}
      for name in pairs(expected) do
        actual[name] = settings(nvim, name)
      end
      t.eq(expected, actual)
    end)

    it('ruby words include ! and ?; yaml words include -', function()
      local nvim = t.nvim()
      nvim:edit('a.rb', { 'valid? save!' })
      t.eq('valid?', nvim:call('expand', '<cword>'))
      nvim:edit('a.yml', { 'foo-bar: 1' })
      t.eq('foo-bar', nvim:call('expand', '<cword>'))
    end)

    it('yaml does not reindent a line when - starts it', function()
      local nvim = t.nvim()
      nvim:edit('a.yml')
      t.eq('!^F,o,O,0},0],<:>', nvim:eval('&l:indentkeys'))
    end)

    it('markdown folds by heading', function()
      local nvim = t.nvim()
      nvim:edit('a.md', { '# One', 'text', '## Two', 'more', 'Three', '=====', 'x' })
      t.eq('expr', nvim:eval('&l:foldmethod'))
      t.eq({ 1, 1, 2, 2, 1, 1, 1 }, nvim:lua([[
        local levels = {}
        for l = 1, vim.fn.line('$') do levels[l] = vim.fn.foldlevel(l) end
        return levels
      ]]))
    end)
  end)

  describe('ftplugin commands', function()
    local function run(ft, command, lines)
      local nvim = t.nvim()
      nvim:edit('x.' .. ft, lines)
      nvim:cmd(command)
      nvim:sleep(50)
      return table.concat(nvim:lines(), '\n')
    end

    local function golden(key, input, output)
      t.golden_section('ftplugin_commands.txt', key, table.concat(input, '\n') .. '\n--- becomes ---\n' .. output)
    end

    it('javascript :SwapSwitchCase swaps case labels and returned values', function()
      local input = { 'switch (x) {', "  case 'a': return 1;", "  case 'b':", '    return 2;', '}' }
      golden('javascript :SwapSwitchCase', input, run('js', 'SwapSwitchCase', input))
    end)

    it('javascript :ConvertApiDef turns FooAPI into a client factory', function()
      local input = { 'UserAPI,', 'BillingAPI,' }
      golden('javascript :ConvertApiDef', input, run('js', 'ConvertApiDef', input))
    end)

    it('javascriptreact :ReactAttrToExp turns attr="x" into attr={`x`}', function()
      local nvim = t.nvim()
      nvim:edit('x.jsx', { '<div className="foo bar" />' })
      nvim:set_cursor(1, 17)
      nvim:cmd('ReactAttrToExp')
      t.eq({ '<div className={`foo bar`} />' }, nvim:lines())
    end)

    it('typescript :ConvertProtoToType / :ConvertInputToProto', function()
      local input = {
        "__typename?: 'User';",
        "name?: Maybe<Scalars['String']['output']>;",
        "tags: Array<Scalars['String']['output']>;",
        'posts: Array<Post>;',
        'owner: Account;',
        "age: Scalars['Int']['output'];",
        'manager?: Maybe<Account>;',
        "Active = 'ACTIVE',",
      }
      golden('typescript :ConvertProtoToType', input, run('ts', 'ConvertProtoToType', input))
      local input2 = {
        "name?: InputMaybe<Scalars['String']['input']>;",
        "tags: Array<Scalars['String']['input']>;",
        'posts: Array<PostInput>;',
        "age: Scalars['Int']['input'];",
        'owner: AccountInput;',
        'manager?: InputMaybe<AccountInput>;',
        "Active = 'ACTIVE',",
      }
      golden('typescript :ConvertInputToProto', input2, run('ts', 'ConvertInputToProto', input2))
    end)

    it('typescript :GenAdaptor generates converter stubs', function()
      local nvim = t.nvim()
      nvim:edit('x.ts', { '' })
      nvim:cmd('GenAdaptor -ns=pb User UserInput Status:pe Kind:ge Item:gt')
      nvim:sleep(100)
      golden('typescript :GenAdaptor -ns=pb User UserInput Status:pe Kind:ge Item:gt', {}, table.concat(nvim:lines(), '\n'))
    end)

    it('graphql :ConvertProtoRpc / :ConvertQM / :ConvertFragment', function()
      local rpc = { 'rpc GetUser(GetUserRequest) returns (User);', 'rpc ListUsers (ListUsersRequest) returns (ListUsersResponse) {}' }
      golden('graphql :ConvertProtoRpc', rpc, run('graphql', 'ConvertProtoRpc', rpc))
      local qm = { 'getUser(input: GetUserInput!): User!' }
      golden('graphql :ConvertQM', qm, run('graphql', 'ConvertQM', qm))
      local fragment = {
        'type User = {',
        "  id: Scalars['ID'];",
        "  nickname?: Maybe<Scalars['String']>;",
        '  owner: Account;',
        '  posts: Array<Post>;',
        '  score: Int32Value;',
        '};',
      }
      golden('graphql :ConvertFragment', fragment, run('graphql', 'ConvertFragment', fragment))
    end)

    it('proto :ConvertProtoField turns a field list into proto fields', function()
      local input = { '- `name: string` The name', '  - `age: int32` The age', '- Create: `User` A user' }
      golden('proto :ConvertProtoField', input, run('proto', 'ConvertProtoField', input))
    end)
  end)
end)
