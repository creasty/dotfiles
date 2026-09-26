# Out of scope and other findings

What fixing CI and modernizing the provisioning in [#105](https://github.com/creasty/dotfiles/pull/105) turned up but left alone, most urgent first.
What #105 dropped, and how to clean up a Mac provisioned before, is in [dropped.md](dropped.md).

## Likely broken

- **ddu's `:Open`**: it lists repositories with the `ghq` source in `$HOME`, and files with the `fd` source elsewhere (`nvim/autoload/user/plugin/ddu.vim`).
  Both sources (`nvim/denops/@ddu-sources/ghq.ts`, `fd.ts`) call `Deno.run`, which Deno 2 removed, and Homebrew installs Deno 2.
  Port them to `Deno.Command`. The denops and ddu plugins are pinned to 2023 commits, from before Deno 2, so they may need updating too.
- **coc-diagnostic's linters** (`nvim/coc-settings.json`) give Go, YAML and Vim script files no diagnostics:
  - golangci-lint v2 replaced `--out-format` with `--output.json.path` and removed the `deadcode` linter, both still passed to it.
  - ansible-lint, run on every YAML file, no longer has `--parseable-severity`.
  - `vint` isn't installed: it was only in the vim role's commented-out pip task.
- **UltiSnips** needs Neovim's Python 3 provider, `pynvim`, which nothing installs (the same commented-out pip task), so it turns itself off with a warning.
  Install pynvim in a virtualenv (`uv` is installed) and point `g:python3_host_prog` at it.
- **RuboCop**: `home/rubocop.yml`, linked to `~/.rubocop.yml`, configures cops RuboCop 1.x removed or renamed (`Style/BracesAroundHashParameters`, `Metrics/LineLength`, `Layout/IndentFirst*`).
  RuboCop refuses an obsolete configuration, so it fails in every project without its own `.rubocop.yml`.
- **`bin/serve`** requires `webrick`, which Ruby 3.0 stopped bundling and `config/mise/default-gems` doesn't install.
  Add it there, or serve with `python3 -m http.server`.
- **`home/irbrc`** requires `hirb`, `interactive_editor`, `fancy_irb` and `awesome_print`, none of them installed, so irb and Rails consoles warn with a `LoadError` and skip the rest of the file.
  `amazing_print` succeeds the unmaintained `awesome_print`.
- **tmux's `default-terminal 'alacritty'`** gives every pane `TERM=alacritty`, but macOS's terminfo has no `alacritty` entry, and provisioning doesn't install one (`tic` on Alacritty's `extra/alacritty.info`).
  On a fresh Mac, macOS's own programs in panes (`less`, `clear`, ...) don't know the terminal.
  tmux's man page asks for `screen`, `tmux` or a derivative: `screen-256color` ships with macOS, `tmux-256color` needs `tic` too.
- **`provision` updates the checkout only when run from it**: `clone_or_update_repo` runs `git --git-dir=…` without a work tree, so git takes the current directory as one.
  Run from anywhere else, as `curl … | bash` usually is, the clean-tree check fails and it skips with "unstaged changes present".
  `git -C "$DOTFILES_PATH"` fixes it.

## Security

- **ssh doesn't check host keys**: `provisioning/roles/ssh/files/_common` sets `StrictHostKeyChecking no` and `UserKnownHostsFile /dev/null` under `Host *`.
  ssh takes the first value it finds, so this covers every host that doesn't set them earlier, github.com included: a changed or spoofed host key goes unnoticed.
  Limit it to the Vagrant hosts in `_va`, and use `StrictHostKeyChecking accept-new` with a real `known_hosts` elsewhere.

## Existing Macs

- **terraform**: a Mac provisioned before may still have homebrew-core's `terraform`, frozen at 1.5.7 (the last MPL release) until core removed it.
  Homebrew can't install formulae of the same name from different taps side by side, so `brew uninstall terraform` before provisioning installs `hashicorp/tap/terraform`, the current, BUSL-licensed release.
