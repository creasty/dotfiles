local M = {}

M.schema = require('candle.schema')

M.highlight = setmetatable({}, {
  __newindex = function(_, hlgroup, opt)
    vim.api.nvim_set_hl(0, hlgroup, opt)
  end
})

function M.setup()
  local hi = M.highlight
  local s = M.schema

  -- Vim editor colors
  hi.Bold = { bold = 1 }
  hi.ColorColumn = { bg = s.guide }
  hi.Conceal = { fg = s.aqua }
  hi.Cursor = { fg = s.background, bg = s.foreground }
  hi.CursorColumn = { bg = s.line }
  hi.CursorLine = { bg = s.line }
  hi.CursorLineNr = { bg = s.line, bold = 1 }
  hi.Debug = { fg = s.brown }
  hi.Directory = { fg = s.blue }
  hi.Error = { fg = s.red }
  hi.ErrorMsg = { fg = s.background, bg = s.red }
  hi.Exception = { fg = s.purple }
  hi.FoldColumn = { fg = s.selection, bg = s.background }
  hi.Folded = { fg = s.comment, bg = s.background, underline = 1 }
  hi.IncSearch = { fg = s.yellow, bg = s.dark_yellow, bold = 1 }
  hi.LineNr = { fg = s.gray200, bg = s.background }
  hi.Macro = { fg = s.purple }
  hi.MatchParen = { bg = s.selection }
  hi.ModeMsg = { fg = s.green, bold = 1 }
  hi.MoreMsg = { fg = s.green, bold = 1 }
  hi.NonText = { fg = s.gray500, bold = 1 }
  hi.Normal = { fg = s.foreground }
  hi.PMenu = { fg = s.foreground, bg = s.gray500 }
  hi.PMenuSbar = { bg = s.window }
  hi.PMenuSel = { fg = s.foreground, bg = s.selection }
  hi.PMenuThumb = { bg = s.gray300 }
  hi.Question = { fg = s.background, bg = s.green, bold = 1 }
  hi.Search = { fg = s.yellow, bg = s.dark_yellow, bold = 1 }
  hi.SignColumn = { fg = s.gray200, bg = s.background }
  hi.SpecialKey = { fg = s.dark_aqua }
  hi.StatusLine = { fg = s.comment, bg = s.window }
  hi.StatusLineNC = {}
  hi.TabLine = { fg = s.comment, bg = s.window }
  hi.TabLineFill = { fg = s.comment, bg = s.window }
  hi.TabLineSel = { fg = s.foreground, bg = s.window }
  hi.Title = { fg = s.foreground, bold = 1 }
  hi.WinSeparator = { fg = s.gray400 }
  hi.Visual = { bg = s.selection }
  hi.WarningMsg = { fg = s.red }
  hi.WildMenu = { fg = s.yellow, bg = s.background }

  hi.BorderedFloat = { fg = s.foreground, bg = s.background }
  hi.FloatBorder = { fg = s.gray400, bg = s.background }
  hi.NvimInternalError = { fg = s.background, bg = s.red }

  -- Standard syntax highlighting
  hi.Boolean = { fg = s.orange }
  hi.Character = { fg = s.orange }
  hi.Comment = { fg = s.comment }
  hi.Conditional = { fg = s.purple }
  hi.Constant = { fg = s.yellow }
  hi.Define = { fg = s.purple }
  hi.Delimiter = { fg = s.gray200 }
  hi.Float = { fg = s.orange }
  hi.Function = { fg = s.pink }
  hi.Identifier = { fg = s.blue }
  hi.Include = { fg = s.purple }
  hi.Keyword = { fg = s.purple }
  hi.Label = { fg = s.purple }
  hi.Number = { fg = s.orange }
  hi.Operator = { fg = s.aqua }
  hi.PreProc = { fg = s.brown }
  hi.Repeat = { fg = s.purple }
  hi.Special = { fg = s.aqua }
  hi.SpecialChar = { fg = s.bright_green }
  hi.SpecialComment = { fg = s.green }
  hi.Statement = { fg = s.purple, bold = 1 }
  hi.StorageClass = { fg = s.yellow }
  hi.String = { fg = s.green }
  hi.Structure = { fg = s.purple }
  hi.Tag = { fg = s.yellow }
  hi.Todo = { fg = s.background, bg = s.comment }
  hi.Type = { fg = s.yellow }
  hi.Typedef = { fg = s.purple }

  -- Spelling highlighting
  hi.SpellBad = { undercurl = 1, sp = s.bright_red }
  hi.SpellLocal = { undercurl = 1, sp = s.bright_aqua }
  hi.SpellCap = { undercurl = 1, sp = s.bright_blue }
  hi.SpellRare = { undercurl = 1, sp = s.bright_purple }

  -- Diff highlighting
  hi.DiffAdd = { fg = s.green }
  hi.DiffChange = { fg = s.blue }
  hi.DiffDelete = { fg = s.red }
  hi.DiffText = { fg = s.blue, bold = 1 }

  -- LSP
  -- hi.LspReferenceText = {  }
  hi.LspDiagnosticsDefaultError = { fg = s.red }
  hi.LspDiagnosticsDefaultWarning = { fg = s.yellow }
  hi.LspDiagnosticsDefaultInformation = { fg = s.blue }
  hi.LspDiagnosticsDefaultHint = { fg = s.green }
  hi.LspDiagnosticsUnderlineError = { undercurl = 1, sp = s.bright_red }
  hi.LspDiagnosticsUnderlineWarning = { undercurl = 1, sp = s.bright_yellow }
  hi.LspDiagnosticsUnderlineInformation = { undercurl = 1, sp = s.bright_blue }
  hi.LspDiagnosticsUnderlineHint = { undercurl = 1, sp = s.bright_green }

  -- Treesitter
  -- hi.TSError = { bg = s.dark_red }
  hi.TSAnnotation = { fg = s.brown }
  hi.TSAttribute = { fg = s.yellow }
  hi.TSConstBuiltin = { fg = s.yellow, italic = 1 }
  hi.TSConstMacro = { fg = s.yellow, bold = 1 }
  hi.TSConstant = { fg = s.orange }
  hi.TSConstructor = { fg = s.yellow }
  hi.TSEmphasis = { italic = 1 }
  hi.TSField = { fg = s.brown }
  hi.TSFuncBuiltin = { fg = s.pink, italic = 1 }
  hi.TSFuncMacro = { fg = s.pink, bold = 1 }
  hi.TSKeywordOperator = { fg = s.aqua, italic = 1 }
  hi.TSLiteral = { fg = s.orange }
  hi.TSNamespace = { fg = s.brown }
  hi.TSNone = { fg = s.foreground }
  hi.TSProperty = { fg = s.brown }
  hi.TSStrike = { strikethrough = 1 }
  hi.TSStringEscape = { fg = s.dark_aqua }
  hi.TSStringRegex = { fg = s.aqua }
  hi.TSStrong = { bold = 1 }
  hi.TSSymbol = { fg = s.red }
  hi.TSTag = { fg = s.yellow }
  hi.TSTagDelimiter = { fg = s.gray200 }
  hi.TSTypeBuiltin = { fg = s.yellow, italic = 1 }
  hi.TSURI = { underline = 1, sp = s.bright_blue }
  hi.TSUnderline = { underline = 1 }
  hi.TSVariable = { fg = s.blue }
  hi.TSVariableBuiltin = { fg = s.blue, italic = 1 }

  -- custom
  hi.StatusLineL0 = { fg = s.foreground, bg = s.window }
  hi.StatusLineMode = { fg = s.foreground, bg = s.window }
  hi.StatusLineDiagnosticsError = { fg = s.red, bg = s.window }
  hi.StatusLineDiagnosticsWarning = { fg = s.yellow, bg = s.window }
  hi.StatusLineDiagnosticsInfo = { fg = s.blue, bg = s.window }
  hi.StatusLineDiagnosticsHint = { fg = s.green, bg = s.window }

  hi.FullwidthSpace = { bg = s.dark_purple }
  hi.GitConflictMarker = { fg = s.red, bg = s.dark_red }
  hi.ExtraWhitespace = { bg = s.line }
  hi.SnipPlaceholder = { fg = s.blue, bg = s.dark_blue }

  -- coc.nvim
  hi.CocHighlightText = { bg = s.selection }
  hi.CocErrorSign = { fg = s.red }
  hi.CocWarningSign = { fg = s.yellow }
  hi.CocInfoSign = { fg = s.blue }
  hi.CocHintSign = { fg = s.green }
  hi.CocErrorHighlight = { undercurl = 1, sp = s.bright_red }
  hi.CocWarningHighlight = { undercurl = 1, sp = s.bright_yellow }
  hi.CocInfoHighlight = { undercurl = 1, sp = s.bright_blue }
  hi.CocHintHighlight = { undercurl = 1, sp = s.bright_green }
  hi.CocDiffAdd = { fg = s.dark_green }
  hi.CocDiffChange = { fg = s.dark_blue }
  hi.CocDiffDelete = { fg = s.dark_red }
  hi.CocFadeOut = { fg = s.gray200 }

  -- vim-searchhi
  hi.CurrentSearch = { fg = s.background, bg = s.yellow, bold = 1 }

  -- markdown
  hi.markdownH1 = { fg = s.brown, bold = 1 }
  hi.markdownH2 = { fg = s.brown, bold = 1 }
  hi.markdownH3 = { fg = s.brown, bold = 1 }
  hi.markdownH4 = { fg = s.brown, bold = 1 }
  hi.markdownH5 = { fg = s.brown, bold = 1 }
  hi.markdownH6 = { fg = s.brown, bold = 1 }
  hi.markdownLink = { fg = s.comment }
  hi.markdownLinkText = { fg = s.blue, underline = 1 }
  hi.markdownCode = { fg = s.green }
  hi.markdownCodeBlock = { fg = s.green }
end

M.current_mode = 'n'

function M.update_mode_highlight()
  local mode = vim.api.nvim_get_mode().mode
  if mode == M.current_mode then
    return
  end
  M.current_mode = mode

  local hi = M.highlight
  local s = M.schema
  local color = s.foreground

  if string.match(mode, '^i') then
    color = s.green
  elseif string.match(mode, '[vV\22]$') then
    color = s.orange
  elseif string.match(mode, '^R') or string.match(mode, 'o') then
    color = s.purple
  elseif string.match(mode, '[sS\19]$') then
    color = s.blue
  end

  hi.StatusLineMode = { fg = color, bg = s.window }
  hi.Cursor = { fg = s.background, bg = color }

  if string.match(mode, '[sS\19]$') then
    hi.Visual = { fg = s.blue, bg = s.dark_blue, bold = 1 }
    vim.cmd('redraw')
  else
    hi.Visual = { bg = s.selection }
  end
end

return M
