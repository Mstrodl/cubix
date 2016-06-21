# Cubix

[![Gitter](https://badges.gitter.im/lkmnds/cubix.svg)](https://gitter.im/lkmnds/cubix?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)

Cubix is an unix-like ComputerCraft OS, made for people who want to hack it as long as you want it to.

## Demos

[Cubix demo(0.5.1)](https://www.youtube.com/watch?v=SZ-8C3hH3F4)

[Cubix Installation(0.5.1)](https://www.youtube.com/watch?v=sxkpyHpaJRY)

## Features
 * Basic coreutils programs(cat, cksum, factor...)
 * Own shell with bash-like syntax
 * init and runlevels
 * Own bootloader(SBL)
 * MIT Licensed
 * Manual pages
 * Package management(yapi)

## Installation in ComputerCraft machines

Cubix works in normal(in theory, not tested) and advanced computers.
You **need** to know how to manage a system with many code and anything could happen, all code is unstable and can change at any moment


### Installing using cubixLI

cubixli(cubix live installer) will download the latest package file of the system on the servers
and will download it, this version is suitable for users that don't want to code on it.

(if you don't want to set any timezone, don't run the "tzselect" command, cubix will set the default timezone as GMT+0)
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

### Installation using git (suitable for developers)

Since most of Cubix codebase is on ComputerCraft LUA, you need or a ComputerCraft accesible directory or a emulator(I use ccemuredux.)

##### ccemuredux instructions
You can clone the repository(the folder needs to have a valid computercraft id) and link that to a computer id in ccemuredux directory
```bash
git clone https://github.com/lkmnds/cubix.git computer_id
ln -s computer_id $HOME/.ccemuredux/sessions/your_session/computer/ # something like that
```
