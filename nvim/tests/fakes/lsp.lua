-- Deterministic fake language server for the e2e suite.
--
--   nvim --clean -l fakes/lsp.lua
--
-- It lets the suite exercise every LSP-driven workflow (completion, jumps,
-- hover, rename, code actions, formatting, diagnostics...) through whatever
-- client the config uses (coc.nvim today, maybe native LSP tomorrow) without
-- depending on real language servers.
--
-- Semantics, applied to open buffers and to files under the workspace root:
--   declaration  `NAME` right after func/function/def/const/let/var/local/
--                type/class/interface/struct, or a Go method `func (r T) NAME`
--   definition   the declaration of the word under the cursor
--   typeDef      the first Capitalized word after NAME on its declaration line,
--                resolved to its declaration
--   implementation  every `X implements NAME` (points at X)
--   references   every whole-word occurrence of NAME
--   hover        "NAME: e2e hover"; words starting with "long" get 80 lines
--   rename       replaces every whole-word occurrence
--   codeAction   "e2e: uppercase" (uppercases the selection, or the word);
--                "e2e: organize imports" (kind source.organizeImports) sorts
--                the leading `import` lines
--   formatting   collapses runs of 2+ spaces between words, strips trailing
--                whitespace (range formatting limits it to the range)
--   signature    innermost unclosed `NAME(` gives `NAME(first, second)`
--   completion   e2eAlpha, e2eBeta, e2eGamma and a snippet item e2eSnippet
--   diagnostics  every ERROR / WARNING / INFO / HINT token

local here = vim.fs.dirname(arg[0])
package.path = here .. '/?.lua;' .. package.path
local rpc = require('jsonrpc')

local docs = rpc.documents('E2E_FAKE_LSP_STATE')
local root

local IDENT = '[%w_]'

local function uri_to_path(uri)
  return vim.uri_to_fname(uri)
end

local function path_to_uri(path)
  return vim.uri_from_fname(path)
end

