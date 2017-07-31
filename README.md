# Cubix

[![Gitter](https://badges.gitter.im/lkmnds/cubix.svg)](https://gitter.im/lkmnds/cubix?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)

Cubix is a unix-like ComputerCraft OS, made to be extremely flexible.

## Demos

[Cubix Demo (0.5.1)](https://www.youtube.com/watch?v=SZ-8C3hH3F4)

[Cubix Installation (0.5.1)](https://www.youtube.com/watch?v=sxkpyHpaJRY)

## Features

* Basic coreutils programs(cat, cksum, factor...)
* Own shell with bash-like syntax
* init and runlevels
* Custom bootloader (SBL)
* Licensed under MIT
* Manual pages
* Package manager (YAPI)

### Notes

The `master` branch contains the latest state of cubix, howerver it shouldn't be used in any production enviroment. Use the `stable` branch for that.

## Installation in ComputerCraft machines

Cubix works in normal (in theory, not tested) and advanced computers.
You **need** to know how to manage a system with lots of code. Anything could happen, all code is unstable and can change at any point.

### Installing using cubixLI

**CUBIXLI DOES NOT WORK ON THE `rewrite` BRANCH**

cubixli (cubix's live installer) will download the latest package file of the system on the servers
and will download it, this version is suitable for users that don't want to code on it.

(If you don't want to set any timezone, don't run the "tzselect" command, cubix will set the default timezone as GMT+0.)

```lua
> pastebin run B1t3L4Uw

mkfs.cbx
smallyapi base
genfstab /etc/fstab

tzselect <timezone1>,<timezone2>
timesetup -auto
mkinitramfs cubixbase
sbl-config new
sethostname <hostname>
reboot
```

### Git Installation (suitable for developers)

Since most of Cubix codebase is on ComputerCraft Lua, you need or a ComputerCraft accesible directory, or an emulator (I use ccemuredux.)

##### ccemuredux instructions

You can clone the repository(the folder needs to have a valid computercraft ID) and link that to a computer ID in ccemuredux directory

```bash
# computer_id = 0, 1, 2, etc. make sure you use the computer_id you used here
git clone https://github.com/lkmnds/cubix.git computer_id
ln -s computer_id $HOME/.ccemuredux/sessions/your_session/computer/ # something like that
```

After linking the folder to your computer folder, boot it up and you should be presented with the *Simple Boot Loader* (SBL). Load CraftOS (we need to load empty folders) and type `/dev/MAKEDEV` and hit enter. Then `reboot` and you can load Cubix without any other adjustments.
