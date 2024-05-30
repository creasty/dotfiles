![creasty's dotfiles](./docs/images/cover.png)

creasty's dotfiles
==================

[ci]: https://github.com/creasty/dotfiles/actions/workflows/provisioning.yml
[ci-badge]: https://github.com/creasty/dotfiles/actions/workflows/provisioning.yml/badge.svg
[platform-badge]: https://img.shields.io/badge/Platform-macOS-lightgrey
[license]: ./LICENSE.txt
[license-badge]: https://img.shields.io/badge/License-MIT-yellow.svg

[![Provisioning][ci-badge]][ci] ![Platform: macOS][platform-badge] [![License: MIT][license-badge]][license]

<pre><code>$ curl -L <a href="https://dotfiles.creasty.com/provision">dotfiles.creasty.com/provision</a> | bash</code></pre>

Screenshots
-----------

| Zsh + tmux (Alacritty) | Neovim (Kitty) |
|---|---|
| ![](./docs/images/screenshots/tmux.png) | ![](./docs/images/screenshots/neovim.png) |

Stats
-----

Both of my zsh and nvim are thoroughly tailored yet carefully fine-tuned for outstanding performance.

### zsh

- ~72ms startup time on M1 Max
- 700 sloc of config
- 1,100 sloc of commands
- 2 third-party plugins and 5 hooks:
  - [fast-syntax-highlighting](https://github.com/zdharma-continuum/fast-syntax-highlighting)
  - [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
  - [anyenv](https://github.com/anyenv/anyenv) ([rbenv](https://github.com/rbenv/rbenv), [nodenv](https://github.com/nodenv/nodenv) & [jenv](https://github.com/jenv/jenv))
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

### nvim

- ~60ms startup time on M1 Max
- 2,900 sloc of config
- 10 original plugins:
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
- 36 third-party plugins, including:
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

Author
------

Yuki Iwanaga / [@creasty](https://github.com/creasty)
