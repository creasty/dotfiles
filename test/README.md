test
====

Building virtualbox image
-------------------------

1\. Get an installer from Mac App Store.

2\. Extract a dmg from the app.

```hcl
$ sudo prepare_iso/prepare_iso.sh /Applications/Install\ OS\ X\ El\ Capitan.app $PWD/dmg
# ...
Elapsed Time:  1m 30.323s
File size: 6698565141 bytes, Checksum: CRC32 $0CA4CA80
Sectors processed: 20971520, 15405945 compressed
Speed: 83.3Mbytes/sec
Savings: 37.6%
created: /Users/ykiwng/go/src/github.com/boxcutter/osx/dmg/OSX_InstallESD_10.11.2_15C50.dmg
-- Fixing permissions..
-- Checksumming output image..
-- MD5: 3fb5983df528ab075f08d4d63a9bae1d
-- Done. Built image is located at dmg/OSX_InstallESD_10.11.2_15C50.dmg. Add this iso and its checksum to your template.
```

3\. Delete the app as it's no longer needed.

```hcl
$ sudo rm /Applications/Install\ OS\ X\ El\ Capitan.app
```

4\. Build a virtualbox image.

```hcl
$ PACKER_LOG=1 packer build \
  -only virtualbox-iso \
  -var-file=macos/macos1011.json \
  -var iso_checksum=3fb5983df528ab075f08d4d63a9bae1d \
  -var iso_url=$PWD/dmg/OSX_InstallESD_10.11.2_15C50.dmg \
  macos/macos.json
# ...
==> Builds finished. The artifacts of successful builds are:
--> virtualbox-iso: 'virtualbox' provider box: box/virtualbox/macos1011-nocm-0.1.0.box
```


Test provisioning on vagrant
----------------------------

1\. Turn on sandbox mode.

```hcl
$ vagrant sandbox on
```

2\. Start vagrant.

```hcl
$ vagrant up
```

3\. Run the bootstrap script over ssh.

```hcl
$ vagrant ssh
Last login: Sun Jan  1 18:07:50 2017 from 10.0.2.2
osx-10_11:~ vagrant$ bash <(curl -L dotfiles.creasty.com/up)
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100    95  100    95    0     0     92      0  0:00:01  0:00:01 --:--:--    92
100  4855  100  4855    0     0   2108      0  0:00:02  0:00:02 --:--:--  4300
--------------------------------------------------------------------------------

                 888          888     .d888 d8b 888
                 888          888    d88P"  Y8P 888
                 888          888    888        888
             .d88888  .d88b.  888888 888888 888 888  .d88b.  .d8888b
            d88" 888 d88""88b 888    888    888 888 d8P  Y8b 88K
            888  888 888  888 888    888    888 888 88888888 "Y8888b.
            Y88b 888 Y88..88P Y88b.  888    888 888 Y8b.          X88
             "Y88888  "Y88P"   "Y888 888    888 888  "Y8888   88888P"

                       Harder, Better, Faster, Stronger

                         github.com/creasty/dotfiles

--------------------------------------------------------------------------------

Cloning repo...
Cloning into '/Users/vagrant/dotfiles'...
```

4\. Clean up.

```hcl
$ vagrant sandbox rollback

# or

$ vagrant halt
$ vagrant sandbox off
```
