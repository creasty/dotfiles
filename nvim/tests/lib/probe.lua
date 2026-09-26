-- Parent-side helpers around the child probes (probe_child.lua).
-- Specs use these instead of plugin APIs, so they describe *what* you see.

local probe = {}

local function call(nvim, name, ...)
  return nvim:lua(('return __e2e.%s(...)'):format(name), ...)
end

local function read_json(path)
  local f = io.open(path, 'r')
  if not f then
    return nil
  end
  local s = f:read('*a')
  f:close()
  local ok, value = pcall(vim.json.decode, s)
  return ok and value or nil
end

--- Waits for the services the config starts in the background (coc today),
--- like a person who opens a file and starts typing a moment later.
function probe.wait_services(nvim, opts)
  nvim:wait_for(function()
    return call(nvim, 'services_ready')
  end, { timeout = (opts or {}).timeout or 15000, message = 'background services' })
end

---------------------------------------------------------------------------
-- Completion
---------------------------------------------------------------------------

function probe.completion(nvim)
  return call(nvim, 'completion')
end

function probe.completion_visible(nvim)
  return probe.completion(nvim).visible
end

local function has_item(items, wanted)
  for _, item in ipairs(items or {}) do
    if item == wanted or vim.startswith(item, wanted) then
      return true
    end
  end
  return false
end

--- Waits until the completion menu is visible (and contains `opts.item`).
function probe.wait_completion(nvim, opts)
  opts = opts or {}
  local last
  local ok = pcall(nvim.wait_for, nvim, function()
    last = probe.completion(nvim)
    return last.visible and (not opts.item or has_item(last.items, opts.item))
  end, { timeout = opts.timeout or 8000 })
  if not ok then
    error(('completion menu%s did not show up; last state: %s'):format(
      opts.item and (' with ' .. opts.item) or '',
      vim.inspect(last)
    ), 2)
  end
  return last
end

function probe.disable_completion(nvim)
  call(nvim, 'disable_completion')
end

--- Waits a moment and asserts no completion menu shows up.
function probe.assert_no_completion(nvim, ms)
  nvim:sleep(ms or 400)
  local state = probe.completion(nvim)
  if state.visible then
    error('unexpected completion menu: ' .. vim.inspect(state.items), 2)
  end
end

---------------------------------------------------------------------------
-- Snippets
---------------------------------------------------------------------------

function probe.snippet_active(nvim)
  return call(nvim, 'snippet_active')
end

---------------------------------------------------------------------------
-- Language server (fakes/lsp.lua)
---------------------------------------------------------------------------

local function server_has_open(state_path, path)
  local state = read_json(state_path)
  if not state then
    return false
  end
  for _, p in ipairs(state.open or {}) do
    if p == path then
      return true
    end
  end
  return false
end

--- Waits until the fake language server has the current buffer open.
function probe.wait_lsp(nvim, opts)
  opts = opts or {}
  local path = vim.uv.fs_realpath(nvim:bufname()) or nvim:bufname()
  nvim:wait_for(function()
    return server_has_open(nvim.lsp_state, path)
  end, { timeout = opts.timeout or 15000, message = 'the language server to attach ' .. path })
  -- Give the client a beat to process the initial diagnostics.
  nvim:sleep(opts.settle or 150)
end

function probe.diagnostics(nvim)
  return call(nvim, 'diagnostics')
end

function probe.signs(nvim, lnum)
  return call(nvim, 'signs', lnum)
end

function probe.reference_highlights(nvim)
  return call(nvim, 'reference_highlights')
end

---------------------------------------------------------------------------
-- AI suggestions (fakes/copilot.lua)
---------------------------------------------------------------------------

--- Waits until the AI client attached the current buffer. Clients start
--- lazily on the first InsertEnter, so call this from insert mode.
function probe.wait_ai(nvim, opts)
  opts = opts or {}
  local path = vim.uv.fs_realpath(nvim:bufname()) or nvim:bufname()
  nvim:wait_for(function()
    return server_has_open(nvim.copilot_state, path)
  end, { timeout = opts.timeout or 15000, message = 'the AI client to attach ' .. path })
end

function probe.ghost_text(nvim)
  return call(nvim, 'ghost_text')
end

function probe.wait_ghost(nvim, text, opts)
  opts = opts or {}
  local last
  local ok = pcall(nvim.wait_for, nvim, function()
    last = probe.ghost_text(nvim)
    return last:find(text, 1, true) ~= nil
  end, { timeout = opts.timeout or 8000 })
  if not ok then
    error(('ghost text %q did not show up; last: %q'):format(text, tostring(last)), 2)
  end
end

---------------------------------------------------------------------------
-- Picker
---------------------------------------------------------------------------

function probe.picker(nvim)
  return call(nvim, 'picker')
end

function probe.wait_picker_ready(nvim, opts)
  nvim:wait_for(function()
    return call(nvim, 'picker_ready')
  end, { timeout = (opts or {}).timeout or 20000, message = 'the picker backend' })
end

--- Waits until the picker is open, done loading, and `pred(state)` holds
--- (default: has items).
function probe.wait_picker(nvim, pred, opts)
  opts = opts or {}
  pred = pred or function(state)
    return #state.items > 0
  end
  local last
  local ok = pcall(nvim.wait_for, nvim, function()
    last = probe.picker(nvim)
    return last.open and not last.loading and pred(last)
  end, { timeout = opts.timeout or 15000 })
  if not ok then
    error('picker did not reach the expected state; last: ' .. vim.inspect(last), 2)
  end
  return last
end

function probe.wait_picker_closed(nvim, opts)
  nvim:wait_for(function()
    return not probe.picker(nvim).open
  end, { timeout = (opts or {}).timeout or 8000, message = 'the picker to close' })
end

---------------------------------------------------------------------------
-- Prompts
---------------------------------------------------------------------------

--- Waits for a text prompt (floating input or command-line input).
function probe.wait_input_prompt(nvim, opts)
  nvim:wait_for(function()
    local mode = nvim:mode()
    return mode == 'i' or mode == 'c'
  end, { timeout = (opts or {}).timeout or 8000, message = 'an input prompt' })
end

--- Waits until a choice menu (code actions etc.) accepts keys.
function probe.wait_choice_menu(nvim, opts)
  nvim:wait_for(function()
    return call(nvim, 'choice_menu_ready')
  end, { timeout = (opts or {}).timeout or 8000, message = 'a choice menu' })
end

--- Waits for a numbered choice list (code actions etc.) and picks the entry
--- whose text contains `label`.
function probe.choose(nvim, label, opts)
  opts = opts or {}
  probe.wait_choice_menu(nvim, opts)
  local index
  nvim:wait_for(function()
    for _, float in ipairs(nvim:floats()) do
      for _, line in ipairs(float.lines) do
        local n, text = line:match('^%s*(%d+)[.:]%s*(.*)$')
        if n and text:find(label, 1, true) then
          index = n
          return true
        end
      end
    end
    for _, line in ipairs(nvim:screen()) do
      local n, text = line:match('^%s*(%d+)[.:]%s*(.*)$')
      if n and text:find(label, 1, true) then
        index = n
        return true
      end
    end
  end, { timeout = opts.timeout or 8000, message = 'a choice containing ' .. label })
  nvim:type(index)
  if nvim:mode() == 'c' or nvim:mode() == 'r' then
    nvim:type('<CR>')
  end
end

return probe
