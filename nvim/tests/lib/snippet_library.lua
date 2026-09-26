-- Pins the expansion of every snippet in nvim/ultisnips as golden text
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
    ['(\\S?)(?<![<-])(-{1,2})\\s?'] = { 'x-', 'x--', '-' },
    ['(\\S?)(?<![<=])(={1,2})\\s?'] = { 'x=', 'x==' },
    ['([=-]>|<[=-])\\s?'] = { '->', '=>', '<-', '<=' },
    ['(?<!/)/'] = { '/' },
    ['(?<!/)//'] = { '//' },
    ['(?<!#)#'] = { '#' },
    ['(?<!#)##'] = { '##' },
  },
  c = {
    ['#include '] = { { keys = '#include ', auto = true } },
    ['(\\w+)\\.\\.(\\w)'] = { { keys = 'ptr..x', auto = true } },
  },
  clike_postfix = {
    ['(\\S+)\\.par'] = { 'a+b.par' },
    ['(\\S+)\\.if'] = { 'ok.if' },
    ['(\\S+)\\.else'] = { 'ok.else' },
    ['(\\S+)\\.(null|nil)'] = { 'p.null', 'p.nil' },
    ['(\\S+)\\.(notnull|notnil|nn)'] = { 'p.notnull', 'p.nn' },
    ['(\\S+)\\.while'] = { 'running.while' },
    ['(\\S+)\\.switch'] = { 'kind.switch' },
  },
  css = {
    ['(?<!/)/'] = { '/' },
    ['(?<!/)//'] = { '//' },
  },
  go_postfix = {
    ['(\\S+)\\.var'] = { 'f(x).var' },
    ['(\\S+)\\.varr'] = { 'f(x).varr' },
    ['(\\S+)\\.const'] = { '42.const' },
    ['(\\S+)\\.par'] = { 'a+b.par' },
    ['(\\S+)\\.if'] = { 'ok.if' },
    ['(\\S+)\\.else'] = { 'ok.else' },
    ['(\\S+)\\.(null|nil)'] = { 'err.nil' },
    ['(\\S+)\\.(notnull|notnil|nn)'] = { 'err.nn' },
    ['(\\S+)\\.for'] = { 'items.for' },
    ['(\\S+)\\.fori'] = { 'items.fori' },
    ['(\\S+)\\.forv'] = { 'items.forv' },
    ['(\\S+)\\.while'] = { 'running.while' },
    ['(\\S+)\\.switch'] = { 'kind.switch' },
    ['(\\S+)\\.append'] = { 'items.append' },
  },
  haml = {
    ['(?<!/)/'] = { '/' },
    ['(?<!/)//'] = { '//' },
  },
  markdown = {
    ['tb(\\d+x\\d+)'] = { 'tb2x3' },
    ['^-{3,}'] = { '---' },
    ['^[\\-=]'] = {
      { before = { 'Title' }, keys = '-', auto = true },
      { before = { 'Title' }, keys = '=', auto = true },
      { before = { '見出し' }, keys = '-', auto = true },
    },
    ['(\\b|\\s+)br'] = { 'line br' },
  },
  proto = {
    ['rpc (\\w+)'] = { 'rpc GetUser', 'rpc ListUsers', 'rpc CreateUser', 'rpc DeleteUser', 'rpc Ping' },
    ['(msg|message) (\\w+)'] = {
      'message GetUserRequest',
      'msg ListUsersResponse',
      'message UpdateUserRequest',
      'message UpdateMultiUsersRequest',
      'message Plain',
    },
  },
  ruby = {
    ['(\\w+)\\.each'] = { 'items.each' },
    ['(\\w+)\\.eachdo'] = { 'items.eachdo' },
    ['(\\w+)\\.map'] = { 'items.map' },
    ['(\\w+)\\.mapdo'] = { 'items.mapdo' },
  },
  ruby_postfix = {
    ['(\\S+)\\.var'] = { 'compute(1).var' },
    ['(\\S+)\\.par'] = { 'a+b.par' },
    ['(\\S+)\\.if'] = { 'ok.if' },
    ['(\\S+)\\.else'] = { 'ok.else' },
    ['(\\S+)\\.format'] = { 'value.format' },
  },
  tex = {
    ['tr(\\d+)'] = { 'tr3' },
    ['(?<!%)%'] = { '%' },
    ['(?<!%)%%'] = { '%%' },
  },
  tla = {
    ['^-{3,}'] = { { keys = '---', auto = true } },
    ['^={3,}'] = { { keys = '===', auto = true } },
  },
  vim = {
    ['(?<!")"'] = { '"' },
    ['(?<!")""'] = { '""' },
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
--- A failing snippet (UltiSnips shows its stack trace in a scratch buffer)
--- is recorded as `ERROR: <last line of the trace>`.
local function capture(nvim)
  local all = table.concat(nvim:lines(), '\n')
  if all:find('An error occured. This is either a bug in UltiSnips', 1, true) then
    local reason = all:match('\n(%w*Error:[^\n]*)') or 'unknown error'
    return 'ERROR: ' .. reason
  end
  local state = nvim:lua([[
    local mode = vim.api.nvim_get_mode().mode
    local selection
    if mode == 's' or mode == 'v' or mode == 'S' or mode == 'V' then
      local ok, region = pcall(vim.fn.getregion, vim.fn.getpos('v'), vim.fn.getpos('.'), { type = mode:lower() == 's' and 'v' or mode })
      selection = ok and table.concat(region, '\n') or nil
    end
    return { mode = mode, selection = selection }
  ]])
  local lines = nvim:buffer({ marker = '‸' })
  local footer = '-- mode: ' .. state.mode
  if state.selection then
    footer = footer .. ', selected: ' .. vim.inspect(state.selection)
  end
  table.insert(lines, footer)
  return normalize(table.concat(lines, '\n'), nvim)
end

--- When several snippets match, UltiSnips asks which one to expand
--- (inputlist). Record the offered choices and pick the first.
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
  { 'all', 'c', 'clike_postfix', 'clike_stmt', 'css', 'gitattributes', 'go', 'go_postfix', 'haml' },
  { 'proto' },
  { 'javascript', 'javascriptreact', 'lua', 'markdown', 'pg', 'ruby', 'ruby_postfix', 'snippets', 'tex' },
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
