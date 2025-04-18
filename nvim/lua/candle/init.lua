local M = {}

M.schema = require('candle.schema')

M.highlight = setmetatable({}, {
  __newindex = function(_, hlgroup, opt)
    -- Color:
    --   fg
    --   bg
    --   sp
    -- Style:
    --   bold
    --   underline
    --   underdouble
    --   undercurl
    --   underdotted
    --   underdashed
    --   strikethrough
    --   reverse / inverse
    --   italic
    --   standout
    -- Link:
    --   link
    --   default (bool)
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
  hi.CurSearch = { fg = s.background, bg = s.yellow, bold = 1 }
  hi.Cursor = { fg = s.background, bg = s.foreground, reverse = 1 }
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
  hi.PMenuSel = { fg = s.foreground, bg = s.gray400 }
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
  hi.Visual = { bg = s.selection }
  hi.WarningMsg = { fg = s.red }
  hi.Whitespace = { fg = s.gray500 }
  hi.WildMenu = { fg = s.yellow, bg = s.background }
  hi.WinSeparator = { fg = s.window }

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

  -- Diagnostic
  hi.DiagnosticError = { fg = s.red }
  hi.DiagnosticWarn = { fg = s.yellow }
  hi.DiagnosticInfo = { fg = s.blue }
  hi.DiagnosticHint = { fg = s.gray200 }
  hi.DiagnosticUnderlineError = { undercurl = 1, sp = s.bright_red }
  hi.DiagnosticUnderlineWarn = { undercurl = 1, sp = s.bright_yellow }
  hi.DiagnosticUnderlineInfo = { undercurl = 1, sp = s.bright_blue }
  hi.DiagnosticUnderlineHint = { undercurl = 1, sp = s.gray200 }

  -- Treesitter
  hi['@annotation'] = { fg = s.brown }
  hi['@attribute'] = { fg = s.yellow }
  hi['@boolean'] = { fg = s.orange }
  hi['@character'] = { fg = s.orange }
  hi['@comment'] = { fg = s.comment }
  hi['@comment.note'] = { fg = s.green }
  hi['@comment.todo'] = { fg = s.background, bg = s.comment }
  hi['@constant'] = { fg = s.orange }
  hi['@constant.builtin'] = { fg = s.yellow, italic = 1 }
  hi['@constant.macro'] = { fg = s.yellow, bold = 1 }
  hi['@constructor'] = { fg = s.yellow }
  hi['@field'] = { fg = s.brown }
  hi['@function'] = { fg = s.pink }
  hi['@function.builtin'] = { fg = s.pink, italic = 1 }
  hi['@function.macro'] = { fg = s.pink, bold = 1 }
  hi['@keyword'] = { fg = s.purple, bold = 1 }
  hi['@keyword.conditional'] = { fg = s.purple }
  hi['@keyword.import'] = { fg = s.purple }
  hi['@keyword.operator'] = { fg = s.aqua, italic = 1 }
  hi['@keyword.repeat'] = { fg = s.purple }
  hi['@label'] = { fg = s.purple }
  hi['@module'] = { fg = s.brown }
  hi['@none'] = { fg = s.foreground } -- ??
  hi['@number'] = { fg = s.orange }
  hi['@number.float'] = { fg = s.orange }
  hi['@property'] = { fg = s.brown }
  hi['@punctuation.delimiter'] = { fg = s.gray200 }
  hi['@punctuation.special'] = { fg = s.aqua }
  hi['@string'] = { fg = s.green }
  hi['@string.escape'] = { fg = s.dark_aqua }
  hi['@string.regex'] = { fg = s.aqua }
  hi['@string.special'] = { fg = s.bright_green }
  hi['@symbol'] = { fg = s.red }
  hi['@tag'] = { fg = s.yellow }
  hi['@tag.attribute'] = { fg = s.brown }
  hi['@tag.delimiter'] = { fg = s.gray200 }
  hi['@text.danger'] = { link = 'ErrorMsg' }
  hi['@text.emphasis'] = { italic = 1 }
  hi['@text.environment'] = { link = 'Macro' }
  hi['@text.environment.name'] = { link = 'Type' }
  hi['@text.literal'] = { fg = s.orange }
  hi['@text.math'] = { link = 'Special' }
  hi['@text.note'] = { link = 'SpecialComment' }
  hi['@text.reference'] = { link = 'Constant' }
  hi['@text.strike'] = { strikethrough = 1 }
  hi['@text.strong'] = { bold = 1 }
  hi['@text.title'] = { link = 'Title' }
  hi['@text.todo'] = { link = 'Todo' }
  hi['@text.underline'] = { underline = 1 }
  hi['@text.uri'] = { underline = 1, sp = s.dark_blue }
  hi['@text.warning'] = { link = 'WarningMsg' }
  hi['@type.builtin'] = { fg = s.yellow, italic = 1 }
  hi['@type.definition'] = { fg = s.purple }
  hi['@variable'] = { fg = s.blue }
  hi['@variable.builtin'] = { fg = s.blue, italic = 1 }
  hi['@variable.member'] = { fg = s.brown }
  hi['@variable.member.private'] = { fg = s.brown, italic = 1 }

  -- custom
  hi.StatusLinePrimary = { fg = s.foreground, bg = s.window }
  hi.StatusLineDiagnosticsError = { fg = s.red, bg = s.window }
  hi.StatusLineDiagnosticsWarning = { fg = s.yellow, bg = s.window }
  hi.StatusLineDiagnosticsInfo = { fg = s.blue, bg = s.window }
  hi.StatusLineDiagnosticsHint = { fg = s.gray200, bg = s.window }

  hi.GitConflictMarker = { link = 'Todo' }
  hi.SnipPlaceholder = { fg = s.blue, bg = s.dark_blue }

  -- coc.nvim
  hi.CocSearch = { fg = s.yellow }
  hi.CocHighlightText = { bg = s.selection }
  hi.CocDiffAdd = { fg = s.dark_green }
  hi.CocDiffChange = { fg = s.dark_blue }
  hi.CocDiffDelete = { fg = s.dark_red }
  hi.CocFadeOut = { fg = s.gray200 }
  hi.CocSnippetVisual = { fg = s.blue, bg = s.dark_blue }
  hi.CocPumDeprecated = { fg = s.gray200, strikethrough = 1 }
  hi.CocPumVirtualText = { fg = s.gray400 }
  hi.CocDialogFloat = { fg = s.foreground, bg = s.background }
  hi.CocDialogFloatBorder = { fg = s.bright_blue, bg = s.background }

  -- copilot.vim
  hi.CopilotSuggestion = { fg = s.gray400, underdotted = 1 }

  -- nvim-treesitter-context
  hi.TreesitterContext = { link = 'Normal' }
  hi.TreesitterContextLineNumber = { fg = s.gray300, bg = s.background }
  hi.TreesitterContextBottom = { sp = s.window, underline = 1 }
  hi.TreesitterContextLineNumberBottom = { sp = s.window, underline = 1 }

  -- markdown
  hi['@markup.quote.markdown'] = { link = '@string' }
  hi['@markup.link.markdown'] = { link = '@tag.delimiter' }
  hi['@markup.link.url.markdown'] = { link = '@text.uri' }
  hi['@markup.link.label.markdown'] = { link = '@constant' }
  hi['@markup.link.markdown_inline'] = { link = '@tag.delimiter' }
  hi['@markup.link.url.markdown_inline'] = { link = '@text.uri' }
  hi['@markup.link.label.markdown_inline'] = { link = '@variable' }

  -- json
  hi['@property.json.2'] = { fg = s.purple }
  hi['@property.json.3'] = { fg = s.blue }
end

return M
