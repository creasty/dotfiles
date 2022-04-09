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
zsh -i -c exit  0.08s user 0.06s system 95% cpu 0.149 total
zsh -i -c exit  0.08s user 0.06s system 95% cpu 0.151 total
zsh -i -c exit  0.08s user 0.06s system 95% cpu 0.142 total
zsh -i -c exit  0.08s user 0.06s system 94% cpu 0.155 total
zsh -i -c exit  0.08s user 0.06s system 95% cpu 0.144 total
```

```sh-session
$ cloc --exclude-dir=plugins shell/zsh
       6 text files.
       6 unique files.
       4 files ignored.

github.com/AlDanial/cloc v 1.84  T=0.01 s (277.8 files/s, 53337.7 lines/s)
-------------------------------------------------------------------------------
Language                     files          blank        comment           code
-------------------------------------------------------------------------------
zsh                              4            126             81            561
-------------------------------------------------------------------------------
SUM:                             4            126             81            561
-------------------------------------------------------------------------------
```

```sh-session
$ ls shell/zsh/plugins | wc -l
```

Profiling:

```sh-session
$ ZSH_PROF_ENABLED=1 zsh -i -c exit
```

</details>

### nvim

- ~140ms to startup
- 3,700 loc of config
- 42 third-party plugins

<details>

```sh-session
$ repeat 5 ( time nvim --headless -c quit ; sleep 0.1 )
nvim --headless -c quit  0.11s user 0.08s system 147% cpu 0.129 total
nvim --headless -c quit  0.12s user 0.08s system 147% cpu 0.135 total
nvim --headless -c quit  0.12s user 0.08s system 146% cpu 0.134 total
nvim --headless -c quit  0.12s user 0.08s system 146% cpu 0.138 total
nvim --headless -c quit  0.12s user 0.08s system 144% cpu 0.135 total
```

```sh-session
$ cloc --exclude-dir=dein,template nvim
      96 text files.
      92 unique files.
      36 files ignored.

github.com/AlDanial/cloc v 1.84  T=0.08 s (785.4 files/s, 57619.3 lines/s)
-------------------------------------------------------------------------------
Language                     files          blank        comment           code
-------------------------------------------------------------------------------
vim script                      52            453            307           2262
Lua                              5             80             21            615
JSON                             1             14              0            293
TypeScript                       3             34              1            270
TOML                             2             45             14            249
Scheme                           1              4              5             28
-------------------------------------------------------------------------------
SUM:                            64            630            348           3717
-------------------------------------------------------------------------------
```

```sh-session
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
