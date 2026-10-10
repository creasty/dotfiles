# Hammerspoon

[creasty/Keyboard](https://github.com/creasty/Keyboard)'s key bindings on [Hammerspoon](https://www.hammerspoon.org): `init.lua` hands each key to the super keys (`superkey.lua`), then to the guard on <kbd>Cmd-Q</kbd> (`quit.lua`) and Emacs mode (`emacs.lua`).
Its mouse keys are left out, and so are two of its keys:

- <kbd>Ctrl-;</kbd>: macOS's own shortcut selects the next input source on it (System Settings > Keyboard > Keyboard Shortcuts > Input Sources), which `nix/modules/macos.nix` sets.
- Switching to English (EISUU) on <kbd>Escape</kbd> and <kbd>Ctrl-C</kbd>: Neovim switches to macOS's keyboard layout itself whenever it's in Normal mode (`nvim/lua/user/input_source.lua`).

`nix/modules/hammerspoon.nix` installs Hammerspoon, and links this directory as `~/.hammerspoon`.
Open Hammerspoon, allow it in System Settings > Privacy & Security > Accessibility, and reload its config (its menu bar icon > Reload Config).
It starts at login from then on.

<kbd>S+H</kbd> and <kbd>S+L</kbd> stroke Mission Control's shortcuts, as macOS has no public API to move a space.
The module also sets them in System Settings > Keyboard > Keyboard Shortcuts:

- Mission Control > Move left a space: <kbd>Ctrl-LeftArrow</kbd> (the default)
- Mission Control > Move right a space: <kbd>Ctrl-RightArrow</kbd> (the default)

## Key bindings

`+` denotes a key sequence in the 'super key' mode, which pressing and holding the first key with no modifier keys activates.
The key still types when tapped, and typing that rolls over it types in order.

### Window/space navigation

| Key | Description |
|:---|:---|
| <kbd>S+H</kbd> | Move to left space |
| <kbd>S+L</kbd> | Move to right space |
| <kbd>S+J</kbd> | Switch to next application |
| <kbd>S+K</kbd> | Switch to previous application |
| <kbd>S+N</kbd> | Switch to next window |
| <kbd>S+B</kbd> | Switch to previous window |
| <kbd>S+M</kbd> | Mission Control |

The application switcher stays open while <kbd>S</kbd> is held, as it does while <kbd>Cmd</kbd> is: <kbd>J</kbd> and <kbd>K</kbd> go through the applications, and releasing <kbd>S</kbd> switches.
<kbd>S+N</kbd> and <kbd>S+B</kbd> go around the app's windows on the current space in the order they opened, skipping minimized windows and panels.

### Window resizing/positioning

| Key | Description |
|:---|:---|
| <kbd>S+D+F</kbd> | Full screen |
| <kbd>S+D+H</kbd> | Left half |
| <kbd>S+D+J</kbd> | Bottom half |
| <kbd>S+D+K</kbd> | Top half |
| <kbd>S+D+L</kbd> | Right half |

### Emacs mode

| Key | Description | Shift allowed |
|:---|:---|:---|
| <kbd>Ctrl-C</kbd> | Escape | NO |
| <kbd>Ctrl-D</kbd> | Forward delete | NO |
| <kbd>Ctrl-H</kbd> | Backspace | NO |
| <kbd>Ctrl-J</kbd> | Enter | NO |
| <kbd>Ctrl-P</kbd> | :arrow_up: | YES |
| <kbd>Ctrl-N</kbd> | :arrow_down: | YES |
| <kbd>Ctrl-B</kbd> | :arrow_left: | YES |
| <kbd>Ctrl-F</kbd> | :arrow_right: | YES |
| <kbd>Ctrl-A</kbd> | Beginning of line | YES |
| <kbd>Ctrl-E</kbd> | End of line | YES |

Terminals, Vim, Emacs, Eclipse, VS Code, virtual machines, remote desktops and X11 keep their own <kbd>Ctrl</kbd> keys (`emacs.lua` lists the apps).
<kbd>Ctrl-C</kbd> stays <kbd>Ctrl-C</kbd> only in terminals and Neovim's GUIs.

### Word motions

| Key | Description |
|:---|:---|
| <kbd>A+D</kbd> | Delete word after cursor |
| <kbd>A+H</kbd> | Delete word before cursor |
| <kbd>A+B</kbd> | Move cursor backward by word |
| <kbd>A+F</kbd> | Move cursor forward by word |

### Switch between apps

<kbd>;+</kbd> brings the app to the front, launching it if needed, or hides it when it's there already.
Brought back from hiding, it shows the window it had in front, after a move to another space too.
kitty takes the windows it opens off every space, whatever Dock > Options > Assign To says: <kbd>;+M</kbd> first brings those on other spaces to the current one, through kitty's remote control (`config/kitty/kitty.conf`).
<kbd>;+1</kbd> shows 1Password's Quick Access, or hides it when it has the focus, by clicking 1Password's menu bar icon, whose action 1Password's Settings > General sets to Show Quick Access.
Without the icon, it starts 1Password's executable with `--quick-access`, which takes about 190 ms more; it launches 1Password when it isn't running.

| Key | App | Bundle ID |
|:---|:---|:---|
| <kbd>;+F</kbd> | Finder | `com.apple.finder` |
| <kbd>;+M</kbd> | kitty | `net.kovidgoyal.kitty` |
| <kbd>;+T</kbd> | Toggl Track | `com.toggl.daneel` |
| <kbd>;+N</kbd> | Bear | `net.shinyfrog.bear` |
| <kbd>;+1</kbd> | 1Password's Quick Access | `com.1password.1password` |

### Quit application

An app quits on a second <kbd>Cmd-Q</kbd>, not on one pressed by mistake.

| Key | Description |
|:---|:---|
| <kbd>Cmd-Q</kbd> | Nothing |
| <kbd>Cmd-Q, Cmd-Q</kbd> | Quits the app, the second within 300 ms of the first |

Held down, <kbd>Cmd-Q</kbd> doesn't repeat: its repeats would quit the app that comes to the front next.
Chrome guards <kbd>Cmd-Q</kbd> itself (Chrome > Warn Before Quitting, on by default), so it gets it as it is: it quits on <kbd>Cmd-Q</kbd> held for half a second, or pressed again within a second.

## Super keys

A super key waits to see what it's for (`superkey.lua`), with Keyboard's timings:

- Pressed and released on its own, it types on its release. Held on its own, it doesn't repeat.
- A key pressed within 50 ms of it is typing: both type.
- Otherwise the keys held with it make a chord, which acts once the super key has stayed down for 150 ms after its last key; the chords after it act at once, and so do their keys' repeats (<kbd>A+B</kbd> held moves word by word).
- Released before that, it types, and so do the keys pressed with it, in order: `sdk` typed fast is text, not <kbd>S+D+K</kbd>.
- A key pressed with <kbd>Cmd</kbd>, <kbd>Option</kbd>, <kbd>Ctrl</kbd> or <kbd>Shift</kbd> ends it, typing what it held back first.
- The apps get neither the super key nor the keys a chord took, their releases and repeats included.

## Tests

`tests/` specs what reaches the apps as keys are typed, on a fake of Hammerspoon's API that routes the events through the config's event tap as macOS does.
They need Lua 5.4, Hammerspoon's, and CI runs them (the `hammerspoon` job of `.github/workflows/tests.yml`).

```sh-session
$ nix shell --inputs-from . nixpkgs#lua5_4 --command hammerspoon/tests/run
$ hammerspoon/tests/run 'Ctrl%-C'   # tests whose name matches a Lua pattern
```
