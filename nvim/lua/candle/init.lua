local M = {}

M.schema = require('candle.schema')

M.highlight = setmetatable({}, {
  __newindex = function(_, hlgroup, opt)
    if opt.clear then vim.cmd('hi clear '..hlgroup) end

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
  hi.Bold = { gui = 'bold' }
  hi.ColorColumn = { bg = s.guide, gui = 'none' }
  hi.Conceal = { fg = s.aqua, clear = true }
  hi.Cursor = { fg = s.background, bg = s.foreground }
  hi.CursorColumn = { bg = s.line, gui = 'none' }
  hi.CursorLine = { bg = s.line, gui = 'none' }
  hi.CursorLineNr = { fg = s.gray200, gui = 'bold' }
  hi.Debug = { fg = s.brown }
  hi.Directory = { fg = s.blue }
  hi.Error = { fg = s.red, bg = 'none' }
  hi.ErrorMsg = { fg = s.background, bg = s.red }
  hi.Exception = { fg = s.purple }
  hi.FoldColumn = { fg = s.selection, bg = s.background }
  hi.Folded = { fg = s.comment, bg = s.background, gui = 'underline' }
  hi.IncSearch = { fg = s.yellow, bg = s.dark_yellow, gui = 'bold' }
  hi.Italic = { gui = 'none' }
  hi.LineNr = { fg = s.gray200, bg = s.background }
  hi.Macro = { fg = s.purple }
  hi.MatchParen = { bg = s.selection }
  hi.ModeMsg = { fg = s.green, gui = 'bold' }
  hi.MoreMsg = { fg = s.green, gui = 'bold' }
  hi.NonText = { fg = s.gray500 }
  hi.Normal = { fg = s.foreground, bg = 'none' }
  hi.PMenu = { fg = s.foreground, bg = s.gray500, gui = 'none' }
  hi.PMenuSbar = { bg = s.window }
  hi.PMenuSel = { fg = s.foreground, bg = s.selection }
  hi.PMenuThumb = { bg = s.gray300 }
  hi.Question = { fg = s.background, bg = s.green }
  hi.Search = { fg = s.yellow, bg = s.dark_yellow, gui = 'bold' }
  hi.SignColumn = { fg = s.gray200, bg = s.background }
  hi.SpecialKey = { fg = s.dark_aqua, gui = 'none' }
  hi.StatusLine = { fg = s.comment, bg = s.window, gui = 'none' }
  hi.StatusLineNC = { fg = s.comment, bg = s.window, gui = 'none' }
  hi.TabLine = { fg = s.comment, bg = s.window, gui = 'none' }
  hi.TabLineFill = { fg = s.comment, bg = s.window, gui = 'none' }
  hi.TabLineSel = { fg = s.window, bg = s.foreground, gui = 'none' }
  hi.Title = { fg = s.foreground, gui = 'bold' }
  hi.Underlined = { fg = s.blue, gui = 'underline' }
  hi.VertSplit = { fg = s.window, bg = s.window, gui = 'none' }
  hi.Visual = { bg = s.selection }
  hi.WarningMsg = { fg = s.red }
  hi.WildMenu = { fg = s.yellow, bg = s.background }

  hi.BorderedFloat = { fg = s.foreground, bg = s.background }
  hi.FloatBorder = { fg = s.foreground, bg = s.background }
  hi.NvimInternalError = { fg = s.background, bg = s.red, gui = 'none' }

  -- Standard syntax highlighting
  hi.Boolean = { fg = s.orange }
  hi.Character = { fg = s.orange }
  hi.Comment = { fg = s.comment }
  hi.Conditional = { fg = s.purple }
  hi.Constant = { fg = s.yellow }
  hi.Define = { fg = s.purple, gui = 'none' }
  hi.Delimiter = { fg = s.gray200 }
  hi.Float = { fg = s.orange }
  hi.Function = { fg = s.pink }
  hi.Identifier = { fg = s.blue, gui = 'none' }
  hi.Include = { fg = s.purple }
  hi.Keyword = { fg = s.purple }
  hi.Label = { fg = s.purple }
  hi.Number = { fg = s.orange }
  hi.Operator = { fg = s.aqua, gui = 'none' }
  hi.PreProc = { fg = s.brown }
  hi.Repeat = { fg = s.purple }
  hi.Special = { fg = s.aqua }
  hi.SpecialChar = { fg = s.bright_green }
  hi.SpecialComment = { fg = s.green }
  hi.Statement = { fg = s.purple }
  hi.StorageClass = { fg = s.yellow }
  hi.String = { fg = s.green }
  hi.Structure = { fg = s.purple }
  hi.Tag = { fg = s.yellow }
  hi.Todo = { fg = s.background, bg = s.comment }
  hi.Type = { fg = s.yellow, gui = 'none' }
  hi.Typedef = { fg = s.purple }

  -- Spelling highlighting
  hi.SpellBad = { gui = 'undercurl', sp = s.bright_red }
  hi.SpellLocal = { gui = 'undercurl', sp = s.bright_aqua }
  hi.SpellCap = { gui = 'undercurl', sp = s.bright_blue }
  hi.SpellRare = { gui = 'undercurl', sp = s.bright_purple }

  -- Diff highlighting
  hi.DiffAdd = { fg = s.green, bg = 'none', gui = 'none' }
  hi.DiffChange = { fg = s.blue, bg = 'none', gui = 'none' }
  hi.DiffDelete = { fg = s.red, bg = 'none', gui = 'none' }
  hi.DiffText = { fg = s.blue, bg = 'none', gui = 'bold' }

  -- LSP
  -- hi.LspReferenceText = {  }
  hi.LspDiagnosticsDefaultError = { fg = s.red, gui = 'none' }
  hi.LspDiagnosticsDefaultWarning = { fg = s.yellow, gui = 'none' }
  hi.LspDiagnosticsDefaultInformation = { fg = s.blue, gui = 'none' }
  hi.LspDiagnosticsDefaultHint = { fg = s.green, gui = 'none' }
  hi.LspDiagnosticsUnderlineError = { gui = 'undercurl', sp = s.bright_red }
  hi.LspDiagnosticsUnderlineWarning = { gui = 'undercurl', sp = s.bright_yellow }
  hi.LspDiagnosticsUnderlineInformation = { gui = 'undercurl', sp = s.bright_blue }
  hi.LspDiagnosticsUnderlineHint = { gui = 'undercurl', sp = s.bright_green }

  -- Treesitter
  -- hi.TSError = { bg = s.dark_red, gui = 'none' }
  hi.TSAnnotation = { fg = s.brown, gui = 'none' }
  hi.TSAttribute = { fg = s.yellow, gui = 'none' }
  hi.TSConstBuiltin = { fg = s.yellow, gui = 'italic' }
  hi.TSConstMacro = { fg = s.yellow, gui = 'bold' }
  hi.TSConstant = { fg = s.orange, gui = 'none' }
  hi.TSConstructor = { fg = s.yellow, gui = 'none' }
  hi.TSEmphasis = { gui = 'italic' }
  hi.TSField = { fg = s.brown, gui = 'none' }
  hi.TSFuncBuiltin = { fg = s.pink, gui = 'italic' }
  hi.TSFuncMacro = { fg = s.pink, gui = 'bold' }
  hi.TSKeywordOperator = { fg = s.aqua, gui = 'italic' }
  hi.TSLiteral = { fg = s.orange, gui = 'none' }
  hi.TSNamespace = { fg = s.brown, gui = 'none' }
  hi.TSNone = { fg = s.foreground, gui = 'none' }
  hi.TSProperty = { fg = s.brown, gui = 'none' }
  hi.TSStrike = { gui = 'strikethrough' }
  hi.TSStringEscape = { fg = s.dark_aqua, gui = 'none' }
  hi.TSStringRegex = { fg = s.aqua, gui = 'none' }
  hi.TSStrong = { gui = 'bold' }
  hi.TSSymbol = { fg = s.red, gui = 'none' }
  hi.TSTag = { fg = s.yellow, gui = 'none' }
  hi.TSTagDelimiter = { fg = s.gray200, gui = 'none' }
  hi.TSTypeBuiltin = { fg = s.yellow, gui = 'italic' }
  hi.TSURI = { gui = 'underline', sp = s.bright_blue }
  hi.TSUnderline = { gui = 'underline' }
  hi.TSVariable = { fg = s.blue, gui = 'none' }
  hi.TSVariableBuiltin = { fg = s.blue, gui = 'italic' }

  -- custom
  hi.StatusLineL0 = { fg = s.foreground, bg = s.window }
  hi.StatusLineMode = { fg = s.foreground, bg = s.window }
  hi.StatusLineDiagnosticsError = { fg = s.red, bg = s.window, gui = 'none' }
  hi.StatusLineDiagnosticsWarning = { fg = s.yellow, bg = s.window, gui = 'none' }
  hi.StatusLineDiagnosticsInfo = { fg = s.blue, bg = s.window, gui = 'none' }
  hi.StatusLineDiagnosticsHint = { fg = s.green, bg = s.window, gui = 'none' }

  hi.FullwidthSpace = { bg = s.dark_purple }
  hi.GitConflictMarker = { fg = s.red, bg = s.dark_red }
  hi.ExtraWhitespace = { bg = s.line }
  hi.SnipPlaceholder = { fg = s.blue, bg = s.dark_blue }

  -- coc.nvim
  hi.CocHighlightText = { bg = s.selection, gui = 'none' }
  hi.CocErrorSign = { fg = s.red }
  hi.CocWarningSign = { fg = s.yellow }
  hi.CocInfoSign = { fg = s.blue }
  hi.CocHintSign = { fg = s.green }
  hi.CocErrorHighlight = { gui = 'undercurl', sp = s.bright_red }
  hi.CocWarningHighlight = { gui = 'undercurl', sp = s.bright_yellow }
  hi.CocInfoHighlight = { gui = 'undercurl', sp = s.bright_blue }
  hi.CocHintHighlight = { gui = 'undercurl', sp = s.bright_green }
  hi.CocDiffAdd = { fg = s.dark_green, bg = 'none', gui = 'none' }
  hi.CocDiffChange = { fg = s.dark_blue, bg = 'none', gui = 'none' }
  hi.CocDiffDelete = { fg = s.dark_red, bg = 'none', gui = 'none' }
  hi.CocFadeOut = { fg = s.gray200, bg = 'none', gui = 'none' }

  -- vim-searchhi
  hi.CurrentSearch = { fg = s.background, bg = s.yellow, gui = 'bold' }

  -- markdown
  hi.markdownH1 = { fg = s.brown, gui = 'bold' }
  hi.markdownH2 = { fg = s.brown, gui = 'bold' }
  hi.markdownH3 = { fg = s.brown, gui = 'bold' }
  hi.markdownH4 = { fg = s.brown, gui = 'bold' }
  hi.markdownH5 = { fg = s.brown, gui = 'bold' }
  hi.markdownH6 = { fg = s.brown, gui = 'bold' }
  hi.markdownLink = { fg = s.comment }
  hi.markdownLinkText = { fg = s.blue, gui = 'underline' }
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
