#!/usr/bin/env lua
--multiuser library

--[[

TODO: framebuffers
TODO: some sort to lock a process to a tty
TODO: switch of ttys

The task of multiuser is to load /bin/login into all ttys
so you can have multiple users in the same computer logged at the same time!

]]

RELOADABLE = false

function create_framebuffer()
    --create some form of multitasking between ttys(allowing read() calls to be made)
    --i'm thinking this needs to be in tty manager
end

function create_switch()
    --create interface to switch between ttys
    --theory:
    --create a routing waiting for ctrl calls
    --see if ctrl+n is pressed
end

function run_all_ttys()
    create_framebuffer()
    create_switch()
    for k,v in pairs(os.lib.tty.get_ttys()) do
        --every active tty running login
        v:run_process("/sbin/login")
    end
end

function libroutine()
    run_all_ttys()
end
