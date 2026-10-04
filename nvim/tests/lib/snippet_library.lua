-- Pins the expansion of every snippet in nvim/snippets as golden text
-- (golden/snippets/<file>.snippets.txt), so a new snippet engine or a
-- converted library can be checked trigger by trigger.
--
-- Plain triggers are typed at the start of an empty line followed by <Tab>.
-- Regex / auto-trigger snippets need sample input: add it to SAMPLES.
-- Each result records the text (‸ = cursor), the mode, and the selected
-- placeholder text when a placeholder is selected.

local t = require('t')
local probe = require('probe')
local snippets = require('snippets')

local SAMPLES = {
  all = {
    ['\\v(\\S?)[<-]@<!(-{1,2})\\s?'] = { 'x-', 'x--', '-' },
    ['\\v(\\S?)[<=]@<!(\\={1,2})\\s?'] = { 'x=', 'x==' },
    ['\\v([=-]\\>|\\<[=-])\\s?'] = { '->', '=>', '<-', '<=' },
  },
  c = {
    ['#include '] = { { keys = '#include ', auto = true } },
    ['\\v(\\w+)\\.\\.(\\w)'] = { { keys = 'ptr..x', auto = true } },
  },
  clike_postfix = {
    ['\\v(\\S+)\\.par'] = { 'a+b.par' },
    ['\\v(\\S+)\\.if'] = { 'ok.if' },
    ['\\v(\\S+)\\.else'] = { 'ok.else' },
    ['\\v(\\S+)\\.(null|nil)'] = { 'p.null', 'p.nil' },
    ['\\v(\\S+)\\.(notnull|notnil|nn)'] = { 'p.notnull', 'p.nn' },
    ['\\v(\\S+)\\.while'] = { 'running.while' },
    ['\\v(\\S+)\\.switch'] = { 'kind.switch' },
  },
  go_postfix = {
    ['\\v(\\S+)\\.var'] = { 'f(x).var' },
    ['\\v(\\S+)\\.varr'] = { 'f(x).varr' },
    ['\\v(\\S+)\\.const'] = { '42.const' },
    ['\\v(\\S+)\\.par'] = { 'a+b.par' },
    ['\\v(\\S+)\\.if'] = { 'ok.if' },
    ['\\v(\\S+)\\.else'] = { 'ok.else' },
    ['\\v(\\S+)\\.(null|nil)'] = { 'err.nil' },
    ['\\v(\\S+)\\.(notnull|notnil|nn)'] = { 'err.nn' },
    ['\\v(\\S+)\\.for'] = { 'items.for' },
    ['\\v(\\S+)\\.fori'] = { 'items.fori' },
    ['\\v(\\S+)\\.forv'] = { 'items.forv' },
    ['\\v(\\S+)\\.while'] = { 'running.while' },
    ['\\v(\\S+)\\.switch'] = { 'kind.switch' },
    ['\\v(\\S+)\\.append'] = { 'items.append' },
  },
  markdown = {
    ['\\vtb(\\d+x\\d+)'] = { 'tb2x3' },
    ['^-\\{3,}'] = { '---' },
    ['\\v(<|\\s+)br'] = { 'line br' },
  },
  proto = {
    ['\\vrpc (\\w+)'] = { 'rpc GetUser', 'rpc ListUsers', 'rpc CreateUser', 'rpc DeleteUser', 'rpc Ping' },
    ['\\v(msg|message) (\\w+)'] = {
      'message GetUserRequest',
      'msg ListUsersResponse',
      'message UpdateUserRequest',
      'message UpdateMultiUsersRequest',
      'message Plain',
    },
  },
  ruby = {
    ['\\v(\\w+)\\.each'] = { 'items.each' },
    ['\\v(\\w+)\\.eachdo'] = { 'items.eachdo' },
    ['\\v(\\w+)\\.map'] = { 'items.map' },
    ['\\v(\\w+)\\.mapdo'] = { 'items.mapdo' },
  },
  ruby_postfix = {
    ['\\v(\\S+)\\.var'] = { 'compute(1).var' },
    ['\\v(\\S+)\\.par'] = { 'a+b.par' },
    ['\\v(\\S+)\\.if'] = { 'ok.if' },
    ['\\v(\\S+)\\.else'] = { 'ok.else' },
    ['\\v(\\S+)\\.format'] = { 'value.format' },
  },
  tex = {
    ['\\vtr(\\d+)'] = { 'tr3' },
  },
  tla = {
    ['^-\\{3,}'] = { { keys = '---', auto = true } },
    ['^=\\{3,}'] = { { keys = '===', auto = true } },
  },
}

local function escape_keys(keys)
  return (keys:gsub('<', '<lt>'))
end

local function normalize(text, nvim)
  text = text:gsub(vim.pesc(nvim.dir), '<SANDBOX>')
  text = text:gsub('%d%d%d%d%-%d%d%-%d%d', '<DATE>')
  return text
end

