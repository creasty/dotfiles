![creasty's dotfiles](https://user-images.githubusercontent.com/1695538/117818019-254abb00-b2a3-11eb-8676-5cd1415ce2b5.png)

dotfiles [![Build Status](https://github.com/creasty/dotfiles/actions/workflows/provisioning.yml/badge.svg)](https://github.com/creasty/dotfiles/actions/workflows/provisioning.yml) ![macOS](https://img.shields.io/badge/platform-macOS-lightgray.svg) [![License](https://img.shields.io/github/license/creasty/dotfiles.svg)](./LICENSE.txt)
========

Where the world revolves around.<br>
Work it harder, make it better, do it faster, makes us stronger.

<pre><code>$ curl -L <a href="http://dotfiles.creasty.com/up">dotfiles.creasty.com/up</a> | bash</code></pre>

Screenshots
-----------

| Tmux + ZSH (Alacritty) | Neovim (Kitty) |
|---|---|
| ![](./docs/images/screenshots/tmux.png) | ![](./docs/images/screenshots/neovim.png) |

Stats
-----

Heavily customized, meticulously optimized for high performance.

### zsh

- ~150ms to startup
- 560 loc of config
- 2 zsh plugins + anyenv (rbenv, nodenv, jenv) + direnv

<details>

```sh-session
$ repeat 5 ( time zsh -i -c exit ; sleep 0.1 )
zsh -i -c exit  0.08s user 0.07s system 96% cpu 0.148 total
zsh -i -c exit  0.08s user 0.07s system 96% cpu 0.151 total
zsh -i -c exit  0.08s user 0.06s system 95% cpu 0.145 total
zsh -i -c exit  0.08s user 0.06s system 94% cpu 0.148 total
zsh -i -c exit  0.08s user 0.06s system 94% cpu 0.148 total
```

```sh-session
$ cloc --exclude-dir=plugins shell/zsh
       6 text files.
       6 unique files.
       4 files ignored.

github.com/AlDanial/cloc v 1.84  T=0.01 s (296.9 files/s, 57072.9 lines/s)
-------------------------------------------------------------------------------
Language                     files          blank        comment           code
-------------------------------------------------------------------------------
zsh                              4            126             81            562
-------------------------------------------------------------------------------
SUM:                             4            126             81            562
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

- ~150ms to startup
- 3,700 loc of config
- 37 third-party plugins

<details>

```sh-session
$ repeat 5 ( time nvim --headless -c quit ; sleep 0.1 )
nvim --headless -c quit  0.14s user 0.09s system 151% cpu 0.149 total
nvim --headless -c quit  0.13s user 0.09s system 149% cpu 0.146 total
nvim --headless -c quit  0.13s user 0.08s system 150% cpu 0.145 total
nvim --headless -c quit  0.13s user 0.08s system 150% cpu 0.142 total
nvim --headless -c quit  0.14s user 0.09s system 150% cpu 0.148 total
```

```sh-session
$ cloc --exclude-dir=dein,template nvim
      95 text files.
      91 unique files.
      35 files ignored.

github.com/AlDanial/cloc v 1.84  T=0.09 s (737.4 files/s, 53433.4 lines/s)
-------------------------------------------------------------------------------
Language                     files          blank        comment           code
-------------------------------------------------------------------------------
vim script                      52            458            309           2235
Lua                              7             88             21            734
JSON                             1             14              0            290
TOML                             2             44             37            239
Python                           2             36              2            192
Scheme                           1              1              0             10
-------------------------------------------------------------------------------
SUM:                            65            641            369           3700
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
