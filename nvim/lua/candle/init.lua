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
  hi.Conceal = { fg = s.aqua300 }
  hi.CurSearch = { fg = s.background, bg = s.yellow300, bold = 1 }
  hi.Cursor = { fg = s.background, bg = s.foreground, reverse = 1 }
  hi.CursorColumn = { bg = s.line }
  hi.CursorLine = { bg = s.line }
  hi.CursorLineNr = { bg = s.line, bold = 1 }
  hi.Debug = { fg = s.orange500 }
  hi.Directory = { fg = s.blue300 }
  hi.Error = { fg = s.red300 }
  hi.ErrorMsg = { fg = s.background, bg = s.red300 }
  hi.Exception = { fg = s.purple300 }
  hi.FoldColumn = { fg = s.selection, bg = s.background }
  hi.Folded = { fg = s.comment, bg = s.background, underline = 1 }
  hi.IncSearch = { fg = s.yellow300, bg = s.yellow700, bold = 1 }
  hi.LineNr = { fg = s.gray450, bg = s.background }
  hi.Macro = { fg = s.purple300 }
  hi.MatchParen = { bg = s.selection }
  hi.ModeMsg = { fg = s.green300, bold = 1 }
  hi.MoreMsg = { fg = s.green300, bold = 1 }
  hi.NonText = { fg = s.gray825, bold = 1 }
  hi.Normal = { fg = s.foreground }
  hi.PMenu = { fg = s.foreground, bg = s.gray825 }
  hi.PMenuSbar = { bg = s.window }
  hi.PMenuSel = { fg = s.foreground, bg = s.gray700 }
  hi.PMenuThumb = { bg = s.gray600 }
  hi.Question = { fg = s.background, bg = s.green300, bold = 1 }
  hi.Search = { fg = s.yellow300, bg = s.yellow700, bold = 1 }
  hi.SignColumn = { fg = s.gray450, bg = s.background }
  hi.SpecialKey = { fg = s.aqua700 }
  hi.StatusLine = { fg = s.foreground, bg = s.window }
  hi.StatusLineNC = {}
  hi.TabLine = { fg = s.comment, bg = s.window }
  hi.TabLineFill = { fg = s.comment, bg = s.window }
  hi.TabLineSel = { fg = s.foreground, bg = s.window }
  hi.TabLineActivity = { fg = s.gray450, bg = s.window }
  hi.Title = { fg = s.foreground, bold = 1 }
  hi.Visual = { bg = s.selection }
  hi.WarningMsg = { fg = s.red300 }
  hi.Whitespace = { fg = s.gray825 }
  hi.WildMenu = { fg = s.yellow300, bg = s.background }
  hi.WinSeparator = { fg = s.window }

  hi.BorderedFloat = { fg = s.foreground, bg = s.background }
  hi.FloatBorder = { fg = s.gray700, bg = s.background }
  hi.NvimInternalError = { fg = s.background, bg = s.red300 }

  -- Standard syntax highlighting
  hi.Boolean = { fg = s.orange300 }
  hi.Character = { fg = s.orange300 }
  hi.Comment = { fg = s.comment }
  hi.Conditional = { fg = s.purple300 }
  hi.Constant = { fg = s.yellow300 }
  hi.Define = { fg = s.purple300 }
  hi.Delimiter = { fg = s.gray450 }
  hi.Float = { fg = s.orange300 }
  hi.Function = { fg = s.pink300 }
  hi.Identifier = { fg = s.blue300 }
  hi.Include = { fg = s.purple300 }
  hi.Keyword = { fg = s.purple300 }
  hi.Label = { fg = s.purple300 }
  hi.Number = { fg = s.orange300 }
  hi.Operator = { fg = s.aqua300 }
  hi.PreProc = { fg = s.orange500 }
  hi.Repeat = { fg = s.purple300 }
  hi.Special = { fg = s.aqua300 }
  hi.SpecialChar = { fg = s.green200 }
  hi.SpecialComment = { fg = s.green300 }
  hi.Statement = { fg = s.purple300, bold = 1 }
  hi.StorageClass = { fg = s.yellow300 }
  hi.String = { fg = s.green300 }
  hi.Structure = { fg = s.purple300 }
  hi.Tag = { fg = s.yellow300 }
  hi.Todo = { fg = s.background, bg = s.comment }
  hi.Type = { fg = s.yellow300 }
  hi.Typedef = { fg = s.purple300 }

  -- Spelling highlighting
  hi.SpellBad = { undercurl = 1, sp = s.red200 }
  hi.SpellLocal = { undercurl = 1, sp = s.aqua200 }
  hi.SpellCap = { undercurl = 1, sp = s.blue200 }
  hi.SpellRare = { undercurl = 1, sp = s.purple200 }

  -- Diff highlighting: backgrounds only, so the syntax shows through
  hi.DiffAdd = { bg = s.green850 }
  hi.DiffChange = { bg = s.gray875 }
  hi.DiffDelete = { bg = s.red850 }
  hi.DiffText = { bg = s.blue850 }

  -- LSP
  -- hi.LspReferenceText = {  }

  -- Diagnostic
  hi.DiagnosticError = { fg = s.red300 }
  hi.DiagnosticWarn = { fg = s.yellow300 }
  hi.DiagnosticInfo = { fg = s.blue300 }
  hi.DiagnosticHint = { fg = s.gray450 }
  hi.DiagnosticUnderlineError = { undercurl = 1, sp = s.red200 }
  hi.DiagnosticUnderlineWarn = { undercurl = 1, sp = s.yellow200 }
  hi.DiagnosticUnderlineInfo = { undercurl = 1, sp = s.blue200 }
  hi.DiagnosticUnderlineHint = { undercurl = 1, sp = s.gray450 }

  -- Treesitter
  hi['@attribute'] = { fg = s.yellow300 }
  hi['@boolean'] = { fg = s.orange300 }
  hi['@character'] = { fg = s.orange300 }
  hi['@comment'] = { fg = s.comment }
  hi['@comment.error'] = { link = 'ErrorMsg' }
  hi['@comment.note'] = { fg = s.green300 }
  hi['@comment.todo'] = { fg = s.background, bg = s.comment }
  hi['@comment.warning'] = { link = 'WarningMsg' }
  hi['@constant'] = { fg = s.orange300 }
  hi['@constant.builtin'] = { fg = s.yellow300, italic = 1 }
  hi['@constant.macro'] = { fg = s.yellow300, bold = 1 }
  hi['@constructor'] = { fg = s.yellow300 }
  hi['@function'] = { fg = s.pink300 }
  hi['@function.builtin'] = { fg = s.pink300, italic = 1 }
  hi['@function.macro'] = { fg = s.pink300, bold = 1 }
  hi['@keyword'] = { fg = s.purple300, bold = 1 }
  hi['@keyword.conditional'] = { fg = s.purple300 }
  hi['@keyword.import'] = { fg = s.purple300 }
  hi['@keyword.operator'] = { fg = s.aqua300, italic = 1 }
  hi['@keyword.repeat'] = { fg = s.purple300 }
  hi['@label'] = { fg = s.purple300 }
  hi['@markup.heading'] = { link = 'Title' }
  hi['@markup.italic'] = { italic = 1 }
  hi['@markup.link'] = { link = 'Constant' }
  hi['@markup.link.url'] = { underline = 1, sp = s.blue700 }
  hi['@markup.math'] = { link = 'Special' }
  hi['@markup.raw'] = { fg = s.orange300 }
  hi['@markup.strikethrough'] = { strikethrough = 1 }
  hi['@markup.strong'] = { bold = 1 }
  hi['@markup.underline'] = { underline = 1 }
  hi['@module'] = { fg = s.orange500 }
  hi['@none'] = { fg = s.foreground } -- ??
  hi['@number'] = { fg = s.orange300 }
  hi['@number.float'] = { fg = s.orange300 }
  hi['@property'] = { fg = s.orange500 }
  hi['@punctuation.delimiter'] = { fg = s.gray450 }
  hi['@punctuation.special'] = { fg = s.aqua300 }
  hi['@string'] = { fg = s.green300 }
  hi['@string.escape'] = { fg = s.aqua700 }
  hi['@string.regexp'] = { fg = s.aqua300 }
  hi['@string.special'] = { fg = s.green200 }
  hi['@string.special.symbol'] = { fg = s.red300 }
  hi['@tag'] = { fg = s.yellow300 }
  hi['@tag.attribute'] = { fg = s.orange500 }
  hi['@tag.delimiter'] = { fg = s.gray450 }
  hi['@type.builtin'] = { fg = s.yellow300, italic = 1 }
  hi['@type.definition'] = { fg = s.purple300 }
  hi['@variable'] = { fg = s.blue300 }
  hi['@variable.builtin'] = { fg = s.blue300, italic = 1 }
  hi['@variable.member'] = { fg = s.orange500 }
  hi['@variable.member.private'] = { fg = s.orange500, italic = 1 }

  -- custom
  hi.StatusLineDiagnosticsError = { fg = s.red300, bg = s.window }
  hi.StatusLineDiagnosticsWarning = { fg = s.yellow300, bg = s.window }
  hi.StatusLineDiagnosticsInfo = { fg = s.blue300, bg = s.window }
  hi.StatusLineDiagnosticsHint = { fg = s.gray450, bg = s.window }
  hi.StatusLineGitAdd = { fg = s.green300, bg = s.window }
  hi.StatusLineGitChange = { fg = s.blue300, bg = s.window }
  hi.StatusLineGitDelete = { fg = s.red300, bg = s.window }

  hi.GitConflictMarker = { link = 'Todo' }
  hi.SnipPlaceholder = { fg = s.blue300, bg = s.blue700 }

  -- LSP
  hi.LspReferenceText = { bg = s.selection }
  hi.LspReferenceRead = { bg = s.selection }
  hi.LspReferenceWrite = { bg = s.selection }
  hi.DiagnosticUnnecessary = { fg = s.gray450 }
  hi.DiagnosticDeprecated = { fg = s.gray450, strikethrough = 1 }

  -- blink.cmp
  hi.BlinkCmpLabelMatch = { fg = s.yellow300 }
  hi.BlinkCmpLabelDeprecated = { fg = s.gray450, strikethrough = 1 }
  hi.BlinkCmpGhostText = { fg = s.gray700 }

  -- snacks.nvim (picker)
  hi.SnacksPicker = { link = 'BorderedFloat' } -- its windows, as its border
  hi.SnacksPickerMatch = { link = 'Constant' }
  hi.SnacksPickerDir = { fg = s.gray300 }
  hi.SnacksPickerBorder = { fg = s.blue200, bg = s.background }
  hi.SnacksPickerTitle = { fg = s.blue200, bg = s.background }
  -- what git ignores, dimmed: a file, its status, and (user.plugin.picker) a directory
  hi.SnacksPickerPathIgnored = { fg = s.gray450 }
  hi.SnacksPickerGitStatusIgnored = { fg = s.gray450 }
  hi.PickerDirectoryIgnored = { fg = s.blue400 }

  -- snacks.nvim's other windows (terminals...) on the editor's background, as its picker: the floats' darker one
  -- (NormalFloat) is for completion's documentation and hovers
  hi.SnacksNormal = { link = 'Normal' }
  hi.SnacksNormalNC = { link = 'Normal' }
  -- (user.plugin.picker: the replacement grep's list previews)
  hi.PickerReplaceOld = { fg = s.red300, bg = s.red700, strikethrough = 1 }
  hi.PickerReplaceNew = { fg = s.green300, bg = s.green700 }

  -- gitsigns.nvim
  hi.GitSignsAdd = { fg = s.green700 }
  hi.GitSignsChange = { fg = s.blue700 }
  hi.GitSignsChangedelete = { fg = s.blue700 }
  hi.GitSignsDelete = { fg = s.red700 }
  hi.GitSignsTopdelete = { fg = s.red700 }

  -- diffview.nvim: the lines a side lacks ('fillchars' diff:╱)
  hi.DiffviewDiffDeleteDim = { fg = s.gray825 }

  -- inline completion (Copilot's suggestions)
  hi.ComplHint = { fg = s.gray700, underdotted = 1 }

  -- nvim-treesitter-context
  hi.TreesitterContext = { link = 'Normal' }
  hi.TreesitterContextLineNumber = { fg = s.gray600, bg = s.background }
  hi.TreesitterContextBottom = { sp = s.window, underline = 1 }
  hi.TreesitterContextLineNumberBottom = { sp = s.window, underline = 1 }

  -- markdown
  hi['@markup.quote.markdown'] = { link = '@string' }
  hi['@markup.link.markdown'] = { link = '@tag.delimiter' }
  hi['@markup.link.label.markdown'] = { link = '@constant' }
  hi['@markup.link.markdown_inline'] = { link = '@tag.delimiter' }
  hi['@markup.link.label.markdown_inline'] = { link = '@variable' }

  -- json
  hi['@property.json.2'] = { fg = s.purple300 }
  hi['@property.json.3'] = { fg = s.blue300 }

  -- terminals' colors: the normal ones (0-7), then the bright ones (8-15)
  local terminal_colors = {
    s.gray700, s.red300, s.green300, s.yellow300, s.blue300, s.purple300, s.aqua300, s.gray600,
    s.gray700, s.red200, s.green200, s.yellow200, s.blue200, s.purple200, s.aqua200, s.gray600,
  }
  for i, color in ipairs(terminal_colors) do
    vim.g['terminal_color_' .. (i - 1)] = color
  end
end

return M