- **`~/.zprofile`**: the link role renames an existing `~/.zprofile` to `~/.zprofile.bak` before linking the new one.
  `~/.profile` already puts Homebrew on `PATH`, which is what the Homebrew installer suggests adding there; move anything else over by hand.

## Verification gaps

- **Neovim's config**: `./verify` runs Neovim without it (`-u NONE`).
  The e2e suite ([creasty/dotfiles#106](https://github.com/creasty/dotfiles/pull/106)) runs it with the plugins pinned in `nvim/dein/lock.json`, but nothing installs the toml files' plugins the way a fresh Mac does, at their latest commits.
  That's how the vanished `phaazon/hop.nvim` repository broke fresh installs unnoticed.
  coc.nvim's extensions need Node, from the `lang` tag, and no CI job provisions both `lang` and `app`.
- **Idempotency**: nothing checks that a second provisioning run changes nothing.
  Only one `command`/`shell` task (the zsh plugins') sets `changed_when`, so the others report `changed` whenever they run.
- **Startup budget on CI**: `zsh -i -c exit` measured 39–101 ms across runs, against the 150 ms budget.
  If it ever flakes, give CI its own `DOTFILES_VERIFY_STARTUP_MS` rather than loosening the local default.
- **Launch agents**: `config/launchagent` holds only `.keep`, so that test always skips.
- **Flutter**: only the cask's installation is checked; `flutter doctor` would need the Android SDK and Xcode set up first.

## Upstream

- **creasty/homebrew-tools has no CI**, only a `.travis.yml` from the travis-ci.org days, so nothing noticed when Homebrew removed `appcast` (fixed in [creasty/homebrew-tools#10](https://github.com/creasty/homebrew-tools/pull/10)).
  A workflow like the one `brew tap-new` generates (`brew test-bot --only-tap-syntax`) would catch the next one.

## Worth modernizing later

- **ctags**: the `ctags` formula is Exuberant Ctags 5.8, unmaintained since 2009.
  `universal-ctags` replaces it, but the two conflict, and Universal Ctags reads `~/.ctags.d/*.ctags` instead of `~/.ctags`.
- **nvim-treesitter** is pinned to `master`; development moved to `main`, an incompatible rewrite.
  Moving means rewriting the treesitter config and `creasty/opfmt`, which both use `nvim-treesitter.configs`.
- **Plugin manager and LSP**: dein.vim's author now develops dpp.vim, and Neovim 0.12 has a built-in `vim.pack`.
  Neovim's built-in LSP client (`vim.lsp.config`, `vim.lsp.enable`) could replace coc.nvim.
- **Kotlin**: JetBrains now develops an official language server, `kotlin-lsp`, besides the community `kotlin-language-server` that coc.nvim runs.
- **coc-metals** is installed with the other coc extensions but disabled (`metals.enable: false`), and was last published in 2022.

## Found and fixed in #105

- Login shells (new terminal tabs, tmux panes) found macOS's commands before Homebrew's: `/etc/zprofile`'s `path_helper` reorders `PATH` after `~/.zshenv`. Fixed with `~/.zprofile`.
- The rustup guard never installed a toolchain: `rustup default` reports an implicit stable even when none is installed.
- The zsh completion cache never refreshed: `ZSH_COMPDUMP` was unset.
- Zsh plugin updates never reached existing Macs: `provision` only synced the submodules.
- Fresh Neovim installs broke: nvim-treesitter's default branch became the incompatible `main`.
  `phaazon/hop.nvim`, gone as well, moved to `smoka7/hop.nvim` in [creasty/dotfiles#106](https://github.com/creasty/dotfiles/pull/106).
- `creasty/tools/keyboard` stopped loading when Homebrew removed `appcast` ([creasty/homebrew-tools#10](https://github.com/creasty/homebrew-tools/pull/10)), and Google Chrome's cask failed on CI runners, which ship Chrome.
