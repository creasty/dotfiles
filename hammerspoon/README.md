# Hammerspoon

[creasty/Keyboard](https://github.com/creasty/Keyboard)'s key bindings on [Hammerspoon](https://www.hammerspoon.org), in place of the app: `keyboard.lua`, with the super keys in `superkey.lua`.
Its mouse keys and its guard on <kbd>Cmd-Q</kbd> are left out.

`nix/modules/hammerspoon.nix` installs Hammerspoon, and links this directory as `~/.hammerspoon`.
Open Hammerspoon, allow it in System Settings > Privacy & Security > Accessibility, and reload its config (its menu bar icon > Reload Config).
It starts at login from then on.

System Settings > Keyboard > Keyboard Shortcuts, as Keyboard needed them:

- Mission Control > Move left a space: <kbd>Ctrl-LeftArrow</kbd> (the default)
- Mission Control > Move right a space: <kbd>Ctrl-RightArrow</kbd> (the default)
- Keyboard > Move focus to next window: <kbd>Cmd-F1</kbd>

## Moving from Keyboard

Provisioning removes Keyboard from `~/Applications/Home Manager Apps`, but a running Keyboard keeps running: quit it (its menu bar icon K > Quit), remove it from System Settings > General > Login Items, and set up Hammerspoon as above.
A `~/.hammerspoon` that was there before is kept as `~/.hammerspoon.before-nix`.

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

Terminals, Vim, Emacs, Eclipse, virtual machines, remote desktops and X11 keep their own <kbd>Ctrl</kbd> keys, and VS Code its <kbd>Ctrl-D</kbd>, <kbd>Ctrl-H</kbd>, <kbd>Ctrl-A</kbd> and <kbd>Ctrl-E</kbd> (`keyboard.lua` lists the apps).
<kbd>Ctrl-C</kbd> stays <kbd>Ctrl-C</kbd> only in terminals and Neovim's GUIs.

### Word motions

| Key | Description |
|:---|:---|
| <kbd>A+D</kbd> | Delete word after cursor |
| <kbd>A+H</kbd> | Delete word before cursor |
| <kbd>A+B</kbd> | Move cursor backward by word |
| <kbd>A+F</kbd> | Move cursor forward by word |

### Switch input source

| Key | Description |
|:---|:---|
| <kbd>Ctrl-;</kbd> | Selects the next input source: the keyboard layouts, then the input methods |

### Switch input source with Escape key

Change the input source to English as you leave 'insert mode' in Vim with <kbd>Escape</kbd> key so it can prevent IME from capturing key strokes in 'normal mode'.

| Key | Description |
|:---|:---|
| <kbd>Ctrl-C</kbd> | Invokes <kbd>EISUU, Ctrl-C</kbd> in terminals and Neovim's GUIs, <kbd>EISUU, Escape</kbd> elsewhere |
| <kbd>Escape</kbd> | Invokes <kbd>EISUU, Escape</kbd> |

### Switch between apps

<kbd>;+</kbd> brings the app to the front, launching it if needed, or hides it when it's there already.

| Key | App | Bundle ID |
|:---|:---|:---|
| <kbd>;+F</kbd> | Finder | `com.apple.finder` |
| <kbd>;+M</kbd> | Ghostty | `com.mitchellh.ghostty` |
| <kbd>;+T</kbd> | Things | `com.culturedcode.ThingsMac` |
| <kbd>;+N</kbd> | Bear | `net.shinyfrog.bear` |

## Super keys

A super key waits to see what it's for (`superkey.lua`), with Keyboard's timings:

- Pressed and released on its own, it types on its release. Held on its own, it doesn't repeat.
- A key pressed within 50 ms of it is typing: both type.
- Otherwise the keys held with it make a chord, which acts once the super key has stayed down for 150 ms after its last key; the chords after it act at once, and so do their keys' repeats (<kbd>A+B</kbd> held moves word by word).
- Released before that, it types, and so do the keys pressed with it, in order: `sdk` typed fast is text, not <kbd>S+D+K</kbd>.
- A key pressed with <kbd>Cmd</kbd>, <kbd>Option</kbd>, <kbd>Ctrl</kbd> or <kbd>Shift</kbd> ends it, typing what it held back first.
- The apps get neither the super key nor the keys a chord took, their releases and repeats included.

Keyboard differed where this follows what it meant to do:

- With two keys or more typed past a super key before its release, it lost them all, the super key too.
  It lost a super key still held as a key with modifiers went down, too: typing `a` then <kbd>Cmd-V</kbd> fast pasted without the `a`.
- It acted on a second key at once, even typed fast: `sdk` moved the window.
- Once the super key was up, it let the keys a chord took through: their release, and their repeats while still held.
- It sized windows to the whole screen, menu bar and Dock included, rather than to the part windows get.
- <kbd>Ctrl-;</kbd> followed the input menu's order, which Hammerspoon doesn't tell, and passed its repeats on to the app.
- It opened Mission Control.app for <kbd>S+M</kbd>, and used [Witch](https://manytricks.com/witch/)'s shortcuts for <kbd>S+J</kbd>, <kbd>S+K</kbd>, <kbd>S+N</kbd> and <kbd>S+B</kbd> when Witch was installed.

## Tests

`tests/` specs what reaches the apps as keys are typed, on a fake of Hammerspoon's API that routes the events through the config's event tap as macOS does.
They need Lua 5.4, Hammerspoon's, and CI runs them (the `hammerspoon` job of `.github/workflows/tests.yml`).

```sh-session
$ nix shell --inputs-from . nixpkgs#lua5_4 --command hammerspoon/tests/run
$ hammerspoon/tests/run 'Ctrl%-C'   # tests whose name matches a Lua pattern
```
