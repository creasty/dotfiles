# Trying Ghostty in place of Alacritty and tmux

Ghostty is provisioned next to Alacritty and tmux, which stay as they are until Ghostty proves itself.
Its config, `config/ghostty/config.ghostty`, reproduces both with Ghostty's own tabs and splits: a tab holds splits, as a tmux window holds panes.
`C-s r` reloads it after an edit, and `/Applications/Ghostty.app/Contents/MacOS/ghostty +validate-config` checks it.

## What maps to what

| Alacritty and tmux | Ghostty |
|---|---|
| Prefix `C-s`, `C-s C-s` sends it | Key sequences: the same keys |
| `C-s t`, `C-s C-b`, `C-s C-n` | New tab after the current one, previous and next tab |
| `C-s s`, `C-s v` (then even-horizontal), `C-s =` | Split down, split right and even out, even out |
| `C-s C-h/j/k/l`, `C-s < > - +` | Go to the split, resize it by about a cell |
| `C-s d`, `C-s c` | Close the split |
| `C-s :` (command prompt), `C-s r` | Command palette, reload the config |
| `C-s p` (pbpaste) | Paste |
| `C-y` copy mode | Neovim over the pane, on its screen and history (`ghostty-pane/`) |
| `j k C-e C-y C-d C-u C-f C-b g G`, `/ ? n N`, `{ }` | Neovim's |
| `v` … `y` (pbcopy) | Neovim's `v` … `y`, to the clipboard (`clipboard=unnamed`) |
| `q`, `C-c` | `:q` |
| Window list: `#{b:pane_current_path}` | Tab titles from `shell/zsh/src/term.zsh` |
| Colors, Menlo 12, padding, maximized window | The same |
| Japanese in Hiragino Sans, macOS's fallback | Named after Menlo: Ghostty asks macOS for kanji only, and could take kana from a serif font |
| `history-limit 15000` | `scrollback-limit`, in bytes: about 15000 lines |

## Where Ghostty differs

- **Copy mode is Neovim**, as Ghostty can't select text with the keyboard ([ghostty-org/ghostty#3488](https://github.com/ghostty-org/ghostty/discussions/3488)).
  `C-y` has Ghostty write the screen and its history to a file, then send F20, the file's path and a return.
  `ghostty-pane`, which runs the shell of each pane in a terminal of its own, takes them and opens the file in Neovim over the pane, then deletes it.
  What runs in the pane keeps running: its output shows once Neovim quits, after the modes it had set that Neovim resets (bracketed paste, the keypad, the mouse, the title...), and a program on the alternate screen redraws it.
  Neovim has the text without its colors, and starts on the last line with text.
- **Ghostty sees a raw terminal** through `ghostty-pane`, as it would tmux: its secure input for password prompts (`macos-auto-secure-input`) doesn't turn on.
- **Unbound keys after the prefix** go to the program together with `C-s`, where tmux dropped them.
- **Closing a split** (`C-s d`) can't even out the remaining splits: `C-s =` does.
- **No activity monitoring** of tabs (`monitor-activity`); a bell marks a tab with 🔔.
- **Tab titles**: programs that set their own title, like Neovim, replace the directory's name while they run.
  The tab bar takes the terminal's background, not the status bar's.
- **Shells don't outlive the app**: tmux's server kept them when Alacritty quit.
  `Cmd+Z` brings back a closed split, tab or window within 5 seconds.
- `+show-config` and `+list-keybinds` of Ghostty 1.3.1 print the bindings that follow a chained one in a sequence as `chain=>…`, though they work.

## Removing Alacritty and tmux

Once Ghostty replaces them:

- `config/alacritty/`, `config/tmux/`
- tmux: `nix/modules/tmux.nix` and its import in `nix/modules/default.nix`, `tmux` in `nix/modules/packages.nix`, `test/tmux.bats`, and the tmux tests of `test/link.bats`
- `pam_reattach` in `nix/modules/default.nix` (Touch ID for sudo in tmux) and its mention in `test/osx.bats`, unless something else runs outside the login session
- `shell/zsh/src/functions.zsh`: the tmux line of `reload`, and `tmk`
- The "Zsh + tmux (Alacritty)" screenshot of `README.md`
- `ghostty-pane/tests` run in tmux: keep it to run them locally (the tests workflow installs its own)
