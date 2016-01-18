# Cubix

Cubix is a unix-like ComputerCraft OS

## Demos

[Cubix demo(0.5.1)](https://www.youtube.com/watch?v=SZ-8C3hH3F4)

[Cubix Installation(0.5.1)](https://www.youtube.com/watch?v=sxkpyHpaJRY)

## Installation in ComputerCraft machines

Cubix works in normal(in theory, not tested) and advanced computers.

```lua
> pastebin run B1t3L4Uw

loadenv cubixli
deldisk hdd
yapstrap cubix
genfstab /etc/fstab
setlabel <computer label>
sethostname <computer hostname>
timesetup <server 1> <server 2> ...
sbl-bcfg
unloadenv
reboot
```

## Features

 * Basic coreutils programs(cat, cksum, factor...)
 * Cubix shell(with piping)
 * init and runlevels
   * Graphical manager(luaX, WIP)
 * Own bootloader(SBL)
 * MIT License
 * Manual pages
 * Package management(yapi)
