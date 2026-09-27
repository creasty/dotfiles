-- Test runner: `nvim -l runner.lua [options] [spec...]` (see ./run --help).
--
-- The main process prepares one isolated environment, then runs each spec
-- file in its own worker process (`--worker`), several in parallel. Workers
-- stream JSON events on stdout.

local tests_dir = vim.fs.dirname(vim.fs.normalize(vim.fn.fnamemodify(arg[0], ':p')))
package.path = table.concat({ tests_dir .. '/lib/?.lua', package.path }, ';')

local env = require('env')

local HELP = [[
Usage: nvim/tests/run [options] [spec ...]

Runs the end-to-end workflow suite against this repository's nvim config.

Options:
  -f, --filter PATTERN   only run tests whose full name matches the Lua pattern
                         (repeat to run the tests matching any of them)
  -j, --jobs N           number of spec files run in parallel (default: 4)
  -l, --list             list the workflow requirements (test names) and exit
  -q, --quirks           with --list: also show why each quirk is pinned
  -k, --keep             keep the temporary run directory
  -v, --verbose          print every test, not only failures
      --timeout MS       per-test timeout (default: 30000)
      --update-golden    rewrite golden files from the current behavior
      --summary FILE     also append a Markdown report to FILE (for CI)
  -h, --help             show this help

spec: a file under spec/ or a substring of its name (e.g. `completion`).
Environment: E2E_PLUGINS, E2E_TMPDIR (see README).]]

local function parse_args(argv)
  local opts = { jobs = 4, timeout = 30000, specs = {}, filters = {} }
  local i = 1
  while i <= #argv do
    local a = argv[i]
    if a == '-f' or a == '--filter' then
      i = i + 1
      table.insert(opts.filters, argv[i])
    elseif a == '-j' or a == '--jobs' then
      i = i + 1
      opts.jobs = tonumber(argv[i])
    elseif a == '-q' or a == '--quirks' then
      opts.quirks = true
    elseif a == '-l' or a == '--list' then
      opts.list = true
    elseif a == '-k' or a == '--keep' then
      opts.keep = true
    elseif a == '-v' or a == '--verbose' then
      opts.verbose = true
    elseif a == '--timeout' then
      i = i + 1
      opts.timeout = tonumber(argv[i])
    elseif a == '--update-golden' then
      opts.update_golden = true
    elseif a == '--summary' then
      i = i + 1
      opts.summary = argv[i]
    elseif a == '--worker' then
      i = i + 1
      opts.worker = argv[i]
    elseif a == '-h' or a == '--help' then
      opts.help = true
    else
      table.insert(opts.specs, a)
    end
    i = i + 1
  end
  return opts
end

local opts = parse_args(arg)

--- Writes all of `data` to stdout. Neovim leaves stdout non-blocking, so on
--- a pipe that fills up (CI logs) plain writes lose output.
local function write_stdout(data)
  local offset = 0
  while offset < #data do
    local written, _, name = vim.uv.fs_write(1, offset == 0 and data or data:sub(offset + 1))
    if written then
      offset = offset + written
    elseif name == 'EAGAIN' then
      vim.uv.sleep(5)
    else
      return
    end
  end
end

local function emit(event)
  write_stdout(vim.json.encode(event) .. '\n')
end

local function selected(name)
  if #opts.filters == 0 then
    return true
  end
  for _, filter in ipairs(opts.filters) do
    if name:find(filter) then
      return true
    end
  end
  return false
end

---------------------------------------------------------------------------
-- Worker: run one spec file
---------------------------------------------------------------------------
if opts.worker then
  local t = require('t')
  local ok, cases = pcall(t.load, opts.worker)
  if not ok then
    emit({ event = 'result', name = '(load) ' .. opts.worker, status = 'fail', error = tostring(cases), ms = 0 })
    os.exit(1)
  end
  for _, case in ipairs(cases) do
    if selected(case.name) then
      if opts.list then
        emit({ event = 'case', name = case.name, quirk = case.opts.quirk })
      else
        emit({ event = 'start', name = case.name })
        local result = t.run_case(case, opts.timeout)
        result.event = 'result'
        result.name = case.name
        emit(result)
      end
    end
  end
  os.exit(0)
end

if opts.help then
  print(HELP)
  os.exit(0)
end

---------------------------------------------------------------------------
-- Main process
---------------------------------------------------------------------------
local spec_files = {}
for name, type in vim.fs.dir(tests_dir .. '/spec') do
  if type == 'file' and name:match('_spec%.lua$') then
    local selected = #opts.specs == 0
    for _, s in ipairs(opts.specs) do
      if name:find(s, 1, true) or (tests_dir .. '/spec/' .. name):find(vim.fn.fnamemodify(s, ':p'), 1, true) then
        selected = true
      end
    end
    if selected then
      table.insert(spec_files, tests_dir .. '/spec/' .. name)
    end
  end
