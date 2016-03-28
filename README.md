# Cubix

Cubix is a unix-like ComputerCraft OS

## Demos

[Cubix demo(0.5.1)](https://www.youtube.com/watch?v=SZ-8C3hH3F4)

[Cubix Installation(0.5.1)](https://www.youtube.com/watch?v=sxkpyHpaJRY)

## Installation in ComputerCraft machines

Cubix works in normal(in theory, not tested) and advanced computers.

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

## Information for Developers

Since most of Cubix codebase is on ComputerCraft, you need or a ComputerCraft accesible directory or a emulator(I use ccemuredux.)

#### ccemuredux instructions
You can clone the repository(the folder needs to have a valid computercraft id) and link that to a computer id in ccemuredux directory
```
git clone https://github.com/lkmnds/cubix.git
ln -s <path_to_repo> .ccemuredux/sessions/<session>/computer/
```

## Features

 * Basic coreutils programs(cat, cksum, factor...)
 * Cubix shell(cshell)(piping is in WIP)
 * init and runlevels
   * Graphical manager(luaX, WIP)
 * Own bootloader(SBL)
 * MIT License
 * Manual pages
 * Package management(yapi)
