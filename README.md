# Cubix

Cubix is a unix-like ComputerCraft OS

## Installation in ComputerCraft machines

Cubix works in normal and advanced computers.

```lua
> pastebin run B1t3L4Uw

loadenv cubixli
deldisk hdd
yapstrap cubix
setlabel <computer label>
sethostname <computer hostname>
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
 * Package management(yapi, WIP)

