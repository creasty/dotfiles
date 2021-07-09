local M = {}

M.schema = require('candle.schema')

M.highlight = setmetatable({}, {
  __newindex = function(_, hlgroup, opt)
    local cmd = {'hi', hlgroup}
    if opt.fg then table.insert(cmd, 'guifg='..opt.fg) end
    if opt.bg then table.insert(cmd, 'guibg='..opt.bg) end
    if opt.gui then table.insert(cmd, 'gui='..opt.gui) end
    if opt.sp then table.insert(cmd, 'guisp='..opt.sp) end
    vim.cmd(table.concat(cmd, ' '))
  end
})

function M.setup()
  local hi = M.highlight
  local s = M.schema

  -- Vim editor colors
  hi.Bold = { fg = nil, bg = nil, gui = 'bold', sp = nil }
  hi.ColorColumn = { fg = nil, bg = s.guide, gui = 'none', sp = nil }
  hi.Cursor = { fg = s.background, bg = s.foreground, gui = nil, sp = nil }
  hi.CursorColumn = { fg = nil, bg = s.line, gui = 'none', sp = nil }
  hi.CursorLine = { fg = nil, bg = s.line, gui = 'none', sp = nil }
  hi.CursorLineNr = { fg = s.gray200, bg = nil, gui = 'bold', sp = nil }
  hi.Debug = { fg = s.brown, bg = nil, gui = nil, sp = nil }
  hi.Directory = { fg = s.blue, bg = nil, gui = nil, sp = nil }
  hi.Error = { fg = s.red, bg = nil, gui = nil, sp = nil }
  hi.ErrorMsg = { fg = s.background, bg = s.red, gui = nil, sp = nil }
  hi.Exception = { fg = s.purple, bg = nil, gui = nil, sp = nil }
  hi.FoldColumn = { fg = s.selection, bg = s.background, gui = nil, sp = nil }
  hi.Folded = { fg = s.comment, bg = s.background, gui = 'underline', sp = nil }
  hi.IncSearch = { fg = s.yellow, bg = s.dark_yellow, gui = 'none', sp = nil }
  hi.Italic = { fg = nil, bg = nil, gui = 'none', sp = nil }
  hi.LineNr = { fg = s.gray200, bg = s.background, gui = nil, sp = nil }
  hi.Macro = { fg = s.purple, bg = nil, gui = nil, sp = nil }
  hi.MatchParen = { fg = nil, bg = s.selection, gui = nil, sp = nil }
  hi.ModeMsg = { fg = s.green, bg = nil, gui = 'bold', sp = nil }
  hi.MoreMsg = { fg = s.green, bg = nil, gui = 'bold', sp = nil }
  hi.NonText = { fg = s.window, bg = nil, gui = nil, sp = nil }
  hi.Normal = { fg = s.foreground, bg = 'none', gui = nil, sp = nil }
  hi.PMenu = { fg = s.foreground, bg = s.gray500, gui = 'none', sp = nil }
  hi.PMenuSbar = { fg = nil, bg = s.window, gui = nil, sp = nil }
  hi.PMenuSel = { fg = s.foreground, bg = s.selection, gui = nil, sp = nil }
  hi.PMenuThumb = { fg = nil, bg = s.gray300, gui = nil, sp = nil }
  hi.Question = { fg = s.background, bg = s.green, gui = nil, sp = nil }
  hi.Search = { fg = s.background, bg = s.yellow, gui = 'bold', sp = nil }
  hi.SignColumn = { fg = s.gray200, bg = s.background, gui = nil, sp = nil }
  hi.SpecialKey = { fg = s.dark_aqua, bg = nil, gui = 'none', sp = nil }
  hi.StatusLine = { fg = s.comment, bg = s.window, gui = 'none', sp = nil }
  hi.StatusLineNC = { fg = s.comment, bg = s.window, gui = 'none', sp = nil }
  hi.TabLine = { fg = s.comment, bg = s.window, gui = 'none', sp = nil }
  hi.TabLineFill = { fg = s.comment, bg = s.window, gui = 'none', sp = nil }
  hi.TabLineSel = { fg = s.window, bg = s.foreground, gui = 'none', sp = nil }
  hi.Title = { fg = s.foreground, bg = nil, gui = 'bold', sp = nil }
  hi.Underlined = { fg = s.blue, bg = nil, gui = 'underline', sp = nil }
  hi.VertSplit = { fg = s.window, bg = s.window, gui = 'none', sp = nil }
  hi.Visual = { fg = nil, bg = s.selection, gui = nil, sp = nil }
  hi.WarningMsg = { fg = s.red, bg = nil, gui = nil, sp = nil }
  hi.WildMenu = { fg = s.yellow, bg = s.background, gui = nil, sp = nil }

  hi.BorderedFloat = { fg = s.foreground, bg = s.background, gui = nil, sp = nil }
  hi.FloatBorder = { fg = s.foreground, bg = s.background, gui = nil, sp = nil }
  hi.NvimInternalError = { fg = s.background, bg = s.red, gui = 'none', sp = nil }

  -- Standard syntax highlighting
  hi.Boolean = { fg = s.orange, bg = nil, gui = nil, sp = nil }
  hi.Character = { fg = s.orange, bg = nil, gui = nil, sp = nil }
  hi.Comment = { fg = s.comment, bg = nil, gui = nil, sp = nil }
  hi.Conditional = { fg = s.purple, bg = nil, gui = nil, sp = nil }
  hi.Constant = { fg = s.yellow, bg = nil, gui = nil, sp = nil }
  hi.Define = { fg = s.purple, bg = nil, gui = 'none', sp = nil }
  hi.Delimiter = { fg = s.gray200, bg = nil, gui = nil, sp = nil }
  hi.Float = { fg = s.orange, bg = nil, gui = nil, sp = nil }
  hi.Function = { fg = s.pink, bg = nil, gui = nil, sp = nil }
  hi.Identifier = { fg = s.blue, bg = nil, gui = 'none', sp = nil }
  hi.Include = { fg = s.purple, bg = nil, gui = nil, sp = nil }
  hi.Keyword = { fg = s.purple, bg = nil, gui = nil, sp = nil }
  hi.Label = { fg = s.purple, bg = nil, gui = nil, sp = nil }
  hi.Number = { fg = s.orange, bg = nil, gui = nil, sp = nil }
  hi.Operator = { fg = s.aqua, bg = nil, gui = 'none', sp = nil }
  hi.PreProc = { fg = s.brown, bg = nil, gui = nil, sp = nil }
  hi.Repeat = { fg = s.purple, bg = nil, gui = nil, sp = nil }
  hi.Special = { fg = s.aqua, bg = nil, gui = nil, sp = nil }
  hi.SpecialChar = { fg = s.bright_green, bg = nil, gui = nil, sp = nil }
  hi.SpecialComment = { fg = s.green, bg = nil, gui = nil, sp = nil }
  hi.Statement = { fg = s.purple, bg = nil, gui = nil, sp = nil }
  hi.StorageClass = { fg = s.yellow, bg = nil, gui = nil, sp = nil }
  hi.String = { fg = s.green, bg = nil, gui = nil, sp = nil }
  hi.Structure = { fg = s.purple, bg = nil, gui = nil, sp = nil }
  hi.Tag = { fg = s.yellow, bg = nil, gui = nil, sp = nil }
  hi.Todo = { fg = s.background, bg = s.comment, gui = nil, sp = nil }
  hi.Type = { fg = s.yellow, bg = nil, gui = 'none', sp = nil }
  hi.Typedef = { fg = s.purple, bg = nil, gui = nil, sp = nil }

  -- Spelling highlighting
  hi.SpellBad = { fg = nil, bg = nil, gui = 'undercurl', sp = s.bright_red }
  hi.SpellLocal = { fg = nil, bg = nil, gui = 'undercurl', sp = s.bright_aqua }
  hi.SpellCap = { fg = nil, bg = nil, gui = 'undercurl', sp = s.bright_blue }
  hi.SpellRare = { fg = nil, bg = nil, gui = 'undercurl', sp = s.bright_purple }

  -- Diff highlighting
  hi.DiffAdd = { fg = s.green, bg = 'none', gui = 'none', sp = nil }
  hi.DiffChange = { fg = s.blue, bg = 'none', gui = 'none', sp = nil }
  hi.DiffDelete = { fg = s.red, bg = 'none', gui = 'none', sp = nil }
  hi.DiffText = { fg = s.blue, bg = 'none', gui = 'bold', sp = nil }

  -- LSP
  -- hi.LspReferenceText = { fg = nil, bg = nil, gui = nil, sp = nil }
  hi.LspDiagnosticsDefaultError = { fg = s.red, bg = nil, gui = 'none', sp = nil }
  hi.LspDiagnosticsDefaultWarning = { fg = s.yellow, bg = nil, gui = 'none', sp = nil }
  hi.LspDiagnosticsDefaultInformation = { fg = s.blue, bg = nil, gui = 'none', sp = nil }
  hi.LspDiagnosticsDefaultHint = { fg = s.green, bg = nil, gui = 'none', sp = nil }
  hi.LspDiagnosticsUnderlineError = { fg = nil, bg = nil, gui = 'undercurl', sp = s.bright_red }
  hi.LspDiagnosticsUnderlineWarning = { fg = nil, bg = nil, gui = 'undercurl', sp = s.bright_yellow }
  hi.LspDiagnosticsUnderlineInformation = { fg = nil, bg = nil, gui = 'undercurl', sp = s.bright_blue }
  hi.LspDiagnosticsUnderlineHint = { fg = nil, bg = nil, gui = 'undercurl', sp = s.bright_green }

  -- Treesitter
  -- hi.TSError = { fg = nil, bg = s.dark_red, gui = 'none', sp = nil }
  hi.TSAnnotation = { fg = s.brown, bg = nil, gui = 'none', sp = nil }
  hi.TSAttribute = { fg = s.yellow, bg = nil, gui = 'none', sp = nil }
  hi.TSConstBuiltin = { fg = s.yellow, bg = nil, gui = 'italic', sp = nil }
  hi.TSConstMacro = { fg = s.yellow, bg = nil, gui = 'bold', sp = nil }
  hi.TSConstant = { fg = s.orange, bg = nil, gui = 'none', sp = nil }
  hi.TSConstructor = { fg = s.yellow, bg = nil, gui = 'none', sp = nil }
  hi.TSEmphasis = { fg = nil, bg = nil, gui = 'italic', sp = nil }
  hi.TSField = { fg = s.brown, bg = nil, gui = 'none', sp = nil }
  hi.TSFuncBuiltin = { fg = s.pink, bg = nil, gui = 'italic', sp = nil }
  hi.TSFuncMacro = { fg = s.pink, bg = nil, gui = 'bold', sp = nil }
  hi.TSKeywordOperator = { fg = s.aqua, bg = nil, gui = 'italic', sp = nil }
  hi.TSLiteral = { fg = s.orange, bg = nil, gui = 'none', sp = nil }
  hi.TSNamespace = { fg = s.brown, bg = nil, gui = 'none', sp = nil }
  hi.TSNone = { fg = s.foreground, bg = nil, gui = 'none', sp = nil }
  hi.TSProperty = { fg = s.brown, bg = nil, gui = 'none', sp = nil }
  hi.TSStrike = { fg = nil, bg = nil, gui = 'strikethrough', sp = nil }
  hi.TSStringEscape = { fg = s.dark_aqua, bg = nil, gui = 'none', sp = nil }
  hi.TSStringRegex = { fg = s.aqua, bg = nil, gui = 'none', sp = nil }
  hi.TSStrong = { fg = nil, bg = nil, gui = 'bold', sp = nil }
  hi.TSSymbol = { fg = s.red, bg = nil, gui = 'none', sp = nil }
  hi.TSTag = { fg = s.yellow, bg = nil, gui = 'none', sp = nil }
  hi.TSTagDelimiter = { fg = s.gray200, bg = nil, gui = 'none', sp = nil }
  hi.TSTypeBuiltin = { fg = s.yellow, bg = nil, gui = 'italic', sp = nil }
  hi.TSURI = { fg = nil, bg = nil, gui = 'underline', sp = s.bright_blue }
  hi.TSUnderline = { fg = nil, bg = nil, gui = 'underline', sp = nil }
  hi.TSVariable = { fg = s.blue, bg = nil, gui = 'none', sp = nil }
  hi.TSVariableBuiltin = { fg = s.blue, bg = nil, gui = 'italic', sp = nil }

  -- custom
  hi.StatusLineDiagnosticsError = { fg = s.red, bg = s.window, gui = 'none', sp = nil }
  hi.StatusLineDiagnosticsWarning = { fg = s.yellow, bg = s.window, gui = 'none', sp = nil }
  hi.StatusLineDiagnosticsInfo = { fg = s.blue, bg = s.window, gui = 'none', sp = nil }
  hi.StatusLineDiagnosticsHint = { fg = s.green, bg = s.window, gui = 'none', sp = nil }

  hi.FullwidthSpace = { fg = nil, bg = s.dark_purple, gui = nil, sp = nil }
  hi.GitConflictMarker = { fg = s.red, bg = s.dark_red, gui = nil, sp = nil }
  hi.ExtraWhitespace = { fg = nil, bg = s.line, gui = nil, sp = nil }
  hi.SnipPlaceholder = { fg = s.blue, bg = s.dark_blue, gui = nil, sp = nil }

  -- coc.nvim
  hi.CocHighlightText = { fg = nil, bg = s.selection, gui = 'none', sp = nil }
  hi.CocErrorSign = { fg = s.red, bg = nil, gui = nil, sp = nil }
  hi.CocWarningSign = { fg = s.yellow, bg = nil, gui = nil, sp = nil }
  hi.CocInfoSign = { fg = s.blue, bg = nil, gui = nil, sp = nil }
  hi.CocHintSign = { fg = s.green, bg = nil, gui = nil, sp = nil }
  hi.CocErrorHighlight = { fg = nil, bg = nil, gui = 'undercurl', sp = s.bright_red }
  hi.CocWarningHighlight = { fg = nil, bg = nil, gui = 'undercurl', sp = s.bright_yellow }
  hi.CocInfoHighlight = { fg = nil, bg = nil, gui = 'undercurl', sp = s.bright_blue }
  hi.CocHintHighlight = { fg = nil, bg = nil, gui = 'undercurl', sp = s.bright_green }

  -- vim-searchhi
  hi.CurrentSearch = { fg = s.background, bg = s.orange, gui = 'bold', sp = nil }

  -- markdown
  hi.markdownH1 = { fg = s.brown, bg = nil, gui = 'bold', sp = nil }
  hi.markdownH2 = { fg = s.brown, bg = nil, gui = 'bold', sp = nil }
  hi.markdownH3 = { fg = s.brown, bg = nil, gui = 'bold', sp = nil }
  hi.markdownH4 = { fg = s.brown, bg = nil, gui = 'bold', sp = nil }
  hi.markdownH5 = { fg = s.brown, bg = nil, gui = 'bold', sp = nil }
  hi.markdownH6 = { fg = s.brown, bg = nil, gui = 'bold', sp = nil }
  hi.markdownLink = { fg = s.comment, bg = nil, gui = nil, sp = nil }
  hi.markdownLinkText = { fg = s.blue, bg = nil, gui = 'underline', sp = nil }
  hi.markdownCode = { fg = s.green, bg = nil, gui = nil, sp = nil }
  hi.markdownCodeBlock = { fg = s.green, bg = nil, gui = nil, sp = nil }
end

function M.update_mode_highlight(mode)
  local hi = M.highlight
  local s = M.schema
  local color = s.foreground

  if string.match(mode, '^i') then
    color = s.green
  elseif string.match(mode, '[vV]$') then
    color = s.orange
  elseif string.match(mode, '^[rR]') or string.match(mode, 'o') then
    color = s.purple
  elseif string.match(mode, '[sS]$') then
    color = s.blue
  end

  hi.StatusLineMode = { fg = color, bg = s.window, gui = nil, sp = nil }
  hi.Cursor = { fg = s.background, bg = color, gui = nil, sp = nil }

  if string.match(mode, '[sS]$') then
    hi.Visual = { fg = s.blue, bg = s.dark_blue, gui = 'bold', sp = nil }
    vim.cmd('redraw')
  else
    hi.Visual = { fg = 'none', bg = s.selection, gui = 'none', sp = nil }
  end
end

return M
