# Out of scope and other findings

What fixing CI and modernizing the provisioning in [#105](https://github.com/creasty/dotfiles/pull/105) turned up but left alone, most urgent first.
What #105 dropped, and how to clean up a Mac provisioned before, is in [dropped.md](dropped.md).

## Verification gaps

- **Neovim's config**: `./verify` runs Neovim without it (`-u NONE`).
  The e2e suite ([creasty/dotfiles#106](https://github.com/creasty/dotfiles/pull/106)) runs it with the plugins pinned in `nvim/dein/lock.json`, but nothing installs the toml files' plugins the way a fresh Mac does, at their latest commits.
  That's how the vanished `phaazon/hop.nvim` repository broke fresh installs unnoticed.
  CI provisions everything in one job now, so a test can start it; coc.nvim's extensions need mise's Node.
- **Idempotency**: nothing checks that a second switch changes nothing.
  The activation steps (mise, rustup, VS Code's extensions, dein.vim) skip what's done, but no test runs them twice.
- **Startup budget on CI**: `zsh -i -c exit` measured 39–101 ms across runs, against the 150 ms budget.
  If it ever flakes, give CI its own `DOTFILES_VERIFY_STARTUP_MS` rather than loosening the local default.
- **Flutter**: only the cask's installation is checked; `flutter doctor` would need the Android SDK and Xcode set up first.

## Upstream

- **creasty/homebrew-tools has no CI**, only a `.travis.yml` from the travis-ci.org days, so nothing noticed when Homebrew removed `appcast` (fixed in [creasty/homebrew-tools#10](https://github.com/creasty/homebrew-tools/pull/10)).
  A workflow like the one `brew tap-new` generates (`brew test-bot --only-tap-syntax`) would catch the next one.
- **JetBrains' tap fails `brew tap`'s check**: its kotlin-lsp formula has a URL only `on_macos`, so on Linux it "requires at least a URL", and `brew tap jetbrains/utils` refuses the whole tap.
  `nix/modules/java.nix` installs the formula without declaring the tap, which skips the check; the tap can go in `homebrew.taps` once the formula has a URL outside `on_macos` too.

## Worth modernizing later

- **nvim-treesitter** is pinned to `master`; development moved to `main`, an incompatible rewrite.
  Moving means rewriting the treesitter config and `creasty/opfmt`, which both use `nvim-treesitter.configs`.
- **Plugin manager**: dein.vim's author now develops dpp.vim, and Neovim 0.12 has a built-in `vim.pack`.
- **Neovim 0.12**: nixpkgs installs 0.12.4, while CI tests on 0.11.7.
  0.12 no longer gives query handlers registered with `all = false` one node per capture, which nvim-treesitter's `master` and nvim-treesitter-endwise rely on (markdown code blocks, as in hover docs, broke with them): `nvim/lua/user/plugin/treesitter/compat.lua` restores it until the move to `main` (see nvim-treesitter above).
  opfmt relies on 0.11's default for directives and is switched off until it handles 0.12; its tests skip meanwhile.
  Two pinned quirks behave differently on 0.12 (xml/eruby `>`, `vs` without a parser).
  blink.cmp's v2 and Neovim's built-in inline completion (`vim.lsp.inline_completion`, for Copilot) need 0.12 too.

## Found and fixed in #105

- Login shells (new terminal tabs, tmux panes) found macOS's commands before Homebrew's: `/etc/zprofile`'s `path_helper` reorders `PATH` after `~/.zshenv`. Fixed with `~/.zprofile`.
- The rustup guard never installed a toolchain: `rustup default` reports an implicit stable even when none is installed.
- The zsh completion cache never refreshed: `ZSH_COMPDUMP` was unset.
- Zsh plugin updates never reached existing Macs: `provision` only synced the submodules.
- Fresh Neovim installs broke: nvim-treesitter's default branch became the incompatible `main`.
  `phaazon/hop.nvim`, gone as well, moved to `smoka7/hop.nvim` in [creasty/dotfiles#106](https://github.com/creasty/dotfiles/pull/106).
- `creasty/tools/keyboard` stopped loading when Homebrew removed `appcast` ([creasty/homebrew-tools#10](https://github.com/creasty/homebrew-tools/pull/10)), and Google Chrome's cask failed on CI runners, which ship Chrome.

## Fixed by moving to Universal Ctags

- The Nix migration installed nixpkgs' `ctags`, Exuberant Ctags built without regex support: every run printed 18 warnings about `~/.ctags`, and Rails' associations and scopes, `.proto` and `.graphql` files went untagged.

## Fixed by replacing coc.nvim, ddu, UltiSnips, lexima and copilot.vim

- ddu's `:Open` and its `ghq` / `fd` sources called `Deno.run`, which Deno 2 removed: snacks.nvim's picker runs fd, rg and `ghq-list-monorepo` itself.
- coc-diagnostic's linters gave Go, YAML and Vim script files no diagnostics (golangci-lint v2 and ansible-lint changed their flags; vint wasn't installed): nvim-lint's maintained definitions run them, and nixpkgs installs vint.
- coc-metals, disabled and unmaintained, is gone with the other coc extensions.
- The tree-sitter CLI came with Homebrew's `neovim`, so the Nix migration dropped it, and nvim-treesitter couldn't build the latex and swift parsers: every startup reported the error.
  nixpkgs installs it now (0.26, which dropped the `--no-bindings` flag nvim-treesitter's `master` passes, so the config passes its own arguments), and without it those two parsers wait.
- GitLab can answer curl's tarball download with a bot check, which kept the jsonc parser from installing: parsers are fetched with git.
- TypeScript 7 no longer ships the `tsserver.js` typescript-language-server runs, so it failed to start in every project without an older TypeScript (mise installs 7): those get TypeScript's own server, `tsc --lsp`.

## Fixed by the Nix migration

- `provision` updates the checkout wherever it runs from (`git -C "$DOTFILES_PATH"`).
- The launchagent role and its always-skipped test are gone; nix-darwin's `launchd.user.agents` can add agents when needed.
