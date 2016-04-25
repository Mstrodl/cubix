#!/usr/bin/env lua

--libev: library for event handling

local libev = {}

libev.queue = os.queueEvent
libev.getev = os.pullEvent

_G['libev'] = libev
