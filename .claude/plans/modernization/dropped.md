# Dropped in the modernization

What provisioning stopped installing or configuring in [#105](https://github.com/creasty/dotfiles/pull/105), why, and what replaces it.
Provisioning never uninstalls anything, so a Mac provisioned before keeps all of this until it's removed by hand ([cleanup](#cleaning-up-a-mac-provisioned-before)).

## Version managers

| Dropped | Why | Instead |
|---|---|---|
| anyenv, with rbenv, nodenv and jenv | Replaced by mise, adopted after benchmarking it against the cached anyenv init | mise: versions in `config/mise/config.toml`; `.ruby-version`, `.node-version` and `.java-version` keep working |
| rbenv-default-gems, nodenv-default-packages | mise's `postinstall` hooks do the same | `config/mise/default-gems`, `config/mise/default-npm-packages` |
| jenv's export plugin and its patch | mise sets `JAVA_HOME` | Homebrew's JDKs registered with `mise link` |
| rbenv-binstubs | mise has no equivalent: binstubs in `vendor/bundle/bin` are no longer found on their own | `bundle exec`, or `PATH_add vendor/bundle/bin` in the project's `.envrc` |
| `bin/anyenv-rehash`, `ANYENV_SHELL`, `ANYENV_INIT_CACHE_DISABLED` | anyenv only | |
| Node 18.15.0 and Ruby 3.2.1 as the global versions | End of life | Node 24.21.0 and Ruby 4.0.7 |

## Homebrew formulae

| Dropped | Why | Instead |
|---|---|---|
| `terraform` | Removed from homebrew-core after HashiCorp's license change; `hashicorp/tap/terraform` replaced it until it was dropped too | Install it by hand to use it |
| `trash` | Keg-only (not linked into `PATH`) now that macOS ships `/usr/bin/trash` | macOS's `trash`, which Neovim's file deletion (`nvim/plugin/file.vim`) uses too. The formula had extra flags (`-F` via Finder, `-l` list, `-e` empty) |
| `readline`, `libxslt` and `ruby-build` as Ruby build dependencies | Ruby 3.3+ uses reline, nokogiri ships precompiled, mise bundles ruby-build | |

## Casks

| Dropped | Why | Instead |
|---|---|---|
| `docker`, `google-cloud-sdk` | Renamed | `docker-desktop`, `gcloud-cli`, to which Homebrew migrates installed ones |
| `1password/tap/1password-cli`, and its tap | Since 2026-09-26, Homebrew refuses to tap `1password/tap`: its cask lacks Linux stanzas (or `depends_on :macos`) | `op` from nixpkgs, which nix-darwin installs at `/usr/local/bin` |
| `alacritty` | Disabled in Homebrew on 2026-09-01: fails Gatekeeper | Ghostty, which replaced it and tmux (`.claude/plans/ghostty-migration/notes.md`) |
| `chromedriver` | Disabled in Homebrew on 2026-09-01: fails Gatekeeper | |
| `pushplaylabs-sidekick` | Discontinued; disabled in Homebrew on 2025-10-05 | |
| `quicklook-json` | Disabled in Homebrew on 2025-12-23 | `syntax-highlight`, which previews JSON too |
| `qlcolorcode`, `qlstephen`, `webpquicklook` | Quick Look generators, which macOS 15+ no longer loads; deprecated in Homebrew on 2025-09-22 | `syntax-highlight` for source code; macOS previews WebP itself |
| QLColorCode's `extraHLFlags` default | Its app is gone | |

## Gems and npm packages

| Dropped | Why | Instead |
|---|---|---|
| `synx` gem | Unmaintained: last release in 2016 | |
| `xcode-install` gem | Sunset | `xcodes` (`brew install xcodes`) |
| `tslint` npm package | Deprecated in favor of ESLint | `eslint` (still installed) |

## Paths and config

| Dropped | Why | Instead |
|---|---|---|
| `/usr/local/opt/llvm/bin` in `PATH` | Intel-only path | clangd from nixpkgs' `clang-tools`, on `PATH` |
| nokogiri's build flags in `home/bundle/config` | Intel-only paths; nokogiri ships precompiled | |
| `~/.cargo/config` link | Cargo warns about the extension-less name | `~/.cargo/config.toml` |
| CI's SSH key step | Nothing clones over SSH any more | Delete the `ID_RSA_FILE_B64` repository secret |

## Cleaning up a Mac provisioned before

```sh-session
$ brew uninstall anyenv
$ brew uninstall trash
$ brew uninstall --cask 1password/tap/1password-cli && brew untap 1password/tap
$ rm -rf ~/.anyenv ~/.anyenv-init-zsh ~/.anyenv-init-bash ~/.cargo/config
$ mise install  # in a project pinned to versions mise doesn't have yet
```

Dropped casks stay installed as well; `brew uninstall --cask <name>` removes one.
