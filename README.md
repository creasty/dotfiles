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

Meticulously customized, highly performance optimized.

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

- ~170ms to startup
- 3700 loc of config (VimScript + Lua + Python)
- 47 plugins

<details>

```sh-session
$ repeat 5 ( time nvim --headless -c quit ; sleep 0.1 )
nvim --headless -c quit  0.16s user 0.07s system 137% cpu 0.168 total
nvim --headless -c quit  0.15s user 0.07s system 139% cpu 0.157 total
nvim --headless -c quit  0.16s user 0.07s system 138% cpu 0.165 total
nvim --headless -c quit  0.16s user 0.07s system 137% cpu 0.165 total
nvim --headless -c quit  0.15s user 0.07s system 139% cpu 0.161 total
```

```sh-session
$ cloc --exclude-dir=dein nvim
     144 text files.
     138 unique files.
      57 files ignored.

github.com/AlDanial/cloc v 1.84  T=0.08 s (1131.0 files/s, 70940.4 lines/s)
--------------------------------------------------------------------------------
Language                      files          blank        comment           code
--------------------------------------------------------------------------------
vim script                       61            675            545           3125
Lua                               4             36             16            373
JSON                              1              9              0            273
TOML                              2             42             12            203
Python                            2             36              2            192
Ruby                              8             17              0            113
C                                 2             14              6             59
Go                                2             11              0             29
C/C++ Header                      1              3              0             12
HTML                              1              0              0             10
Scheme                            1              1              0             10
make                              1              4              0              9
GraphQL                           3              0              0              9
Java                              1              1              3              8
Markdown                          1              3              0              7
C++                               1              2              5              7
Bourne Again Shell                1              3              0              6
TypeScript                        1              1              0              4
--------------------------------------------------------------------------------
SUM:                             94            858            589           4449
--------------------------------------------------------------------------------
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
