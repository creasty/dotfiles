-- Deterministic fake GitHub Copilot language server for the e2e suite.
--
--   nvim --clean -l fakes/copilot.lua --stdio
--
-- Speaks the subset of the copilot-language-server protocol that clients use
-- for inline suggestions (textDocument/inlineCompletion), never touches the
-- network, and only suggests when the text before the cursor ends with one of
-- the SUGGESTIONS keys below, so other tests never see ghost text.

local here = vim.fs.dirname(arg[0])
package.path = here .. '/?.lua;' .. package.path
local rpc = require('jsonrpc')

local SUGGESTIONS = {
  ['const answer = '] = '42;',
  ['function greet('] = "name) {\n  return 'hello ' + name;\n}",
  ['The quick brown '] = 'fox jumps over the lazy dog.',
  ['greeting: '] = 'hello world',
  ['return '] = "'from ai';",
  ['class Greeter '] = "{\n  hello = 'world';\n}",
  -- Collides with the `lorem` snippet trigger.
  ['lorem'] = ' ipsum from ai',
  -- Collides with the completion menu (the fake language server offers e2e*).
  ['x := e2e'] = 'Alpha() // from ai',
}

local docs = rpc.documents('E2E_FAKE_COPILOT_STATE')

local handlers = {}

handlers['initialize'] = function()
  return {
    serverInfo = { name = 'e2e-fake-copilot', version = '1.0.0', nodeVersion = '20.0.0' },
    capabilities = {
      textDocumentSync = { openClose = true, change = 2 },
      inlineCompletionProvider = vim.empty_dict(),
      workspace = { workspaceFolders = { supported = true, changeNotifications = true } },
    },
  }
end

handlers['initialized'] = function()
  rpc.notify('didChangeStatus', { kind = 'Normal', message = '' })
end

handlers['shutdown'] = function()
  return nil
end

handlers['textDocument/didOpen'] = function(params)
  docs.open(params.textDocument)
end

handlers['textDocument/didChange'] = function(params)
  docs.change(params)
end

handlers['textDocument/didClose'] = function(params)
  docs.close(params.textDocument.uri)
end

handlers['checkStatus'] = function()
  return { status = 'OK', user = 'e2e' }
end

handlers['getVersion'] = function()
  return { version = '1.0.0' }
end

local function inline_completion(params)
  local doc = docs.get(params.textDocument.uri)
  if not doc then
    return { items = {} }
  end
  local pos = params.position
  local line = doc.lines[pos.line + 1] or ''
  local prefix = line:sub(1, pos.character)
  for trigger, text in pairs(SUGGESTIONS) do
    if vim.endswith(prefix, trigger) then
      return {
        items = {
          {
            insertText = prefix .. text,
            range = { start = { line = pos.line, character = 0 }, ['end'] = { line = pos.line, character = #line } },
            command = { title = 'accepted', command = 'e2e.accepted', arguments = {} },
          },
        },
      }
    end
  end
  return { items = {} }
end

handlers['textDocument/inlineCompletion'] = inline_completion
-- Older clients (copilot.lua < 2) use the pre-LSP-standard methods.
handlers['getCompletions'] = function(params)
  local result = inline_completion({ textDocument = params.doc or params.textDocument, position = params.doc and params.doc.position or params.position })
  local completions = {}
  for _, item in ipairs(result.items) do
    completions[#completions + 1] = {
      text = item.insertText,
      displayText = item.insertText,
      range = item.range,
      position = item.range['end'],
      uuid = 'e2e',
    }
  end
  return { completions = completions }
end
handlers['getCompletionsCycling'] = handlers['getCompletions']

rpc.serve(handlers)
