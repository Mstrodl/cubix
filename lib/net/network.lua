#!/usr/bin/env lua
--network library for cubix

RELOADABLE = false

local INTERFACES = {}
local R_ENTRIES = {}
local LOCAL_IP = ''

local buffer = ''

function create_interface(name, type)
    --local device = get_interf(type)
    local device = {nil}
    INTERFACES[name] = device
end

function set_local(ip)
    LOCAL_IP = ip
end

function new_resolve_entry(name, ip)
    R_ENTRIES[name] = ip
end

function new_package(type_package, dest, data)
    return nil
end

function libroutine()
    create_interface("lo", "loopback")
    create_interface("eth0", "cable")
    create_interface("wlan0", "wireless")
    set_local("127.0.0.1")
    new_resolve_entry("localhost", '127.0.0.1')
    sleep(0.5)
    --test if local routing is working with ping
    --local pkg = new_package(PKG_ICMP, '127.0.0.1', nil)
    --send_package(pkg)
    --local data = read_data(1024)
    --local processed_data = parse_data(data, PKG_ICMP_RESPONSE)
    --print('ping to localhost: '..get_fpkg(processed_data, 'ping_value_ms'))
end
