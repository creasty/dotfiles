![creasty's dotfiles](./docs/visual.jpg)

dotfiles
========

![last build on 2017-01 with 10.11](https://img.shields.io/badge/build-2017--01--02%20with%2010.11-green.svg) ![OS X 10.9+](https://img.shields.io/badge/platform-osx%2010.9%2B-blue.svg) [![MIT License](http://img.shields.io/badge/license-MIT-blue.svg?style=flat)](./LICENSE.txt)

A powerful development environment for full-stack engineers.  
Work it harder, make it better, do it faster, makes us stronger.

<pre><code>$ bash <(curl -L <a href="http://dotfiles.creasty.com/up">dotfiles.creasty.com/up</a>)</code></pre>


What's included
---------------

Automated provisioning by [ansible](https://www.ansible.com/).

<pre><code>$ ls <a href="https://github.com/creasty/dotfiles/tree/master/provisioning/roles">./provisioning/roles</a></code></pre>

- anyenv
- automator
- elixir
- envchain
- erlang
- gcp
- golang
- haskell
- homebrew
- java
- karabiner
- launchagent
- link
- lua
- mas
- nodejs
- osx
- python
- redis
- rlang
- ruby
- scala
- ssh
- tex
- vagrant
- vim
- zsh


Manual
------

1. Prepare credentials (TBA)
2. Run bootstrap script (TBA)
3. [Customize "System Preference"](./docs/system_preference.md)


Testing
-------

By using [boxcutter/macos](https://github.com/boxcutter/macos) and vagrant, you can test the provisioning on a clean environment.  
Read the [document](./provisioning/test) for details.


Author
------

<table>
  <tr align="center">
    <td>
      <img src="https://avatars2.githubusercontent.com/u/1695538?v=3&s=100" alt="">
    </td>
  </tr>
  <tr align="center">
    <td>Yuki Iwanaga<br><a href="https://github.com/creasty">@creasty</a></td>
  </tr>
</table>
