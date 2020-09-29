![creasty's dotfiles](./docs/visual.jpg)

dotfiles [![Build Status](https://travis-ci.com/creasty/dotfiles.svg?branch=master)](https://travis-ci.com/creasty/dotfiles) ![macOS](https://img.shields.io/badge/platform-macOS-lightgray.svg) [![License](https://img.shields.io/github/license/creasty/dotfiles.svg)](./LICENSE.txt)
========

A powerful development environment for full-stack engineers.  
Work it harder, make it better, do it faster, makes us stronger.

<pre><code>$ curl -L <a href="http://dotfiles.creasty.com/up">dotfiles.creasty.com/up</a> | bash</code></pre>

Screenshots
-----------

| Tmux + ZSH (Alacritty) | Vim (MacVim) |
|---|---|
| ![](./docs/images/screenshots/tmux.png) | ![](./docs/images/screenshots/vim.png) |

Performance
-----------

### zsh

Starts up in ~380ms.

- 600 code lines of Zsh (config)
- 3 plugins

<details><summary>`cloc` result</summary>

```sh-session
$ cloc --exclude-dir=plugins shell/zsh
       6 text files.
       6 unique files.
       4 files ignored.

github.com/AlDanial/cloc v 1.84  T=0.01 s (280.3 files/s, 54656.2 lines/s)
-------------------------------------------------------------------------------
Language                     files          blank        comment           code
-------------------------------------------------------------------------------
zsh                              4            126             86            568
-------------------------------------------------------------------------------
SUM:                             4            126             86            568
-------------------------------------------------------------------------------
```

```sh-session
$ ls shell/zsh/plugins | wc -l
       3
```

</details>

<details><summary>Benchmark</summary>

```sh-session
$ for i in $(seq 1 5); do time zsh -i -c exit; done
zsh -i -c exit  0.18s user 0.18s system 97% cpu 0.364 total
zsh -i -c exit  0.19s user 0.19s system 98% cpu 0.382 total
zsh -i -c exit  0.18s user 0.19s system 99% cpu 0.372 total
zsh -i -c exit  0.19s user 0.20s system 98% cpu 0.391 total
zsh -i -c exit  0.19s user 0.19s system 99% cpu 0.386 total
```

</details>

### vim/nvim

Starts up in ~180ms.

- 3200 code lines of VimScript (config)
- 50 plugins

<details><summary>`cloc` result</summary>

```sh-session
$ cloc --exclude-dir=dein vim
     138 text files.
     134 unique files.
      54 files ignored.

github.com/AlDanial/cloc v 1.84  T=0.06 s (1477.6 files/s, 92922.7 lines/s)
--------------------------------------------------------------------------------
Language                      files          blank        comment           code
--------------------------------------------------------------------------------
vim script                       65            739            658           3192
JSON                              1              8              0            196
Python                            2             36              2            192
TOML                              2             49             20            172
Ruby                              8             17              0            113
C                                 2             14              6             59
Go                                2             11              0             29
C/C++ Header                      1              3              0             12
HTML                              1              0              0             10
make                              1              4              0              9
Java                              1              1              3              8
Bourne Again Shell                1              3              0              7
C++                               1              2              5              7
Markdown                          1              3              0              7
--------------------------------------------------------------------------------
SUM:                             89            890            694           4013
--------------------------------------------------------------------------------
```

```sh-session
$ ag '^\[\[plugins' vim/dein.toml vim/dein_lazy.toml | wc -l
      50
```

</details>

<details><summary>Benchmark</summary>

```sh-session
$ for i in $(seq 1 5); do time nvim -c quit; done
nvim -c quit  0.18s user 0.06s system 129% cpu 0.187 total
nvim -c quit  0.16s user 0.06s system 131% cpu 0.171 total
nvim -c quit  0.18s user 0.07s system 132% cpu 0.183 total
nvim -c quit  0.17s user 0.06s system 128% cpu 0.178 total
nvim -c quit  0.17s user 0.06s system 131% cpu 0.178 total
```

</details>

Author
------

Yuki Iwanaga (@creasty)