end
table.sort(spec_files)
if #spec_files == 0 then
  io.stderr:write('no spec files matched\n')
  os.exit(1)
end

local use_color = os.getenv('NO_COLOR') == nil and vim.fn.has('unix') == 1
local function color(code, s)
  return use_color and ('\27[' .. code .. 'm' .. s .. '\27[0m') or s
end
local out = function(...)
  write_stdout(table.concat({ ... }))
end

local ctx
if opts.list then
  -- Listing does not need a prepared environment, but spec files may call
  -- env helpers at load time; give them a minimal context.
  ctx = { context_file = '' }
else
  out(color('2', 'Preparing environment... '))
  local started = vim.uv.hrtime()
  local ok, res = pcall(env.prepare)
  if not ok then
    out(color('31', 'failed\n') .. tostring(res) .. '\n')
    os.exit(1)
  end
  ctx = res
  out(color('2', ('done (%.1fs) %s\n'):format((vim.uv.hrtime() - started) / 1e9, ctx.run_dir)))
  out(color('2', 'Warming up plugins... '))
  started = vim.uv.hrtime()
  local warm_ok, warm_err = require('warmup').run(ctx)
  out(color('2', ('%s (%.1fs)\n'):format(warm_ok and 'done' or 'failed', (vim.uv.hrtime() - started) / 1e9)))
  if not warm_ok then
    out(color('33', '  warm-up failed; the first picker tests may time out:\n  ' .. tostring(warm_err):gsub('\n', '\n  ') .. '\n'))
  end
  if ctx.startup_messages ~= '' then
    out(color('33', 'Startup messages:\n  ' .. ctx.startup_messages:gsub('\n', '\n  ') .. '\n'))
  end
end

local results = {}
local queue = vim.deepcopy(spec_files)
local running = 0
local started_at = vim.uv.hrtime()