-- All known documents: open buffers win over files on disk.
local function workspace()
  local result = {}
  local seen = {}
  for uri, doc in pairs(docs.all()) do
    result[#result + 1] = { uri = uri, lines = doc.lines }
    seen[uri] = true
  end
  if root then
    for name, type in vim.fs.dir(root, {
      depth = 6,
      skip = function(dir)
        return not (dir:match('^%.git$') or dir:match('node_modules'))
      end,
    }) do
      if type == 'file' then
        local path = root .. '/' .. name
        local uri = path_to_uri(path)
        if not seen[uri] then
          local f = io.open(path, 'r')
          if f then
            local text = f:read('*a')
            f:close()
            if not text:find('\0', 1, true) then
              result[#result + 1] = { uri = uri, lines = vim.split(text, '\n', { plain = true }) }
            end
          end
        end
      end
    end
  end
  table.sort(result, function(a, b)
    return a.uri < b.uri
  end)
  return result
end

-- Current document first, then the rest of the workspace.
local function ordered_docs(current_uri)
  local all = workspace()
  local ordered = {}
  for _, d in ipairs(all) do
    if d.uri == current_uri then
      table.insert(ordered, 1, d)
    else
      ordered[#ordered + 1] = d
    end
  end
  return ordered
end

local function word_at(lines, pos)
  local line = lines[pos.line + 1] or ''
  local col = pos.character + 1
  local s, e = col, col - 1
  while s > 1 and line:sub(s - 1, s - 1):match(IDENT) do
    s = s - 1
  end
  while line:sub(e + 1, e + 1):match(IDENT) do
    e = e + 1
  end
  if e < s then
    return nil
  end
  return line:sub(s, e), s - 1, e
end

local function range(line, s, e)
  return { start = { line = line, character = s }, ['end'] = { line = line, character = e } }
end

local function occurrences(lines, name)
  local found = {}
  for i, line in ipairs(lines) do
    local init = 1
    while true do
      local s, e = line:find('%f[%w_]' .. vim.pesc(name) .. '%f[^%w_]', init)
      if not s then
        break
      end
      found[#found + 1] = { line = i - 1, s = s - 1, e = e }
      init = e + 1
    end
  end
  return found
end

local DECL = { 'func', 'function', 'def', 'const', 'let', 'var', 'local', 'type', 'class', 'interface', 'struct' }

local function find_declaration(current_uri, name, keywords)
  for _, d in ipairs(ordered_docs(current_uri)) do
    for i, line in ipairs(d.lines) do
      for _, kw in ipairs(keywords or DECL) do
        local s, e = line:find('%f[%w_]' .. kw .. '%s+' .. vim.pesc(name) .. '%f[^%w_]')
        if s then
          local ns = e - #name
          return { uri = d.uri, range = range(i - 1, ns, e), line = line, name_end = e }
        end
      end
      if not keywords then
        local s, e = line:find('func%s+%b()%s*' .. vim.pesc(name) .. '%f[^%w_]')
        if s then
          return { uri = d.uri, range = range(i - 1, e - #name, e), line = line, name_end = e }
        end
      end
    end
  end
end

local function current(params)
  local doc = docs.get(params.textDocument.uri)
  if not doc then
    return nil
  end
  local name = word_at(doc.lines, params.position)
  return doc, name
end

local diagnostic_tokens = {
  { token = 'ERROR', severity = 1, message = 'e2e error' },
  { token = 'WARNING', severity = 2, message = 'e2e warning' },
  { token = 'INFO', severity = 3, message = 'e2e info' },
  { token = 'HINT', severity = 4, message = 'e2e hint' },
}

local function publish_diagnostics(doc)
  local diagnostics = {}
  for _, def in ipairs(diagnostic_tokens) do
    for _, o in ipairs(occurrences(doc.lines, def.token)) do
      diagnostics[#diagnostics + 1] = {
        range = range(o.line, o.s, o.e),
        severity = def.severity,
        source = 'e2e',
        message = def.message,
      }
    end
  end
  table.sort(diagnostics, function(a, b)
    return a.range.start.line < b.range.start.line
  end)
  rpc.notify('textDocument/publishDiagnostics', { uri = doc.uri, diagnostics = diagnostics })
end

local function format_line(line)
  line = line:gsub('%s+$', '')
  local indent, body = line:match('^(%s*)(.*)$')
  body = body:gsub('(%S)%s%s+(%S)', '%1 %2')
  -- a second pass catches overlapping matches such as "a  b  c"
  body = body:gsub('(%S)%s%s+(%S)', '%1 %2')
  return indent .. body
end

local function format_edits(doc, first, last)
  local edits = {}
  for i = first, last do
    local line = doc.lines[i + 1]
    if line then
      local formatted = format_line(line)
      if formatted ~= line then
        edits[#edits + 1] = { range = range(i, 0, #line), newText = formatted }
      end
    end
  end
  return edits
end

local handlers = {}

handlers['initialize'] = function(params)
  if params.rootUri and params.rootUri ~= vim.NIL then
    root = uri_to_path(params.rootUri)
  elseif params.rootPath and params.rootPath ~= vim.NIL then
    root = params.rootPath
  end
  return {
    serverInfo = { name = 'e2e-fake-lsp', version = '1.0.0' },
    capabilities = {
      textDocumentSync = { openClose = true, change = 1, save = { includeText = false } },
      completionProvider = { triggerCharacters = { '.' }, resolveProvider = false },
      hoverProvider = true,
      signatureHelpProvider = { triggerCharacters = { '(', ',' } },
      definitionProvider = true,
      typeDefinitionProvider = true,
      implementationProvider = true,
      referencesProvider = true,
      documentHighlightProvider = true,
      codeActionProvider = { codeActionKinds = { 'quickfix', 'refactor.rewrite', 'source.organizeImports' } },
      documentFormattingProvider = true,
      documentRangeFormattingProvider = true,
      renameProvider = { prepareProvider = true },
      executeCommandProvider = { commands = { 'e2e.noop' } },
    },
  }
end

handlers['shutdown'] = function()
  return nil
end

handlers['textDocument/didOpen'] = function(params)
  publish_diagnostics(docs.open(params.textDocument))
end

handlers['textDocument/didChange'] = function(params)
  local doc = docs.change(params)
  if doc then
    publish_diagnostics(doc)
  end
end

handlers['textDocument/didClose'] = function(params)
  docs.close(params.textDocument.uri)
end

handlers['textDocument/completion'] = function()
  return {
    isIncomplete = false,
    items = {
      { label = 'e2eAlpha', kind = 3, detail = 'func e2eAlpha()', sortText = '1' },
      { label = 'e2eBeta', kind = 6, detail = 'var e2eBeta', sortText = '2' },
      { label = 'e2eGamma', kind = 2, detail = 'method e2eGamma()', sortText = '3' },
      {
        label = 'e2eSnippet',
        kind = 15,
        detail = 'snippet e2eSnippet(first, second)',
        sortText = '4',
        insertTextFormat = 2,
        insertText = 'e2eSnippet(${1:first}, ${2:second})$0',
      },
    },
  }
end

handlers['textDocument/hover'] = function(params)
  local _, name = current(params)
  if not name then
    return nil
  end
  local lines = { '```e2e', name .. ': e2e hover', '```' }
  if name:match('^long') then
    for i = 1, 80 do
      lines[#lines + 1] = ('hover line %d'):format(i)
    end
  end
  return { contents = { kind = 'markdown', value = table.concat(lines, '\n') } }
end

handlers['textDocument/signatureHelp'] = function(params)
  local doc = docs.get(params.textDocument.uri)
  if not doc then
    return nil
  end
  local line = (doc.lines[params.position.line + 1] or ''):sub(1, params.position.character)
  -- innermost unclosed call
  local depth, name, commas = 0, nil, 0
  for i = #line, 1, -1 do
    local c = line:sub(i, i)
    if c == ')' then
      depth = depth + 1
    elseif c == '(' then
      if depth == 0 then
        name = line:sub(1, i - 1):match('([%w_]+)%s*$')
        break
      end
      depth = depth - 1
    elseif c == ',' and depth == 0 then
      commas = commas + 1
    end
  end
  if not name then
    return nil
  end
  return {
    signatures = {
      {
        label = name .. '(first, second)',
        parameters = { { label = 'first' }, { label = 'second' } },
      },
    },
    activeSignature = 0,
    activeParameter = math.min(commas, 1),
  }
end

handlers['textDocument/definition'] = function(params)
  local _, name = current(params)
  if not name then
    return nil
  end
  local decl = find_declaration(params.textDocument.uri, name)
  if not decl then
    return nil
  end
  return { uri = decl.uri, range = decl.range }
end

handlers['textDocument/typeDefinition'] = function(params)
  local _, name = current(params)
  if not name then
    return nil
  end
  local decl = find_declaration(params.textDocument.uri, name)
  if not decl then
    return nil
  end
  local type_name = decl.line:sub(decl.name_end + 1):match('%f[%w_]([A-Z][%w_]*)')
  if not type_name then
    return nil
  end
  local type_decl = find_declaration(params.textDocument.uri, type_name, { 'type', 'class', 'interface', 'struct' })
  if not type_decl then
    return nil
  end
  return { uri = type_decl.uri, range = type_decl.range }
end

handlers['textDocument/implementation'] = function(params)
  local _, name = current(params)
  if not name then
    return nil
  end
  local result = {}
  for _, d in ipairs(ordered_docs(params.textDocument.uri)) do
    for i, line in ipairs(d.lines) do
      local s, e = line:find('([%w_]+)%s+implements%s+' .. vim.pesc(name) .. '%f[^%w_]')
      if s then
        local impl = line:match('([%w_]+)%s+implements')
        result[#result + 1] = { uri = d.uri, range = range(i - 1, s - 1, s - 1 + #impl) }
      end
    end
  end
  return result
end

handlers['textDocument/references'] = function(params)
  local _, name = current(params)
  if not name then
    return nil
  end
  local include_decl = params.context == nil or params.context.includeDeclaration ~= false
  local decl = find_declaration(params.textDocument.uri, name)
  local result = {}
  for _, d in ipairs(ordered_docs(params.textDocument.uri)) do
    for _, o in ipairs(occurrences(d.lines, name)) do
      local is_decl = decl and decl.uri == d.uri and decl.range.start.line == o.line and decl.range.start.character == o.s
      if include_decl or not is_decl then
        result[#result + 1] = { uri = d.uri, range = range(o.line, o.s, o.e) }
      end
    end
  end
  return result
end

handlers['textDocument/documentHighlight'] = function(params)
  local doc, name = current(params)
  if not name then
    return nil
  end
  local result = {}
  for _, o in ipairs(occurrences(doc.lines, name)) do
    result[#result + 1] = { range = range(o.line, o.s, o.e), kind = 1 }
  end
  return result
end

handlers['textDocument/prepareRename'] = function(params)
  local doc = docs.get(params.textDocument.uri)
  if not doc then
    return nil
  end
  local name, s, e = word_at(doc.lines, params.position)
  if not name then
    return nil
  end
  return { range = range(params.position.line, s, e), placeholder = name }
end

handlers['textDocument/rename'] = function(params)
  local _, name = current(params)
  if not name then
    return nil
  end
  local changes = {}
  for _, d in ipairs(ordered_docs(params.textDocument.uri)) do
    for _, o in ipairs(occurrences(d.lines, name)) do
      changes[d.uri] = changes[d.uri] or {}
      table.insert(changes[d.uri], { range = range(o.line, o.s, o.e), newText = params.newName })
    end
  end
  return { changes = changes }
end

local function wants(only, kind)
  if only == nil then
    return true
  end
  for _, k in ipairs(only) do
    if kind == k or vim.startswith(kind, k .. '.') then
      return true
    end
  end
  return false
end

handlers['textDocument/codeAction'] = function(params)
  local doc = docs.get(params.textDocument.uri)
  if not doc then
    return {}
  end
  local only = params.context and params.context.only
  local actions = {}

  if wants(only, 'refactor.rewrite') then
    local r = params.range
    local edit_range, text
    if r.start.line == r['end'].line and r.start.character ~= r['end'].character then
      local line = doc.lines[r.start.line + 1] or ''
      edit_range = r
      text = line:sub(r.start.character + 1, r['end'].character)
    else
      local name, s, e = word_at(doc.lines, r.start)
      if name then
        edit_range = range(r.start.line, s, e)
        text = name
      end
    end
    if text then
      actions[#actions + 1] = {
        title = 'e2e: uppercase',
        kind = 'refactor.rewrite',
        edit = { changes = { [doc.uri] = { { range = edit_range, newText = text:upper() } } } },
      }
    end
  end

  if only and wants(only, 'source.organizeImports') then
    local first, last
    for i, line in ipairs(doc.lines) do
      if line:match('^import%s') then
        first = first or i
        last = i
      elseif first then
        break
      end
    end
    if first then
      local imports = vim.list_slice(doc.lines, first, last)
      local sorted = vim.deepcopy(imports)
      table.sort(sorted)
      actions[#actions + 1] = {
        title = 'e2e: organize imports',
        kind = 'source.organizeImports',
        edit = {
          changes = {
            [doc.uri] = {
              {
                range = { start = { line = first - 1, character = 0 }, ['end'] = { line = last, character = 0 } },
                newText = table.concat(sorted, '\n') .. '\n',
              },
            },
          },
        },
      }
    end
  end

  return actions
end

handlers['textDocument/formatting'] = function(params)
  local doc = docs.get(params.textDocument.uri)
  if not doc then
    return {}
  end
  return format_edits(doc, 0, #doc.lines - 1)
end

handlers['textDocument/rangeFormatting'] = function(params)
  local doc = docs.get(params.textDocument.uri)
  if not doc then
    return {}
  end
  return format_edits(doc, params.range.start.line, params.range['end'].line)
end

handlers['workspace/executeCommand'] = function()
  return nil
end

rpc.serve(handlers)
