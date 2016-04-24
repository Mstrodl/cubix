#!/usr/bin/env lua

--libev: library foe event handling

local libev = {}

libev.queue = os.queueEvent
libev.getev = os.pullEvent

_G['libev'] = libev