local function rel(path)
  return path:sub(#tests_dir + 2)
end

local function report(spec, event)
  if event.event == 'case' then
    table.insert(results, { spec = spec, name = event.name, quirk = event.quirk, status = 'list' })
    return
  end
  if event.event ~= 'result' then
    return
  end
  event.spec = spec
  table.insert(results, event)
  if opts.verbose or event.status == 'fail' then
    local mark = event.status == 'pass' and color('32', '✓') or event.status == 'skip' and color('33', '-') or color('31', '✗')
    local tag = event.quirk and color('35', ' [quirk]') or ''
    if event.status == 'pass' and (event.attempts or 1) > 1 then
      tag = tag .. color('33', (' [passed on attempt %d]'):format(event.attempts))
    end
    out(('%s %s%s %s\n'):format(mark, event.name, tag, color('2', ('(%s, %.0fms)'):format(rel(spec), event.ms or 0))))
  else
    out(event.status == 'pass' and color('32', '.') or color('33', 's'))
  end
end

local function start_worker(spec)
  running = running + 1
  local cmd = { vim.v.progpath, '--clean', '-l', tests_dir .. '/runner.lua', '--worker', spec, '--timeout', tostring(opts.timeout) }
  for _, filter in ipairs(opts.filters) do
    vim.list_extend(cmd, { '--filter', filter })
  end
  if opts.list then
    table.insert(cmd, '--list')
  end
  local buffered = ''
  local current_case
  vim.system(cmd, {
    env = {
      E2E_CONTEXT = ctx.context_file,
      E2E_UPDATE_GOLDEN = opts.update_golden and '1' or nil,
    },
    stdout = function(_, data)
      if not data then
        return
      end
      buffered = buffered .. data
      while true do
        local nl = buffered:find('\n', 1, true)
        if not nl then
          break
        end
        local line = buffered:sub(1, nl - 1)
        buffered = buffered:sub(nl + 1)
        local ok, event = pcall(vim.json.decode, line)
        if ok and type(event) == 'table' then
          if event.event == 'start' then
            current_case = event.name
          elseif event.event == 'result' then
            current_case = nil
          end
          vim.schedule(function()
            report(spec, event)
          end)
        end
      end
    end,
    stderr = function() end,
  }, function(res)
    vim.schedule(function()
      if res.code ~= 0 and current_case then
        report(spec, { event = 'result', name = current_case, status = 'fail', error = 'worker exited with code ' .. res.code })
      end
      running = running - 1
    end)
  end)
end

while #queue > 0 or running > 0 do
  while #queue > 0 and running < opts.jobs do
    start_worker(table.remove(queue, 1))
  end
  vim.wait(50, function()
    return (#queue > 0 and running < opts.jobs) or (running == 0 and #queue == 0)
  end)
end

if opts.list then
  local by_spec = {}
  for _, r in ipairs(results) do
    by_spec[r.spec] = by_spec[r.spec] or {}
    table.insert(by_spec[r.spec], r)
  end
  local total, quirks = 0, 0
  for _, spec in ipairs(spec_files) do
    local cases = by_spec[spec] or {}
    out(color('1', rel(spec)) .. '\n')
    for _, r in ipairs(cases) do
      if r.quirk then
        quirks = quirks + 1
        out('  ' .. color('35', '~') .. ' ' .. r.name .. color('35', ' [quirk]') .. '\n')
        if opts.quirks then
          out(color('2', '      ' .. r.quirk) .. '\n')
        end
      else
        out('  • ' .. r.name .. '\n')
      end
    end
    total = total + #cases
  end
  out(('\n%d requirements, %d pinned quirks\n'):format(total - quirks, quirks))
  os.exit(0)
end

local counts = { pass = 0, fail = 0, skip = 0 }
local failures = {}
for _, r in ipairs(results) do
  counts[r.status] = (counts[r.status] or 0) + 1
  if r.status == 'fail' then
    table.insert(failures, r)
  end
end
out('\n')

if #failures > 0 then
  out('\n' .. color('1;31', 'Failures') .. '\n')
  for i, r in ipairs(failures) do
    out(('\n%d) %s %s\n'):format(i, color('1', r.name), color('2', '(' .. rel(r.spec) .. ')')))
    if r.quirk then
      out(color('35', '   [quirk] this test pins a known oddity: ' .. r.quirk .. '\n   If the new behavior is better, update or delete the test.\n'))
    end
    out('   ' .. tostring(r.error):gsub('\n', '\n   ') .. '\n')
    if r.dump then
      out(color('2', '   ' .. r.dump:gsub('\n', '\n   ')) .. '\n')
    end
  end
end

local skips = vim.tbl_filter(function(r)
  return r.status == 'skip'
end, results)
if #skips > 0 then
  out('\n' .. color('33', 'Skipped') .. '\n')
  for _, r in ipairs(skips) do
    out(('  - %s: %s\n'):format(r.name, r.error or ''))
  end
end

out(('\n%s, %s, %s  %s\n'):format(
  color(counts.fail > 0 and '31' or '32', counts.pass .. ' passed'),
  color(counts.fail > 0 and '1;31' or '2', counts.fail .. ' failed'),
  color('33', counts.skip .. ' skipped'),
  color('2', ('(%.1fs)'):format((vim.uv.hrtime() - started_at) / 1e9))
))

--- Markdown for CI (e.g. $GITHUB_STEP_SUMMARY): what changed, and why.
local function write_summary(file)
  local function html(s)
    return (s:gsub('&', '&amp;'):gsub('<', '&lt;'):gsub('>', '&gt;'))
  end
  local lines = {
    '## Neovim workflow tests',
    '',
    ('**%d passed**, **%d failed**, %d skipped (%.0fs)'):format(counts.pass, counts.fail, counts.skip, (vim.uv.hrtime() - started_at) / 1e9),
    '',
  }
  if #failures > 0 then
    lines[#lines + 1] = ('### Changed workflows (%d)'):format(#failures)
    lines[#lines + 1] = ''
    lines[#lines + 1] = 'A failing requirement is a workflow that behaves differently now. A failing **quirk** pinned an oddity of the old setup: if the new behavior is better, update or delete the test.'
    lines[#lines + 1] = ''
    for _, r in ipairs(failures) do
      local error_text = tostring(r.error):gsub('\n%s*stack traceback:.*$', '')
      vim.list_extend(lines, {
        ('<details><summary>%s%s</summary>'):format(r.quirk and '<b>[quirk]</b> ' or '', html(r.name)),
        '',
        ('`%s`%s'):format(rel(r.spec), r.quirk and (' — pinned because ' .. html(r.quirk)) or ''),
        '',
        '```text',
        error_text,
      })
      if r.dump then
        vim.list_extend(lines, { '', r.dump })
      end
      vim.list_extend(lines, { '```', '', '</details>', '' })
    end
  end
  local flaky = vim.tbl_filter(function(r)
    return r.status == 'pass' and (r.attempts or 1) > 1
  end, results)
  if #flaky > 0 then
    lines[#lines + 1] = ('### Passed on a retry (%d)'):format(#flaky)
    lines[#lines + 1] = ''
    for _, r in ipairs(flaky) do
      lines[#lines + 1] = ('- %s (attempt %d)'):format(html(r.name), r.attempts)
    end
    lines[#lines + 1] = ''
  end
  if #skips > 0 then
    lines[#lines + 1] = ('### Skipped (%d)'):format(#skips)
    lines[#lines + 1] = ''
    for _, r in ipairs(skips) do
      lines[#lines + 1] = ('- %s: %s'):format(html(r.name), html(r.error or ''))
    end
    lines[#lines + 1] = ''
  end
  local f = assert(io.open(file, 'a'))
  f:write(table.concat(lines, '\n'), '\n')
  f:close()
end

if opts.summary then
  write_summary(opts.summary)
end

env.cleanup(ctx, opts.keep)
os.exit(counts.fail > 0 and 1 or 0)
