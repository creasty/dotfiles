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

- ~150ms to startup
- 560 loc of Zsh config
- 2 plugins + anyenv (rbenv, nodenv, jenv) + direnv

<details>

```sh-session
$ repeat 5 ( time zsh -i -c exit ; sleep 0.1 )
zsh -i -c exit  0.08s user 0.06s system 96% cpu 0.146 total
zsh -i -c exit  0.08s user 0.06s system 96% cpu 0.149 total
zsh -i -c exit  0.08s user 0.07s system 96% cpu 0.155 total
zsh -i -c exit  0.08s user 0.06s system 96% cpu 0.143 total
zsh -i -c exit  0.08s user 0.06s system 97% cpu 0.147 total
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
- 3,500 loc of config
- 47 plugins

<details>

```sh-session
$ repeat 5 ( time nvim --headless -c quit ; sleep 0.1 )
nvim --headless -c quit  0.13s user 0.08s system 150% cpu 0.140 total
nvim --headless -c quit  0.14s user 0.09s system 151% cpu 0.150 total
nvim --headless -c quit  0.13s user 0.08s system 153% cpu 0.140 total
nvim --headless -c quit  0.15s user 0.09s system 155% cpu 0.152 total
nvim --headless -c quit  0.14s user 0.08s system 152% cpu 0.150 total
```

```sh-session
$ cloc --exclude-dir=dein,template nvim
      97 text files.
      93 unique files.
      36 files ignored.

github.com/AlDanial/cloc v 1.84  T=0.09 s (725.9 files/s, 48312.3 lines/s)
-------------------------------------------------------------------------------
Language                     files          blank        comment           code
-------------------------------------------------------------------------------
vim script                      57            497            313           2331
Lua                              5             36             16            433
JSON                             1             13              0            292
TOML                             2             50             12            292
Python                           2             36              2            192
Scheme                           1              1              0             10
-------------------------------------------------------------------------------
SUM:                            68            633            343           3550
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
