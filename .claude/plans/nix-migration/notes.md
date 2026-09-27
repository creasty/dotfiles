# Provisioning with Nix

Ansible is replaced by a flake: [nix-darwin](https://github.com/nix-darwin/nix-darwin) configures the system, [home-manager](https://github.com/nix-community/home-manager) the home directory.
`./provision` installs Homebrew and Determinate Nix, then switches to `darwinConfigurations.<user>`; `./verify` still proves the result.

## Design

- **A module per topic** (`nix/modules/*.nix`), in place of an Ansible role. Each configures both the system and the home directory, so everything about a tool is in one file.
- **Links follow the tree**, instead of the central `link:` list of `provisioning/config.yml`:
  - `home/<path>` → `~/.<path>`, `config/<path>` → `~/.config/<path>`, file by file (`nix/modules/links.nix`).
  - The modules add only the links that live elsewhere: `nvim/` (as a directory, since dein.vim writes into it), the shell files, and VS Code's settings.
  - Links point into the checkout (`mkOutOfStoreSymlink`), so edits apply without a rebuild. A new file needs `git add` and a switch.
- **Packages:**
  - Command-line tools come from nixpkgs, pinned by `flake.lock`.
  - Homebrew keeps:
    - the casks
    - what nixpkgs lacks (carthage)
    - the JDKs, which `/usr/libexec/java_home` and mise use at stable paths
    - Ruby's build libraries (openssl@3, libyaml, zlib)
    - libpq (psql)
    - icu4c, for the charlock_holmes gem
- **Runtimes stay with mise** (`config/mise/config.toml`). home-manager runs `mise install` on every switch, after registering the JDKs.
- **1Password's CLI** comes from nixpkgs through nix-darwin, which copies `op` to `/usr/local/bin`, the path the app's integration requires.
- **1Password manages the SSH keys:**
  - `~/.ssh/config` is generated and makes ssh use 1Password's SSH agent.
  - Private keys move into 1Password; public keys stay in `~/.ssh/keys` to pick a key per host (`IdentitiesOnly`).
- **Shells:**
  - nix-darwin's `/etc/zshenv` sets up `PATH` for every zsh. Its `/etc/zprofile` doesn't run `path_helper`.
  - `~/.profile` puts Nix's profile in front of Homebrew, so formulae left from before don't shadow Nix's packages.
  - The zsh plugins come from nixpkgs instead of submodules.
- **Verification:**
  - The tests read what the activated configuration provisioned from `/etc/dotfiles/manifest.json` (`nix/modules/verify.nix`).
  - Ansible's tag selection is gone, because the whole configuration is always applied.

## Where each role went

| Ansible role | Module |
|---|---|
| link | `links.nix` (the tree), plus the modules below for their own files |
| ssh | `ssh.nix` |
| homebrew | `homebrew.nix` (taps, casks, formulae), `packages.nix` (command-line tools) |
| mise, ruby, nodejs | `mise.nix` |
| java | `java.nix` |
| golang, rust, swift | `go.nix`, `rust.nix`, `swift.nix` |
| vim | `neovim.nix` |
| vscode | `vscode.nix` |
| flutter | `flutter.nix` |
| osx | `macos.nix` |
| zsh | `shell.nix` |
| launchagent, vagrant | dropped |

## Migrating a Mac provisioned with Ansible

1. Pull, and run `./provision`. It installs Nix and switches.
   - home-manager removes the links Ansible made into the checkout, and keeps other files in the way with a `.before-nix` suffix (e.g. the `~/.ssh/config` Ansible assembled).
   - nix-darwin takes over `/etc/zshenv`, `/etc/zprofile`, `/etc/zshrc` and `/etc/bashrc`. It keeps known versions with a `.before-nix-darwin` suffix.
     - If it aborts with "Unexpected files in /etc", check those files and rename them that way.
   - If it fails with "toolchain 'stable-…' does not contain component 'rust-analyzer'", the stable toolchain predates Rust 1.64, and `rustup update` fails too on its `rls`, which Rust no longer ships.
     `rustup toolchain uninstall stable`, then run it again: rustup installs the current stable.
2. Clean up what the switch leaves behind:

   ```sh-session
   $ rm -rf ~/dotfiles/shell/zsh/plugins  # the former submodules
   $ rm ~/.config/.ripgreprc              # ripgrep's config is at ~/.config/ripgrep/config now
   ```

   - Docker Desktop can come back from its upgrade in "User" mode, which adds a PATH section to the top of the shell files on every start (`./verify` fails then).
     Set Settings > Advanced > CLI tools to "System", then remove the sections: `git -C ~/dotfiles checkout shell/profile shell/bash/bash_profile`, and `rm ~/.zprofile.before-nix` if it only holds Docker Desktop's.
   - Tabnine is no longer installed, but stays until uninstalled, and its VS Code extension adds `tabnine.experimentalAutoImports` to `vscode/settings.json` whenever it activates.
     `code --uninstall-extension tabnine.tabnine-vscode`, and `:CocUninstall coc-tabnine` in Neovim. With VS Code quit, its data can go too: `~/Library/Application Support/TabNine`, `~/Library/Preferences/TabNine` and `~/Library/Application Support/Code/User/globalStorage/tabnine.tabnine-vscode`.

3. Uninstall the formulae that Nix provides now, when convenient.
   - Until then, Nix's come first on `PATH`.
   - The switch never uninstalls anything (`cleanup = "none"`).

   ```sh-session
   $ brew uninstall awscli bat cloc ctags curl deno difftastic direnv envchain expect eza fd ffmpeg gh ghq git \
       git-filter-repo git-lfs gnupg graphviz hyperfine imagemagick jo jq massren ngrep nkf parallel pastel peco \
       procs protobuf ripgrep sd tmux uv webp xh mise go gopls golangci-lint rustup gradle pre-commit coursier \
       kotlin-language-server neovim ansible-lint clang-format llvm shellcheck terraform-ls watchman yarn ansible
   $ brew untap golangci/tap hashicorp/tap
   $ brew uninstall --cask 1password-cli  # if still installed, from either tap
   $ brew untap 1password/tap             # if still tapped
   ```

4. Move the SSH keys into 1Password.
   - Import each private key, and turn on the SSH agent in 1Password's settings (Developer).
   - Keep the public key in `~/.ssh/keys/<name>.pub`, and point the host's `IdentityFile` in `~/.ssh/config.d/` at it.
   - Delete the private key files.
5. Optionally, `chsh -s /bin/zsh`. A Homebrew zsh that is already the login shell stays, but nothing updates it any more.

## Dropped

| Dropped | Why | Instead |
|---|---|---|
| Ansible (`provisioning/`) | Replaced by the flake | `flake.nix`, `nix/modules/` |
| `provisioning/secrets.yml` (the sudo password) | darwin-rebuild asks for it | Touch ID for sudo |
| `config.yml`'s `link:` list | Replaced by the tree | `home/`, `config/` |
| The launchagent role | No launch agents were configured | nix-darwin's `launchd.user.agents` when needed |
| The vagrant role | Already disabled | |
| The zsh plugin submodules | Pinned by `flake.lock` instead | nixpkgs' `zsh-autosuggestions`, `zsh-fast-syntax-highlighting` |
| Homebrew's zsh as the login shell | macOS's zsh gets nix-darwin's setup as well | `/bin/zsh`, unless a zsh already is the login shell |
| `yarn` formula | Also in `config/mise/default-npm-packages` | mise's Node.js |
| `llvm`, `clang-format` formulae | Only clangd and clang-format were used | nixpkgs' `clang-tools`, with no `clangd.path` setting |
| `golangci/tap` | golangci-lint is in nixpkgs | |
| Homebrew's `1password-cli` cask | The CLI comes from nixpkgs, like the other command-line tools | nix-darwin's `programs._1password`, `op` at `/usr/local/bin` |
| `./verify --tags`, `DOTFILES_NOEDIT_SECRETS` | No Ansible tags or secrets file | `./verify [bats options]` |
