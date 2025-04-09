![creasty's dotfiles](./docs/images/cover.png)

# creasty's dotfiles

[ci]: https://github.com/creasty/dotfiles/actions/workflows/provisioning.yml
[ci-badge]: https://github.com/creasty/dotfiles/actions/workflows/provisioning.yml/badge.svg
[platform-badge]: https://img.shields.io/badge/Platform-macOS-lightgrey
[license]: ./LICENSE.txt
[license-badge]: https://img.shields.io/badge/License-MIT-yellow.svg

[![Provisioning][ci-badge]][ci] ![Platform: macOS][platform-badge] [![License: MIT][license-badge]][license]

This repository contains my personal dotfiles configuration for macOS, featuring thoroughly tailored setups for NeoVim and Zsh with performance in mind.

| Neovim (Kitty) | Zsh + tmux (Alacritty) |
|---|---|
| ![](./docs/images/screenshots/neovim.png) | ![](./docs/images/screenshots/tmux.png) |

## Installation

<pre><code>$ curl -L <a href="https://dotfiles.creasty.com/provision">dotfiles.creasty.com/provision</a> | bash</code></pre>

## Project structure

### Main configuration directories

- **`bin/`** : Custom executable scripts and commands (Added to system `PATH`)
- **`config/*`** : XDG-compliant configuration files
- **`home/*`** : Home directory dotfiles
- **`nvim/`** : Neovim configurations
- **`shell/`** : Shell environment configurations
  - **`bash/*`** : Bash-specific configurations
  - **`zsh/*`** : Zsh-specific configurations

### Administrative directories

- **`docs/`** : Setup documentation and resources
- **`provisioning/`** : Ansible playbooks and tasks

## Stats

| | nvim | zsh |
|---:|---|---|
| Startup time | ~60ms | ~72ms |
| Config size | 2,900 sloc | 700 sloc |
| Original plugins | 10 plugins | 1,100 sloc of bin |
| Third-party plugins | 36 plugins | 2 plugins + 5 hooks |

### nvim

Original plugins:
- [mold.vim](https://github.com/creasty/mold.vim)
- [opfmt](https://github.com/creasty/opfmt)
- [auto_save.vim](./nvim/plugin/auto_save.vim)
- [better_tagfunc.vim](./nvim/plugin/better_tagfunc.vim)
- [blockwise_visual_insert.vim](./nvim/plugin/blockwise_visual_insert.vim)
- [emacs_cursor.vim](./nvim/plugin/emacs_cursor.vim)
- [file.vim](./nvim/plugin/file.vim)
- [next_file.vim](./nvim/plugin/next_file.vim)
- [project_dir.vim](./nvim/plugin/project_dir.vim)
- [restore_buffer.vim](./nvim/plugin/restore_buffer.vim)

Third-party plugins (excerpt):
- [coc.nvim](https://github.com/neoclide/coc.nvim)
- [copilot.vim](https://github.com/github/copilot.vim)
- [ddu.vim](https://github.com/Shougo/ddu.vim)
- [lexima.vim](https://github.com/cohama/lexima.vim)
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)
- [ultisnips](https://github.com/SirVer/ultisnips)

<details>

```sh-session
$ hyperfine --warmup 3 --prepare 'sleep 0.1' 'nvim --headless -c quit'
$ cloc --exclude-dir=dein,template nvim
$ rg '^repo\b.+\bcreasty/' nvim/dein/*.toml
$ rg --no-heading '^\[\[plugins' nvim/dein/*.toml | wc -l
```

Profiling:

```sh-session
$ nvim --headless --startuptime /dev/stdout -c quit
```

</details>

### zsh

Third-party plugins/hooks:

- [fast-syntax-highlighting](https://github.com/zdharma-continuum/fast-syntax-highlighting)
- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
- [anyenv](https://github.com/anyenv/anyenv)
    - [rbenv](https://github.com/rbenv/rbenv)
    - [nodenv](https://github.com/nodenv/nodenv)
    - [jenv](https://github.com/jenv/jenv)
- [direnv](https://github.com/direnv/direnv)

<details>

```sh-session
$ hyperfine --warmup 3 --prepare 'sleep 0.1' 'zsh -i -c exit'
$ cloc --exclude-dir=plugins,bash --lang-no-ext=zsh shell
$ cloc bin
$ ls shell/zsh/plugins | wc -l
```

Profiling:

```sh-session
$ ZSH_PROF_ENABLED=1 zsh -i -c exit
```

</details>

## Author

Yuki Iwanaga / [@creasty](https://github.com/creasty)
