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
| `C-y` copy mode: `j k C-e C-y C-d C-u C-f C-b g G` | Key table `copy`: the same keys scroll the view |
| `{` `}` (paragraphs) | Previous and next prompt |
| `/` `?` then `n` `N` | Search bar: type, Enter, Escape back to `n` (older) and `N` (newer) |
| `v` … `y` (pbcopy) | `v` opens the screen and the history in Neovim, to select and yank there |
| `q`, `C-c` | Leave copy mode |
| Window list: `#{b:pane_current_path}` | Tab titles from `shell/zsh/src/term.zsh` |
| Colors, Menlo 12, padding, maximized window | The same |
| `history-limit 15000` | `scrollback-limit`, in bytes: about 15000 lines |

## Where Ghostty differs

- **No keyboard selection** ([ghostty-org/ghostty#3488](https://github.com/ghostty-org/ghostty/discussions/3488)): copy mode scrolls the view, with no cursor to move or select from.
  `v` sends F20, the path of a file with the screen and its history, and a return; `term.zsh` opens it in Neovim (`view_scrollback`), then deletes it.
  That takes a shell prompt: in a full-screen program (Neovim, less), the path is typed into it.
- **Search** goes one way: `n` goes to older matches, `N` to newer ones, whether it started with `/` or `?`, and it doesn't wrap around.
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
