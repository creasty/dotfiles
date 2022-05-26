![creasty's dotfiles](https://user-images.githubusercontent.com/1695538/117818019-254abb00-b2a3-11eb-8676-5cd1415ce2b5.png)

dotfiles [![Build Status](https://github.com/creasty/dotfiles/actions/workflows/provisioning.yml/badge.svg)](https://github.com/creasty/dotfiles/actions/workflows/provisioning.yml) ![macOS](./docs/images/badges/platform.svg) [![License](./docs/images/badges/license.svg)](./LICENSE.txt)
========

Work it harder, make it better, do it faster, makes us stronger.

<pre><code>$ curl -L <a href="http://dotfiles.creasty.com/up">dotfiles.creasty.com/up</a> | bash</code></pre>

Screenshots
-----------

| Tmux + ZSH (Alacritty) | Neovim (Kitty) |
|---|---|
| ![](./docs/images/screenshots/tmux.png) | ![](./docs/images/screenshots/neovim.png) |

Stats
-----

Heavily customized while meticulously optimized for insane performance.

### zsh

- ~150ms to startup
- 560 loc of config
- 4 (+3) third-party plugins and hooks
  - [fast-syntax-highlighting](https://github.com/zdharma-continuum/fast-syntax-highlighting)
  - [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
  - [anyenv](https://github.com/anyenv/anyenv) with `rbenv`, `nodenv` and `jenv`
  - [direnv](https://github.com/direnv/direnv)

<details>

```sh-session
$ repeat 5 ( time zsh -i -c exit ; sleep 0.1 )
$ cloc --exclude-dir=plugins shell/zsh
$ ls shell/zsh/plugins | wc -l
```

Profiling:

```sh-session
$ ZSH_PROF_ENABLED=1 zsh -i -c exit
```

</details>

### nvim

- ~150ms to startup
- 3,600 loc of config
- 41 third-party plugins

<details>

```sh-session
$ repeat 5 ( time nvim --headless -c quit ; sleep 0.1 )
$ cloc --exclude-dir=dein,template nvim
$ rg '^\[\[plugins' nvim/dein.toml nvim/dein_lazy.toml | wc -l
```

Profiling:

```sh-session
$ nvim --headless --startuptime /dev/stdout -c quit
```

</details>

Author
------

Yuki Iwanaga ([@creasty](https://github.com/creasty))