--- Buffer text (‸ = cursor), mode and selected text after an expansion.
--- With a placeholder selected, ‸ marks its last character, whichever end
--- of the selection the engine leaves the cursor at.
local function capture(nvim)
  local state = nvim:lua([[
    local mode = vim.api.nvim_get_mode().mode
    local selection, marker
    if mode == 's' or mode == 'v' or mode == 'S' or mode == 'V' then
      local from, to = vim.fn.getpos('v'), vim.fn.getpos('.')
      local ok, region = pcall(vim.fn.getregion, from, to, { type = mode:lower() == 's' and 'v' or mode })
      selection = ok and table.concat(region, '\n') or nil
      if from[2] > to[2] or (from[2] == to[2] and from[3] > to[3]) then
        to = from
      end
      marker = { to[2], to[3] - 1 }
    end
    return { mode = mode, selection = selection, marker = marker }
  ]])
  local lines = nvim:lines()
  local row, col = unpack(state.marker or nvim:cursor())
  local line = lines[row] or ''
  lines[row] = line:sub(1, col) .. '‸' .. line:sub(col + 1)
  local footer = '-- mode: ' .. state.mode
  if state.selection then
    footer = footer .. ', selected: ' .. vim.inspect(state.selection)
  end
  table.insert(lines, footer)
  return normalize(table.concat(lines, '\n'), nvim)
end

--- When several snippets match, an engine may ask which one to expand, with
--- inputlist (LuaSnip takes the first by priority). Record the offered choices
--- and pick the first.
local function resolve_choice(nvim)
  if nvim:mode() ~= 'c' then
    return nil
  end
  local screen = table.concat(nvim:screen(), '')
  if not screen:find('Type number and <Enter>', 1, true) then
    return nil
  end
  local choices = {}
  for n, trigger, desc in screen:gmatch('(%d+): %(([^)]*)%) "([^"]*)"') do
    choices[#choices + 1] = ('%s: (%s) "%s"'):format(n, trigger, desc)
  end
  nvim:type('1<CR>')
  return 'CHOICES: ' .. table.concat(choices, ' | ') .. ' -> picked 1'
end

local function run_case(name, filetype, case)
  local nvim = t.nvim({ name = 'snip-' .. name })
  local ext = snippets.extension[filetype] or filetype
  nvim:edit('example/example.' .. ext, case.before or { '' })
  nvim:cmd('set filetype=' .. filetype)
  probe.disable_completion(nvim)
  nvim:type(case.before and 'Go' or 'A')
  -- Trigger and <Tab> in one burst: given a moment in between, opfmt
  -- reformats triggers such as `api-client-general` (see the quirk in
  -- snippets_spec), and this file pins what each snippet expands to.
  nvim:type(escape_keys(case.keys) .. (case.auto and '' or '<Tab>'))
  local choice = resolve_choice(nvim)
  local result = capture(nvim)
  return choice and (choice .. '\n' .. result) or result
end

local M = {}

--- Snippet files per spec file (several spec files run in parallel).
--- Every snippet file must be listed; snippets_spec checks it.
M.shards = {
  { 'all', 'c', 'clike_postfix', 'clike_stmt', 'gitattributes', 'go', 'go_postfix' },
  { 'proto' },
  { 'javascript', 'javascriptreact', 'markdown', 'pg', 'ruby', 'ruby_postfix', 'tex' },
  { 'sh', 'sql', 'bq', 'tla', 'typescript', 'typescript_henry', 'typescriptreact', 'vim' },
}

--- Defines one test per snippet (per sample for regex snippets).
function M.define(files)
  for _, name in ipairs(files) do
    local filetype = snippets.filetype[name] or name
    local golden = ('snippets/%s.snippets.txt'):format(name)
    t.describe(('%s.snippets (%s)'):format(name, filetype), function()
      for _, snip in ipairs(snippets.read(name)) do
        local cases
        if snip.regex or snip.auto then
          local samples = (SAMPLES[name] or {})[snip.trigger]
          cases = {}
          for _, sample in ipairs(samples or {}) do
            cases[#cases + 1] = type(sample) == 'string' and { keys = sample } or sample
          end
          if #cases == 0 then
            t.it(('/%s/ (line %d)'):format(snip.trigger, snip.line), function()
              t.skip('regex snippet without sample input; add one to SAMPLES in lib/snippet_library.lua')
            end)
          end
        else
          cases = { { keys = snip.trigger } }
        end
        for _, case in ipairs(cases) do
          local key = snip.regex and ('/%s/ %s'):format(snip.trigger, case.keys) or snip.trigger
          local label = snip.regex and ('/%s/ with %q'):format(snip.trigger, case.keys) or snip.trigger
          if case.before then
            key = key .. ' (after ' .. table.concat(case.before, '\\n') .. ')'
            label = label .. ' after ' .. vim.inspect(case.before[#case.before])
          end
          t.it(('%s — %s'):format(label, snip.description), function()
            t.golden_section(golden, key, run_case(name, filetype, case))
          end)
        end
      end
    end)
  end
end

return M
