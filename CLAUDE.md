# CLAUDE.md

What the code and the README don't tell about this repository.

## Verification gaps

- **Neovim's config**: `./verify` starts Neovim without it (`-u NONE`, `nix/tests/vim.bats`).
  The e2e suite (`nvim/tests/`) runs it with the plugins `nvim/lazy-lock.json` pins, but CI restores those from its cache: a pinned repository that vanishes breaks fresh installs unnoticed, until Renovate fails to bump it or the pins change.
  The `apply` workflow's `macos` job has everything installed, so a test there could start Neovim with its config.
- **kitty**: no test starts it, so that it starts Neovim (`shell`) goes untested; `nix/tests/link.bats` loads its config, which flags only unknown options and files it can't include.
- **Idempotency**: nothing checks that a second switch changes nothing.
  The activation steps (mise, rustup, VS Code's extensions, the dotfiles' links) skip what's done, but no test runs them twice, nor drops a link to see it removed.
- **Login before /nix**: no test restarts macOS, so that the apps it starts at login find their configs and a shell goes untested; `nix/tests/link.bats` checks that the links point straight into the checkout, and nothing checks `shell/zsh/zshenv`'s wait for /nix.
- **Budgets on CI**: CI's runners measured `zsh -i -c exit` at 68–151 ms over 82 runs (2026-10-01 to 05), as far apart on one config as across configs.
  So the `apply` workflow benchmarks it against 200 ms (`DOTFILES_VERIFY_STARTUP_MS`), where the default is 150 ms (`nix/tests/shell.bats`): a regression fails it only once it more than doubles a typical run.
  Neovim's benchmarks keep their defaults on CI, 150 ms to start (`nvim/tests/spec/startup_spec.lua`) and 16.7 ms to follow a held key (`emacs_keys_spec.lua`), and a pass prints no time, so CI has no numbers for them; if one flakes, give CI its own `E2E_STARTUP_BUDGET_MS` or `E2E_KEY_REPEAT_BUDGET_MS` rather than loosening the default.
- **Cloud sessions**: nothing runs `etc/claude-cloud-setup`.
  Anthropic's docs say a cloud session doesn't read `~/.claude/settings.json`, yet it read the one the script writes (seen 2026-10-20): while it still does, `echo $DISABLE_COST_WARNINGS` in a session prints 1.
- **Flutter**: only the cask's installation is checked; `flutter doctor` would need the Android SDK and Xcode set up first.
- **Releases a pin follows**: nothing notices when a repository stops tagging the releases a pin follows (`version` in `nvim/lua/user/plugins.lua`, a `refs/tags/` `ref` in `nix/modules/skills.nix`); Renovate just proposes no more updates.
  GitHub's comparison of its latest tag with its branch (`compare/<tag>...<branch>`) tells how long its changes have waited.

## lazy.nvim rewriting its lockfile at start

