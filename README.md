![creasty's dotfiles](https://user-images.githubusercontent.com/1695538/117818019-254abb00-b2a3-11eb-8676-5cd1415ce2b5.png)

dotfiles [![CircleCI](https://circleci.com/gh/creasty/dotfiles.svg?style=shield)](https://circleci.com/gh/creasty/dotfiles) ![macOS](https://img.shields.io/badge/platform-macOS-lightgray.svg) [![License](https://img.shields.io/github/license/creasty/dotfiles.svg)](./LICENSE.txt)
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

- ~130ms to startup
- 560 loc of config
- 2 plugins + anyenv (rbenv, nodenv, jenv) + direnv

<details>

```sh-session
$ repeat 5 ( time zsh -i -c exit ; sleep 0.1 )
zsh -i -c exit  0.07s user 0.06s system 94% cpu 0.139 total
zsh -i -c exit  0.07s user 0.06s system 95% cpu 0.130 total
zsh -i -c exit  0.07s user 0.05s system 95% cpu 0.133 total
zsh -i -c exit  0.07s user 0.05s system 96% cpu 0.130 total
zsh -i -c exit  0.07s user 0.05s system 94% cpu 0.130 total
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

- ~130ms to startup
- 3,500 loc of config
- 43 plugins

<details>

```sh-session
$ repeat 5 ( time nvim --headless -c quit ; sleep 0.1 )
nvim --headless -c quit  0.12s user 0.07s system 145% cpu 0.129 total
nvim --headless -c quit  0.12s user 0.07s system 148% cpu 0.130 total
nvim --headless -c quit  0.12s user 0.08s system 147% cpu 0.135 total
nvim --headless -c quit  0.12s user 0.07s system 145% cpu 0.127 total
nvim --headless -c quit  0.13s user 0.08s system 147% cpu 0.137 total
```

```sh-session
$ cloc --exclude-dir=dein,template nvim
      94 text files.
      90 unique files.
      35 files ignored.

github.com/AlDanial/cloc v 1.84  T=0.08 s (823.2 files/s, 58123.6 lines/s)
-------------------------------------------------------------------------------
Language                     files          blank        comment           code
-------------------------------------------------------------------------------
vim script                      51            453            306           2187
Lua                              6             68             16            614
JSON                             1             13              0            291
TOML                             2             45             14            266
Python                           2             36              2            192
Scheme                           1              1              0             10
Markdown                         1              1              0              4
-------------------------------------------------------------------------------
SUM:                            64            617            338           3564
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
