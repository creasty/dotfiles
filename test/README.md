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


