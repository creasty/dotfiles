![creasty's dotfiles](./docs/images/cover.png)

creasty's dotfiles [![Build Status](https://github.com/creasty/dotfiles/actions/workflows/provisioning.yml/badge.svg)](https://github.com/creasty/dotfiles/actions/workflows/provisioning.yml) ![Platform: macOS](https://img.shields.io/badge/Platform-macOS-lightgrey) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE.txt)
==================

Orbit the zenith of productivity - unlock the hidden potential within.

<pre><code>$ curl -L <a href="https://dotfiles.creasty.com/up">dotfiles.creasty.com/up</a> | bash</code></pre>

📸 Screenshots
--------------

| 🚀 Tmux + ZSH (Alacritty) | 🌌 Neovim (Kitty) |
|---|---|
| ![](./docs/images/screenshots/tmux.png) | ![](./docs/images/screenshots/neovim.png) |

📊 Stats: Power-packed Performance
----------------------------------

Both of my zsh and nvim are thoroughly tailored yet carefully fine-tuned for outstanding performance, contributing to remarkable productivity and efficiency gains.

### ⚡ zsh

- Blazing fast ~72ms startup time on M1 Max
- 550 sloc of finely-tuned config
- 2 third-party plugins and 5 hooks:
  - [fast-syntax-highlighting](https://github.com/zdharma-continuum/fast-syntax-highlighting)
  - [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
  - [anyenv](https://github.com/anyenv/anyenv) ([rbenv](https://github.com/rbenv/rbenv), [nodenv](https://github.com/nodenv/nodenv) & [jenv](https://github.com/jenv/jenv))
  - [direnv](https://github.com/direnv/direnv)

<details>

```sh-session
$ hyperfine --warmup 3 --prepare 'sleep 0.1' 'zsh -i -c exit'
$ cloc --exclude-dir=plugins shell/zsh
$ ls shell/zsh/plugins | wc -l
```

Profiling:

```sh-session
$ ZSH_PROF_ENABLED=1 zsh -i -c exit
```

</details>

### 🌌 nvim

- Lightning-fast ~60ms startup time on M1 Max
- 2,900 sloc of expertly-crafted config
- 41 third-party plugins, including:
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
$ rg '^\[\[plugins' nvim/dein/*.toml | wc -l
```

Profiling:

```sh-session
$ nvim --headless --startuptime /dev/stdout -c quit
```

</details>

💻 Author
---------

Yuki Iwanaga / [@creasty](https://github.com/creasty)
