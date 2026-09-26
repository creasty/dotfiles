-- Minimal JSON-RPC (LSP base protocol) over stdio for the fake servers.
-- Runs under `nvim --clean -l`, so vim.json and vim.fs are available.

local M = {}

local log_path = os.getenv('E2E_FAKE_SERVER_LOG')

function M.log(...)
  if not log_path then
    return
  end
  local f = io.open(log_path, 'a')
  if f then
    f:write(table.concat(vim.tbl_map(tostring, { ... }), ' '), '\n')
    f:close()
  end
end

local function read_message()
  local length
  while true do
    local line = io.stdin:read('*l')
    if line == nil then
      return nil
    end
    line = line:gsub('\r$', '')
    if line == '' then
      if length then
        break
      end
    else
      local key, value = line:match('^([%w%-]+):%s*(.-)%s*$')
      if key and key:lower() == 'content-length' then
        length = tonumber(value)
      end
    end
  end
  local body = io.stdin:read(length)
  if body == nil then
    return nil
  end
  M.log('<-', body)
  return vim.json.decode(body, { luanil = { object = true, array = true } })
end

function M.send(msg)
  msg.jsonrpc = '2.0'
  local body = vim.json.encode(msg)
  M.log('->', body)
  io.stdout:write(('Content-Length: %d\r\n\r\n%s'):format(#body, body))
  io.stdout:flush()
end

function M.notify(method, params)
  M.send({ method = method, params = params })
end

--- Serve until `exit`. `handlers[method](params, msg)` returns the result for
--- requests (nil means JSON null); for notifications the return value is ignored.
function M.serve(handlers)
  while true do
    local msg = read_message()
    if msg == nil or msg.method == 'exit' then
      os.exit(0)
    end
    local handler = msg.method and handlers[msg.method]
    local ok, result = true, nil
    if handler then
      ok, result = pcall(handler, msg.params or {}, msg)
      if not ok then
        M.log('!!', msg.method, result)
      end
    end
    if msg.id ~= nil and msg.method then
      if ok then
        M.send({ id = msg.id, result = result == nil and vim.NIL or result })
      else
        M.send({ id = msg.id, error = { code = -32603, message = tostring(result) } })
      end
    end
  end
end

--- Tracks open documents (full or incremental sync) keyed by URI. When the
--- `state_env` environment variable names a file, the set of open documents is
--- mirrored there as JSON so tests can tell when a client has attached.
function M.documents(state_env)
  local docs = {}
  local state_path = state_env and os.getenv(state_env)

  local function save_state()
    if not state_path or state_path == '' then
      return
    end
    local open = {}
    for uri in pairs(docs) do
      open[#open + 1] = vim.uri_to_fname(uri)
    end
    table.sort(open)
    local tmp = state_path .. '.tmp'
    local f = io.open(tmp, 'w')
    if f then
      f:write(vim.json.encode({ pid = vim.uv.os_getpid(), open = open }))
      f:close()
      os.rename(tmp, state_path)
    end
  end

  local function split(text)
    return vim.split(text, '\n', { plain = true })
  end

  local function apply_change(doc, change)
    if not change.range then
      doc.lines = split(change.text)
      return
    end
    local s, e = change.range.start, change.range['end']
    local before = (doc.lines[s.line + 1] or ''):sub(1, s.character)
    local after = (doc.lines[e.line + 1] or ''):sub(e.character + 1)
    local inserted = split(before .. change.text .. after)
    local new = {}
    for i = 1, s.line do
      new[#new + 1] = doc.lines[i]
    end
    vim.list_extend(new, inserted)
    for i = e.line + 2, #doc.lines do
      new[#new + 1] = doc.lines[i]
    end
    doc.lines = new
  end

  return {
    open = function(item)
      docs[item.uri] = { uri = item.uri, lines = split(item.text), languageId = item.languageId }
      save_state()
      return docs[item.uri]
    end,
    change = function(params)
      local doc = docs[params.textDocument.uri]
      if not doc then
        return nil
      end
      for _, change in ipairs(params.contentChanges or {}) do
        apply_change(doc, change)
      end
      return doc
    end,
    close = function(uri)
      docs[uri] = nil
      save_state()
    end,
    save_state = save_state,
    get = function(uri)
      return docs[uri]
    end,
    all = function()
      return docs
    end,
  }
end

return M
