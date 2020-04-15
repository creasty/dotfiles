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

`zsh` starts up in ~370ms.

```sh-session
$ for i in $(seq 1 5); do time zsh -i -c exit; done
zsh -i -c exit  0.18s user 0.18s system 97% cpu 0.363 total
zsh -i -c exit  0.18s user 0.19s system 97% cpu 0.377 total
zsh -i -c exit  0.18s user 0.19s system 98% cpu 0.378 total
zsh -i -c exit  0.18s user 0.18s system 98% cpu 0.374 total
zsh -i -c exit  0.18s user 0.18s system 98% cpu 0.371 total
```

`vim` starts up in ~160ms.

```sh-session
$ for i in $(seq 1 5); do time vim -c quit; done
vim -c quit  0.13s user 0.05s system 114% cpu 0.158 total
vim -c quit  0.13s user 0.06s system 114% cpu 0.168 total
vim -c quit  0.13s user 0.05s system 115% cpu 0.154 total
vim -c quit  0.13s user 0.05s system 115% cpu 0.154 total
vim -c quit  0.13s user 0.05s system 115% cpu 0.154 total
```

Author
------

Yuki Iwanaga (@creasty)
