-- Icons: Nerd Font's in kitty, which draws them from the Symbols Nerd Font
-- Mono it bundles, and characters any font has elsewhere, as with no UI (the
-- e2e tests). kitty draws an icon followed by a space over both cells.

local severity = vim.diagnostic.severity

--- Whether a UI runs in kitty (Neovim sources the config once its terminal UI
--- has attached).
local function in_kitty()
  for _, ui in ipairs(vim.api.nvim_list_uis()) do
    if ui.term_name == 'xterm-kitty' then
      return true
    end
  end
  return false
end

if in_kitty() then
  return {
    diagnostics = {
      [severity.ERROR] = '\u{ea87}', -- cod-error
      [severity.WARN] = '\u{ea6c}', -- cod-warning
      [severity.INFO] = '\u{f02fd}', -- md-information_outline
      [severity.HINT] = '\u{f400}', -- oct-light_bulb
    },
    -- Before a git branch
    branch = '\u{f062c} ', -- md-source_branch
    -- Before a terminal's name
    terminal = '\u{ea85} ', -- cod-terminal
  }
end

return {
  diagnostics = {
    [severity.ERROR] = '✕',
    [severity.WARN] = '∆',
    [severity.INFO] = '□',
    [severity.HINT] = '*',
  },
  branch = '',
  terminal = '$',
}
