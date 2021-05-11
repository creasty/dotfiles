![creasty's dotfiles](./docs/visual.jpg)

dotfiles [![CircleCI](https://circleci.com/gh/creasty/dotfiles.svg?style=svg)](https://circleci.com/gh/creasty/dotfiles) ![macOS](https://img.shields.io/badge/platform-macOS-lightgray.svg) [![License](https://img.shields.io/github/license/creasty/dotfiles.svg)](./LICENSE.txt)
========

Work it harder, make it better, do it faster, makes us stronger.

<pre><code>$ curl -L <a href="http://dotfiles.creasty.com/up">dotfiles.creasty.com/up</a> | bash</code></pre>

Screenshots
-----------

| Tmux + ZSH (Alacritty) | Vim (MacVim) |
|---|---|
| ![](./docs/images/screenshots/tmux.png) | ![](./docs/images/screenshots/vim.png) |

Stats
-----

### zsh

- ~440ms to startup
- 600 loc of Zsh config
- 3 plugins

<details><summary>`cloc` result</summary>

```sh-session
$ cloc --exclude-dir=plugins shell/zsh
       6 text files.
       6 unique files.
       4 files ignored.

github.com/AlDanial/cloc v 1.84  T=0.02 s (251.6 files/s, 49440.2 lines/s)
-------------------------------------------------------------------------------
Language                     files          blank        comment           code
-------------------------------------------------------------------------------
zsh                              4            127             92            567
-------------------------------------------------------------------------------
SUM:                             4            127             92            567
-------------------------------------------------------------------------------
```

```sh-session
$ ls shell/zsh/plugins | wc -l
       3
```

</details>
<details><summary>Benchmark</summary>

```sh-session
$ repeat 5 time zsh -i -c exit
zsh -i -c exit  0.22s user 0.22s system 98% cpu 0.446 total
zsh -i -c exit  0.21s user 0.21s system 98% cpu 0.429 total
zsh -i -c exit  0.21s user 0.21s system 98% cpu 0.430 total
zsh -i -c exit  0.21s user 0.22s system 98% cpu 0.436 total
zsh -i -c exit  0.23s user 0.22s system 98% cpu 0.459 total
```

</details>

### nvim/vim

- ~300ms to startup
- 3300 loc of VimScript config
- 46 plugins (extra 82k loc of VimScript & 43k of other various languages)

<details><summary>`cloc` result</summary>

```sh-session
$ cloc --exclude-dir=dein vim
     146 text files.
     141 unique files.
      57 files ignored.

github.com/AlDanial/cloc v 1.84  T=0.05 s (1906.0 files/s, 119066.7 lines/s)
--------------------------------------------------------------------------------
Language                      files          blank        comment           code
--------------------------------------------------------------------------------
vim script                       66            764            671           3382
JSON                              1              8              0            257
Python                            2             36              2            192
TOML                              2             44             17            152
Ruby                              8             17              0            113
C                                 2             14              6             59
Go                                2             11              0             29
C/C++ Header                      1              3              0             12
HTML                              1              0              0             10
make                              1              4              0              9
GraphQL                           3              0              0              9
Java                              1              1              3              8
C++                               1              2              5              7
Markdown                          1              3              0              7
Bourne Again Shell                1              3              0              7
TypeScript                        1              1              0              4
--------------------------------------------------------------------------------
SUM:                             94            911            704           4257
--------------------------------------------------------------------------------
```

```sh-session
$ ag '^\[\[plugins' vim/dein.toml vim/dein_lazy.toml | wc -l
      46
```

</details>

<details><summary>Benchmark</summary>

```sh-session
$ repeat 5 time nvim -c quit
nvim -c quit  0.30s user 0.05s system 114% cpu 0.314 total
nvim -c quit  0.29s user 0.05s system 114% cpu 0.297 total
nvim -c quit  0.29s user 0.05s system 114% cpu 0.299 total
nvim -c quit  0.30s user 0.05s system 115% cpu 0.311 total
nvim -c quit  0.29s user 0.05s system 114% cpu 0.299 total
```

</details>

Author
------

Yuki Iwanaga ([@creasty](https://github.com/creasty))
