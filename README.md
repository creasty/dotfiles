![creasty's dotfiles — Stellar productivity](./.github/cover.jpg)

# creasty's dotfiles

[ci]: https://github.com/creasty/dotfiles/actions/workflows/apply.yml
[ci-badge]: https://github.com/creasty/dotfiles/actions/workflows/apply.yml/badge.svg
[tests]: https://github.com/creasty/dotfiles/actions/workflows/tests.yml
[tests-badge]: https://github.com/creasty/dotfiles/actions/workflows/tests.yml/badge.svg
[platform-badge]: https://img.shields.io/badge/Platform-macOS-lightgrey
[license]: ./LICENSE.txt
[license-badge]: https://img.shields.io/badge/License-MIT-yellow.svg

[![Apply][ci-badge]][ci] [![Tests][tests-badge]][tests] ![Platform: macOS][platform-badge] [![License: MIT][license-badge]][license]

This repository contains my personal dotfiles configuration for macOS, featuring thoroughly tailored setups for NeoVim and Zsh with performance in mind.

## Installation

<pre><code>$ curl -fsSL <a href="https://dotfiles.creasty.com/apply">https://dotfiles.creasty.com/apply</a> | bash</code></pre>

It installs Homebrew, clones this repository to `~/dotfiles`, installs [Nix](https://determinate.systems/nix/), and applies the [nix-darwin](https://github.com/nix-darwin/nix-darwin) configuration of `flake.nix` for the current user, [home-manager](https://github.com/nix-community/home-manager) included.

To apply changes later, run it again:

```sh-session
$ ~/dotfiles/apply
```

It skips what's already installed, and pulls master first unless the checkout is on another branch or has changes of its own.
Then it switches to the configuration and [verifies](#verification) the result.
Flakes only see files tracked by git, so `git add` a new file first.

## Verification

`./apply` ends by verifying its result with behavioral tests (`nix/tests/`): shells are started the way terminals start them, and have to find the right runtimes, configs and commands.
To verify a machine again:

```sh-session
$ ./verify
$ ./verify --filter java  # options go to bats
$ ./verify --bench        # only the benchmarks
```

The tests compare the machine with what the activated configuration lists in `/etc/dotfiles/manifest.json`.
Benchmarks, the tests tagged `bench` such as the shell's startup time, check a budget that a busy machine misses: `./apply` and the other runs skip them.
Set `DOTFILES_NOVERIFY=1` to apply without verifying.

## Updates

Versions are pinned, and [Renovate](./.github/renovate.json) bumps them on Friday mornings, in a pull request per kind:

| Pinned in | What | Tested by |
|---|---|---|
| `nvim/lazy-lock.json` | Neovim plugins, at the commits lazy.nvim installs | [Neovim's workflow tests](./nvim/tests/README.md) |
| `flake.lock` | nixpkgs, nix-darwin and home-manager | The `apply` workflow |
| `config/mise/config.toml` | Runtimes and tools, which mise installs | The `apply` workflow |
| `nix/modules/skills.nix` | Agent skills, at commits of their repositories | The `apply` workflow |
| `nix/modules/shell.nix` | zsh plugins, at their releases' commits | The shell tests and the `apply` workflow |
| `.github/workflows/` | GitHub Actions, by commit SHA | The workflows themselves |

A Neovim plugin or an agent skill whose repository tags a release of each change within weeks is pinned at a release's commit, the others at a commit of the branch they follow.
Patch releases, minor ones from 1.0 on and `flake.lock`'s refresh merge themselves once CI passes.
After merging, run `./apply` again, and run `:Lazy restore` in Neovim to check out the new plugin commits.

## Project structure

`flake.nix` configures the system with nix-darwin and the home directory with home-manager, from a module per topic in `nix/modules/`: each has everything about a tool, for both.

- `bin/`: Commands, on `PATH`
- `cloud/`: Files for machines other than this Mac
  - `claude/`: [Claude Code's cloud sessions](./cloud/claude/README.md)
- `config/`: Configs, linked into `~/.config`
- `hammerspoon/`: Key bindings, on [Hammerspoon](./hammerspoon/README.md)
  - `tests/`: Specs, on a fake of Hammerspoon's API
- `home/`: Dotfiles, linked into `~` with a leading dot
- `nix/`
  - `modules/`: The configuration, a module per topic
  - `tests/`: Behavioral tests of the applied configuration, which `./verify` runs
- `nvim/`: Neovim
  - `tests/`: [End-to-end workflow tests](./nvim/tests/README.md)
- `shell/`: Bash and Zsh
  - `tests/`: Behavioral tests of the commands in `bin/` and the zsh config, with fakes of what they'd reach
- `vscode/`: VS Code's settings and key bindings

### Links

Files are linked into the home directory by where they are in the repository, with no list to maintain:

| Repository | Home directory |
|---|---|
| `home/<path>` | `~/.<path>` (`home/aws/config` → `~/.aws/config`) |
| `config/<path>` | `~/.config/<path>` (`config/git/config` → `~/.config/git/config`) |

The modules link the rest: `nvim/`, `hammerspoon/`, the shell files and VS Code's settings.
Links point straight into the checkout, not through the Nix store: edits apply without a rebuild, and the apps macOS starts at login find their configs before `/nix` is mounted.

### Packages

Command-line tools come from nixpkgs, pinned by `flake.lock`, ahead of Homebrew's on `PATH`.
Homebrew installs the apps (casks), and the formulae that nixpkgs lacks or that need a stable path, such as the JDKs and the libraries Ruby is built against.
mise installs the runtimes of `config/mise/config.toml` on every switch, and takes Homebrew's JDKs for Java.

### App Store apps

Homebrew Bundle installs the App Store apps of `nix/modules/appstore.nix` with [mas](https://github.com/mas-cli/mas), which asks for your password (sudo) to install them.
mas can't sign in to the App Store, so sign in before running `./apply`.
`mas list` shows the IDs of installed apps, and `mas search <name>` those of others.
mas can't install iPhone and iPad apps, such as Kindle's, so get those from the App Store app.

## Author

Yuki Iwanaga / [@creasty](https://github.com/creasty)
