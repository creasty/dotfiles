# CLAUDE.md

What the code and the README don't tell about this repository.

## Verification gaps

- **Neovim's config**: `./verify` starts Neovim without it (`-u NONE`, `nix/tests/vim.bats`).
  The e2e suite (`nvim/tests/`) runs it with the plugins `nvim/flake.lock` pins, but CI restores those from its cache: a pinned repository that vanishes breaks fresh installs unnoticed, until Dependabot fails to bump it or the pins change.
  The provisioning job has everything installed, so a test there could start Neovim with its config.
- **Idempotency**: nothing checks that a second switch changes nothing.
  The activation steps (mise, rustup, VS Code's extensions) skip what's done, but no test runs them twice.
- **Startup budget on CI**: `zsh -i -c exit` measured 39–101 ms across runs, against the 150 ms budget (`nix/tests/shell.bats`).
  If it ever flakes, give CI its own `DOTFILES_VERIFY_STARTUP_MS` rather than loosening the local default.
- **Flutter**: only the cask's installation is checked; `flutter doctor` would need the Android SDK and Xcode set up first.

## opfmt is off

`creasty/opfmt` is switched off (`cond = false` in `nvim/lua/user/plugins.lua`) until it works with nvim-treesitter's `main` branch:

- It loads modules only `master` has: `nvim-treesitter.query`, `.parsers` (`has_parser`) and `.ts_utils`, and registers itself as one of `master`'s modules (`define_modules`).
- Its `opfmt!` directive takes a capture as one node, where Neovim 0.12 passes a list of nodes.
  `compat.lua` (below) doesn't cover it, as it's registered without `all = false`.

It stays pinned in `nvim/flake.lock`, and its tests skip while it's off (`probe.opfmt_enabled` in `nvim/tests/spec/treesitter_spec.lua` and `snippets_spec.lua`).
With `dev = true`, lazy.nvim loads it from its working copy in `~/go/src/github.com/creasty/opfmt` when there is one.

## nvim/lua/user/plugin/treesitter/compat.lua

nvim-treesitter-endwise registers its `endwise!` directive with `all = false`, for a handler that gets one node per capture.
Neovim 0.12 dropped the option and always passes a list of nodes, which breaks endwise: no `endfunction` after `function` in Vim script.
`compat.lua` wraps `vim.treesitter.query.add_predicate` and `add_directive` to bring the option back, as Neovim 0.11 had it; `nvim/init.vim` loads it before the tree-sitter plugins.
Remove it once endwise takes lists: the endwise tests in `nvim/tests/spec/treesitter_spec.lua` tell.

## Homebrew tap trap

`brew tap` checks that every formula and cask of a tap loads on Linux too, and refuses the whole tap when one doesn't: a formula with a URL only `on_macos`, or a cask without Linux stanzas or `depends_on :macos`.
Such a tap can't go in `homebrew.taps`, which nix-darwin taps with that check. Instead:

- Install the formula by its full name, with its tap unlisted: installing taps it without the check, and nix-darwin trusts the formula itself (`trusted`, for Homebrew's `HOMEBREW_REQUIRE_TAP_TRUST`).
  `nix/modules/java.nix` installs `jetbrains/utils/kotlin-lsp` so, until kotlin-lsp has a URL outside `on_macos` too and its tap can be listed.
- Or take the tool from nixpkgs, as `nix/modules/1password.nix` does 1Password's CLI: Homebrew refuses `1password/tap`.
