![dotfiles -- Work it harder, make it better, do it faster, makes us stronger](./readme/dotfiles.png)


dotfiles
========

Installation
------------

```sh
$ bash <(curl -L dotfiles.creasty.com/bootstrap)
```

or to update already bootstrapped computer:

```sh
$ ./bootstrap
```


Applications via AppStore
-------------------------

- 1Password
- Airmail
- ColorChooser
- Dash
- Equation Maker
- Evernote
- ForkLift
- Growl
- Keynote
- Notefile
- Numbers
- Pages
- Paw
- Pocket
- Slack
- SnapRuler
- Texpad
- The Unarchiver
- Wunderlist
- iPhoto


Extra configurations
--------------------

### Security key settings

1. Create `_zsh/secrets.zsh`.
2. Configure aws cli by run: `$ aws configure`

### System Preference.app

#### Keyboard

1. Change modifier keys (press `Modifier Keys...` button in `Keyboard` tab)  
  ![](./readme/syspref/keyboard/modifiers.png)
2. Set key for moving focus to next window (in `Keyboard` section of `Shortcuts` tab)  
  ![](./readme/syspref/keyboard/next_window.png)
3. Enable full keyboard access (in `Shortcuts` tab)  
  ![](./readme/syspref/keyboard/access.png)

#### Trackpad

![](./readme/syspref/trackpad/point_click.png)
![](./readme/syspref/trackpad/scroll_zoom.png)
![](./readme/syspref/trackpad/more_gestures.png)

### Karabiner.app

1. Enable these options (in `Change Key` tab)  
  ![](./readme/karabiner/change_key.png)
2. Set these values (in `Key Repeate` tab)  
  ![](./readme/karabiner/key_repeat.png)
3. Turn off status message (in `Status Message` tab)  
  ![](./readme/karabiner/status_message.png)
4. Hide icon in the menu bar (in `MenuBar` tab)  
  ![](./readme/karabiner/icon.png)

### Seil.app

Change `Control_L` to `Escape` in `Other keys` section of `Setting` tab.  
![](./readme/seil/control_l.png)


Author
------

Yuki Iwanaga [@creasty](https://github.com/creasty)
