![creasty's dotfiles](./docs/visual.jpg)

dotfiles ![OS X 10.9+](https://img.shields.io/badge/platform-OSX%2010.9%2B-lightgray.svg) [![License](https://img.shields.io/github/license/creasty/dotfiles.svg)](./LICENSE.txt)
========

A powerful development environment for full-stack engineers.  
Work it harder, make it better, do it faster, makes us stronger.

<pre><code>$ bash <(curl -L <a href="http://dotfiles.creasty.com/up">dotfiles.creasty.com/up</a>)</code></pre>

Read the [detailed manual](./docs/README.md) for setting up a new computer.


What's included
---------------

Automated provisioning by ansible.

<pre><code>$ ls <a href="https://github.com/creasty/dotfiles/tree/master/provisioning/roles">./provisioning/roles</a>
anyenv      erlang      haskell     karabiner   lua         osx         rlang       ssh         vim
automator   gcp         homebrew    launchagent mas         python      ruby        tex         zsh
elixir      golang      java        link        nodejs      redis       scala       vagrant
</code></pre>


Testing
-------

By using [boxcutter/macos](https://github.com/boxcutter/macos) and vagrant, you can test the provisioning on a clean environment.  
Read the [document](./provisioning/test) for details.


Screenshots
-----------

**Tmux + ZSH**

![](./docs/images/screenshots/tmux.png)

**Vim**

![](./docs/images/screenshots/vim.png)


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