After installing missing plugins on a start, lazy.nvim rewrites `nvim/lazy-lock.json` with what is installed: that undoes the pins a pull moved, and drops the pin of a plugin that failed to install.
So `keep_pins` in `nvim/lua/user/plugins.lua` puts them back.
Remove it once lazy.nvim keeps the lockfile when it installs from it ([lazy.nvim#2127](https://github.com/folke/lazy.nvim/pull/2127) would): a start that installs a missing plugin while another is behind its pin tells.

## Neovim's exit without a UI

An error on exit has Neovim wait for Enter (`getout()` calls `wait_return()`), which a server whose UI is gone never gets: it keeps running, with its terminals ([neovim#42096](https://github.com/neovim/neovim/issues/42096), seen with 0.12.4).
Writing the ShaDa file is such an error when several Neovims exit at once, as kitty or Ghostty quitting with several windows has them: `vim_rename()` deletes `main.shada` before renaming its temporary file onto it, and one that checks for it in between fails with E137 and keeps its `main.shada.tmp.X` ([neovim#41940](https://github.com/neovim/neovim/issues/41940)).
So `_exit_without_ui` in `nvim/init.vim` writes the ShaDa file as the last UI leaves, with errors silenced, and empties `'shada'` so the exit doesn't write it again.
Remove it once neovim#42096 is fixed: the read-only case in `nvim/tests/spec/exit_spec.lua` passes without it.

## kitty off every Space

kitty takes each window it opens off every Space, the first at launch included, whatever Dock > Options > Assign To says ([kitty#10581](https://github.com/kovidgoyal/kitty/issues/10581), seen with 0.49.1 and 0.49.2).
The likely cause is `_glfwPlatformShowWindow` in its `glfw/cocoa_window.m`, which resets the window's collection behavior as it shows it (from 0.43.0) and adds it to the active Space (from 0.48.0), a workaround for its quick-access terminal (kitty#8740).
Hammerspoon can't put a window back: the private calls `hs.spaces.moveWindowToSpace` makes fail on macOS 26, and restarting the Dock doesn't either.
So as ;+M brings kitty, `hammerspoon/kitty.lua` (called from `hammerspoon/apps.lua`) has it hide and show its windows on other Spaces through its remote control (`allow_remote_control` and `listen_on` in `config/kitty/kitty.conf`), which adds them to the current Space.
Remove both once kitty#10581 is fixed and a new window stays on every Space.

## /nix after login

FileVault keeps the /nix volume locked until `determinate-nixd init` unlocks it, and macOS starts that daemon only once loginwindow is up, holding third-party daemons until then: on 26.6.2, /nix was mounted 9 s after login, 4 s after macOS had reopened the last session's apps ([nix-installer#689](https://github.com/DeterminateSystems/nix-installer/issues/689) has the same on 26.2).
Until then a link into the Nix store dangles: kitty came up without its config, and the Claude app, which resolves the login shell's environment once at start, would have run every session without Nix's tools.
So `nix/modules/links.nix` links the dotfiles straight into the checkout, and `shell/zsh/zshenv` waits for /nix before reading `/etc/zshenv`, which links into it.
What home-manager links itself (`home.file`, `xdg.dataFile`), the agent skills among them, still goes through the store.
Remove both once /nix is mounted before loginwindow starts: in a restart's unified log, diskarbitrationd's `mounted disk` for the volume comes before launchd spawns `loginwindow`.
A restart in which /nix merely beats the reopened apps doesn't tell: on 2026-10-22 the unlock took 1.3 s instead of 4.6 s, and /nix was mounted 0.2 s before macOS reopened kitty.

## The picker's toggles in its title

snacks.nvim adds a picker's toggles (h, f, i) to its title in `pairs()` order (`update_titles()` in `lua/snacks/picker/core/picker.lua`), which differs from one start of Neovim to the next: `Files h f` in one, `Files f h` in the next.
So `order_toggles` in `nvim/lua/user/plugin/picker.lua` has it go through them in the order of their names.
Remove it once snacks orders them itself: without it, the file picker's and the explorer's scenes (`nvim/tests/spec/scenes_ui_spec.lua`) fail in about half the runs.

## Language servers off buffers without a name

Neovim gives a buffer without a name (`:enew`) the URI `file://`, which some language servers fail on (seen with Neovim 0.12.4; [neovim#21276](https://github.com/neovim/neovim/issues/21276) concluded that clients shouldn't use `file:` for such buffers):

- TypeScript 7's server stops: `panic: vfs: path "tsconfig.json" is not absolute` ([microsoft/TypeScript#64300](https://github.com/microsoft/TypeScript/issues/64300), seen with 7.0.2), and the project's other buffers, which share it, lose TypeScript with it.
- clangd fails every request: `-32602: failed to decode textDocument/documentHighlight request: unresolvable URI` (seen with 21.1.8).
- gopls and terraform-ls fail hover: `no package metadata for file file:///`, `file:: file not found` (seen with 0.22.0 and 0.38.6).

So `named_only` in `nvim/lua/user/plugin/lsp.lua` has `vim.lsp.start` start none of `M.servers` on such a buffer until it has a name, and `nvim/tests/spec/lsp_spec.lua` checks both.
It isn't each config's `root_dir`: with one, Neovim starts the server a moment after the FileType event, by when flatten.nvim's guest has deleted its buffer, and the error leaves `git commit` from a terminal waiting (`nvim/tests/spec/terminal_spec.lua`).
Remove it once Neovim gives such a buffer a URI the servers resolve: without it, clangd answers a request after `:enew | setfiletype c`.

## Homebrew tap trap

`brew tap` checks that every formula and cask of a tap loads on Linux too, and refuses the whole tap when one doesn't: a formula with a URL only `on_macos`, or a cask without Linux stanzas or `depends_on :macos`.
Such a tap can't go in `homebrew.taps`, which nix-darwin taps with that check. Instead:

- Install the formula by its full name, with its tap unlisted: installing taps it without the check, and nix-darwin trusts the formula itself (`trusted`, for Homebrew's `HOMEBREW_REQUIRE_TAP_TRUST`).
  `nix/modules/java.nix` installs `jetbrains/utils/kotlin-lsp` so, until kotlin-lsp has a URL outside `on_macos` too and its tap can be listed.
- Or take the tool from nixpkgs, as `nix/modules/1password.nix` does 1Password's CLI: Homebrew refuses `1password/tap`.

## gcloud's placeholder token in cloud sessions

A cloud session's VM sets `CLOUDSDK_AUTH_ACCESS_TOKEN=proxy-injected`, a placeholder its proxy replaces with a token only when the environment has a GCP network secret (seen in October 2026).
gcloud uses it over the account it's logged in to, so `gcloud`, `bq` and `docker-credential-gcloud` send the placeholder and fail, and `gcloud auth print-access-token` prints it as if logged in.
Setting it to `""`, in a project's `settings.json` `env` or in the environment's variables, leaves the placeholder, and `CLOUDSDK_AUTH_CREDENTIAL_FILE_OVERRIDE` doesn't take its place.
So `etc/claude-cloud-setup` unsets it on the first line of `~/.bashrc`, above the return that skips the rest in a non-interactive shell, as Claude's commands run; that also turns off the proxy's injection.
Remove it once the VM leaves the variable unset without a GCP secret: in a new session without the line, `[ -n "${CLOUDSDK_AUTH_ACCESS_TOKEN+x}" ] && echo set || echo unset` prints `unset`.
