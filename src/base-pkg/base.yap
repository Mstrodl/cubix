Name;base
Version;0.5.1
Build;51
Author;Lukas Mendes
Email-Author;lkmnds@gmail.com
Description;Cubix base system
Url;http://github.com/lkmnds/cubix
License;MIT
Folder;mnt
Folder;mnt/tmpfs
Folder;etc
Folder;etc/scripts
Folder;etc/init.d
Folder;etc/rc2.d
Folder;etc/rc1.d
Folder;etc/rc5.d
Folder;etc/rc3.d
Folder;etc/rc6.d
Folder;etc/rc0.d
Folder;root
Folder;sbin
Folder;home
Folder;home/cubix
Folder;usr
Folder;usr/sbin
Folder;usr/games
Folder;usr/manuals
Folder;usr/manuals/kernel
Folder;usr/bin
Folder;usr/lib
Folder;media
Folder;proc
Folder;proc/2
Folder;proc/1
Folder;proc/3
Folder;proc/70
Folder;proc/76
Folder;tmp
Folder;dev
Folder;dev/disk
Folder;dev/shm
Folder;dev/hda
Folder;bin
Folder;src
Folder;src/base-pkg
Folder;var
Folder;var/yapi
Folder;var/yapi/cache
Folder;var/yapi/db
Folder;boot
Folder;boot/sblcfg
Folder;g
Folder;g/lxterm
Folder;lib
Folder;lib/fs
Folder;lib/luaX
Folder;lib/hash
Folder;lib/multiuser
Folder;lib/net
Folder;lib/devices
Folder;lib/modules
File;lib/devices/urandom_device.lua
function rawread()
    while true do
        local sEvent, param = os.pullEvent("key")
        if sEvent == "key" then
            if param == 28 then
                break
            end
        end
    end
end
local RANDOM_BLOCKS = 256
local function getRandomString()
    local cache = ''
    for i=0, RANDOM_BLOCKS do
        cache = cache .. string.char(math.random(0, 255))
    end
    return cache
end
function print_rndchar()
    local newseed = ''
    while true do
        newseed = getRandomString()
        math.randomseed(newseed)
        io.write(os.safestr(s))
    end
end
dev_urandom = {}
dev_urandom.device = {}
dev_urandom.name = '/dev/urandom'
dev_urandom.device.device_write = function (message)
    print("cannot write to /dev/urandom")
end
dev_urandom.device.device_read = function (bytes)
    local crand = {}
    local cache = tostring(os.clock())
    local seed = 0
    for i=1,#cache do
        seed = seed + string.byte(string.sub(cache,i,i))
    end
    math.randomseed(tostring(seed))
    if bytes == nil then
        crand = coroutine.create(print_rndchar)
        coroutine.resume(crand)
        while true do
            local event, key = os.pullEvent( "key" )
            if event and key then
                break
            end
        end
    else
        result = ''
        for i = 0, bytes do
            s = string.char(math.random(0, 255))
            result = result .. os.safestr(s)
        end
        return result
    end
    return 0
end
return dev_random
EndFile;
File;bin/su
#!/usr/bin/env lua
--/bin/su: logins to root
function main(args)
    os.runfile_proc("/sbin/login", {"root"})
end
main({...})
EndFile;
File;bin/lsmod
#!/usr/bin/env lua
--/bin/lsmod: list loaded modules in cubix
_handler = {}
_handler.signal_handler = function(sig)
    if sig == 'kill' then
        return 0
    end
end
function main(args)
    term.set_term_color(colors.green)
    os.viewLoadedMods()
    term.set_term_color(colors.white)
end
main({...})
EndFile;
File;src/base-pkg/pkgdata
# Base pkgdata for cubix
# As of actual packages, base is just a package with a special rule
# Because it can't get all files manually, Just made a rule that gets
# All files and folders in the given path, btw in base the path is /
# So it gets all items in / and put them in base.yap, simple.
pkgname;base
pkgver;0.5.1
pkgbuild;51
author;Lukas Mendes
eauthor;lkmnds@gmail.com
desc;Cubix base system
url;http://github.com/lkmnds/cubix
license;MIT
all;/
EndFile;
File;bin/man
#!/usr/bin/env lua
--/bin/man: program to open manual pages
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        --print("man: SIGKILL'd!")
        return 0
    end
end
MANPATH = "/usr/manuals"
function parse_cmfl(path)
    local h = fs.open(path, 'r')
    if h == nil then
        os.ferror("parse_cmfl: file not found")
        return 1
    end
    local file = h.readAll()
    h.close()
    local lines = os.strsplit(file, '\n')
    local new_lines = {}
    for k,v in ipairs(lines) do
        if v == '.name' then
            new_lines[#new_lines+1] = lines[k+1]..'\n'
        elseif v == '.cmd' then
            new_lines[#new_lines+1] = "Usage:"
            new_lines[#new_lines+1] = '\t'..lines[k+1]..'\n'
        elseif v == '.desc' then
            new_lines[#new_lines+1] = "Description:"
            new_lines[#new_lines+1] = '\t'..lines[k+1]..'\n'
        elseif os.strsplit(v, ' ')[1] == '.listop' then
            new_lines[#new_lines+1] = "Option "..os.strsplit(v, ' ')[2]
            local i = 1
            while lines[k+i] ~= '.e' do
                new_lines[#new_lines+1] = lines[k+i]
                i = i + 1
            end
        elseif v == '.m' then
            new_lines[#new_lines+1] = '\n'
            new_lines[#new_lines+1] = lines[k+1]
            local i = 2
            while lines[k+i] ~= '.e' do
                new_lines[#new_lines+1] = lines[k+i]
                i = i + 1
            end
        end
    end
    local w,h = term.getSize()
    local nLines = 0
    for k,v in ipairs(new_lines) do
        nLines = nLines + textutils.pagedPrint(v, (h-3) - nLines)
    end
end
function main(args)
    local topic, page = {0,0}
    if #args == 1 then
        topic = args[1]
    elseif #args == 2 then
        topic, page = args[1], args[2]
    else
        print("man: what manual do you want?")
        return 0
    end
    local file = {}
    local p = ''
    if topic == 'manuals' then
        pages = fs.list(MANPATH)
        for k,v in pairs(pages) do
            if not fs.isDir(fs.combine(MANPATH, v)) then
                pages[k] = string.sub(v, 0, #v - 4)
            end
        end
        textutils.tabulate(pages)
        return 0
    end
    if page == nil then
        --work for getting <topic>.man
        p = topic..".man"
        file = io.open(fs.combine(MANPATH, p))
    else
        --get <topic>/<page>.man
        p = topic..'/'..page..'.man'
        file = io.open(fs.combine(MANPATH, p))
    end
    local w,h = term.getSize()
    if file then
        --actual reading of the file
        term.clear()
        term.setCursorPos(1,1)
        os.central_print(p)
        local sLine = file:read()
        if sLine == '!cmfl!' then --Cubix Manuals Formatting Language
            os.debug.debug_write("[man] cmfl file!", false)
            file:close()
            parse_cmfl(fs.combine(MANPATH, p))
        else
            local nLines = 0
            while sLine do
                nLines = nLines + textutils.pagedPrint(sLine, (h-3) - nLines)
                sLine = file:read()
            end
    	    file:close()
        end
    elseif fs.isDir(fs.combine(MANPATH, topic)) then
        --print available pages in topic
        print('Pages in the topic "'..topic..'":\n')
        pages = fs.list(fs.combine(MANPATH, topic))
        for k,v in pairs(pages) do
            write(string.sub(v, 0, #v - 4) .. " ")
        end
        write('\n')
    else
        print("No manual available")
    end
    return 0
end
main({...})
EndFile;
File;bin/sync
#!/usr/bin/env lua
--/bin/sync: synchronize filesystems
_handler = {}
_handler.signal_handler = function(sig)
    if sig == 'kill' then
        --print("sync: SIGKILL")
        return 0
    end
end
function main()
    fsmanager.sync()
end
main({...})
EndFile;
File;bin/cshell_rewrite
#!/usr/bin/env lua
--/bin/cshell_rewrite: rewrite of cubix shell
local shellToken = {}
--local shell_wd = os.lib.control.get('/sbin/login', 'cwd')
local shell_wd = nil
--getting shell process
local itself = os.lib.proc.get_processes()[os.getrunning()]
local itself_pid = os.lib.proc.get_by_pid(3)
if not os.cshell then
    os.cshell = {}
end
os.cshell.PATH = '/bin:/usr/bin'
local last_command = ''
function register_lcmd(c)
    os.lib.control.register_proof(itself_pid, 'last_cmd', c)
end
local function normal_command(cmd)
    --normal routine to run commands
    local tokens = os.strsplit(cmd, ' ')
    local args = os.tail(tokens)
    if args == nil then args = {} end
    local program = tokens[1]
    --built-in "programs"
    --echo, APATH, PPATH, getuid, getperm, alias, aliases
    if program == 'echo' then
        local message = os.strsplit(cmd, ';')[2]
        print(message)
        return 0
    elseif program == 'APATH' then
    elseif program == 'PPATH' then
        print(os.cshell.PATH)
        return 0
    elseif program == 'getuid' then
        print(os.lib.login.userUID())
        return 0
    elseif program == 'getperm' then
        permission.getPerm()
        return 0
    elseif program == 'CTTY' then
        print(os.lib.tty.getcurrentTTY().id)
        return 0
    end
    found = false
    --part where we see paths and permissions to run and everything
    --TODO: permission checks
    --[[
    if fs.verifyPerm(program, os.currentUser(), 'x') then
        exec_prog = true
    end
    if not exec_proc then
        ferror("csh: unable to run")
    end
    ]]
    --check absolute paths
    if fs.exists(program) then
        --security check: check if program is in /sbin
        local tok = os.strsplit(program, '/')
        if tok[1] ~= '/sbin' then
            found = true
            os.runfile_proc(program, args, itself)
            register_lcmd(program .. ' ' .. table.concat(args, ' '))
        end
        --if its not, continue to other checks
        --(theorical) security check(still not implemented):
        --to make this possible, os.run needs to be reimplemented with permission checks to run a file
        -- if fs.checkPerm(program, 'r') then
        --     os.runfile_proc(program, args)
        -- end
    --check cwd .. program
    elseif not found and fs.exists(os.cshell.resolve(program)) then
        print(current_path)
        if shell_wd ~= '/sbin' or shell_wd ~= 'sbin' then
            found = true
            os.runfile_proc(os.cshell.resolve(program), args, itself)
            register_lcmd(os.cshell.resolve(program) .. ' ' .. table.concat(args, ' '))
        end
    end
    --check program in PATH
    local path = os.strsplit(os.cshell.PATH, ':')
    for _,token in ipairs(path) do
        local K = fs.combine(token..'/', program)
        if not found and fs.exists(K) then
            found = true
            os.runfile_proc(K, args, itself)
            register_lcmd(K .. ' ' .. table.concat(args, ' '))
        end
    end
    --check /sbin
    if not found and fs.exists(fs.combine("/sbin/", program)) then
        if os.lib.login.userUID == 0 then
            found = true
            os.runfile_proc(fs.combine("/sbin/", program), args, itself)
            register_lcmd(fs.combine("/sbin/", program) .. ' ' .. table.concat(args, ' '))
        end
    end
    --not found
    if not found then
        --register_lcmd(program .. ' ' .. table.concat(args, ' '))
        ferror("csh: "..program..": program not found")
    end
end
local function shcmd(cmd)
    --parse command
    --nothing
    if cmd == nil or cmd == '' then return 0 end
    --comments
    if string.sub(cmd, 1, 1) == '#' then return 0 end
    --parse multiple commands
    for _, command in pairs(os.strsplit(cmd, "&&")) do
        if command:find("|") then --piping
            local count = 1
            local programs = os.strsplit(command, "|")
            local main_pipe = os.lib.pipe.Pipe.new('main')
            for _, prog in pairs(programs) do
                --[[
                For each program, run it with pipe support
                ]]
            end
        else
            --if command does not have |, run program normally
            --now parse the command, with args and everything
            normal_command(command)
        end
    end
end
os.cshell.change_path = function(newpath)
end
os.cshell.resolve = function()
end
os.cshell.run = function(command)
    return shcmd(command)
end
os.cshell.cwd = function(newpwd)
    --only cd can use this
    local cdlock = os.lib.control.get('/bin/cd', 'cd_lock')
    if cdlock == '1' then
        shell_wd = newpwd
    else
        ferror("csh: cwd: cdlock ~= '1'")
    end
end
os.cshell.getwd = function()
    return shell_wd
end
os.cshell.getpwd = os.cshell.getwd
os.cshell.resolve = function(pth)
    local wd = os.cshell.getwd()
    function _combine(c) return wd .. '/' .. c end
    function check_slash(s) return string.sub(s, 1, 1) == '/' end
    if check_slash(pth) then
        return pth
    else
        return _combine(pth)
    end
end
os.cshell.complete = function(pth)
end
function main(args)
    os.shell = os.cshell
    --get first cwd
    shell_wd = os.lib.control.get('/sbin/login', 'cwd')
    --generate a new token.
    shellToken = os.lib.login.Token.new(os.lib.login.currentUser(), 100)
    local HISTORY = {} --csh history
    while true do --main loop
        if shellToken.user == 'root' then --always check if user is root
            shell_char = '#'
        else
            shell_char = '$'
        end
        write(shellToken.user)
        write("@"..gethostname())
        write(":"..shell_wd)
        write(shell_char..' ')
        local cmd = read(nil, HISTORY, os.cshell.complete)
        if cmd == 'exit' then --hardcoded command
            return 0
        elseif cmd ~= nil then
            if command ~= '' or not command:find(" ") then
                table.insert(HISTORY, cmd)
            end
            shcmd(cmd)
        end
    end
end
--running
main({...})
EndFile;
File;etc/initramfs.modules
#This is the file that generate-initramfs uses to genenerate a cubix-initramfs file
#libcubix entry
libcubix
#boot splash entry(disabled by default):
#bootsplash
EndFile;
File;proc/2/cmd
/sbin/login 
EndFile;
File;usr/manuals/pipe.man
On the Subject of Pipes
A pipe is a communication interface between programs(not as well as unix, as unix links stdout of one program to stdin of another), the symbol used to create pipes(in cshell) is "|", a simple example would be:
ps | glep login
as a result, ps will show the list of processes, but glep filters that output, showing only the lines that contain "login", a example result would be:
2 /sbin/init > /sbin/login
EndFile;
File;lib/hash/md5.lua
local md5 = {
  _VERSION     = "md5.lua 1.0.2",
  _DESCRIPTION = "MD5 computation in Lua (5.1-3, LuaJIT)",
  _URL         = "https://github.com/kikito/md5.lua",
  _LICENSE     = [[
    MIT LICENSE
    Copyright (c) 2013 Enrique García Cota + Adam Baldwin + hanzao + Equi 4 Software
    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:
    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
  ]]
}
-- bit lib implementions
local char, byte, format, rep, sub =
  string.char, string.byte, string.format, string.rep, string.sub
local bit_or, bit_and, bit_not, bit_xor, bit_rshift, bit_lshift
local ok, bit = pcall(require, 'bit')
if ok then
  bit_or, bit_and, bit_not, bit_xor, bit_rshift, bit_lshift = bit.bor, bit.band, bit.bnot, bit.bxor, bit.rshift, bit.lshift
else
  ok, bit = pcall(require, 'bit32')
  if ok then
    bit_not = bit.bnot
    local tobit = function(n)
      return n <= 0x7fffffff and n or -(bit_not(n) + 1)
    end
    local normalize = function(f)
      return function(a,b) return tobit(f(tobit(a), tobit(b))) end
    end
    bit_or, bit_and, bit_xor = normalize(bit.bor), normalize(bit.band), normalize(bit.bxor)
    bit_rshift, bit_lshift = normalize(bit.rshift), normalize(bit.lshift)
  else
    local function tbl2number(tbl)
      local result = 0
      local power = 1
      for i = 1, #tbl do
        result = result + tbl[i] * power
        power = power * 2
      end
      return result
    end
    local function expand(t1, t2)
      local big, small = t1, t2
      if(#big < #small) then
        big, small = small, big
      end
      -- expand small
      for i = #small + 1, #big do
        small[i] = 0
      end
    end
    local to_bits -- needs to be declared before bit_not
    bit_not = function(n)
      local tbl = to_bits(n)
      local size = math.max(#tbl, 32)
      for i = 1, size do
        if(tbl[i] == 1) then
          tbl[i] = 0
        else
          tbl[i] = 1
        end
      end
      return tbl2number(tbl)
    end
    -- defined as local above
    to_bits = function (n)
      if(n < 0) then
        -- negative
        return to_bits(bit_not(math.abs(n)) + 1)
      end
      -- to bits table
      local tbl = {}
      local cnt = 1
      local last
      while n > 0 do
        last      = n % 2
        tbl[cnt]  = last
        n         = (n-last)/2
        cnt       = cnt + 1
      end
      return tbl
    end
    bit_or = function(m, n)
      local tbl_m = to_bits(m)
      local tbl_n = to_bits(n)
      expand(tbl_m, tbl_n)
      local tbl = {}
      for i = 1, #tbl_m do
        if(tbl_m[i]== 0 and tbl_n[i] == 0) then
          tbl[i] = 0
        else
          tbl[i] = 1
        end
      end
      return tbl2number(tbl)
    end
    bit_and = function(m, n)
      local tbl_m = to_bits(m)
      local tbl_n = to_bits(n)
      expand(tbl_m, tbl_n)
      local tbl = {}
      for i = 1, #tbl_m do
        if(tbl_m[i]== 0 or tbl_n[i] == 0) then
          tbl[i] = 0
        else
          tbl[i] = 1
        end
      end
      return tbl2number(tbl)
    end
    bit_xor = function(m, n)
      local tbl_m = to_bits(m)
      local tbl_n = to_bits(n)
      expand(tbl_m, tbl_n)
      local tbl = {}
      for i = 1, #tbl_m do
        if(tbl_m[i] ~= tbl_n[i]) then
          tbl[i] = 1
        else
          tbl[i] = 0
        end
      end
      return tbl2number(tbl)
    end
    bit_rshift = function(n, bits)
      local high_bit = 0
      if(n < 0) then
        -- negative
        n = bit_not(math.abs(n)) + 1
        high_bit = 0x80000000
      end
      local floor = math.floor
      for i=1, bits do
        n = n/2
        n = bit_or(floor(n), high_bit)
      end
      return floor(n)
    end
    bit_lshift = function(n, bits)
      if(n < 0) then
        -- negative
        n = bit_not(math.abs(n)) + 1
      end
      for i=1, bits do
        n = n*2
      end
      return bit_and(n, 0xFFFFFFFF)
    end
  end
end
-- convert little-endian 32-bit int to a 4-char string
local function lei2str(i)
  local f=function (s) return char( bit_and( bit_rshift(i, s), 255)) end
  return f(0)..f(8)..f(16)..f(24)
end
-- convert raw string to big-endian int
local function str2bei(s)
  local v=0
  for i=1, #s do
    v = v * 256 + byte(s, i)
  end
  return v
end
-- convert raw string to little-endian int
local function str2lei(s)
  local v=0
  for i = #s,1,-1 do
    v = v*256 + byte(s, i)
  end
  return v
end
-- cut up a string in little-endian ints of given size
local function cut_le_str(s,...)
  local o, r = 1, {}
  local args = {...}
  for i=1, #args do
    table.insert(r, str2lei(sub(s, o, o + args[i] - 1)))
    o = o + args[i]
  end
  return r
end
local swap = function (w) return str2bei(lei2str(w)) end
local function hex2binaryaux(hexval)
  return char(tonumber(hexval, 16))
end
local function hex2binary(hex)
  local result, _ = hex:gsub('..', hex2binaryaux)
  return result
end
-- An MD5 mplementation in Lua, requires bitlib (hacked to use LuaBit from above, ugh)
-- 10/02/2001 jcw@equi4.com
local CONSTS = {
  0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee,
  0xf57c0faf, 0x4787c62a, 0xa8304613, 0xfd469501,
  0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be,
  0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821,
  0xf61e2562, 0xc040b340, 0x265e5a51, 0xe9b6c7aa,
  0xd62f105d, 0x02441453, 0xd8a1e681, 0xe7d3fbc8,
  0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed,
  0xa9e3e905, 0xfcefa3f8, 0x676f02d9, 0x8d2a4c8a,
  0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c,
  0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70,
  0x289b7ec6, 0xeaa127fa, 0xd4ef3085, 0x04881d05,
  0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665,
  0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039,
  0x655b59c3, 0x8f0ccc92, 0xffeff47d, 0x85845dd1,
  0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1,
  0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391,
  0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476
}
local f=function (x,y,z) return bit_or(bit_and(x,y),bit_and(-x-1,z)) end
local g=function (x,y,z) return bit_or(bit_and(x,z),bit_and(y,-z-1)) end
local h=function (x,y,z) return bit_xor(x,bit_xor(y,z)) end
local i=function (x,y,z) return bit_xor(y,bit_or(x,-z-1)) end
local z=function (f,a,b,c,d,x,s,ac)
  a=bit_and(a+f(b,c,d)+x+ac,0xFFFFFFFF)
  -- be *very* careful that left shift does not cause rounding!
  return bit_or(bit_lshift(bit_and(a,bit_rshift(0xFFFFFFFF,s)),s),bit_rshift(a,32-s))+b
end
local function transform(A,B,C,D,X)
  local a,b,c,d=A,B,C,D
  local t=CONSTS
  a=z(f,a,b,c,d,X[ 0], 7,t[ 1])
  d=z(f,d,a,b,c,X[ 1],12,t[ 2])
  c=z(f,c,d,a,b,X[ 2],17,t[ 3])
  b=z(f,b,c,d,a,X[ 3],22,t[ 4])
  a=z(f,a,b,c,d,X[ 4], 7,t[ 5])
  d=z(f,d,a,b,c,X[ 5],12,t[ 6])
  c=z(f,c,d,a,b,X[ 6],17,t[ 7])
  b=z(f,b,c,d,a,X[ 7],22,t[ 8])
  a=z(f,a,b,c,d,X[ 8], 7,t[ 9])
  d=z(f,d,a,b,c,X[ 9],12,t[10])
  c=z(f,c,d,a,b,X[10],17,t[11])
  b=z(f,b,c,d,a,X[11],22,t[12])
  a=z(f,a,b,c,d,X[12], 7,t[13])
  d=z(f,d,a,b,c,X[13],12,t[14])
  c=z(f,c,d,a,b,X[14],17,t[15])
  b=z(f,b,c,d,a,X[15],22,t[16])
  a=z(g,a,b,c,d,X[ 1], 5,t[17])
  d=z(g,d,a,b,c,X[ 6], 9,t[18])
  c=z(g,c,d,a,b,X[11],14,t[19])
  b=z(g,b,c,d,a,X[ 0],20,t[20])
  a=z(g,a,b,c,d,X[ 5], 5,t[21])
  d=z(g,d,a,b,c,X[10], 9,t[22])
  c=z(g,c,d,a,b,X[15],14,t[23])
  b=z(g,b,c,d,a,X[ 4],20,t[24])
  a=z(g,a,b,c,d,X[ 9], 5,t[25])
  d=z(g,d,a,b,c,X[14], 9,t[26])
  c=z(g,c,d,a,b,X[ 3],14,t[27])
  b=z(g,b,c,d,a,X[ 8],20,t[28])
  a=z(g,a,b,c,d,X[13], 5,t[29])
  d=z(g,d,a,b,c,X[ 2], 9,t[30])
  c=z(g,c,d,a,b,X[ 7],14,t[31])
  b=z(g,b,c,d,a,X[12],20,t[32])
  a=z(h,a,b,c,d,X[ 5], 4,t[33])
  d=z(h,d,a,b,c,X[ 8],11,t[34])
  c=z(h,c,d,a,b,X[11],16,t[35])
  b=z(h,b,c,d,a,X[14],23,t[36])
  a=z(h,a,b,c,d,X[ 1], 4,t[37])
  d=z(h,d,a,b,c,X[ 4],11,t[38])
  c=z(h,c,d,a,b,X[ 7],16,t[39])
  b=z(h,b,c,d,a,X[10],23,t[40])
  a=z(h,a,b,c,d,X[13], 4,t[41])
  d=z(h,d,a,b,c,X[ 0],11,t[42])
  c=z(h,c,d,a,b,X[ 3],16,t[43])
  b=z(h,b,c,d,a,X[ 6],23,t[44])
  a=z(h,a,b,c,d,X[ 9], 4,t[45])
  d=z(h,d,a,b,c,X[12],11,t[46])
  c=z(h,c,d,a,b,X[15],16,t[47])
  b=z(h,b,c,d,a,X[ 2],23,t[48])
  a=z(i,a,b,c,d,X[ 0], 6,t[49])
  d=z(i,d,a,b,c,X[ 7],10,t[50])
  c=z(i,c,d,a,b,X[14],15,t[51])
  b=z(i,b,c,d,a,X[ 5],21,t[52])
  a=z(i,a,b,c,d,X[12], 6,t[53])
  d=z(i,d,a,b,c,X[ 3],10,t[54])
  c=z(i,c,d,a,b,X[10],15,t[55])
  b=z(i,b,c,d,a,X[ 1],21,t[56])
  a=z(i,a,b,c,d,X[ 8], 6,t[57])
  d=z(i,d,a,b,c,X[15],10,t[58])
  c=z(i,c,d,a,b,X[ 6],15,t[59])
  b=z(i,b,c,d,a,X[13],21,t[60])
  a=z(i,a,b,c,d,X[ 4], 6,t[61])
  d=z(i,d,a,b,c,X[11],10,t[62])
  c=z(i,c,d,a,b,X[ 2],15,t[63])
  b=z(i,b,c,d,a,X[ 9],21,t[64])
  return A+a,B+b,C+c,D+d
end
----------------------------------------------------------------
function md5_sumhexa(s)
  local msgLen = #s
  local padLen = 56 - msgLen % 64
  if msgLen % 64 > 56 then padLen = padLen + 64 end
  if padLen == 0 then padLen = 64 end
  s = s .. char(128) .. rep(char(0),padLen-1) .. lei2str(8*msgLen) .. lei2str(0)
  assert(#s % 64 == 0)
  local t = CONSTS
  local a,b,c,d = t[65],t[66],t[67],t[68]
  for i=1,#s,64 do
    local X = cut_le_str(sub(s,i,i+63),4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4)
    assert(#X == 16)
    X[0] = table.remove(X,1) -- zero based!
    a,b,c,d = transform(a,b,c,d,X)
  end
  return format("%08x%08x%08x%08x",swap(a),swap(b),swap(c),swap(d))
end
function md5_sum(s)
  return hex2binary(md5_sumhexa(s))
end
return md5
EndFile;
File;boot/sblcfg/craftos
set root=(hdd)
load_video
insmod kernel
kernel /rom/programs/shell
boot
EndFile;
File;bin/mknod
#!/usr/bin/env lua
--/bin/mknod: create devices
_handler = {}
_handler.signal_handler = function(sig)
    if sig == 'kill' then
        --print("mount: SIGKILL")
        return 0
    end
end
function main(args)
    if #args == 4 then
        local path = args[1]
        local type = args[2]
        local major = tonumber(args[3])
        local minor = tonumber(args[4])
        if os.lib.devices then
            os.lib.devices.lddev(path, type, major, minor)
        else
            ferror("mknod: how are you there in limbo?")
        end
    end
end
main({...})
EndFile;
File;proc/2/exe
/sbin/login
EndFile;
File;proc/70/stat
stat working
EndFile;
File;bin/rm
#!/usr/bin/env lua
--/bin/rm: removes files and folders
_handler = {}
_handler.signal_handler = function(sig)
    if sig == 'kill' then
        --print("rm: SIGKILL")
        return 0
    end
end
function main(args)
    --actually doing multiple args
    for i=1, #args do
        local file = os.cshell.resolve(args[i])
        if fs.exists(file) then
            fs.delete(file)
        else
            ferror("rm: node not found")
        end
    end
end
main({...})
EndFile;
File;bin/umount
#!/usr/bin/env lua
--/bin/umount: umount devices
_handler = {}
_handler.signal_handler = function(sig)
    if sig == 'kill' then
        --print("umount: SIGKILL")
        return 0
    end
end
function main(args)
    if permission.grantAccess(fs.perms.ROOT) then
        local path = args[1]
        local components = os.strsplit(path, '/')
        if components[1] == 'dev' then
            local ok = fsmanager.umount_dev(path)
            if ok[1] == true then
                os.debug.debug_write('[umount] '..path)
            else
                os.debug.debug_write('[umount_dev] error umounting '..path..' : '..ok[2], nil, true)
            end
        else
            local ok = fsmanager.umount_path(path)
            if ok[1] == true then
                os.debug.debug_write('[umount] '..path)
            else
                os.debug.debug_write('[umount_path] error umounting '..path..' : '..ok[2], nil, true)
            end
        end
    else
        os.ferror("umount: system permission is required to umount")
        return 0
    end
end
main({...})
EndFile;
File;usr/manuals/kernel/api.man
Cubix API
os.list_mfiles [table]
    managed files in cubix ["man procmngr"]
os.list_devices [table]
    list the devices registered in cubix ["man devicemngr"]
os.system_halt() [function, nil]
    halts the system execution.
os.viewTable(table) [function, nil]
    show the elements from a table.
os.ferror(s) [function, nil]
    error function
os.safestr(s) [function, string]
    turns a string into printable characters
os.strsplit(s, sep) [function, list]
    emulation of python 'split' function
os.lib.hash.sha256(s) [function, string]
    SHA256 hash of a string
os.lib.hash.md5(s) [function, string]
    MD5 hash of a string
term.set_term_color(color) [function, nil]
    a simple function to compatiblity between Computers and ADV. Computers
EndFile;
File;lib/hash_manager
#!/usr/bin/env lua
--hash manager
--task: automate hash management, using a global object "hash"
hash = {}
function libroutine()
    if os.loadAPI("/lib/hash/sha256.lua") then
        sha256 = _G["sha256.lua"]
        os.debug.debug_write("[hash] sha256: loaded")
        hash.sha256 = sha256.hash_sha256
        local H = hash.sha256("hell")
        if H == "0ebdc3317b75839f643387d783535adc360ca01f33c75f7c1e7373adcd675c0b" then
            os.debug.testcase("[hash] sha256('michigan') test = PASS")
        else
            os.debug.kpanic("[hash] sha256('michigan') test = NOT PASS")
        end
    else
        os.debug.kpanic("[hash] sha256: not loaded")
    end
    if os.loadAPI("/lib/hash/md5.lua") then
        md5 = _G["md5.lua"]
        os.debug.debug_write("[hash] md5: loaded")
        hash.md5 = md5.md5_sumhexa
        local H = hash.md5("hell")
        if H == "4229d691b07b13341da53f17ab9f2416" then
            os.debug.testcase("[hash] md5('michigan') test = PASS")
        else
            os.debug.kpanic("[hash] md5('michigan') test = NOT PASS")
        end
    else
        os.debug.kpanic("[hash] md5: not loaded")
    end
end
EndFile;
File;usr/manuals/kernel/internals.man
On the subject of Internal Functions
Internal Functions are used by the kernel to do its inner workings, the most of them are accesible by os.internals._kernel
WARNING: please, don't mess with them.
register_device(device)
    loads a device into DEVICES list
register_mfile(controller)
    registers a Managed File(MFILE) into cubix["man procmngr"]
register_tty(path, tty)
    registers a TTY to TTYS list
EndFile;
File;bin/cd
#!/usr/bin/env lua
--/bin/cd : change directory
_handler = {}
_handler.signal_handler = function(sig)
    if sig == 'kill' then
        --print("cd: SIGKILL")
        return 0
    end
end
CURRENT_PATH = ''
function strsplit(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t={} ; i=1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        t[i] = str
        i = i + 1
    end
    return t
end
function pth_goup(p)
    elements = strsplit(p, '/')
    res = ''
    for i = 1, (#elements - 1) do
        --print(res)
        res = res .. '/' .. elements[i]
    end
    return res
end
function cd(pth)
    local current_user = os.lib.login.currentUser()
    if CURRENT_PATH == nil then
        CURRENT_PATH = '/'
    elseif pth == nil then
        CURRENT_PATH = "/home/"..current_user
    elseif pth == '.' then
        CURRENT_PATH = CURRENT_PATH
    elseif pth == '..' then
        CURRENT_PATH = pth_goup(CURRENT_PATH)
    elseif pth == '/' then
        CURRENT_PATH = pth
    elseif fs.exists(fs.combine(CURRENT_PATH, pth)) == true then
        CURRENT_PATH = fs.combine(CURRENT_PATH, pth)
    elseif fs.exists(pth) == true then
        CURRENT_PATH = pth
    else
        print("cd: not found!")
    end --end
end
function main(args)
    local pth = args[1]
    CURRENT_PATH = os.cshell.getpwd()
    cd(pth)
    --local _cpath = fs.open("/tmp/current_path", 'w')
    --_cpath.write(CURRENT_PATH)
    --_cpath.close()
    os.lib.control.register('/bin/cd', 'cd_lock', '1')
    os.cshell.cwd(CURRENT_PATH)
    os.lib.control.register('/bin/cd', 'cd_lock', nil)
end
main({...})
EndFile;
File;proc/3/stat
stat working
EndFile;
File;proc/76/stat
stat working
EndFile;
File;bin/yapi
#!/usr/bin/env lua
--/bin/yapi: Yet Another Package Installer (with a pacman syntax-like)
AUTHOR = 'Lukas Mendes'
VERSION = '0.1.3'
--defining some things
local SERVERIP = 'lkmnds.github.io'
local SERVERDIR = '/yapi'
local YAPIDIR = '/var/yapi'
function download_file(url)
    local cache = os.strsplit(url, '/')
    local fname = cache[#cache]
    print('request: ' .. fname)
    http.request(url)
    local req = true
    while req do
        local e, url, stext = os.pullEvent()
        if e == 'http_success' then
            local rText = stext.readAll()
            stext.close()
            return rText
        elseif e == 'http_failure' then
            req = false
            return {false, 'http_failure'}
        end
    end
end
function success(msg)
    term.set_term_color(colors.green)
    print(msg)
    term.set_term_color(colors.white)
end
function cache_file(data, filename)
    local h = fs.open(YAPIDIR..'/cache/'..filename, 'w')
    h.write(data)
    h.close()
    return 0
end
function isin(inputstr, wantstr)
    for i = 1, #inputstr do
        local v = string.sub(inputstr, i, i)
        if v == wantstr then return true end
    end
    return false
end
function create_default_struct()
    fs.makeDir(YAPIDIR.."/cache")
    fs.makeDir(YAPIDIR.."/db")
    fs.open(YAPIDIR..'/installedpkg', 'a').close()
end
function update_repos()
    --download core, community and extra
    local SPATH = 'http://'.. SERVERIP .. SERVERDIR .. '/database/core'
    local k = download_file(SPATH)
    if type(k) == 'table' then
        ferror("yapi: http error")
        return 1
    end
    local _h = fs.open(YAPIDIR..'/db/core', 'w')
    _h.write(k)
    _h.close()
    local SPATH = 'http://'.. SERVERIP .. SERVERDIR .. '/database/community'
    local k = download_file(SPATH)
    if type(k) == 'table' then
        ferror("yapi: http error")
        return 1
    end
    local _h = fs.open(YAPIDIR..'/db/community', 'w')
    _h.write(k)
    _h.close()
    local SPATH = 'http://'.. SERVERIP .. SERVERDIR .. '/database/extra'
    local k = download_file(SPATH)
    if type(k) == 'table' then
        ferror("yapi: http error")
        return 1
    end
    local _h = fs.open(YAPIDIR..'/db/extra', 'w')
    _h.write(k)
    _h.close()
end
--Yapi Database
yapidb = {}
yapidb.__index = yapidb
function yapidb.new(path)
    local inst = {}
    setmetatable(inst, yapidb)
    inst.path = path
    inst.db = ''
    return inst
end
function yapidb:update()
    self.db = ''
    self.db = self.db .. '\n'
    local h = fs.open(self.path..'/core', 'r')
    local _k = h.readAll()
    self.db = self.db .. _k
    h.close()
    self.db = self.db .. '\n'
    local h = fs.open(self.path..'/community', 'r')
    local _k = h.readAll()
    self.db = self.db .. '\n'
    self.db = self.db .. _k
    h.close()
    self.db = self.db .. '\n'
    local h = fs.open(self.path..'/extra', 'r')
    local _k = h.readAll()
    self.db = self.db .. '\n'
    self.db = self.db .. _k
    self.db = self.db .. '\n'
    h.close()
end
function yapidb:search(pkgname)
    self:update()
    local _lines = self.db
    local lines = os.strsplit(_lines, '\n')
    for k,v in pairs(lines) do
        local pkgdata = os.strsplit(v, ';')
        if pkgdata[1] == pkgname then
            return {true, v}
        end
    end
    return {false, nil}
end
function yapidb:search_wcache(pkgname)
    self:update()
    if fs.exists(YAPIDIR..'/cache/'..pkgname..'.yap') then
        local h = fs.open(YAPIDIR..'/cache/'..pkgname..'.yap', 'r')
        local f = h.readAll()
        h.close()
        return f
    else
        local _url = self:search(pkgname)
        local url = os.strsplit(_url[2], ';')[2]
        local yapdata = download_file(url)
        if type(yapdata) == 'table' then return -1 end
        cache_file(yapdata, pkgname..'.yap')
        return yapdata
    end
end
--parsing yap files
function parse_yap(yapf)
    local lines = os.strsplit(yapf, '\n')
    local yapobject = {}
    yapobject['folders'] = {}
    yapobject['files'] = {}
    yapobject['deps'] = {}
    if type(lines) ~= 'table' then
        os.ferror("::! [parse_yap] type(lines) ~= table")
        return 1
    end
    local isFile = false
    local rFile = ''
    for _,v in pairs(lines) do
        if isFile then
            local d = v
            if d ~= 'EndFile;' then
                if yapobject['files'][rFile] == nil then
                    yapobject['files'][rFile] = d .. '\n'
                else
                    yapobject['files'][rFile] = yapobject['files'][rFile] .. d .. '\n'
                end
            else
                isFile = false
                rFile = ''
            end
        end
        local splitted = os.strsplit(v, ';')
        if splitted[1] == 'Name' then
            yapobject['name'] = splitted[2]
        elseif splitted[1] == 'Version' then
            yapobject['version'] = splitted[2]
        elseif splitted[1] == 'Build' then
            yapobject['build'] = splitted[2]
        elseif splitted[1] == 'Author' then
            yapobject['author'] = splitted[2]
        elseif splitted[1] == 'Email-Author' then
            yapobject['email_author'] = splitted[2]
        elseif splitted[1] == 'Description' then
            yapobject['description'] = splitted[2]
        elseif splitted[1] == 'Url' then
            yapobject['url'] = splitted[2]
        elseif splitted[1] == 'License' then
            yapobject['license'] = splitted[2]
        elseif splitted[1] == 'Folder' then
            table.insert(yapobject['folders'], splitted[2])
        elseif splitted[1] == 'File' then
            isFile = true
            rFile = splitted[2]
        elseif splitted[1] == 'Dep' then
            table.insert(yapobject['deps'], splitted[2])
        end
    end
    return yapobject
end
function yapidb:installed_pkgs()
    local handler = fs.open(YAPIDIR..'/installedpkg', 'r')
    local file = handler.readAll()
    handler.close()
    local lines = os.strsplit(file, '\n')
    return lines
end
function yapidb:is_installed(namepkg)
    local installed = self:installed_pkgs()
    for k,v in ipairs(installed) do
        local splitted = os.strsplit(v, ';')
        if splitted[1] == namepkg then return true end
    end
    return false
end
function yapidb:updatepkgs()
    self:update()
    for k,v in pairs(self:installed_pkgs()) do
        local pair = os.strsplit(v, ';')
        local w = self:search(pair[1])
        local yd = {}
        if w[1] == false then
            os.ferror("::! updatepkgs: search error")
            return false
        end
        local url = os.strsplit(w[2], ';')[2]
        local rawdata = download_file(url)
        if type(rawdata) == 'table' then
            os.ferror("::! [install] type(rawdata) == table : "..yapfile[2])
            return false
        end
        local yd = parse_yap(rawdata)
        if tonumber(pair[2]) < tonumber(yd['build']) then
            print(" -> new build of "..pair[1].." ["..pair[2].."->"..yd['build'].."] ")
            self:install(pair[1]) --install latest
        else
            print(" -> [updatepkgs] "..yd['name']..": OK")
        end
    end
end
function yapidb:register_pkg(yapdata)
    print("==> [register] "..yapdata['name'])
    local _h = fs.open(YAPIDIR..'/installedpkg', 'r')
    local _tLines = _h.readAll()
    _h.close()
    local pkg_found = false
    local tLines = os.strsplit(_tLines, '\n')
    for k,v in ipairs(tLines) do
        local pair = os.strsplit(v, ';')
        if pair[1] == yapdata['name'] then
            pkg_found = true
            tLines[k] = yapdata['name']..';'..yapdata['build']
        else
            tLines[k] = tLines[k] .. '\n'
        end
    end
    if not pkg_found then
        tLines[#tLines+1] = yapdata['name']..';'..yapdata['build'] .. '\n'
    end
    print(" -> writing to file")
    local h2 = fs.open(YAPIDIR..'/installedpkg', 'w')
    for k,v in pairs(tLines) do
        h2.write(v)
    end
    h2.close()
end
function yapidb:install_yap(yapdata)
    print("==> install_yap: "..yapdata['name'])
    for k,v in pairs(yapdata['folders']) do
        fs.makeDir(v)
    end
    for k,v in pairs(yapdata['files']) do
        local h = fs.open(k, 'w')
        h.write(v)
        h.close()
    end
    return true
end
function yapidb:return_dep_onepkg(pkgname)
    local _s = self:search(pkgname)
    if _s[1] == true then
        local result = os.strsplit(_s[2], ';')
        local yapfile = download_file(result[2])
        if type(yapfile) == 'table' then
            os.ferror("::! [getdep] "..yapfile[2])
            return false
        end
        cache_file(yapfile, pkgname..'.yap')
        local yapdata = parse_yap(yapfile)
        local dependencies = {}
        if yapdata['deps'] == nil then
            print(" -> no dependencies: "..pkgname)
            return {}
        end
        for _,dep in ipairs(yapdata['deps']) do
            if not self:is_installed(dep) then
                table.insert(dependencies, dep)
            end
        end
        return dependencies
    else
        return false
    end
end
function yapidb:return_deps(pkglist)
    local r = {}
    for _,pkg in ipairs(pkglist) do
        local c = self:return_dep_onepkg(pkg)
        if c == false then
            ferror("::! [getdeps] error getting deps: "..pkg)
            return nil
        end
        for i=0,#c do
            table.insert(r, c[i])
        end
        table.insert(r, pkg)
    end
    return r
end
function yapidb:install(pkgname)
    local _s = self:search(pkgname)
    if _s[1] == true then
        local result = os.strsplit(_s[2], ';')
        local yapfile = download_file(result[2])
        if type(yapfile) == 'table' then
            os.ferror("::! [install] "..yapfile[2])
            return false
        end
        cache_file(yapfile, pkgname..'.yap')
        local yapdata = parse_yap(yapfile)
        local missing_dep = {}
        if yapdata['deps'] == nil then
            print(" -> no dependencies: "..pkgname)
        else
            for _,dep in ipairs(yapdata['deps']) do
                if not self:is_installed(dep) then
                    table.insert(missing_dep, dep)
                end
            end
        end
        if #missing_dep > 0 then
            ferror("error: missing dependencies")
            for _,v in ipairs(missing_dep) do
                write(v..' ')
            end
            write('\n')
            return false
        end
        self:register_pkg(yapdata)
        self:install_yap(yapdata)
        return true
    else
        os.ferror("error: target not found: "..pkgname)
        return false
    end
end
function yapidb:remove(pkgname)
    --1st: read cached yapdata
    --2nd: remove all files made by yapdata['files']
    --3rd: remove entry in YAPIDIR..'/installedpkg'
    if not self:is_installed(pkgname) then
        os.ferror(" -> package not installed")
        return false
    end
    local yfile = self:search_wcache(pkgname)
    local ydata = parse_yap(yfile)
    --2nd part
    print("==> remove: "..ydata['name'])
    for k,v in pairs(ydata['files']) do
        --print(" -> removing "..k)
        fs.delete(k)
    end
    for k,v in pairs(ydata['folders']) do
        --print(" -> removing folder "..v)
        fs.delete(v)
    end
    --3rd part
    --print(" -> remove_entry: "..ydata['name'])
    local _h = fs.open(YAPIDIR..'/installedpkg', 'r')
    local _tLines = _h.readAll()
    _h.close()
    local pkg_found = false
    local tLines = os.strsplit(_tLines, '\n')
    for k,v in ipairs(tLines) do
        local pair = os.strsplit(v, ';')
        if pair[1] == ydata['name'] then
            tLines[k] = '\n'
        else
            tLines[k] = tLines[k] .. '\n'
        end
    end
    --print(" -> writing empty entry")
    local h2 = fs.open(YAPIDIR..'/installedpkg', 'w')
    for k,v in pairs(tLines) do
        h2.write(v)
    end
    h2.close()
    return true
end
function yapidb:clear_cache()
    fs.delete(YAPIDIR..'/cache')
    fs.makeDir(YAPIDIR..'/cache')
end
function main(args)
    if not permission.grantAccess(fs.perms.SYS) then
        os.ferror("yapi: not running as root")
        return 1
    end
    create_default_struct()
    if #args == 0 then
        print("usage: yapi <mode> ...")
    else
        local option = args[1]
        if string.sub(option, 1, 1) == '-' then
            if string.sub(option, 2,2) == 'S' then
                local packages = os.tail(args)
                if packages ~= nil then
                    local database = yapidb.new(YAPIDIR..'/db')
                    database:update()
                    for k,pkg in ipairs(packages) do
                        if not database:search(pkg)[1] then
                            os.ferror("error: target not found: "..pkg)
                            return 1
                        end
                    end
                    print("resolving dependencies...")
                    packages = database:return_deps(packages)
                    print("")
                    if packages == nil then
                        os.ferror("yapi: error getting deps")
                        return 1
                    end
                    write("Packages ("..#packages..") ")
                    for _,pkg in ipairs(packages) do
                        write(pkg..' ')
                    end
                    print("\n")
                    if not prompt(":: Proceed with installation?", "Y", "n") then
                        print("==> Aborted")
                        return true
                    end
                    for k,package in ipairs(packages) do
                        print(":: Installing packages ...")
                        local completed = 1
                        if database:install(package) then
                            success("("..completed.."/"..tostring(#packages)..")"..package.." : SUCCESS")
                            completed = completed + 1
                        else
                            return 1
                        end
                    end
                end
                if isin(option, 'c') then
                    local database = yapidb.new(YAPIDIR..'/db')
                    print("==> [clear_cache]")
                    database:clear_cache()
                end
                if isin(option, 'y') then
                    print(":: Update from "..SERVERIP)
                    if not http then
                        os.ferror("yapi: http not enabled")
                        return 1
                    end
                    update_repos()
                end
                if isin(option, 'u') then
                    local database = yapidb.new(YAPIDIR..'/db')
                    print(":: Starting full system upgrade")
                    if prompt("Confirm full system upgrade", "Y", "n") then
                        database:updatepkgs()
                    else
                        print("==> Aborted")
                    end
                end
            elseif string.sub(option,2,2) == 'U' then
                local yfile = os.cshell.resolve(args[2])
                print("==> [install_yap] "..yfile)
                if not fs.exists(yfile) then
                    ferror("-> file does not exist")
                    return 0
                end
                local h = fs.open(yfile, 'r')
                local _data = h.readAll()
                h.close()
                local ydata = parse_yap(_data)
                local database = yapidb.new(YAPIDIR..'/db')
                if database:install_yap(ydata) then
                    success("==> [install_yap] "..ydata['name'])
                else
                    os.ferror("::! [install_yap] "..ydata['name'])
                end
            elseif string.sub(option,2,2) == 'Q' then
                local database = yapidb.new(YAPIDIR..'/db')
                local pkg = args[2]
                local _k = database:search(pkg)
                if pkg then
                    if _k[1] == true then
                        local _c = database:search_wcache(pkg)
                        local yobj = parse_yap(_c)
                        if type(yobj) ~= 'table' then
                            os.ferror("::! [list -> parse_yap] error (yobj ~= table)")
                            return 1
                        end
                        print(yobj.name .. ' b' .. yobj.build .. ' v' .. yobj.version .. ' ('..yobj.license..')')
                        print("Maintainer: "..yobj.author.." <"..yobj['email_author']..">")
                        print("Description: "..yobj.description)
                        print("URL: "..yobj.url)
                    else
                        os.ferror("::! package not found")
                    end
                end
                if isin(option, 'e') then
                    local database = yapidb.new(YAPIDIR..'/db')
                    database:update()
                    local ipkg = database:installed_pkgs()
                    for _,ntv in ipairs(ipkg) do
                        local v = os.strsplit(ntv, ';')
                        write(v[1] .. ':' .. v[2] .. '\n')
                    end
                end
            elseif string.sub(option,2,2) == 'R' then
                local packages = os.tail(args)
                if packages ~= nil then
                    local database = yapidb.new(YAPIDIR..'/db')
                    database:update()
                    for k,pkg in ipairs(packages) do
                        if not database:search(pkg)[1] then
                            os.ferror("error: target not found: "..pkg)
                            return 1
                        end
                    end
                    if not prompt("Proceed with remotion?", "Y", "n") then
                        print("==> Aborted")
                        return true
                    end
                    for k,package in ipairs(packages) do
                        --local database = yapidb.new(YAPIDIR..'/db')
                        --database:update()
                        print(":: removing "..package)
                        if database:remove(package) then
                            success("==> [remove] "..package.." : SUCCESS")
                        else
                            os.ferror("::! [remove] "..package.." : FAILURE")
                            return 1
                        end
                    end
                end
            end
        else
            os.ferror("yapi: sorry, see \"man yapi\" for details")
        end
    end
end
main({...})
EndFile;
File;bin/hashrate
#!/usr/bin/env lua
--/bin/hashrate_test
--livre,
hc = 1
seconds = 0
function hashing_start()
    print("hashing_start here")
    while true do
        local k = os.lib.hash.hash.sha256('constant1' .. 'constant2' .. tostring(hc))
        write(k..'\n')
        hc = hc + 1
        sleep(0)
    end
    print("hashing_start ded")
end
function hashing_count()
    print("hashing_count here")
    while true do
        local hrate = hc / seconds
        term.set_term_color(colors.red)
        term.setCursorPos(1,1)
        print("hashrate: "..tostring(hrate)..' h/s')
        term.set_term_color(colors.white)
        seconds = seconds + 1
        sleep(1)
    end
    print("hashing_count ded")
end
function main(args)
    print("starting Hashrate program")
    local seconds = 0
    os.startThread(hashing_count)
    os.startThread(hashing_start)
    return 0
end
--thread API
local threads = {}
local starting = {}
local eventFilter = nil
rawset(os, "startThread", function(fn, blockTerminate)
        table.insert(starting, {
                cr = coroutine.create(fn),
                blockTerminate = blockTerminate or false,
                error = nil,
                dead = false,
                filter = nil
        })
end)
local function tick(t, evt, ...)
        if t.dead then return end
        if t.filter ~= nil and evt ~= t.filter then return end
        if evt == "terminate" and t.blockTerminate then return end
        coroutine.resume(t.cr, evt, ...)
        t.dead = (coroutine.status(t.cr) == "dead")
end
local function tickAll()
        if #starting > 0 then
                local clone = starting
                starting = {}
                for _,v in ipairs(clone) do
                        tick(v)
                        table.insert(threads, v)
                end
        end
        local e
        if eventFilter then
                e = {eventFilter(coroutine.yield())}
        else
                e = {coroutine.yield()}
        end
        local dead = nil
        for k,v in ipairs(threads) do
                tick(v, unpack(e))
                if v.dead then
                        if dead == nil then dead = {} end
                        table.insert(dead, k - #dead)
                end
        end
        if dead ~= nil then
                for _,v in ipairs(dead) do
                        table.remove(threads, v)
                end
        end
end
rawset(os, "setGlobalEventFilter", function(fn)
        if eventFilter ~= nil then error("This can only be set once!") end
        eventFilter = fn
        rawset(os, "setGlobalEventFilter", nil)
end)
if type(main) == "function" then
        os.startThread(main)
else
        os.startThread(function() shell.run("shell") end)
end
while #threads > 0 or #starting > 0 do
        tickAll()
end
EndFile;
File;usr/manuals/debugmngr.man
Debug Manager
Task #1:
    Manage debug information from the OS and from other managers
    All of the functions of the Debug Manager can be found in os.debug (no, the debug manager isn't loaded like other modules(with loadmodule), instead, loadAPI is used)
    The system log can be found in /tmp/syslog(will be deleted when shutdown["man acpi"])
    debug_write(message[, toScreen, isErrorMessage])
        writes message to screen if toscreen is nil
        if toscreen is false it does not write a message
        but in any of the cases it writes the message to the __debug_buffer
    dmesg()
        shows __debug_buffer
    kpanic()
        Kernel Panic!
EndFile;
File;bin/make
#!/usr/bin/env lua
VER = '0.0.1'
function warning_verbose(command)
    if string.sub(command, 1, 14) == 'rm /tmp/syslog' then
        return true
    elseif string.sub(command, 1, 7) == 'rm /dev' then
        return true
    end
end
function run_command(c, warning_table)
    if warning_table['WARN_VERBOSE'] then
        term.setTextColor(colors.blue)
        if warning_verbose(c) then
            print("WARN_VERBOSE: "..c)
            local c = read()
        else
            term.setTextColor(colors.lightBlue)
            print(": "..c)
        end
        term.setTextColor(colors.white)
        os.cshell.run(c)
    else
        term.setTextColor(colors.lightBlue)
        print(': '..c)
        term.setTextColor(colors.white)
        os.cshell.run(c)
    end
end
function make_debug(opener, msg)
    term.setTextColor(colors.green)
    print('['..opener..'] '..msg)
    term.setTextColor(colors.white)
end
function parse_mkfile(mkfdata)
    local lines = os.strsplit(mkfdata, '\n')
    local mkdata = {}
    local actual_target = ''
    local isTarget = false
    for _,v in ipairs(lines) do
        if isTarget then
            --print(v)
            if v == 'end-target;' then
                isTarget = false
            else
                mkdata['target:'..actual_target]['data'][#mkdata['target:'..actual_target]['data'] + 1] = v
            end
        end
        if string.sub(v, 1, 1) == 'd' then
            --default target
            mkdata['default_target'] = os.strsplit(v, ' ')[2]
        elseif string.sub(v, 1, 1) == 't' then
            --target
            isTarget = true
            target_id = os.strsplit(v, ' ')[2]
            local s = os.strsplit(target_id, ',')
            actual_target = s[1]
            target_deps = os.tail(s)
            --remove the : at the final of line
            target_deps[#target_deps] = string.sub(target_deps[#target_deps], 1, #target_deps[#target_deps] -1)
            mkdata['target:'..actual_target] = {}
            mkdata['target:'..actual_target]['data'] = {}
            mkdata['target:'..actual_target]['deps'] = target_deps
        end
    end
    return mkdata
end
function do_make(mkdata, target)
    --os.viewTable(mkdata['target:submit']['deps'])
    if target == '' then
        return 0
    end
    if target == 'None' then
        make_debug("do_make", "default target is None, can't do make")
        return 0
    end
    if not mkdata['target:'..target] then
        ferror("[do_make] target "..target.." not found")
        return 0
    end
    for k,v in pairs(mkdata['target:'..target]['deps']) do
        do_make(mkdata, v)
    end
    make_debug("do_make", target)
    local variables = {}
    local order_var = false
    local warnings = {}
    for k,v in pairs(mkdata['target:'..target]['data']) do
        if string.sub(v, 1, 2) == 'c ' then
            cmd = string.sub(v, 3, #v)
            run_command(cmd, warnings)
            order_var = False
        elseif string.sub(v, 1, 3) == 'vc ' then
            cmd = string.sub(v, 4, #v)
            local var_count = 1
            local strfinal = ''
            for i=1, #cmd do
                local c = string.sub(cmd, i, i)
                if c == '$' then
                    local variable = variables[order_var[var_count]]
                    if variable == nil then
                        ferror("syntax error: "..order_var[var_count].." is not defined")
                        return 0
                    end
                    strfinal = strfinal .. variable
                    var_count = var_count + 1
                else
                    strfinal = strfinal .. c
                end
            end
            run_command(strfinal, warnings)
            order_var = false
        elseif string.sub(v, 1, 2) == 'v ' then
            local var_name = os.strsplit(v, ':')[2]
            variables[var_name] = nil
        elseif string.sub(v, 1, 2) == 'l ' then
            order_var = os.strsplit(string.sub(v, 3, #v), ',')
            --os.viewTable(order_var)
        elseif string.sub(v, 1, 2) == 'r ' then
            var_name = os.strsplit(v, ':')[2]
            variables[var_name] = read()
        elseif string.sub(v, 1, 2) == 'w ' then
            warn_name = os.strsplit(v, ' ')[2]
            warnings[warn_name] = true
        end
    end
end
function main(args)
    print("make v"..VER)
    local mpath = os.cshell.resolve("makefile")
    if not fs.exists(mpath) then
        ferror("make: makefile not found")
        return 0
    end
    local mfile = fs.open(mpath, 'r')
    local mkfile_data = parse_mkfile(mfile.readAll())
    mfile.close()
    local target = ''
    if #args == 1 then
        target = args[1]
    else
        target = mkfile_data['default_target']
    end
    do_make(mkfile_data, target)
end
main({...})
EndFile;
File;var/yapi/cache/devscripts.yap
Name;devscripts
Version;0.0.4
Build;8
Author;Lukas Mendes
Email-Author;lkmnds@gmail.com
Description;Developer Scripts for Cubix
Dep;base
Url;github.com
License;MIT
File;/usr/bin/makeyap
#!/usr/bin/env lua
--makeyap:
--based on pkgdata, creates a .yap file to be a package.
--compatible with Cubix and CraftOS
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        return 0
    end
end
cwd = ''
local strsplit = function (inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    if inputstr == nil then
        return ''
    end
    local t={} ; i=1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        t[i] = str
        i = i + 1
    end
    return t
end
local ferror = function(message)
    term.set_term_color(colors.red)
    print(message)
    term.set_term_color(colors.white)
end
local viewTable = function (t)
    print(t)
    for k,v in pairs(t) do
        print(k..","..tostring(v).." ("..type(v)..")")
    end
end
function listAll(p)
    local starting = '/'
    if p ~= nil then
        starting = p
    end
    if starting == '.git' or starting == '/.git' or starting == 'rom' or starting == '/rom' then
        return {folders={}, files={}}
    end
    local folders = {}
    local files = {}
    for _,v in ipairs(fs.list(starting)) do
        local node = fs.combine(starting, v)
        if fs.isDir(node) then
            if not (node == '.git' or node == '/.git' or node == 'rom' or node == '/rom') then
                table.insert(folders, node)
                local cache = listAll(node)
                for _,v in ipairs(cache['folders']) do
                    table.insert(folders, v)
                end
                for _,v in ipairs(cache['files']) do
                    table.insert(files, v)
                end
            end
        else
            table.insert(files, node)
        end
    end
    return {folders=folders, files=files}
end
function parse_pkgdata(lines)
    local pkgobj = {}
    pkgobj['file_assoc'] = {}
    pkgobj['folders'] = {}
    pkgobj['deps'] = {}
    for k,v in ipairs(lines) do
        if string.sub(v, 1, 1) ~= '#' then --comments
            local d = strsplit(v, ';')
            if d[1] == 'pkgName' then
                pkgobj['name'] = d[2]
            elseif d[1] == 'pkgVersion' then
                pkgobj['version'] = d[2]
            elseif d[1] == 'pkgBuild' then
                pkgobj['build'] = d[2]
            elseif d[1] == 'pkgAuthor' then
                pkgobj['author'] = d[2]
            elseif d[1] == 'pkgEAuthor' then
                pkgobj['email-author'] = d[2]
            elseif d[1] == 'pkgDescription' then
                pkgobj['description'] = d[2]
            elseif d[1] == 'pkgFile' then
                table.insert(pkgobj['file_assoc'], {d[2], d[3]})
            elseif d[1] == 'pkgFolder' then
                table.insert(pkgobj['folders'], d[2])
            elseif d[1] == 'pkgDep' then
                table.insert(pkgobj['deps'], d[2])
            elseif d[1] == 'pkgAll' then
                local nodes = listAll()
                for _,v in ipairs(nodes['folders']) do
                    table.insert(pkgobj['folders'], v)
                end
                for _,v in ipairs(nodes['files']) do
                    table.insert(pkgobj['file_assoc'], {v, v})
                end
            end
        end
    end
    return pkgobj
end
function create_yap(pkgdata, cwd)
    local yapdata = {}
    yapdata['name'] = pkgdata['name']
    yapdata['version'] = pkgdata['version']
    yapdata['build'] = pkgdata['build']
    yapdata['author'] = pkgdata['author']
    yapdata['email_author'] = pkgdata['email-author']
    yapdata['description'] = pkgdata['description']
    yapdata['folders'] = pkgdata['folders']
    yapdata['deps'] = pkgdata['deps']
    yapdata['files'] = {}
    for k,v in pairs(pkgdata['file_assoc']) do
        local original_file = fs.combine(cwd, v[1])
        local absolute_path = v[2]
        yapdata['files'][absolute_path] = ''
        local handler = fs.open(original_file, 'r')
        local _lines = handler.readAll()
        handler.close()
        local lines = strsplit(_lines, '\n')
        for k,v in ipairs(lines) do
            yapdata['files'][absolute_path] = yapdata['files'][absolute_path] .. v .. '\n'
        end
    end
    return yapdata
end
function write_yapdata(yapdata)
    local yp = fs.combine(cwd, yapdata['name']..'.yap')
    if fs.exists(yp) then
        fs.delete(yp)
    end
    local yfile = fs.open(yp, 'w')
    yfile.write('Name;'..yapdata['name']..'\n')
    yfile.write('Version;'..yapdata['version']..'\n')
    yfile.write('Build;'..yapdata['build']..'\n')
    yfile.write('Author;'..yapdata['author']..'\n')
    yfile.write('Email-Author;'..yapdata['email_author']..'\n')
    yfile.write('Description;'..yapdata['description']..'\n')
    os.viewTable(yapdata['folders'])
    for k,v in pairs(yapdata['folders']) do
        yfile.write("Folder;"..v..'\n')
    end
    for k,v in pairs(yapdata['deps']) do
        yfile.write("Dep;"..v..'\n')
    end
    for k,v in pairs(yapdata['files']) do
        yfile.write("File;"..k..'\n')
        yfile.write(v)
        yfile.write("EndFile;\n")
    end
    yfile.close()
    return yp
end
function main()
    if type(os.cshell) == 'table' then
        cwd = os.cshell.getpwd()
    else
        cwd = shell.dir()
    end
    --black magic goes here
    local pkgdata_path = fs.combine(cwd, 'pkgdata')
    local handler = {}
    if fs.exists(pkgdata_path) and not fs.isDir(pkgdata_path) then
        handler = fs.open(pkgdata_path, 'r')
    else
        ferror('makeyap: pkgdata needs to exist')
        return 1
    end
    local _tLines = handler.readAll()
    handler.close()
    if _tLines == nil then
        ferror("yapdata: file is empty")
        return 1
    end
    local tLines = strsplit(_tLines, '\n')
    local pkgdata = parse_pkgdata(tLines)
    print("[parse_pkgdata]")
    print("creating yap...")
    local ydata = create_yap(pkgdata, cwd)
    print("[create_yap] created yapdata from pkgdata")
    local path = write_yapdata(ydata)
    print("[write_yapdata] "..path)
end
main({...})
EndFile;
File;/usr/bin/testing
#!/usr/bin/env lua
--/usr/bin/testing: test yapi
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        os.debug.debug_write("testing: SIGKILL'd!", false)
        return 0
    end
end
function main()
    print("Hello World!")
end
main({...})
EndFile;
EndFile;
File;changelog
0.5.1 - 0.5.2 (17-01-2015) [just writing changes before official release]
  tl;dr this is not finished
  Major changes:
    +login manager rewrited (sudoers, groups, and more)!
    +added better support for devices
  Devices:
    +changed way /dev/random and /dev/urandom get random seeds(based on os.clock(), not os.time())
0.4.0 - 0.5.1 (12-21-2015)
  tl;dr you should use this now
  Major changes:
    +yapi works! (more details in commit 596ce81)
    +luaX, a graphical interface to cubix!
  General changes(cubixli and cubix):
    *bugfix: running runlevel as a kernel option
    */tmp/debug_info is now /tmp/syslog
    +os.ferror is in _G too(as only ferror)
    +external device support(stdin, stdout and stderr almost finished)
    +new device: /dev/full
    +added more signals in os.signals
    +loadmodule_ret: returns the module _G, instead of putting it on os.lib
    +device_write and device_read are the default interfaces to devices now.
    +/sbin/sbl-mkconfig: 'default' mode now generates system.cfg based of default.cfg, not in a hardcoded way anymore
    +dev_available(path): simply returns true if the device exists, false if its not
  Libraries:
    +proc:
        +os.getrunning() returns the running PID of the system
        +generate_pfolder(process, procfolder) generates a /proc/<pid> folder, with the executable and the status of the process
    +os.debug.kpanic: when lx is loaded, shows a beautiful panic message
    +login: kpanic when opening /tmp/current_user or /tmp/current_path gives an error
    +acpi:
        +clears /proc/<pid> folders when __clear_temp is called
        +sets CUBIX_TURNINGOFF to true when acpi_shutdown is called
        +sets CUBIX_REBOOTING to true when acpi_reboot is called
          +because of that, init won't cause a reboot to be a shutdown
  Added programs:
    +/bin/panic: just calls kpanic
    +/bin/curtime: shows current time(GMT 0)
    +/bin/hashrate: just a utility.
  CubixLI:
    +yapstrap creates /tmp/install_lock, not unloadenv
    +sbl_bcfg: restores systems.cfg to default configurations(just in case if the cubix repo provides a broken systems.cfg or a different one from the recommended)
    +timesetup: writes servers to /etc/time-servers
    +genfstab: coming in another commit, but it is there
  Manuals:
    +CMFL, Cubix Manual Formatting Language.
        yapi manual is written in cmfl, you should see it
0.3.7 - 0.4.0 (11-28-2015)
  +Finally, a stable version(still has its bugs but yeah)
  ![/bin/sleep /bin/read] bugs everything, deleted for now
  +cubixli has some workarounds to deldisk
    this includes deleting the partitions cubixli created
    (leading to a halt)
  +cubixli: lsblk, cat, shutdown, sethostname
  +cubixli: "override", when the override flag is activated, all the commands that are not allowed are done
  +/sbin/init: runlevels 3 and 5 being made
0.3.6 - 0.3.7 (11-16-2015)
  +Writing a Installer(cubix_live_installer or cubixli for short)
  -/boot/cubix_minimal does not exist anymore
  +rewrited manuals for 0.3.7
  -os.runfile (yes, this is now marked as bad)
  +finally, /bin/cksum works(only with files)!
  +/bin/cat works with pipes(getting from file and throwing into a pipe)
  +rewrited [/bin/cp /bin/mkdir /bin/mv], using os.chell.resolve now
  +os.cshell.getpwd
  +/bin/eject works using disk.eject, not os.runfile
  -[/bin/read /bin/sleep] is not working [proposital as I'm working on a solution]
  +/bin/rm does not use os.runfile, using fs.delete now
  +/bin/sh uses os.runfile_proc, not os.runfile
  !/bin/wget: working on problems
  !/bin/yapi: still WIP
  +/bin/yes: rewrite based on dev_random
  +/boot/cubix sets IS_CUBIX = true when booting
  *bugfix: runlevel= wasnt working
  +_prompt(message, yescmd, ncmd)
    -Shows a prompt to the user, if he types the same as yescmd, return true
  *bugfix_sbl: kernel module works
  +/dev/MAKEDEV removes /tmp
  +acpi deletes and creates /tmp, not using os.runfile
  +Pipe:readAll()
  +check in proc_manager if p.rfile.main ~= nil and p.rfile.main == function
  +os.run_process sends SIGKILL to process after its execution
  *bugfix: /sbin/adduser crashed when #args == 0
  +/sbin/adduser uses os.lib.login
  +/sbin/init runs scripts in /etc/rc1.d using shell.run, not os.runfile
  +Rewrite of some manual pages
0.3.5 - 0.3.6 (11-07-2015)
  *bugfix: /dev/MAKEDEV does not work more on craftOS, fixed installation
  +SBL: bootscripts!
  +Yet Another Package Installer: /bin/yapi
  +NEW: os.tail
  !os.strsplit now warns you if the type of inputstr isn't string
  +/startup now runs /boot/sbl
0.3.4 - 0.3.5 (10-31-2015)
  +Cubix is now MIT licensed
  +new (not new) security lock: when kernel is stable, "os.pullEvent = os.pullEventRaw" is applied
  +new: /sbin/modprobe
  +when loadmodule() loads a module that RELOADABLE = false is defined, it does not load the module
    This helps when trying to "modprobe proc /lib/proc_manager", since this would wipe os.processes,
    leaving no trace of init or other processes
  *bugfix: /bin/cshell does not run /sbin/, even if you provide the path
  +/bin/ls does not depend of os.runfile (own algorithim now)
  -os.runfile: DEPRECATED!
  +/bin/sudo uses permission module and front_login
  +os.system_halt does not use os.sleep(10000...) anymore
  !SBL: CraftOS does not boot anymore, still working on it
  +acpi uses permission now
  +acpi: acpi_suspend() works (/sbin/pm-suspend)!
  +debug_write(message, screen) -> debug_write(message, screen, isError)
  +new: debug.warning(message)
  {disclaimer here: I used quite a lot of code from UberOS to create
  the filesystem manager to now, because of this, cubix is now MIT licensed}
  +fs_manager: permissions in unix format, load filesystems(for now its
  CFS, cubix file system, but there will be more), nodes and mounting devices(/bin/mount and /bin/umount) :D
  +/sbin/kill: now can kill multiple PIDs!
  !sudo: because of magic, sudo still makes it way to os.processes, even
  if killed, so, don't trust it
  +/bin/license: shows /LICENSE
0.3.3 - 0.3.4 (10-21-2015)
  +new loading mechanism for kernel, decreasing its size
  +login now uses sha256(password + salt) instead of sha256(password)
  +login: session tokens!
  +ACPI management now possible(SBL loads it by default)!
  +new: os.generateSalt
  *bugfix: /proc/cpuinfo & /proc/temperature now support stripping
  +new: /proc/partitions
  +new TTY logic
0.3.2 - 0.3.3 (10-13-2015)
  +new pipe logic using classes
  +starting fs_manager
  +/bin/tee now works!
  *bugfix: "while true do" in /bin/yes
  +/bin/cshell: now searches in path
  +/bin/sudo: now ignores if current user is root
  +/bin/init: runlevels (incomplete)
  +debug: kernel panic complete
  *fix: proc_manager: now the first PID is 1, not 2!
  +/bin/cpkg: Cubix Packages [wip]
  +reboot moved to /sbin
0.3.1 - 0.3.2 (10-10-2015)
  *bugfix: factor makes a infinite loop when n <= 0
  +/bin/cscript: CubixScript [going to create a manual]!
  +/bin/glep: grep in lua!
  +SBL: now you can load a kernel manually!
  +/bin/cubix
    +added boot options, for now its just "quiet" and "nodebug".
    +NEW os.pprint, stands for "pipe print"
  +/sbin/init
    +runlevels (still working)
  +/bin/cshell: FINALLY, PIPES! ("ps | glep login" works)
0.3.0 - 0.3.1 (10-07-2015)
  +/bin/cshell: now has a history
  +/bin/wget
  +/bin/cubix: NEW os.safestr, os.strsplit
    +about init: now init has some control about how the system will load (just loads /sbin/login, but its a thing!)
  +/dev/random: not using os.time(), using os.clock() instead!
  +procmanager: calls to debug are being written to os.debug
0.2.1 - 0.3.0 (10-05-2015)
  -bugfix in cp, rn, mv, mkdir, touch (including the draft nano)... (string comparison, "s[1] == 'a'" does not work)
  -consistency fix on cat: opening a file and not closing it after use
  -cp: does not require absolute paths now!
  -su and sulogin: using os.runfile() now
  -cleanup: not using /bin/shell and /bin/wshell anymore!
  -/dev/MAKEDEV now creates /usr
  -login manager: add users and change password of a user
0.1.0a - 0.2.1 (by 09-30-2015)
  -proc_manager now can kill processes, including their children!
    -every program has to have its main(args) function defined!, it's a rule.
    -proc_manager runs this function when the process of a file is created and run(using os.run_process)
  -Manuals!, use man to run, following the syntax:
    -man <topic> <manual>
      -follows to /usr/manuals/topic/manual.man
    -man <manual>
      -follows to /usr/manuals/manual.man
EndFile;
File;dev/stdin
EndFile;
File;lib/comm_manager
#!/usr/bin/env lua
--comm_manager: communication and control manager
-- This manager makes communication between processes without files(resolving the /tmp/current_path issue)
local data = {}
local function local_register(proc_name, label, v)
    if v == nil then v = '' end
    if data[proc_name] == nil then
        data[proc_name] = {}
    end
    data[proc_name][label] = v
end
function register(process, label, h)
    local runningproc = os.lib.proc.get_processes()[os.getrunning()]
    if h == nil then h = '' end
    if runningproc == nil or runningproc == -1 then
        os.debug.debug_write("comm: no running process")
        return false
    end
    if runningproc.file == process then
        local_register(runningproc.file, label, h)
    elseif '/'..runningproc.file == process then
        local_register('/'..runningproc.file, label, h)
    else
        ferror("comm_manager: running process ~= process")
    end
end
function register_proof(proc, label, value)
    --prove to comm that even without running process, I am a process of myself
    if os.lib.proc.check_proof(proc) then
        local_register(proc.file, label, value)
    end
end
function get(process, label)
    if not data[process] then
        return nil
    end
    return data[process][label]
end
function libroutine()
end
EndFile;
File;lib/proc_manager
#!/usr/bin/env lua
--proc manager
--task: manage /proc, creating its special files;
--manage processes, threads and signals to processes.
RELOADABLE = false
--os.processes = {}
--secutiry fix
local processes = {}
os.pid_last = 0
local running = 0
os.signals = {}
os.signals.SIGKILL = 0
os.signals.SIGINT = 2
os.signals.SIGQUIT = 3
os.signals.SIGILL = 4 --illegal instruction
os.signals.SIGFPE = 8
os.signals.SIGTERM = 15 --termination
os.sys_signal = function (signal)
    --this just translates the recieved signal to a printable string
    local signal_str = ''
    if signal == os.signals.SIGILL then
        signal_str = 'Illegal instruction'
    elseif signal == os.signals.SIGFPE then
        signal_str = 'Floating Point Exception'
    end
    ferror(signal_str)
    return 0
end
os.call_handle = function(process, sig)
    program_env = {}
    program_env.__PS_SIGNAL = sig
    os.run(program_env, process.file)
end
os.send_signal = function (proc, signal)
    if proc == nil then
        os.ferror("proc.send_signal: process == nil")
    elseif proc == -1 then
        os.ferror("proc.send_signal: process was killed")
    elseif signal == os.signals.SIGKILL then
        os.debug.debug_write("[proc_manager] SIGKILL -> "..proc.file, false)
        processes[proc.pid] = -1 --removing anything related to the process in os.processes
        for k,v in pairs(proc.childs) do
            os.terminate(v)
        end
        os.terminate(proc)
    end
end
function __killallproc()
    for k,v in ipairs(processes) do
        if v ~= -1 then
            os.send_signal(v, os.signals.SIGKILL)
        end
    end
end
os.terminate = function (p)
    --os.call_handle(p, "kill")
    if p.pid == 1 then
        if CUBIX_TURNINGOFF or CUBIX_REBOOTING then
            return 0
        else
            os.shutdown()
        end
    end
    p = nil
    --os.sleep(1)
end
os.getrunning = function()
    return running
end
function generate_pfolder(proc, folder, arguments)
    --[[
    exe - executable
    stat - status
    status - status (human readable)
    ]]
    local exe_handler = fs.open(fs.combine(folder, 'exe'), 'w')
    exe_handler.write(proc.file)
    exe_handler.close()
    local stat_handler = fs.open(fs.combine(folder, 'stat'), 'w')
    stat_handler.write("stat working")
    stat_handler.close()
    local line_args = ''
    for k,v in ipairs(arguments) do
        line_args = line_args .. v .. ' '
    end
    local cmd_handler = fs.open(fs.combine(folder, 'cmd'), 'w')
    cmd_handler.write(proc.file..' '..line_args)
    cmd_handler.close()
end
os.run_process = function(process, arguments, pipe)
    --[[
    So, about the issue of non-compatibility with
    "CraftOS" designed programs with
    "Cubix" programs, mostly because of the main() function
    this new os.run_process is able to solve this
    all "Cubix" programs must run the main function by themselves,
    since I will use os.run to run them
    Issue #1: pipe does not work as old
    since the programs are  by os.run, the manager will not
    be able to comunicate
    ]]
    if arguments == nil then arguments = {} end
    --if pipe == nil then pipe = {} end
    os.debug.debug_write("[process]  "..process.file.." pid="..tostring(process.pid), false)
    permission.default()
    running = process.pid
    processes[process.pid] = process
    local cu = os.lib.login.currentUser()
    if cu == '' then
        process.user = 'root'
    else
        process.user = cu
    end
    local ctty = os.lib.tty.getcurrentTTY()
    if ctty == nil or ctty == {} or ctty == '' then
        process.tty = '/dev/ttde'
    else
        process.tty = ctty.id
    end
    local line_args = ''
    for k,v in ipairs(arguments) do
        line_args = line_args .. v .. ' '
    end
    process.lineargs = line_args
    local proc_folder = "/proc/"..tostring(process.pid)
    fs.makeDir(proc_folder)
    generate_pfolder(process, proc_folder, arguments)
    process.uid = os.lib.login.userUID()
    --_G['pipe'] = pipe
    os.run({pipe=pipe}, process.file, unpack(arguments,1))
    --finish process
    fs.delete(proc_folder)
    os.send_signal(process, os.signals.SIGKILL)
end
os.set_child = function(prnt, proc)
    prnt.childs[#prnt.childs + 1] = proc
end
os.set_parent = function(proc, parent)
    os.set_child(parent, proc)
    proc.parent = parent.file
end
os.new_process = function(executable)
    local cls = {}
    os.pid_last = os.pid_last + 1
    cls.pid = os.pid_last
    cls.file = executable
    cls.parent = nil
    cls.childs = {}
    cls.rfile = nil
    cls.uid = -1
    cls.lineargs = ''
    cls.user = ''
    cls.tty = ''
    os.debug.debug_write("[proc] new: "..cls.file, false)
    return cls
end
os.currentUID = function()
    local proc = processes[running]
    if proc == nil or proc == -1 then
        return nil
    else
        return proc.uid
    end
end
--executable: string
--arguments: table
--parent: process
--pipe: Pipe
os.runfile_proc = function(executable, arguments, parent, pipe)
    if parent == nil then
        _parent = os.__parent_init --making sure /sbin/init is parent of all processes(without parent)
    else
        _parent = parent
    end
    if arguments == nil then arguments = {} end
    --if pipe == nil then pipe = pipemngr.new_pipe("empty") end
    _process = os.new_process(executable) --creating
    os.set_parent(_process, _parent) --parenting
    os.run_process(_process, arguments, pipe) --running.
end
function get_processes()
    local c = deepcopy(processes)
    c['CPY_FLAG'] = true --copy flag
    return c
end
function get_by_pid(pid)
    --get a process by its PID(not of deepcopy, but the original process) with permission
    if permission.grantAccess(fs.perms.SYS)
     or processes[running].file == '/bin/cshell_rewrite'
     or processes[running].file == '/sbin/login'
     or processes[running].file == '/sbin/kill'
     or processes[running].file == 'sbin/kill' then
        return processes[pid]
    else
        ferror("get_by_pid: perm error")
    end
end
function check_proof(p)
    -- check if a process is a original one(not a copy)
    if p == processes[p.pid] then
        return true
    end
    return false
end
FLAG_CTTY = 0 --all processes in the same tty(the tty)
FLAG_ATTY = 1 --all process in all tty
FLAG_APRC = 2 --all process in the system
--filters processes by its flag
function filter_proc(filter_flag)
    if filter_flag == FLAG_CTTY then
        local ctty = os.lib.tty.getcurrentTTY()
        local filtered = {}
        for k,v in pairs(get_processes()) do
            if type(v) == 'table' then
                if v.tty == ctty.id then
                    filtered[v.pid] = v
                end
            end
        end
        return filtered
    elseif filter_flag == FLAG_ATTY or filter_flag == FLAG_APRC then
        local filtered = {}
        for k,v in pairs(get_processes()) do
            if type(v) == 'table' then
                filtered[v.pid] = v
            end
        end
        return filtered
    else
        ferror("proc.filter_proc: no flag")
        return nil
    end
end
function test_processes()
    p1 = os.new_process("/sbin/init")
    os.run_process(p1)
    os.send_signal(p1, os.signals.SIGKILL)
end
--test_processes()
cinfo = [[processor       : 0
vendor_id       : ComputerCraft
cpu family      : -1
model           : 17
model name      : ComputerCraft CraftCPU @ TickGHZ
stepping        : 0
microcode       : 0x17
cpu MHz         : 1
cache size      : 0 KB
physical id     : 0
siblings        : 1
core id         : 0
cpu cores       : 1
apicid          : 0
initial apicid  : 0
fpu             : yes
fpu_exception   : yes
cpuid level     : -1
wp              : yes
flags           : fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx rdtscp lm constant_tsc arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc aperfmperf eagerfpu pni pclmulqdq dtes64 monitor ds_cpl vmx est tm2 ssse3 cx16 xtpr pdcm pcid sse4_1 sse4_2 x2apic popcnt tsc_deadline_timer xsave avx f16c rdrand lahf_lm ida arat epb xsaveopt pln pts dtherm tpr_shadow vnmi flexpriority ept vpid fsgsbase smep erms
bogomips        : 0
clflush size    : 0
cache_alignment : 32
address sizes   : 36 bits physical, 48 bits virtual
power management:
]]
function CPUINFO()
    return cinfo
end
cpuinfo_file = {}
cpuinfo_file.name = "/proc/cpuinfo"
cpuinfo_file.file = {}
cpuinfo_file.file.write = function(data)
    os.ferror("cannot write to /proc/cpuinfo")
end
cpuinfo_file.file.read = function(bytes)
    if bytes == nil then
        return CPUINFO()
    else
        return string.sub(CPUINFO(), 0, bytes)
    end
end
temperature_file = {}
temperature_file.name = "/proc/temperature"
temperature_file.file = {}
temperature_file.file.write = function(data)
    os.ferror("cannot write to /proc/temperature")
end
temperature_file.file.read = function(bytes)
    return 'computer: 30C'
end
partitions_file = {}
partitions_file.name = "/proc/partitions"
partitions_file.file = {}
partitions_file.file.write = function(data)
    os.ferror("cannot write to /proc/partitions")
end
partitions_file.file.read = function(bytes)
    k = [[major minor  #blocks name
8      0      1024876  hdd]]
    if bytes == nil then
        return k
    else
        return string.sub(k, 0, bytes)
    end
end
function libroutine()
    os.internals._kernel.register_mfile(cpuinfo_file)
    os.internals._kernel.register_mfile(temperature_file)
    os.internals._kernel.register_mfile(partitions_file)
end
EndFile;
File;FINISHINSTALL
_G['shell'] = shell
os.loadAPI("/dev/MAKEDEV")
EndFile;
File;boot/sblcfg/systems.cfg
Cubix;/boot/sblcfg/cubixboot
Cubix(luaX);/boot/sblcfg/cubixlx
Cubix(quiet,nodebug);/boot/sblcfg/cubixquiet
CraftOS;/boot/sblcfg/craftos
Boot Disk;/boot/sblcfg/bootdisk
EndFile;
File;startup
#!/usr/bin/env lua
--load SBL
_G['shell'] = shell
term.set_term_color = function (c)
    if term.isColor() then
        term.setTextColor(c)
    end
end
if fs.exists('/boot/sbl') then
    print("mbr: loading sbl.")
    os.run({}, "/boot/sbl")
else
    term.set_term_color(colors.red)
    print("error: sbl not found")
    term.set_term_color(colors.white)
    return 0
end
EndFile;
File;lib/devices/zero_device.lua
#!/usr/bin/env lua
--zero_device.lua
function safestr(s)
    if string.byte(s) > 191 then
        return '#'
    end
    return s
end
dev_zero = {}
dev_zero.name = '/dev/zero'
dev_zero.device = {}
dev_zero.device.device_read = function (bytes)
    if bytes == nil then
        return 0
    else
        result = ''
        for i = 0, bytes do
            result = result .. safestr(0)
        end
        return result
    end
    return 0
end
dev_zero.device.device_write = function(s)
    os.sys_signal(os.signals.SIGILL)
    return 0
end
EndFile;
File;bin/mv
#!/usr/bin/env lua
--/bin/mv: move files or folders
_handler = {}
_handler.signal_handler = function(sig)
    if sig == 'kill' then
        --print("mv: SIGKILL")
        return 0
    end
end
function main(args)
    if #args == 0 then
        print("usage: mv <file> <destination>")
    end
    local from, to = args[1], args[2]
    if fs.exists(os.cshell.resolve(from)) then
        fs.move(os.cshell.resolve(from), os.cshell.resolve(to))
    else
        os.ferror("mv: input node does not exist")
        return 1
    end
    return 0
end
main({...})
EndFile;
File;bin/touch
#!/usr/bin/env lua
--/bin/touch: creates empty files
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        --print("touch: recieved SIGKILL")
        return 0
    end
end
function main(args)
    local d = os.cshell.resolve(args[1])
    if not fs.exists(d) then
        fs.open(d, 'w').close()
    end
end
main({...})
EndFile;
File;proc/76/cmd
src/base-pkg/makeyap 
EndFile;
File;LICENSE
Copyright (c) 2014-2015 Tsarev Nikita
Copyright (c) 2015-2016 Lukas Mendes
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
EndFile;
File;dev/mouse
EndFile;
File;src/base-pkg/makefile
#default target
d base
# base target
t base,:
w WARN_VERBOSE
c rm /tmp/syslog && touch /tmp/syslog
c rm /dev/hda/CFSDATA
c yapi -Syc
c makeyap
c sync
end-target;
# Submit target, default to all packages
t submit,base:
v :PKGNAME
c echo ;Package name for your base.yap?
r :PKGNAME
v :USR
c echo ;Username:
r :USR
v :USRPWD
c echo ;Password:
r :USRPWD
l USR,USRPWD
vc pkgsend auth $;$
l PKGNAME
vc pkgsend send base.yap $ vote-community
end-target;
#Clean target
t clean,:
c rm base.yap
end-target;
#redo build
t rebuild,clean,base:
end-target;
EndFile;
File;dev/tty8
EndFile;
File;usr/manuals/yapi.man
!cmfl!
.name
yapi - Yet Another Package Installer
.cmd
yapi <MODE> [...]
.desc
yapi - The default package management system in cubix.
.listop MODE
    -S <pkg1 pkg2 ...>
        installs packages
    -U <file>
        installs <file> as a YAP file
    -Q <package>
        queries the database to show details of a package
    -R <pkg1 pkg2 ...>
        removes packages
.e
.m
Options applied to -S(in order they're applied)
    c
        clears yapi cache
    y
        updates yapi database
    u
        updates all installed packages
.e
.m
Options applied to -Q
    e
        shows all installed packages and their builds
.e
EndFile;
File;bin/hwclock
#!/usr/bin/env lua
--/bin/hwclock: """"hardware"""" clock
_handler = {}
_handler.signal_handler = function(sig)
    if sig == 'kill' then
        --print("hwclock: SIGKILL")
        return 0
    end
end
function main(args)
    print(textutils.formatTime(tonumber(os.time()), false))
end
main({...})
EndFile;
File;lib/luaX/lxMouse.lua
--[[while true do
  local event, button, x, y = os.pullEvent( "mouse_click" )
  print( "The mouse button ", button, " was pressed at ", x, " and ", y )
end
]]
EndFile;
File;bin/uname
#!/usr/bin/env lua
--/bin/uname: system information
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        --print("uname: recieved SIGKILL")
        return 0
    end
end
function main(args)
    local argmt = args[1]
    local fpcid = fs.open("/var/pcid", 'r')
    local fversion = fs.open("/proc/version", 'r')
    local fbuilddate = fs.open("/proc/build_date", 'r')
    local PC_ID = fpcid.readAll()
    local VERSION = fversion.readAll()
    local BUILD_DATE = fbuilddate.readAll()
    fpcid.close()
    fversion.close()
    fbuilddate.close()
    function uname(arg)
        args = {0, arg}
        if args == nil then
            return 'Cubix'
        elseif args[2] == '-a' then
            return 'Cubix '..PC_ID..' v'..VERSION..'-ccraft  Cubix '..VERSION..' ('..BUILD_DATE..') x86 Cubix'
        elseif args[2] == '-s' then
            return 'Cubix'
        elseif args[2] == '-n' then
            return PC_ID
        elseif args[2] == '-r' then
            return VERSION..'-ccraft'
        elseif args[2] == '-v' then
            return 'Cubix '..VERSION..' ('..BUILD_DATE..')'
        elseif args[2] == '-m' then
            return 'x86'
        elseif args[2] == '-p' then
            return 'unknown'
        elseif args[2] == '-i' then
            return 'unknown'
        elseif args[2] == '-o' then
            return 'Cubix'
        else
            return 'Cubix'
        end
    end
    print(uname(argmt))
end
main({...})
EndFile;
File;boot/sblcfg/default.cfg
Cubix;/boot/sblcfg/cubixboot
Cubix(luaX);/boot/sblcfg/cubixlx
Cubix(quiet,nodebug);/boot/sblcfg/cubixquiet
CraftOS;/boot/sblcfg/craftos
Boot Disk;/boot/sblcfg/bootdisk
EndFile;
File;etc/hostname
cubix
EndFile;
File;proc/76/exe
src/base-pkg/makeyap
EndFile;
File;bin/dd
#!/usr/bin/env lua
--/bin/dd
--TODO: support for devices
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        --print("dd: recieved SIGKILL")
        return 0
    end
end
function main(args)
    local infile = os.cshell.resolve(args[1])
    local outfile = os.cshell.resolve(args[2])
    local bytes = tonumber(args[3])
    local bs = 0
    if args[4] then
        bs = tonumber(args[4])
    else
        bs = 1
    end
    if infile == nil or outfile == nil or bytes == nil then
        print("usage: dd infile outfile bytes [bs]")
        return 0
    end
    local data = {}
    local DEVICES = os.list_devices
    if DEVICES[infile] ~= nil then
        local cache = DEVICES[infile].device_read(bs*bytes)
        for i=0, #cache do
            table.insert(data, string.byte(string.sub(cache, i, i)))
        end
    else
        local h = fs.open(infile, 'rb')
        for i=0, bs*bytes do
            table.insert(data, h.read())
        end
        h.close()
    end
    local o = fs.open(outfile, 'wb')
    if o == nil then
        ferror("dd: error opening file")
        return false
    end
    for i=0, bs*bytes do
        o.write(data[i])
    end
    o.close()
    return true
end
main({...})
EndFile;
File;proc/build_date
2016-03-05
EndFile;
File;bin/lua
#!/usr/bin/env lua
--/bin/lua: lua interpreter (based on the rom interpreter)
_handler = {}
_handler.signal_handler = function(sig)
    if sig == 'kill' then
        os.debug.debug_write("lua: recieved SIGKILL", false, true)
        return 0
    end
end
function main(args)
    local tArgs = args
    if #tArgs > 0 then
    	print( "This is an interactive Lua prompt." )
    	print( "To run a lua program, just type its name." )
    	return
    end
    local bRunning = true
    local tCommandHistory = {}
    local tEnv = {
    	["exit"] = function()
    		bRunning = false
    	end,
    	["_echo"] = function( ... )
    	    return ...
    	end,
    }
    setmetatable( tEnv, { __index = _ENV } )
    if term.isColour() then
    	term.setTextColour( colours.yellow )
    end
    print( "Interactive Lua prompt." )
    print( "Call exit() to exit." )
    term.setTextColour( colours.white )
    while bRunning do
    	--if term.isColour() then
    	--	term.setTextColour( colours.yellow )
    	--end
    	write("> ")
    	--term.setTextColour( colours.white )
    	local s = read( nil, tCommandHistory, function( sLine )
    	    local nStartPos = string.find( sLine, "[a-zA-Z0-9_%.]+$" )
    	    if nStartPos then
    	        sLine = string.sub( sLine, nStartPos )
    	    end
    	    if #sLine > 0 then
                return textutils.complete( sLine, tEnv )
            end
            return nil
    	end )
    	table.insert( tCommandHistory, s )
    	local nForcePrint = 0
    	local func, e = load( s, "lua", "t", tEnv )
    	local func2, e2 = load( "return _echo("..s..");", "lua", "t", tEnv )
    	if not func then
    		if func2 then
    			func = func2
    			e = nil
    			nForcePrint = 1
    		end
    	else
    		if func2 then
    			func = func2
    		end
    	end
    	if func then
            local tResults = { pcall( func ) }
            if tResults[1] then
            	local n = 1
            	while (tResults[n + 1] ~= nil) or (n <= nForcePrint) do
            	    local value = tResults[ n + 1 ]
            	    if type( value ) == "table" then
                	    local ok, serialised = pcall( textutils.serialise, value )
                	    if ok then
                	        print( serialised )
                	    else
                	        print( tostring( value ) )
                	    end
                	else
                	    print( tostring( value ) )
                	end
            		n = n + 1
            	end
            else
            	printError( tResults[2] )
            end
        else
        	printError( e )
        end
    end
end
main({...})
EndFile;
File;var/yapi/installedpkg
base;51
EndFile;
File;bin/license
#!/usr/bin/env lua
--/bin/license: how cubix license
_handler = {}
_handler.signal_handler = function(sig)
    if sig == 'kill' then
        --print("license: SIGKILL")
        return 0
    end
end
function main(args,pipe)
    local h = fs.open("/LICENSE", 'r')
    print(h.readAll())
    h.close()
    return 0
end
main({...})
EndFile;
File;bin/glep
#!/usr/bin/env lua
--/bin/glep: port of ClamShell's glep to Cubix (http://github.com/Team-CC-Corp/ClamShell)
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        --print("glep: recieved SIGKILL")
        return 0
    end
end
function work_files(pattern, files)
    local RFiles = {}
    for k,v in pairs(files) do
        RFiles[k] = fs.open(v, 'r')
    end
    for i, fh in pairs(RFiles) do
        while true do
            local line = fh.readLine()
            if not line then break end
            if line:find(pattern) then
                print(line)
            end
        end
        fh.close()
    end
end
function work_pipe(pat, pipe)
    local k = os.lib.pipe.Pipe.copyPipe(pipe)
    pipe:flush()
    while true do
        local line = k:readLine()
        if not line or line == nil then break end
        local K = line:find(pat)
        if K ~= nil then
            os.pprint(line, pipe, true)
        end
    end
end
function main(args, pipe)
    function tail(t)
       if # t <= 1 then
          return nil
       end
       local newtable = {}
       for i, v in ipairs(t) do
          if i > 1 then
              table.insert(newtable, v)
          end
       end
       return newtable
    end
    if #args == 0 then
        print("usage: glep <pattern> <files>")
        print("usage(pipe): glep <pattern>")
        return 0
    end
    if pipe ~= nil then
        --print("recieved pipe")
        local pattern = args[1]
        work_pipe(pattern, pipe)
    else
        local pattern, files = args[1], tail(args)
        work_files(pattern, files)
    end
    return 0
end
main({...})
EndFile;
File;dev/loop2
EndFile;
File;g/lxterm/lxterm.lxw
#LXW data for lxTerm
# maximum is 19x51
name:lxterm
hw:9,30
changeable:false
main:/g/lxterm/lxterm.lua
EndFile;
File;bin/cscript
#!/usr/bin/env lua
--/bin/cscript: CubixScript
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        --print("cscript: recieved SIGKILL")
        return 0
    end
end
--$("echo ;Hello World!")
function parseCommand(cmd)
    local _k = cmd:find('"')
    local command = string.sub(cmd, _k, #cmd-2)
    os.cshell.__shell_command(command)
end
function parseEcho(cmd)
    local _k = string.sub(cmd, 1, #cmd)
    print(cmd)
end
function main(args)
    local file = args[1]
    if file == nil then
        print("usage: cscript <file>")
        return 0
    end
    local _h = fs.open("/tmp/current_path", 'r')
    local CPATH = _h.readAll()
    _h.close()
    local fh = {}
    if string.sub(file, 0, 1) == '/' then
        fh = fs.open(file, 'r')
    elseif fs.exists(fs.combine(CPATH, file)) then
        fh = fs.open(fs.combine(CPATH, file), 'r')
    else
        os.ferror("cscript: file not found")
        return 0
    end
    local fLines = {}
    local F = fh.readAll()
    local K = os.strsplit(F, "\n")
    for k,v in pairs(K) do
        fLines[k] = v
    end
    fh.close()
    for k,v in pairs(fLines) do
        if string.sub(v, 0, 1) == '$' then
            parseCommand(v)
        elseif string.sub(v, 0, 1) == '!' then
            parseEcho(v)
        elseif string.sub(v, 0, 1) == '#' then
            parseRootCommand(v)
        end
    end
end
main({...})
EndFile;
File;lib/time
#!/usr/bin/env lua
--time: manages time calls
local fallback2 = "http://luca.spdns.eu/time.php"
local fallback1 = 'http://www.timeapi.org/utc/now?format=%7B%25d%2C%25m%2C%25Y%2C%25H%2C%25M%2C%25S%7D'
local servers = {}
local function readServers()
    local ts_file = fs.open("/etc/time-servers", 'r')
    local ts_data = ts_file.readAll()
    ts_file.close()
    servers = {}
    local data = os.strsplit(ts_data, '\n')
    for k,v in ipairs(data) do
        table.insert(servers, v)
    end
    table.insert(servers, fallback1)
    table.insert(servers, fallback2)
end
local function getTimeData()
    local res = ''
    for k,v in pairs(servers) do
        os.debug.debug_write("[time] getting time data from "..v, false)
        local s = http.get(v)
        if s ~= nil then
            local d = s.readAll()
            s.close()
            if d ~= nil then
                return d
            else
                os.debug.debug_write("getTimeData: d == nil", true, true)
            end
        else
            os.debug.debug_write("getTimeData: s == nil", true, true)
        end
    end
    return nil
end
function getTime_fmt(_tZoneH, _tZoneM)
    readServers()
    local tZoneH = _tZoneH or 0
    local tZoneM = _tZoneM or 0
    local d = getTimeData()
    if d == nil then
        os.debug.debug_write("getTime_fmt: getTimeData returned nil, returning time zero", true, true)
        return {0,0,0,0,0,0,0}
    end
    local t = textutils.unserialise(d)
    local gh = t[4]
    local gm = t[5]
    local s = t[6]
    local m = gm + tZoneM
    local h = gh + tZoneH + math.floor(m/60)
    local m = m%60
    h = h%24
    return {h,m,s}
end
function localtime(tz1, tz2)
    local k = getTime_fmt(tz1, tz2)
    return {hours=k[1], minutes=k[2], seconds=k[3]}
end
function asctime(tm)
    local h,m,s = tm.hours, tm.minutes, tm.seconds
    local formatted = string.format("%2d:%2d:%2d",h,m,s):gsub(" ","0")
    return formatted
end
function strtime(tz1, tz2)
    return asctime(localtime(tz1,tz2))
end
function libroutine()
    os.debug.debug_write("[time] testing time")
    os.debug.debug_write("[time] GMT -3: "..asctime(localtime(-3,0)))
    os.debug.debug_write("[time] Greenwich: "..strtime())
end
EndFile;
File;proc/sttime
23.049
EndFile;
File;dev/zero
EndFile;
File;proc/version
0.5.1
EndFile;
File;lib/devices/null_device.lua
dev_null = {}
dev_null.name = '/dev/null'
dev_null.device = {}
dev_null.device.device_read = function (bytes)
    print("cannot read from /dev/null")
end
dev_null.device.device_write = function(s)
    return 0
end
EndFile;
File;cubix_live_installer
#!/usr/bin/env lua
--cubix_live_installer(cubixli): starts a enviroment where the user can install cubix
AUTHOR = "Lukas Mendes"
VERSION = "0.1.0"
BUILD_DATE = "2016-01-26"
--[[
    The Cubix Live Installer has the basic utilities to install cubix
    It has these Arch Linux vibe going on so, yeah
    CubixLI has everything in one script: a shell, a downloader to install cubix, setting label, hostname and so on
    pastebin: B1t3L4Uw
]]
function do_halt()
    while true do sleep(0) end
end
tail = function(t)
       if # t <= 1 then
          return nil
       end
       local newtable = {}
       for i, v in ipairs(t) do
          if i > 1 then
              table.insert(newtable, v)
          end
       end
       return newtable
end
strsplit = function (inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    if inputstr == nil then
        return ''
    end
    local t={} ; i=1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        t[i] = str
        i = i + 1
    end
    return t
end
viewtable = function (t)
    print(t)
    for k,v in pairs(t) do
        print(k..","..tostring(v).." ("..type(v)..")")
    end
end
function _prompt(message, yes, nope)
    write(message..'['..yes..'/'..nope..'] ')
    local result = read()
    if result == yes then
        return true
    else
        return false
    end
end
prompt = _prompt
term.set_term_color = function (c)
    if term.isColor() then
        term.setTextColor(c)
    end
end
function ferror(msg)
    term.set_term_color(colors.red)
    print(msg)
    term.set_term_color(colors.white)
end
function normal(msg)
    term.set_term_color(colors.yellow)
    print(msg)
    term.set_term_color(colors.white)
end
function load_env()
    normal("[cubixli:load_screen]")
    term.clear()
    term.setCursorPos(1,1)
    normal("[cubixli:load_disk]")
    print("[cubixli:main->run_shell]")
end
local current_path = '/'
local current_envir = ''
local current_disks = {
    hdd = {
        {"hdd", "part", "/"}
    },
    cubixli_ramdisk = {
        {"edev", "edevfs", "./dev"},
        {"cbxli", "cbxlifs", "./cbxli"}
    }
}
local override = false
function cubixli_delete_disk(args)
    local disk = args[1]
    if disk == 'hdd' or disk == '/' then
        normal("[cubixli:delete_disk] wiping hdd")
        for k,v in pairs(fs.list('/'))do
            if v ~= 'rom' then
                fs.delete(v)
            end
        end
    elseif disk == 'cubixli_ramdisk' or disk == 'cbxli' or disk == 'emudev' then
        if not override then
            ferror("cubixli_delete_disk: perm_error formatting "..disk)
            return 1
        else
            ferror("[HALT_ERROR] cubixli needs a manual reboot. (ctrl+r btw)")
            do_halt()
        end
    else
        ferror("cubixli_delete_disk: error getting disk")
        return 1
    end
    return 0
end
_G['cubixli_delete_disk'] = cubixli_delete_disk
function cubixli_call(func, args)
    if current_envir ~= 'cubixli' then
        ferror("cubixli_call: cubixli env not loaded")
        return false
    end
    normal("[cubix:"..func.."]")
    local result = _G['cubixli_'..func](args)
    if result == 0 then return true end
    return false
end
--deldisk util
function deldisk(args)
    if #args == 0 then print("usage: deldisk <disk>") return 0 end
    if _prompt("Do you want to delete your disk?", "Y", "n") then
        if cubixli_call("delete_disk", args) then
            print("deldisk: deleted /")
        else
            ferror("deldisk: error doing delete_disk")
        end
    else
        return 0
    end
end
--lsblk binary
function lsblk()
    for k,vl in pairs(current_disks) do
        write(k..':\n')
        for _, v in pairs(vl) do
            write("  "..v[1].." type "..v[2].." mounted in "..v[3]..'\n')
        end
    end
    write('\n')
    return 0
end
--yapstrap binary
function run_build_hook(hook)
    if hook == 'initramfs' then
        if os.loadAPI("/boot/libcubix") then
            libcubix.generate_lcubix('all', '/boot/cubix-initramfs')
        else
            ferror("error loading libcubix.")
        end
    else
        ferror("build hook not found")
    end
end
function yapstrap(args)
    if current_envir ~= 'cubixli' then
        ferror("yapstrap: cubixli env not loaded")
        return 1
    end
    if #args == 0 then print("usage: yapstrap <task>") return 0 end
    for k,v in pairs(args) do
        if v == 'cubix' then
            shellcmd("yapi -Sy")
            shellcmd("yapi -S base")
            shell.run("FINISHINSTALL")
            local handler = fs.open("/tmp/install_lock", 'w')
            handler.close()
            normal("created /tmp/install_lock")
            normal("running build hook: initramfs")
            run_build_hook('initramfs')
            normal("yapstrap: finished "..v.." task")
        end
    end
    return 0
end
--ls binary
local chars = {}
for i = 32, 126 do chars[string.char(i)] = i end
local function sortingComparsion(valueA, valueB)
    local strpos = 0
    local difference = 0
    while strpos < #valueA and strpos < #valueB and difference == 0 do
        strpos = strpos + 1
        if chars[string.sub(valueA, strpos, strpos)] > chars[string.sub(valueB, strpos, strpos)] then
            difference = 1
        elseif chars[string.sub(valueA, strpos, strpos)] < chars[string.sub(valueB, strpos, strpos)] then
            difference = -1
        end
    end
    if difference == -1 then
        return true
    else
        return false
    end
end
function _ls(pth)
    local nodes = fs.list(pth)
    local files = {}
    local folders = {}
    for k,v in ipairs(nodes) do
        if fs.isDir(pth..'/'..v) then
            table.insert(folders, v)
        else
            table.insert(files, v)
        end
    end
    table.sort(folders, sortingComparsion)
    table.sort(files, sortingComparsion)
    --printing folders
    term.set_term_color(colors.green)
    for k,v in ipairs(folders) do
        write(v..' ')
    end
    term.set_term_color(colors.white)
    --printing files
    for k,v in ipairs(files) do
        write(v..' ')
    end
    write('\n')
end
function ls(args)
    local p = args[1]
    if p == nil then
        _ls(current_path)
    elseif fs.exists(p) then
        _ls(p)
    elseif fs.exists(fs.combine(current_path, p)) then
        _ls(fs.combine(current_path, p))
    end
end
--cd binary
function pth_goup(p)
    elements = strsplit(p, '/')
    res = ''
    for i = 1, (#elements - 1) do
        print(res)
        res = res .. '/' .. elements[i]
    end
    return res
end
function _cd(pth)
    local CURRENT_PATH = current_path
    if CURRENT_PATH == nil then
        CURRENT_PATH = '/'
    elseif pth == '.' then
        CURRENT_PATH = CURRENT_PATH
    elseif pth == '..' then
        CURRENT_PATH = pth_goup(CURRENT_PATH)
    elseif pth == '/' then
        CURRENT_PATH = pth
    elseif fs.exists(CURRENT_PATH .. '/' .. pth) == true then
        CURRENT_PATH = CURRENT_PATH .. '/' .. pth
    elseif fs.exists(pth) == true then
        CURRENT_PATH = pth
    elseif pth == nil then
        --CURRENT_PATH = "/home/"..current_user
    else
        print("cd: not found!")
    end
    return CURRENT_PATH
end
function cd(args)
    local pth = args[1]
    local npwd = _cd(pth)
    current_path = npwd
end
--"cat"ing
function cat(args)
    if #args == 0 then print("usage: cat <absolute path>") return 0 end
    local file = args[1]
    if fs.exists(file) then
        local f = fs.open(file, 'r')
        local data = f.readAll()
        f.close()
        print(data)
        return 0
    else
        ferror("cat: file not found")
        return 1
    end
end
--interface for rebooting
function front_reboot(args)
    if current_envir == 'cubixli' then
        ferror("front_reboot: cannot reboot with cubixli enviroment loaded, please use unloadenv")
        return 1
    end
    print("[cubixli:front_reboot] sending RBT")
    os.sleep(1.5)
    os.reboot()
end
--interface for "shutdowning"
function front_shutdown(args)
    if current_envir == 'cubixli' then
        ferror("front_shutdown: cannot reboot with cubixli enviroment loaded, please use unloadenv")
        return 1
    end
    print("[cubixli:front_shutdown] sending HALT")
    os.sleep(1.5)
    os.shutdown()
end
--set label
function setlabel(args)
    if #args == 0 then print("usage: setlabel <newlabel>") return 0 end
    os.setComputerLabel(tostring(args[1]))
end
--version of cubixLI
function version()
    print("CubixLI "..VERSION.." in "..BUILD_DATE)
end
--load enviroment for cubix to start
function loadenviroment(args)
    if #args == 0 then return 0 end
    normal("[cubixli:loadenviroment] loading "..tostring(args[1]))
    current_envir = tostring(args[1])
end
--unload enviroment
function unloadenv()
    normal("[cubixli:unloadenv] unloading current enviroment ")
    current_envir = ''
end
--sethostname binary
function sethostname(args)
    if current_envir ~= 'cubixli' then
        ferror("sethostname: cubixli enviroment not loaded")
        return 1
    end
    local nhostname = tostring(args[1])
    normal("[cubixli:sethostname] setting hostname to "..nhostname)
    local hostname_handler = fs.open("/etc/hostname", 'w')
    hostname_handler.write(nhostname)
    hostname_handler.close()
    return 0
end
function sbl_bcfg(args)
    local default = fs.open("/boot/sblcfg/default.cfg", 'r')
    local systems = fs.open("/boot/sblcfg/systems.cfg", 'w')
    systems.write(default.readAll())
    default.close()
    systems.close()
    print("sbl-bcfg: systems.cfg restored to default.cfg")
end
function timesetup(args)
    local timeservers = fs.open("/etc/time-servers", 'w')
    for k,v in ipairs(args) do
        timeservers.write(v..'\n')
    end
    timeservers.close()
end
--install help
function insthelp()
    print([[
Installing cubix:
    loadenv cubixli
    lsblk
    deldisk hdd
    yapstrap cubix
    genfstab /etc/fstab
    setlabel <your label here>
    sethostname <your hostname here>
    timesetup <server 1> <server 2> ...
    sbl-bcfg
    unloadenv
    reboot
]])
    return 0
end
function runpath(args)
    --PLEASE DONT USE THIS
    os.run({}, args[1], unpack(tail(args)))
end
function override_shell()
    write("command to run with override=true: ")
    local cmd = read()
    override = true
    shellcmd(cmd)
    override = false
    return 0
end
function genfstab(args)
    local file = args[1]
    local fh = fs.open(file, 'w')
    --device;mountpoint;fs;options;\n
    fh.write("/dev/hda;/;cfs;;\n")
    fh.write("/dev/loop1;/dev/shm;tmpfs;;\n")
    fh.close()
    print("genfstab: generated fstab in "..file)
end
os.tail = function(t)
    if # t <= 1 then
        return nil
    end
    local newtable = {}
    for i, v in ipairs(t) do
        if i > 1 then
            table.insert(newtable, v)
        end
    end
    return newtable
end
os.strsplit = function (inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    if type(inputstr) ~= 'string' then
        os.ferror("os.strsplit: type(inputstr) == "..type(inputstr))
        return 1
    end
    if inputstr == nil then
        return ''
    end
    local t={} ; i=1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        t[i] = str
        i = i + 1
    end
    return t
end
os.ferror = ferror
function yapi(args)
    if current_envir ~= 'cubixli' then
        ferror("yapi: cannot run without cubixli enviroment loaded")
        return 1
    end
    VERSION = '0.1.1'
    --defining some things
    local SERVERIP = 'lkmnds.github.io'
    local SERVERDIR = '/yapi'
    local YAPIDIR = '/var/yapi'
    function download_file(url)
        local cache = os.strsplit(url, '/')
        local fname = cache[#cache]
        print('requesting ' .. fname)
        http.request(url)
        local req = true
        while req do
            local e, url, stext = os.pullEvent()
            if e == 'http_success' then
                local rText = stext.readAll()
                stext.close()
                return rText
            elseif e == 'http_failure' then
                req = false
                return {false, 'http_failure'}
            end
        end
    end
    function success(msg)
        term.set_term_color(colors.green)
        print(msg)
        term.set_term_color(colors.white)
    end
    function cache_file(data, filename)
        local h = fs.open(YAPIDIR..'/cache/'..filename, 'w')
        h.write(data)
        h.close()
        return 0
    end
    function isin(inputstr, wantstr)
        for i = 1, #inputstr do
            local v = string.sub(inputstr, i, i)
            if v == wantstr then return true end
        end
        return false
    end
    function create_default_struct()
        fs.makeDir(YAPIDIR.."/cache")
        fs.makeDir(YAPIDIR.."/db")
        fs.open(YAPIDIR..'/installedpkg', 'a').close()
    end
    function update_repos()
        --download core, community and extra
        local SPATH = 'http://'.. SERVERIP .. SERVERDIR .. '/database/core'
        local k = download_file(SPATH)
        if type(k) == 'table' then
            ferror("yapi: http error")
            return 1
        end
        local _h = fs.open(YAPIDIR..'/db/core', 'w')
        _h.write(k)
        _h.close()
        local SPATH = 'http://'.. SERVERIP .. SERVERDIR .. '/database/community'
        local k = download_file(SPATH)
        if type(k) == 'table' then
            ferror("yapi: http error")
            return 1
        end
        local _h = fs.open(YAPIDIR..'/db/community', 'w')
        _h.write(k)
        _h.close()
        local SPATH = 'http://'.. SERVERIP .. SERVERDIR .. '/database/extra'
        local k = download_file(SPATH)
        if type(k) == 'table' then
            ferror("yapi: http error")
            return 1
        end
        local _h = fs.open(YAPIDIR..'/db/extra', 'w')
        _h.write(k)
        _h.close()
    end
    --Yapi Database
    yapidb = {}
    yapidb.__index = yapidb
    function yapidb.new(path)
        local inst = {}
        setmetatable(inst, yapidb)
        inst.path = path
        inst.db = ''
        return inst
    end
    function yapidb:update()
        self.db = ''
        self.db = self.db .. '\n'
        local h = fs.open(self.path..'/core', 'r')
        local _k = h.readAll()
        self.db = self.db .. _k
        h.close()
        self.db = self.db .. '\n'
        local h = fs.open(self.path..'/community', 'r')
        local _k = h.readAll()
        self.db = self.db .. '\n'
        self.db = self.db .. _k
        h.close()
        self.db = self.db .. '\n'
        local h = fs.open(self.path..'/extra', 'r')
        local _k = h.readAll()
        self.db = self.db .. '\n'
        self.db = self.db .. _k
        self.db = self.db .. '\n'
        h.close()
    end
    function yapidb:search(pkgname)
        self:update()
        local _lines = self.db
        local lines = os.strsplit(_lines, '\n')
        for k,v in pairs(lines) do
            local pkgdata = os.strsplit(v, ';')
            if pkgdata[1] == pkgname then
                return {true, v}
            end
        end
        return {false, nil}
    end
    function yapidb:search_wcache(pkgname)
        self:update()
        if fs.exists(YAPIDIR..'/cache/'..pkgname..'.yap') then
            local h = fs.open(YAPIDIR..'/cache/'..pkgname..'.yap', 'r')
            local f = h.readAll()
            h.close()
            return f
        else
            local _url = self:search(pkgname)
            local url = os.strsplit(_url[2], ';')[2]
            local yapdata = download_file(url)
            if type(yapdata) == 'table' then return -1 end
            cache_file(yapdata, pkgname..'.yap')
            return yapdata
        end
    end
    --parsing yap files
    function parse_yap(yapf)
        local lines = os.strsplit(yapf, '\n')
        local yapobject = {}
        yapobject['folders'] = {}
        yapobject['files'] = {}
        yapobject['deps'] = {}
        if type(lines) ~= 'table' then
            os.ferror("::! [parse_yap] type(lines) ~= table")
            return 1
        end
        local isFile = false
        local rFile = ''
        for _,v in pairs(lines) do
            if isFile then
                local d = v
                if d ~= 'EndFile;' then
                    if yapobject['files'][rFile] == nil then
                        yapobject['files'][rFile] = d .. '\n'
                    else
                        yapobject['files'][rFile] = yapobject['files'][rFile] .. d .. '\n'
                    end
                else
                    isFile = false
                    rFile = ''
                end
            end
            local splitted = os.strsplit(v, ';')
            if splitted[1] == 'Name' then
                yapobject['name'] = splitted[2]
            elseif splitted[1] == 'Version' then
                yapobject['version'] = splitted[2]
            elseif splitted[1] == 'Build' then
                yapobject['build'] = splitted[2]
            elseif splitted[1] == 'Author' then
                yapobject['author'] = splitted[2]
            elseif splitted[1] == 'Email-Author' then
                yapobject['email_author'] = splitted[2]
            elseif splitted[1] == 'Description' then
                yapobject['description'] = splitted[2]
            elseif splitted[1] == 'Folder' then
                table.insert(yapobject['folders'], splitted[2])
            elseif splitted[1] == 'File' then
                isFile = true
                rFile = splitted[2]
            elseif splitted[1] == 'Dep' then
                table.insert(yapobject['deps'], splitted[2])
            end
        end
        return yapobject
    end
    function yapidb:installed_pkgs()
        local handler = fs.open(YAPIDIR..'/installedpkg', 'r')
        local file = handler.readAll()
        handler.close()
        local lines = os.strsplit(file, '\n')
        return lines
    end
    function yapidb:is_installed(namepkg)
        local installed = self:installed_pkgs()
        for k,v in ipairs(installed) do
            local splitted = os.strsplit(v, ';')
            if splitted[1] == namepkg then return true end
        end
        return false
    end
    function yapidb:updatepkgs()
        self:update()
        for k,v in pairs(self:installed_pkgs()) do
            local pair = os.strsplit(v, ';')
            local w = self:search(pair[1])
            local yd = {}
            if w[1] == false then
                os.ferror("::! updatepkgs: search error")
                return false
            end
            local url = os.strsplit(w[2], ';')[2]
            local rawdata = download_file(url)
            if type(rawdata) == 'table' then
                os.ferror("::! [install] type(rawdata) == table : "..yapfile[2])
                return false
            end
            local yd = parse_yap(rawdata)
            if tonumber(pair[2]) < tonumber(yd['build']) then
                print(" -> new build of "..pair[1].." ["..pair[2].."->"..yd['build'].."] ")
                self:install(pair[1]) --install latest
            else
                print(" -> [updatepkgs] "..yd['name']..": OK")
            end
        end
    end
    function yapidb:register_pkg(yapdata)
        print("==> [register] "..yapdata['name'])
        local _h = fs.open(YAPIDIR..'/installedpkg', 'r')
        local _tLines = _h.readAll()
        _h.close()
        local pkg_found = false
        local tLines = os.strsplit(_tLines, '\n')
        for k,v in ipairs(tLines) do
            local pair = os.strsplit(v, ';')
            if pair[1] == yapdata['name'] then
                pkg_found = true
                tLines[k] = yapdata['name']..';'..yapdata['build']
            else
                tLines[k] = tLines[k] .. '\n'
            end
        end
        if not pkg_found then
            tLines[#tLines+1] = yapdata['name']..';'..yapdata['build'] .. '\n'
        end
        print(" -> writing to file")
        local h2 = fs.open(YAPIDIR..'/installedpkg', 'w')
        for k,v in pairs(tLines) do
            h2.write(v)
        end
        h2.close()
    end
    function yapidb:install_yap(yapdata)
        print("==> install_yap: "..yapdata['name'])
        for k,v in pairs(yapdata['folders']) do
            fs.makeDir(v)
        end
        for k,v in pairs(yapdata['files']) do
            local h = fs.open(k, 'w')
            h.write(v)
            h.close()
        end
        return true
    end
    function yapidb:return_dep_onepkg(pkgname)
        local _s = self:search(pkgname)
        if _s[1] == true then
            local result = os.strsplit(_s[2], ';')
            local yapfile = download_file(result[2])
            if type(yapfile) == 'table' then
                os.ferror("::! [getdep] "..yapfile[2])
                return false
            end
            cache_file(yapfile, pkgname..'.yap')
            local yapdata = parse_yap(yapfile)
            local dependencies = {}
            if yapdata['deps'] == nil then
                print(" -> no dependencies: "..pkgname)
                return {}
            end
            for _,dep in ipairs(yapdata['deps']) do
                table.insert(dependencies, dep)
            end
            return dependencies
        else
            return false
        end
    end
    function yapidb:return_deps(pkglist)
        local r = {}
        for _,pkg in ipairs(pkglist) do
            local c = self:return_dep_onepkg(pkg)
            if c == false then
                ferror("::! [getdeps] error getting deps: "..pkg)
                return 1
            end
            for i=0,#c do
                table.insert(r, c[i])
            end
            table.insert(r, pkg)
        end
        return r
    end
    function yapidb:install(pkgname)
        local _s = self:search(pkgname)
        if _s[1] == true then
            local result = os.strsplit(_s[2], ';')
            local yapfile = download_file(result[2])
            if type(yapfile) == 'table' then
                os.ferror("::! [install] "..yapfile[2])
                return false
            end
            cache_file(yapfile, pkgname..'.yap')
            local yapdata = parse_yap(yapfile)
            local missing_dep = {}
            if yapdata['deps'] == nil or pkgname == 'base' then
                print(" -> no dependencies: "..pkgname)
            else
                for _,dep in ipairs(yapdata['deps']) do
                    if not self:is_installed(dep) then
                        table.insert(missing_dep, dep)
                    end
                end
            end
            if #missing_dep > 0 then
                ferror("error: missing dependencies")
                for _,v in ipairs(missing_dep) do
                    write(v..' ')
                end
                write('\n')
                return false
            end
            self:register_pkg(yapdata)
            self:install_yap(yapdata)
            return true
        else
            os.ferror("error: target not found: "..pkgname)
            return false
        end
    end
    function yapidb:remove(pkgname)
        --1st: read cached yapdata
        --2nd: remove all files made by yapdata['files']
        --3rd: remove entry in YAPIDIR..'/installedpkg'
        if not self:is_installed(pkgname) then
            os.ferror(" -> package not installed")
            return false
        end
        local yfile = self:search_wcache(pkgname)
        local ydata = parse_yap(yfile)
        --2nd part
        print("==> remove: "..ydata['name'])
        for k,v in pairs(ydata['files']) do
            fs.delete(k)
        end
        for k,v in pairs(ydata['folders']) do
            fs.delete(v)
        end
        local _h = fs.open(YAPIDIR..'/installedpkg', 'r')
        local _tLines = _h.readAll()
        _h.close()
        local pkg_found = false
        local tLines = os.strsplit(_tLines, '\n')
        for k,v in ipairs(tLines) do
            local pair = os.strsplit(v, ';')
            if pair[1] == ydata['name'] then
                tLines[k] = '\n'
            else
                tLines[k] = tLines[k] .. '\n'
            end
        end
        local h2 = fs.open(YAPIDIR..'/installedpkg', 'w')
        for k,v in pairs(tLines) do
            h2.write(v)
        end
        h2.close()
        return true
    end
    function yapidb:clear_cache()
        fs.delete(YAPIDIR..'/cache')
        fs.makeDir(YAPIDIR..'/cache')
    end
    function main(args)
        create_default_struct()
        if #args == 0 then
            print("usage: yapi <mode> ...")
        else
            --print("yapi "..VERSION)
            local option = args[1]
            if string.sub(option, 1, 1) == '-' then
                if string.sub(option, 2,2) == 'S' then
                    local packages = os.tail(args)
                    if packages ~= nil then
                        local database = yapidb.new(YAPIDIR..'/db')
                        database:update()
                        for k,pkg in ipairs(packages) do
                            if not database:search(pkg)[1] then
                                os.ferror("error: target not found: "..pkg)
                                return 1
                            end
                        end
                        print("resolving dependencies...")
                        packages = database:return_deps(packages)
                        print("")
                        write("Packages ("..#packages..") ")
                        for _,pkg in ipairs(packages) do
                            write(pkg..' ')
                        end
                        print("\n")
                        if not prompt(":: Proceed with installation?", "Y", "n") then
                            print("==> Aborted")
                            return true
                        end
                        for k,package in ipairs(packages) do
                            --local database = yapidb.new(YAPIDIR..'/db')
                            --database:update()
                            --print("==> [install] "..package)
                            print(":: Installing packages ...")
                            local completed = 1
                            if database:install(package) then
                                success("("..completed.."/"..tostring(#packages)..")"..package.." : SUCCESS")
                                completed = completed + 1
                            else
                                --os.ferror("==> "..package.." : FAILURE")
                                return 1
                            end
                        end
                    end
                    if isin(option, 'c') then
                        local database = yapidb.new(YAPIDIR..'/db')
                        print("==> [clear_cache]")
                        database:clear_cache()
                    end
                    if isin(option, 'y') then
                        print(":: Update from "..SERVERIP)
                        if not http then
                            os.ferror("yapi: http not enabled")
                            return 1
                        end
                        update_repos()
                    end
                    if isin(option, 'u') then
                        local database = yapidb.new(YAPIDIR..'/db')
                        print(":: Starting full system upgrade")
                        if prompt("Confirm full system upgrade", "Y", "n") then
                            database:updatepkgs()
                        else
                            print("==> Aborted")
                        end
                    end
                elseif string.sub(option,2,2) == 'U' then
                    local yfile = fs.combine(current_path, args[2])
                    print("==> [install_yap] "..yfile)
                    local h = fs.open(yfile, 'r')
                    local _data = h.readAll()
                    h.close()
                    local ydata = parse_yap(_data)
                    local database = yapidb.new(YAPIDIR..'/db')
                    if database:install_yap(ydata) then
                        success("==> [install_yap] "..ydata['name'])
                    else
                        os.ferror("::! [install_yap] "..ydata['name'])
                    end
                elseif string.sub(option,2,2) == 'Q' then
                    local database = yapidb.new(YAPIDIR..'/db')
                    local pkg = args[2]
                    local _k = database:search(pkg)
                    if pkg then
                        if _k[1] == true then
                            local _c = database:search_wcache(pkg)
                            local yobj = parse_yap(_c)
                            if type(yobj) ~= 'table' then
                                os.ferror("::! [list -> parse_yap] error (yobj ~= table)")
                                return 1
                            end
                            print(yobj.name .. ' ' .. yobj.build .. ':' .. yobj.version)
                            print("Maintainer: "..yobj.author.." <"..yobj['email_author']..">")
                            print("Description: "..yobj.description)
                        else
                            os.ferror("::! package not found")
                        end
                    end
                    if isin(option, 'e') then
                        local database = yapidb.new(YAPIDIR..'/db')
                        database:update()
                        --print("Installed packages: ")
                        local ipkg = database:installed_pkgs()
                        for _,ntv in ipairs(ipkg) do
                            local v = os.strsplit(ntv, ';')
                            write(v[1] .. ':' .. v[2] .. '\n')
                        end
                    end
                elseif string.sub(option,2,2) == 'R' then
                    local packages = os.tail(args)
                    if packages ~= nil then
                        local database = yapidb.new(YAPIDIR..'/db')
                        database:update()
                        for k,pkg in ipairs(packages) do
                            if not database:search(pkg)[1] then
                                os.ferror("error: target not found: "..pkg)
                                return 1
                            end
                        end
                        if not prompt("Proceed with remotion?", "Y", "n") then
                            print("==> Aborted")
                            return true
                        end
                        for k,package in ipairs(packages) do
                            --local database = yapidb.new(YAPIDIR..'/db')
                            --database:update()
                            print(":: removing "..package)
                            if database:remove(package) then
                                success("==> [remove] "..package.." : SUCCESS")
                            else
                                os.ferror("::! [remove] "..package.." : FAILURE")
                                return 1
                            end
                        end
                    end
                end
            else
                os.ferror("yapi: sorry, see \"man yapi\" for details")
            end
        end
    end
    main(args)
end
local SHELLCMD = {}
SHELLCMD['ls'] = ls
SHELLCMD['cd'] = cd
SHELLCMD['yapstrap'] = yapstrap
SHELLCMD['deldisk'] = deldisk
SHELLCMD['setlabel'] = setlabel
SHELLCMD['loadenv'] = loadenviroment
SHELLCMD['unloadenv'] = unloadenv
SHELLCMD['version'] = version
SHELLCMD['help'] = insthelp
SHELLCMD['reboot'] = front_reboot
SHELLCMD['shutdown'] = front_shutdown
SHELLCMD['run'] = runpath
SHELLCMD['lsblk'] = lsblk
SHELLCMD['sethostname'] = sethostname
SHELLCMD['cat'] = cat
SHELLCMD['override'] = override_shell
SHELLCMD['sbl-bcfg'] = sbl_bcfg
SHELLCMD['timesetup'] = timesetup
SHELLCMD['genfstab'] = genfstab
SHELLCMD['yapi'] = yapi
function list_cmds(args)
    print("Available commands:")
    for k,v in pairs(SHELLCMD) do
        write(k..' ')
    end
    write('\n')
end
SHELLCMD['cmds'] = list_cmds
function shellcmd(cmd)
    local k = strsplit(cmd, ' ')
    local _args = tail(k)
    if _args == nil then _args = {} end
    if SHELLCMD[k[1]] ~= nil then
        SHELLCMD[k[1]](_args)
    else
        ferror("clish: command not found")
    end
end
function run_shell()
    --THIS IS NOT CSHELL!!!!11!!!ELEVEN!!
    local command = ""
    local shell_char = '# '
    local current_user = 'root'
    local HISTORY = {}
    while true do
        write(current_user .. ':' .. current_path .. shell_char)
        command = read(nil, HISTORY)
        table.insert(HISTORY, command)
        if command == "exit" then
            return 0
        elseif command ~= nil then
            shellcmd(command)
        end
    end
    return 0
end
function main()
    if _G["IS_CUBIX"] then
        ferror("cubixli: in cubix, cubixli must run as root")
        return 0
    end
    load_env()
    run_shell()
end
if not IS_CUBIX then
    main()
end
EndFile;
File;sstartup
shell.run("/boot/cubix acpi")
EndFile;
File;proc/70/exe
bin/make
EndFile;
File;dev/full
EndFile;
File;proc/2/stat
stat working
EndFile;
File;boot/sblcfg/cubixlx
set root=(hdd)
load_video
insmod kernel
kernel /boot/cubix acpi runlevel=5
boot
EndFile;
File;dev/loop4
EndFile;
File;lib/debug_manager
#!/usr/bin/env lua
--debug manager
--task: simplify debug information from program to user
__debug_buffer = ''
__debug_counter = 0
function debug_write_tobuffer(dmessage)
    __debug_buffer = __debug_buffer .. '[' .. __debug_counter ..']' .. dmessage
    local dfile = fs.open("/tmp/syslog", 'a')
    dfile.write('[' .. __debug_counter ..']' .. dmessage)
    dfile.close()
    __debug_counter = __debug_counter + 1
end
function debug_write(dmessage, screen, isErrorMsg)
    if os.__kflag.nodebug == false or os.__kflag.nodebug == nil then
        if isErrorMsg then
            term.set_term_color(colors.red)
        end
        if screen == nil then
            print('[' .. __debug_counter ..']' .. dmessage)
        elseif screen == false and os.__boot_flag or _G['CUBIX_REBOOTING'] or _G['CUBIX_TURNINGOFF'] then
            print('[' .. __debug_counter ..']' .. dmessage)
        end
        debug_write_tobuffer(dmessage..'\n')
        os.sleep(math.random() / 16)
        --os.sleep(.5)
        term.set_term_color(colors.white)
    end
end
function testcase(message, correct)
    term.set_term_color(colors.green)
    debug_write(message)
    term.set_term_color(colors.white)
end
function warning(msg)
    term.set_term_color(colors.yellow)
    debug_write(msg)
    term.set_term_color(colors.white)
end
function dmesg()
    print(__debug_buffer)
end
function kpanic(message)
    if _G['LX_SERVER_LOADED'] == nil or _G['LX_SERVER_LOADED'] == false then
        term.set_term_color(colors.yellow)
        debug_write("[cubix] Kernel Panic!")
        if os.__boot_flag then --early kernel
            debug_write("Proc: /boot/cubix")
        else
            debug_write("Proc: "..tostring(os.getrunning()))
        end
        term.set_term_color(colors.red)
        debug_write(message)
        term.set_term_color(colors.white)
        os.system_halt()
    else
        os.lib.lxServer.write_solidRect(3,3,25,7,colors.red)
        os.lib.lxServer.write_rectangle(3,3,25,7,colors.black)
        local kpanic_title = 'Kernel Panic!'
        for i=1, #kpanic_title do
            os.lib.lx.write_letter(string.sub(kpanic_title,i,i), 9+i, 3, colors.red, colors.white)
        end
        local process_line = ''
        if not os.lib.proc or os.__boot_flag then --how are you in early boot?
            process_line = "proc: /boot/cubix"
        else
            process_line = "pid: "..tostring(os.getrunning())
        end
        for i=1, #process_line do
            os.lib.lx.write_letter(string.sub(process_line,i,i), 4+i, 5, colors.red, colors.white)
        end
        local procname = ''
        if not os.lib.proc or os.__boot_flag then --how are you in early boot(seriously, how)?
            procname = "name: /boot/cubix"
        else
            procname = "pname: "..tostring(os.lib.proc.get_processes()[os.getrunning()].file)
        end
        for i=1, #procname do
            os.lib.lx.write_letter(string.sub(procname,i,i), 4+i, 6, colors.red, colors.white)
        end
        for i=1, #message do
            os.lib.lx.write_letter(string.sub(message,i,i), 4+i, 7, colors.red, colors.white)
        end
        os.system_halt()
    end
end
EndFile;
File;dev/stderr
EndFile;
File;lib/devices/term.lua
local devname = ''
local devpath = ''
function device_read(bytes)
    ferror("term: cannot read from term deivces")
    os.sys_signal(os.signals.SIGILL)
    return 1
end
function device_write(data)
    write(data)
end
function setup(name, path)
    devname = name
    devpath = path
    fs.open(path, 'w').close()
end
function libroutine()end
EndFile;
File;usr/manuals/kernel/bootseq.man
On the subject of Cubix Boot Sequence
 * SBL is loaded in startup file and reads /boot/sblcfg/systems.cfg file, then, SBL loads a menu and the user select which OS to load, then it will load the bootscript related to it in systems.cfg and passes control to it["man sbl"].
Then, if Cubix was selected at the menu, /boot/cubix starts to manage the system bootup:
Tasks of /boot/cubix:
 * First Stage:
    load label and put it in /var/pcid
    write version of cubix to /proc/version
    write the build time to /proc/build_date and the time the OS started in /proc/sttime.
 * Second Stage: loads the Managers:
    video_manager
    debug_manager["man debugmngr"]
    acpi["man acpi"]
    fs_manager["man fsmngr"]
    proc_manager["man procmngr"]
    hash_manager["man kernel api"]
    device_manager["man devicemngr"]
    tty_manager: loads support for ttys in /dev/ttyX
    login_manager["man loginmngr"]
    pipe_manager["man pipe"]
 * Third Stage:
    Load /sbin/init, which, depending of the runlevel, could start /sbin/login or luaX(the "graphical manager")
 * Shutdown:
    Shutdown starts when /sbin/init gets a SIGKILL or when user runs /sbin/shutdown, they call os.shutdown() (assuming acpi is loaded)
    then acpi_(shutdown|reboot) will:
     * kill all processes
     * delete /tmp and /proc/<number> folders
     * recreate /tmp
     * do a native shutdown
     * bang.
EndFile;
File;lib/multiuser/multiuser.lua
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
function create_multitty()
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
    create_multitty()
    create_switch()
    for k,v in pairs(os.lib.tty.get_ttys()) do
        --every active tty running login
        v:run_process("/sbin/login")
    end
end
function libroutine()
    run_all_ttys()
end
EndFile;
File;usr/manuals/programs.man
On the Subject of Programs
Cubix starts a program by its main() function, if the program doesnt have a main() function, it will run without arguments.
 * Main Function:
    A main function of a program will recieve two arguments:
        args [list] - argumetns to program
        pipe [pipe] - just a Pipe object["man pipe"]
EndFile;
File;tmp/current_tty
/dev/tty1
EndFile;
File;proc/cpuinfo
EndFile;
File;sbin/pm-hibernate
#!/usr/bin/env lua
--/bin/pm-hibernate: wrapper to (acpi) hibernate
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        os.debug.debug_write("pm-suspend: recieved SIGKILL")
        return 0
    end
end
function main(args)
    os.hibernate()
end
main({...})
EndFile;
File;dev/null
EndFile;
File;bin/mkdir
#!/usr/bin/env lua
--/bin/mkdir: wrapper to CC mkdir
_handler = {}
_handler.signal_handler = function(sig)
    if sig == 'kill' then
        --print("mkdir: SIGKILL")
        return 0
    end
end
function main(args)
    if #args == 0 then return 0 end
    local newfolder = args[1]
    fs.makeDir(os.cshell.resolve(newfolder))
    return 0
end
main({...})
EndFile;
File;proc/1/exe
/sbin/init
EndFile;
File;bin/cat
#!/usr/bin/env lua
--/bin/cat
_handler = {}
_handler.signal_handler = function(sig)
    if sig == 'kill' then
        --print("cat: SIGKILL")
        return 0
    end
end
function cat(file, bytes)
    local DEVICES = os.list_devices
    local MFILES = os.list_mfiles
    local cpth = fs.open("/tmp/current_path", 'r')
    local CURRENT_PATH = cpth.readAll()
    cpth.close()
    local pth = os.cshell.resolve(file)
    local _result = ''
    if DEVICES[file] ~= nil then
        _result = DEVICES[file].device_read(bytes)
    elseif MFILES[file] ~= nil then
        _result = MFILES[file].read(bytes)
    elseif fs.exists(pth) and not fs.isDir(pth) then
        local h = fs.open(pth, 'r')
        if h == nil then ferror("cat: error opening file") return 0 end
        _result = h.readAll()
        h.close()
    elseif fs.exists(file) and fs.isDir(file) then
        os.ferror("cat: cannot cat into folders")
    else
        os.ferror("cat: file not found")
    end
    return _result
end
function cat_pipe(file, pipe)
    local _r = cat(file)
    os.pprint(_r, pipe)
end
function main(args, pipe)
    if #args == 0 then return 0 end
    if pipe == nil then
        print(cat(args[1], args[2]))
    else
        cat_pipe(args[1], pipe)
    end
end
main({...})
EndFile;
File;dev/tty5
EndFile;
File;bin/cshell
#!/usr/bin/env lua
--/bin/wshell: cubix shell
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        print("cshell: recieved SIGKILL")
        return 0
    end
end
function strsplit(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t={} ; i=1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        t[i] = str
        i = i + 1
    end
    return t
end
local cuser = fs.open("/tmp/current_user", 'r')
local cpath = fs.open("/tmp/current_path", 'r')
current_user = cuser.readAll()
current_path = cpath.readAll()
cuser.close()
cpath.close()
os.cshell = {}
os.cshell.PATH = '/bin:/usr/bin'
os.cshell.getpwd = function()
    local handler = fs.open("/tmp/current_path", 'r')
    local result = handler.readAll()
    handler.close()
    return result
end
os.cshell.resolve = function(pth)
    local current_path = os.cshell.getpwd()
    function _combine(c) return current_path .. '/' .. c end
    function check_slash(s) return string.sub(s, 1, 1) == '/' end
    if check_slash(pth) then
        return pth
    else
        return _combine(pth)
    end
end
aliases = {}
function shell_command(k)
    --TODO: add support for & (multitasking)
    --if k == nil or k == "" then return 0 end
    if k == nil or k == '' then return 0 end
    if string.sub(k, 1, 1) == '#' then return 0 end
    for _, k in pairs(os.strsplit(k, "&&")) do
    if k:find("|") then
        local count = 1
        local programs = os.strsplit(k, "|")
        local npipe = os.lib.pipe.Pipe.new('main')
        for k,v in pairs(programs) do
            local c = os.strsplit(v, ' ')
            local program = c[1]
            local pargs = {}
            for k,v in pairs(c) do
                if v ~= program then
                    pargs[#pargs+1] = tostring(v)
                end
            end
            local found = false
            if fs.exists(program) then
                found = true
                os.runfile_proc(program, pargs, nil, npipe)
            elseif fs.exists(fs.combine(current_path, program)) then
                found = true
                os.runfile_proc(fs.combine(current_path, program), pargs, nil, npipe)
            end
            local _path = os.strsplit(os.cshell.PATH, ':')
            for k,v in ipairs(_path) do
                local K = fs.combine(v..'/', program)
                if fs.exists(K) then
                    found = true
                    os.runfile_proc(K, pargs, nil, npipe)
                end
            end
            if fs.exists(fs.combine("/sbin/", program)) then
                if current_user == "root" then
                    found = true
                    os.runfile_proc(fs.combine("/sbin/", program), pargs, nil, npipe)
                end
            end
            if not found then
                os.ferror("cshell: Program not found")
            end
        end
    else
        local c = strsplit(k, " ")
        local program = c[1]
        if program == 'echo' then
            args = strsplit(k, ';')
            print(args[2])
            return 0
        elseif program == 'APATH' then
            args = strsplit(k, ' ')
            os.cshell.PATH = os.cshell.PATH .. ':' .. args[2]
            return 0
        elseif program == 'PPATH' then
            print(os.cshell.PATH)
            return 0
        elseif program == "getuid" then
            print(os.lib.login.currentUser().uid)
            return 0
        elseif program == 'getperm' then
            permission.getPerm()
            return 0
        elseif program == 'alias' then
            local arg = string.sub(k, #program + 1, #k)
            local spl = os.strsplit(arg, '=')
            local key = spl[1]
            local alias = spl[2]
            aliases[key] = string.sub(alias, 2, #alias - 1)
            return 0
        elseif program == 'aliases' then
            os.viewTable(aliases)
            return 0
        end
        local args = {}
        for k,v in pairs(c) do
            if v == program then
            else
                args[#args+1] = v
            end
        end
        local found = false
        if fs.exists(program) then
            _l = os.strsplit(program, '/')
            if _l[1] ~= 'sbin' then
                found = true
                os.runfile_proc(program, args)
            end
        elseif not found and fs.exists(fs.combine(current_path, program)) then
            print(current_path)
            if current_path ~= '/sbin' or current_path ~= 'sbin' then
                found = true
                os.runfile_proc(fs.combine(current_path, program), args)
            end
        end
        local _path = os.strsplit(os.cshell.PATH, ':')
        for k,v in ipairs(_path) do
            local K = fs.combine(v..'/', program)
            if not found and fs.exists(K) then
                found = true
                os.runfile_proc(K, args)
            end
        end
        if not found and fs.exists(fs.combine("/sbin/", program)) then
            if current_user == "root" then
                found = true
                os.runfile_proc(fs.combine("/sbin/", program), args)
            end
        end
        if not found then
            os.ferror("cshell: "..program..": Program not found")
        end
    end
    end
end
os.cshell.__shell_command = shell_command
os.cshell.complete = function()
    --return fs.complete(current_path)
end
local aliases = {}
function new_shcommand(cmd)
    shell_command(cmd)
end
function run_cshrc(user)
    if not fs.exists('/home/'..user..'/.cshrc') then
        os.debug.debug_write("[cshell] .cshrc not found", nil, true)
        return 1
    end
    local cshrc_handler = fs.open('/home/'..user..'/.cshrc', 'r')
    local _lines = cshrc_handler.readAll()
    cshrc_handler.close()
    local lines = os.strsplit(_lines, '\n')
    for k,v in ipairs(lines) do
        new_shcommand(v)
    end
    return 0
end
function main(args)
    os.shell = os.cshell --compatibility
    --TODO: -c
    if fs.exists("/tmp/install_lock") then
        term.set_term_color(colors.green)
        print("Hey, it seems that you installed cubix recently, do you know you can create a new user using 'sudo adduser' in the shell, ok?(remember that the default password is 123)")
        term.set_term_color(colors.white)
        fs.delete("/tmp/install_lock")
    end
    local command = ""
    local HISTORY = {}
    if #args > 0 then
        local ecmd = args[1]
        print(ecmd)
        --print(string.sub(ecmd, 1, #ecmd -1))
        local h = fs.open(os.cshell.resolve(ecmd), 'r')
        local _l = h.readAll()
        h.close()
        local lines = os.strsplit(_l, '\n')
        for k,v in ipairs(lines) do
            shell_command(v)
        end
        return 0
    end
    local cuser = fs.open("/tmp/current_user", 'r')
    current_user = cuser.readAll()
    cuser.close()
    run_cshrc(current_user)
    while true do
        local cuser = fs.open("/tmp/current_user", 'r')
        local cpath = fs.open("/tmp/current_path", 'r')
        current_user = cuser.readAll()
        current_path = cpath.readAll()
        cuser.close()
        cpath.close()
        if current_user == 'root' then
            shell_char = '# '
        else
            shell_char = '$ '
        end
        write(current_user .. ':' .. current_path .. shell_char)
        command = read(nil, HISTORY, os.cshell.complete)
        if command == "exit" then
            return 0
        elseif command ~= nil then
            if command ~= '' or not command:find(" ") then
                --i dont know why this isnt working, sorry.
                table.insert(HISTORY, command)
            end
            shell_command(command)
        end
    end
    return 0
end
main({...})
EndFile;
File;boot/cubix
#!/usr/bin/env lua
--/boot/cubix: well, cubix!
AUTHOR = "Lukas Mendes"
BUILD_DATE = "2016-03-05"
--  version format: major.revision.minor
--      major: linear
--      revision: odd: unstable
--      revision: even: stable
--      minor: number of RELEASES necessary to get to this version, not including BUILDS
--  0.3.8 < 0.3.9 < 0.3.10 < 0.3.11 < 0.4.0 < 0.4.1 [...]
--  {           UNSTABLE           }  {  STABLE   }
VERSION_MAJOR = 0
VERSION_REV   = 5
VERSION_MINOR = 1
VERSION = VERSION_MAJOR.."."..VERSION_REV.."."..VERSION_MINOR
STABLE = ((VERSION_REV % 2) == 0)
if STABLE then
    local pullEvent = os.pullEvent
    os.pullEvent = os.pullEventRaw
else
    print("[cubix] warning, loading a unstable")
end
_G['IS_CUBIX'] = true
--frontend for compatibility
term.set_term_color = function (c)
    if term.isColor() then
        term.setTextColor(c)
    end
end
if os.loadAPI("/boot/cubix-initramfs") then
    print("[cubix] loaded initramfs.")
else
    term.set_term_color(colors.red)
    print("[cubix] initramfs error, can't start kernel.")
    os.system_halt()
end
local Args = {...} --arguments to cubix
os.__boot_flag = true
kflag = {}
for k,v in ipairs(Args) do
    if v == 'quiet' then
        kflag.quiet = true
    elseif v == 'splash' then
        kflag.splash = true
    elseif v == 'acpi' then
        kflag.acpi = true
    elseif string.sub(v, 0, 4) == 'init' then
        k = os.strsplit(v, '=')
        kflag.init = k[2]
    elseif string.sub(v, 0, 8) == 'runlevel' then
        k = os.strsplit(v, '=')
        kflag.sRunlevel = k[2]
    end
end
if kflag.init == nil then
    kflag.init = "/sbin/init"
end
os.__kflag = kflag
local pcid = fs.open("/var/pcid", 'w')
local _label = os.getComputerLabel()
if _label == nil then _label = 'generic' end
pcid.write(_label)
pcid.close()
--some default things in /proc
local version = fs.open("/proc/version", 'w')
version.write(VERSION)
version.close()
local build = fs.open("/proc/build_date", 'w')
build.write(BUILD_DATE)
build.close()
local sttime = fs.open("/proc/sttime", 'w')
sttime.write(tostring(os.time()))
sttime.close()
DEVICES = {}
MANAGED_FILES = {}
TTYS = {}
os.list_mfiles = {}
--halting.
os.system_halt = function()
    while true do sleep(0) end
end
os._read = read
os._sleep = os.sleep
os.ferror = function(message)
    --TODO: stdin, stdout and stderr
    --[[
    device_write("/dev/stderr", message)
    ]]
    term.set_term_color(colors.red)
    print(message)
    term.set_term_color(colors.white)
end
_G['ferror'] = os.ferror
if os.loadAPI("/lib/video_manager") then
    print("loaded video")
end
if os.loadAPI("/lib/debug_manager") then
    __debug = _G["debug_manager"]
    __debug.debug_write("debug: loaded")
else
    __debug.debug_write = print
    term.set_term_color(colors.red)
    __debug.debug_write("debug: not loaded")
    term.set_term_color(colors.white)
end
os.debug = __debug
debug = os.debug
cubix = {}
_G['cubix'] = cubix
cubix.boot_kernel = function()
if kflag.quiet then
    --if quiet, just make normal debug functions as nothing.
    __debug.debug_write = function()
        os.sleep(math.random() / 16)
    end
    __debug.testcase = function()
    end
    __debug.ferror = function()end
end
--Welcome message
term.set_term_color(colors.green)
os.debug.debug_write("Welcome to Cubix "..VERSION..'!')
print('\n')
term.set_term_color(colors.white)
os.sleep(.5)
os.lib = {}
os.internals = {}
os.internals._kernel = {}
local isReloadable = {}
--default function to load modules
function loadmodule(nmodule, path)
    os.debug.debug_write('[mod] loading: '..nmodule)
    if isReloadable[nmodule] ~= nil and isReloadable[nmodule] == false then
        os.debug.debug_write("[mod] cannot reload "..nmodule..", please reboot!", nil, true)
        return 0
    end
    if os.loadAPI(path) then
        _G[nmodule] = _G[fs.getName(path)]
        if _G[nmodule].libroutine ~= nil then
            _G[nmodule].libroutine()
        else
            os.debug.debug_write("[mod] libroutine() not found", nil, true)
            sleep(.3)
        end
        os.lib[nmodule] = _G[fs.getName(path)]
        isReloadable[nmodule] = os.lib[nmodule].RELOADABLE
        os.debug.debug_write('[mod] loaded: '..nmodule)
    else
        os.debug.kpanic("[mod] not loaded: "..nmodule)
    end
end
--unload a module
function unloadmod(mod)
    if os.lib[mod] then
        os.debug.debug_write("[unloadmod] unloading "..mod)
        os.lib[mod] = nil
        return true
    else
        ferror("unloadmod: module not found")
        return false
    end
end
function loadmodule_ret(path)
    -- instead of putting the library into os.lib, just return it
    os.debug.debug_write('[loadmodule:ret] loading: '..path)
    local ret = {}
    if os.loadAPI(path) then
        ret = _G[fs.getName(path)]
        if ret.libroutine ~= nil then
            ret.libroutine()
        else
            os.debug.debug_write("[loadmodule:ret] libroutine() not found", nil, true)
            sleep(.3)
        end
        os.debug.debug_write('[loadmodule:ret] loaded: '..path)
        return ret
    else
        ferror("[loadmodule:ret] not loaded: "..path)
        return nil
    end
end
os.internals.loadmodule = loadmodule
os.internals.unloadmod = unloadmod
--show all loaded modules in the system(shows to stdout)
os.viewLoadedMods = function()
    for k,v in pairs(os.lib) do
        write(k..' ')
    end
    write('\n')
end
--hack
os.lib.proc = {}
os.lib.proc.running = 0
os.processes = {}
function make_readonly(table)
    local temporary = {}
    setmetatable(temporary, {
        __index = table,
        __newindex = function(_t, k, v)
            local runningproc = os.processes[os.lib.proc.running]
            if runningproc == nil then
                os.debug.debug_write("[readonly -> proc] cubix is not running any process now!", nil, true)
                table[k] = v
                return 0
            end
            if runningproc.uid ~= 0 then
                os.debug.debug_write("[readonly] Attempt to modify read-only table", nil, true)
            else
                table[k] = v
            end
        end,
        __metatable = false
    })
    os.debug.debug_write("[readonly] new read-only table!")
    return temporary
end
_G['make_readonly'] = make_readonly
--acpi module
if kflag.acpi then
    loadmodule("acpi", "/lib/acpi.lua")
end
--another hack
os.lib.login = {}
os.lib.login.currentUser = function()
    return {uid = 2}
end
--filesystem manager
loadmodule("fs_mngr", "/lib/fs_manager")
--start permission system for kernel boot
permission.initKernelPerm()
--hibernation detection
if fs.exists("/dev/ram") and os.lib.acpi then
    os.lib.acpi.acpi_hwake()
else
--process manager
function os.internals._kernel.register_mfile(controller) --register Managed Files
    debug.debug_write("[mfile] "..controller.name.." created")
    os.list_mfiles[controller.name] = controller.file
    fs.open(controller.name, 'w', fs.perms.SYS).close()
    -- debug.debug_Write("[mfile] "..controller.name)
    -- new_mfile(controller)
end
loadmodule("proc", "/lib/proc_manager")
--hash manager
loadmodule("hash", "/lib/hash_manager")
function os.internals._kernel.register_device(path, d)
    os.debug.debug_write("[dev] "..path.." created")
    DEVICES[path] = d.device
    fs.open(path, 'w', fs.perms.SYS).close()
end
--device manager
loadmodule("devices", "/lib/device_manager")
--external devices
function from_extdev(name_dev, path_dev, type_dev)
    --path_dev -> /dev/
    --name -> only a id
    --type_dev -> device drivers(something.lua)
    --returns a table with the device methods
    local devmod = loadmodule_ret("/lib/devices/"..type_dev..".lua")
    devmod.setup(name_dev, path_dev)
    return devmod
end
EXTDEVICES = {}
function os.internals._kernel.new_device(typedev, name, pth)
    os.debug.debug_write("[extdev] "..name.." ("..typedev..") -> "..pth)
    EXTDEVICES[name] = {devtype=typedev, path=pth}
    os.internals._kernel.register_device(pth, {name=pth, device=from_extdev(name,pth,typedev)})
end
--default devices
os.internals._kernel.new_device("kbd", "cckbd", "/dev/stdin")
os.internals._kernel.new_device("term", "ccterm", "/dev/stdout")
os.internals._kernel.new_device("err", "ccterm-err", "/dev/stderr")
os.list_devices = deepcopy(DEVICES)
function dev_write(path, data)
    return os.list_devices[path].device_write(data)
end
_G['dev_write'] = dev_write
--device functions
function dev_read(path, bytes) --read from devices
    local result = os.list_devices[path].device_read(bytes)
    return result
end
_G['dev_read'] = dev_read
function dev_available(path) --check if device is available
    local av = os.list_devices[path] ~= nil
    return av
end
_G['dev_available'] = dev_available
function get_device(pth) --get the device object from its path
    return os.list_devices[pth]
end
_G['get_device'] = get_device
function os.list_dev() --list all devices(shows to stdout automatically)
    for k,v in pairs(os.list_devices) do
        write(k..' ')
    end
    write('\n')
end
local perilist = peripheral.getNames()
os.debug.debug_write("[peripheral:st]")
for i = 1, #perilist do
    os.internals._kernel.new_device("peripheral", tostring(peripheral.getType(perilist[i])))
end
--tty, login and pipe managers
function os.internals._kernel.register_tty(path, tty) --register TTY to the system
    os.debug.debug_write("[tty] new tty: "..path)
    fs.open(path, 'w', fs.perms.SYS).close()
end
loadmodule("tty", "/lib/tty_manager")
loadmodule("login", "/lib/login_manager")
loadmodule("pipe", "/lib/pipe_manager")
loadmodule("time", "/lib/time")
loadmodule("control", "/lib/comm_manager")
os.pprint = function(message, pipe, double)
    if double == nil then double = false end
    if message == nil then message = '' end
    if pipe ~= nil then
        pipe:write(message..'\n')
        if double then
            print(message)
        end
    else
        print(message)
    end
end
term.clear()
term.setCursorPos(1,1)
--finishing boot
os.__debug_buffer = debug.__debug_buffer
os.__boot_flag = false
--setting tty
os.lib.tty.current_tty("/dev/tty0")
--if quiet, return debug to original state(you know, debug is important)
if kflag.quiet then
    if os.loadAPI("/lib/debug_manager") then
        __debug = _G["debug_manager"]
        debug.debug_write("debug: loaded")
    else
        __debug.debug_write = print
        term.set_term_color(colors.red)
        __debug.debug_write("debug: not loaded")
        term.set_term_color(colors.white)
    end
end
os.debug = __debug
term.clear()
term.setCursorPos(1,1)
--finally, run!
os.__parent_init = os.new_process(kflag.init)
if kflag.sRunlevel ~= nil then
    os.run_process(os.__parent_init, {kflag.sRunlevel})
else
    os.run_process(os.__parent_init)
end
--if something goes wrong in kflag.init(such as kill of a monster), just halt
os.system_halt()
end
end
if kflag.splash then
    if bootsplash then
        kflag.quiet = true
        bootsplash.load_normal()
    else
        ferror("splash: bootsplash not loaded at initramfs.")
        sleep(.5)
        kflag.quiet = false
        cubix.boot_kernel()
    end
else
    cubix.boot_kernel()
end
--if the boot_kernel() returns or something, just print a message saying it
print("cubix kernel: end of kernel execution.")
EndFile;
File;lib/video_manager
#!/usr/bin/env lua
-- cubix: video_manager
os.central_print = function(text)
    local x,y = term.getSize()
    local x2,y2 = term.getCursorPos()
    term.setCursorPos(math.ceil((x / 2) - (text:len() / 2)), y2)
    write(text..'\n')
end
EndFile;
File;boot/cubix-initramfs
#!/usr/bin/env lua
--libcubix: compatibility for cubix
AUTHOR = 'Lukas Mendes'
VERSION = '0.2'
--[[
Libcubix serves as a library that contains all the functions
that do not use any "cubix" thing(like ferror for example)
Libcubix is used in installation stage to create a cubix initramfs,
this servers as the basic functions that are needed in systemboot and
after it(os.strsplit, os.tail, etc.)
As there can be other versions of initramfs created by the community,
this version serves as the "official" libcubix and initramfs generator
for cubix.
Libcubix was created to make programs writed in Pure Lua to use some of
the functions in Cubix, without making the programs to be run at Cubix enviroment
]]
os.viewTable = function (t)
    if t == nil then return 0 end
    print(t)
    for k,v in pairs(t) do
        print(k..","..tostring(v).." ("..type(v)..")")
    end
end
os.tail = function(t)
    if # t <= 1 then
        return nil
    end
    local newtable = {}
    for i, v in ipairs(t) do
        if i > 1 then
            table.insert(newtable, v)
        end
    end
    return newtable
end
os.strsplit = function (inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    if type(inputstr) ~= 'string' then
        term.set_term_color(colors.red)
        print("os.strsplit: type(inputstr) == "..type(inputstr))
        term.set_term_color(colors.white)
        return 1
    end
    if inputstr == nil then
        return ''
    end
    local t={} ; i=1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        t[i] = str
        i = i + 1
    end
    return t
end
function strcount(str, char)
    local c = 0
    for i=1, #str do
        local v = string.sub(str, i, i)
        if v == char then
            c = c + 1
        end
    end
    return c
end
_G['strcount'] = strcount
os.safestr = function (s)
    if string.byte(s) > 191 then
        return '@'..string.byte(s)
    end
    return s
end
os.generateSalt = function(l)
    if l < 1 then
        return nil
    end
    local res = ''
    for i = 1, l do
        res = res .. string.char(math.random(32, 126))
    end
    return res
end
function _prompt(message, yes, nope)
    write(message..'['..yes..'/'..nope..'] ')
    local result = read()
    if result == yes then
        return true
    else
        return false
    end
end
_G['prompt'] = _prompt
function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end
os.deepcopy = deepcopy
_G['deepcopy'] = deepcopy
function gethostname()
    local h = fs.open("/etc/hostname", 'r')
    if h == nil then
        return ''
    end
    local hstn = h.readAll()
    h.close()
    return hstn
end
_G['gethostname'] = gethostname
function class(base, init)
   local c = {}    -- a new class instance
   if not init and type(base) == 'function' then
      init = base
      base = nil
   elseif type(base) == 'table' then
    -- our new class is a shallow copy of the base class!
      for i,v in pairs(base) do
         c[i] = v
      end
      c._base = base
   end
   -- the class will be the metatable for all its objects,
   -- and they will look up their methods in it.
   c.__index = c
   -- expose a constructor which can be called by <classname>(<args>)
   local mt = {}
   mt.__call = function(class_tbl, ...)
   local obj = {}
   setmetatable(obj,c)
   if init then
      init(obj,...)
   else
      -- make sure that any stuff from the base class is initialized!
      if base and base.init then
      base.init(obj, ...)
      end
   end
   return obj
   end
   c.init = init
   c.is_a = function(self, klass)
      local m = getmetatable(self)
      while m do
         if m == klass then return true end
         m = m._base
      end
      return false
   end
   setmetatable(c, mt)
   return c
end
_G['class'] = class
function generate_lcubix(type, path)
    if type == 'all' then
        local h = fs.open("/boot/libcubix", 'r')
        local all_lcubix = h.readAll()
        h.close()
        local h2 = fs.open(path, 'w')
        h2.write(all_lcubix)
        h2.close()
    end
end
EndFile;
File;dev/tty6
EndFile;
File;lib/fs_manager
#!/usr/bin/env lua
--filesystem manager
--task: Manage Filesystems
--TODO: filesystem drivers(vfat, ext3, devfs, tmpfs)
oldfs = deepcopy(fs)
fsdrivers = {}
function load_fs(fsname)
    os.debug.debug_write("[load_fs] loading "..fsname)
    local pth = '/lib/fs/'..fsname..'.lua'
    if os.loadAPI(pth) then
        fsdrivers[fsname] = _G[fs.getName(pth)]
        os.debug.debug_write('[load_fs] loaded: '..fsname)
    else
        os.debug.kpanic("[load_fs] not loaded: "..fsname)
    end
end
function load_filesystems()
    load_fs('cfs') --Cubix File System
    load_fs('tmpfs') --Temporary File System
    --load_fs('ext2')
    --load_fs('ext3')
    --load_fs('ext4')
    --load_fs('vfat')
end
_G["fsdrivers"] = fsdrivers
--yes, this was from uberOS
--local nodes = {} --{ {owner, gid, perms[, linkto]} }
nodes = {}
local mounts = {} --{ {fs, dev}, ... }
fs.perms = {}
fs.perms.ROOT = 1
fs.perms.SYS = 2
fs.perms.NORMAL = 3
fs.perms.FOOL = 4
fs.perm = function (path)
    local perm_obj = {}
    local information = nodes[path]
    perm_obj.writeperm = true
    return perm_obj
end
permission = {}
local __using_perm = nil
local __afterkperm = false
permission.grantAccess = function(perm)
    local _uid = nil
    if not os.__boot_flag then
        if os.lib.login.isSudo() then
            _uid = 0
        else
            _uid = os.lib.login.userUID()
        end
    end
    if (perm == fs.perms.ROOT or perm == fs.perms.SYS) and (_uid == 0 or os.__boot_flag == true) then
        return true
    elseif perm == fs.perms.NORMAL then
        return true
    end
    return false
end
permission.initKernelPerm = function()
    if not __afterkperm then
        __using_perm = fs.perms.SYS
        __afterkperm = true
    end
end
permission.default = function()
    local _uid = os.lib.login.userUID()
    if _uid == 0 then
        __using_perm = fs.perms.ROOT
    elseif _uid > 0 then
        __using_perm = fs.perms.NORMAL
    elseif _uid == -1 then
        __using_perm = fs.perms.FOOL
    end
end
permission.getPerm = function()
    print(__using_perm)
end
fsmanager = {}
fsmanager.normalizePerm = function(perms)
    local tmp = tostring(perms)
    local arr = {}
    for i = 1, 3 do
        local n = tonumber(string.sub(tmp, i, i))
        if n == 0 then arr[i] = "---" end
        if n == 1 then arr[i] = "--x" end
        if n == 2 then arr[i] = "-w-" end
        if n == 3 then arr[i] = "-wx" end
        if n == 4 then arr[i] = "r--" end
        if n == 5 then arr[i] = "r-x" end
        if n == 6 then arr[i] = "rw-" end
        if n == 7 then arr[i] = "rwx" end
    end
    return arr
end
fsmanager.strPerm = function(perms)
    local k = fsmanager.normalizePerm(perms)
    return k[1] .. k[2] .. k[3]
end
fs.verifyPerm = function(path, user, mode)
    local info = fsmanager.getInformation(path)
    local norm = fsmanager.normalizePerm(info.perms)
    if user == info.owner then
        if mode == "r" then return string.sub(norm[1], 1, 1) == "r" end
        if mode == "w" then return string.sub(norm[1], 2, 2) == "w" end
        if mode == "x" then return string.sub(norm[1], 3, 3) == "x" end
    elseif os.lib.login.isInGroup(user, info.gid) then
        if mode == "r" then return string.sub(norm[2], 1, 1) == "r" end
        if mode == "w" then return string.sub(norm[2], 2, 2) == "w" end
        if mode == "x" then return string.sub(norm[2], 3, 3) == "x" end
    else
        if mode == "r" then return string.sub(norm[3], 1, 1) == "r" end
        if mode == "w" then return string.sub(norm[3], 2, 2) == "w" end
        if mode == "x" then return string.sub(norm[3], 3, 3) == "x" end
    end
end
--{owner, owner group, others}
--[[
PERMISSIONS:
---------- 	0000 	no permissions
---x--x--x 	0111 	execute
--w--w--w- 	0222 	write
--wx-wx-wx 	0333 	write & execute
-r--r--r-- 	0444 	read
-r-xr-xr-x 	0555 	read & execute
-rw-rw-rw- 	0666 	read & write
-rwxrwxrwx 	0777 	read, write, & execute
]]
permission.fileCurPerm = function()
    if os.currentUID() == 0 then
        --root here
        return '770'
    elseif os.currentUID() ~= 0 then
        return '777'
    end
end
fsmanager.stripPath = function(base, full)
    if base == full then return '/' end
    return string.sub(full, #base + 1, #full)
end
fsmanager.loadFS = function(mountpath)
    local x = fsdrivers[mounts[mountpath].fs].loadFS
    if x then
        local tmp, r = x(mountpath, mounts[mountpath].dev)
        if not r then return false end
        if mountpath == '/' then mountpath = '' end
        for k,v in pairs(tmp) do
            nodes[mountpath .. k] = v
        end
    end
    return true
end
fsmanager.saveFS = function(mountpath)
    local x = fsdrivers[fsmanager.getMount(mountpath).fs].saveFS
    if x then
        x(mountpath, fsmanager.getMount(mountpath).dev)
    end
end
fsmanager.sync = function()
    os.debug.debug_write('[fsmanager:sync]')
    for k,v in pairs(mounts) do
        os.debug.debug_write('[sync] saveFS: '..k)
        fsmanager.saveFS(k)
    end
end
fsmanager.deleteNode = function(node)
    if not nodes[node] then return true end
    if fs.verifyPerm(node, os.currentUID(), 'w') then
    --if fs.perm(node).writeperm then
        nodes[node] = nil
        return true
    else
        os.ferror("fsmanager.deleteNode: Access Denied")
    end
    return false
end
fsmanager.getInformation = function(node)
    local p = node
    if node == '/' then
        return {owner = 0, perms = '755', gid = 0}
    end
    if nodes[p] then
        return deepcopy(nodes[p])
    end
    return {owner = 0, perms = '777', gid = 0}
end
fsmanager.setNode = function(node, owner, perms, linkto, gid)
    if node == '/' then
        nodes['/'] = {owner = 0, perms = '755', gid = 0}
        return true
    end
    if not nodes[node] then
        --create node
        if fs.verifyPerm(node, os.currentUID(), 'w') then
            nodes[node] = deepcopy(fsmanager.getInformation(node))
        else
            os.ferror("fsmanager.setNode [perm]: Access denied")
            return false
        end
    end
    owner = owner or nodes[node].owner
    perms = perms or nodes[node].perms
    gid = gid or nodes[node].gid
    perms = tonumber(perms)
    if nodes[node].owner == os.currentUID() then
        nodes[node].owner = owner
        nodes[node].gid = gid
        nodes[node].perms = perms
        nodes[node].linkto = linkto
    else
        os.ferror("fsmanager.setNode [uid]: Access denied")
        return false
    end
end
fsmanager.viewNodes = function()
    os.viewTable(nodes)
end
fsmanager.canMount = function(fs)
    if os.__boot_flag then
        return true
    else
        return fsdrivers[fs].canMount(os.currentUID())
    end
end
fsmanager.mount = function(device, filesystem, path)
    --if not permission.grantAccess(fs.perms.SYS) then
    --    os.ferror("mount: system permission is required to mount")
    --    return false
    --end
    if not fsmanager.canMount(filesystem) then
        os.ferror("mount: current user can't mount "..filesystem)
        return false
    end
    if not fsdrivers[filesystem] then
        os.ferror("mount: can't mount "..device..": filesystem not loaded")
        return false
    end
    if mounts[path] then
        os.ferror("mount: filesystem already mounted")
        return false
    end
    if not oldfs.exists(path) then
        ferror("mount: mountpath "..path.." doesn't exist")
        return false
    end
    if not oldfs.isDir(path) then
        ferror("mount: mountpath is not a folder")
        return false
    end
    os.debug.debug_write("[mount] mounting "..device..": "..filesystem.." at "..path, false)
    mounts[path] = {["fs"] = filesystem, ["dev"] = device}
    local r = fsmanager.loadFS(path, device)
    if not r then
        mounts[path] = nil
        os.ferror("mount: unable to mount")
        return false
    end
    return true
end
fsmanager.umount_path = function(mpath)
    if not permission.grantAccess(fs.perms.SYS) then
        --os.ferror("umount: system permission is required to umount")
        return {false, 'system permission is required to umount'}
    end
    if mpath == '/' then
        return {false, "device is busy"}
    end
    if mounts[mpath] then
        fsmanager.saveFS(mpath)
        mounts[mpath] = nil
        return {true}
    end
    return {false, 'mountpath not found'}
end
fsmanager.umount_dev = function(dev)
    if not permission.grantAccess(fs.perms.SYS) then
        --os.ferror("umount: system permission is required to umount")
        return {false, 'system permission is required to umount'}
    end
    if dev == '/dev/hdd' then
        return {false, "device is busy"}
    end
    local k = next(mounts)
    while k do
        if mounts[k] then
            if mounts[k]['dev'] == dev then
                fsmanager.saveFS(k)
                mounts[k] = nil
                return {true}
            end
        end
        k = next(mounts)
    end
    return {false, 'device not found'}
end
fsmanager.getMount = function(mountpath)
    return deepcopy(mounts[mountpath])
end
fsmanager.getMounts = function()
    return deepcopy(mounts)
end
fsmanager._test = function()
    fsmanager.setNode("/startup", 0, 755, nil, 0)
end
function shutdown_procedure()
    local k = next(mounts)
    while k do
        if mounts[k] then
            os.debug.debug_write('[fs_mngr] umounting '..mounts[k]['dev']..' at '..k)
            fsmanager.saveFS(k)
            mounts[k] = nil
            --return {true}
        end
        k = next(mounts)
    end
    sleep(.5)
end
-- how to basic: fs.complete
-- fs.find
-- fs.getDir
fs.combine = oldfs.combine
fs.getSize = function (path)
    for k,v in pairs(mounts) do
        if string.sub(path, 1, #k) == k and k ~= '/' then
            --mounted path ahead
            return fsdrivers[mounts[k]['fs']].getSize(k, string.sub(path, #k + 1))
        end
    end
    --normal path
    if fsdrivers['cfs'] then
        return fsdrivers['cfs'].getSize('/', path)
    else
        return oldfs.getSize(path)
    end
end
fs.getFreeSpace = oldfs.getFreeSpace
fs.getDrive = oldfs.getDrive --???
fs.getDir = oldfs.getDir
fs.exists = function(path)
    for k,v in pairs(mounts) do
        if string.sub(path, 1, #k) == k and k ~= '/' then
            --mounted path ahead
            return fsdrivers[mounts[k]['fs']].exists(k, string.sub(path, #k + 2))
        end
    end
    --normal path(as cfs mounted in '/')
    if fsdrivers['cfs'] then
        return fsdrivers['cfs'].exists('/', path)
    else
        return oldfs.exists(path)
    end
end
fs.move = function(fpath, tpath)
    return oldfs.move(fpath, tpath)
end
fs.copy = function(fpath, tpath)
    return oldfs.copy(fpath, tpath)
end
fs.delete = function(path)
    for k,v in pairs(mounts) do
        if string.sub(path, 1, #k) == k and k ~= '/' then
            --mounted path ahead
            return fsdrivers[mounts[k]['fs']].delete(k, string.sub(path, #k + 2))
        end
    end
    --normal path(as cfs mounted in '/')
    if fsdrivers['cfs'] then
        return fsdrivers['cfs'].delete('/', path)
    else
        return oldfs.delete(path)
    end
end
fs.isReadOnly = oldfs.isReadOnly
fs.list = function(path)
    for k,v in pairs(mounts) do
        if string.sub(path, 1, #k) == k and k ~= '/' then
            --mounted path ahead
            return fsdrivers[mounts[k]['fs']].list(k, string.sub(path, #k + 1))
        end
    end
    --normal path(as cfs mounted in '/')
    if fsdrivers['cfs'] then
        return fsdrivers['cfs'].list('/', path)
    else
        return oldfs.list(path)
    end
end
fs.makeDir = function(path)
    for k,v in pairs(mounts) do
        if string.sub(path, 1, #k) == k and k ~= '/' then
            --mounted path ahead
            return fsdrivers[mounts[k]['fs']].makeDir(k, string.sub(path, #k + 2))
        end
    end
    --normal path(as cfs mounted in '/')
    if fsdrivers['cfs'] then
        return fsdrivers['cfs'].makeDir('/', path)
    else
        return oldfs.makeDir(path)
    end
end
fs.isDir = function(path)
    for k,v in pairs(mounts) do
        if string.sub(path, 1, #k) == k and k ~= '/' then
            --mounted path ahead
            return fsdrivers[mounts[k]['fs']].isDir(k, string.sub(path, #k + 2))
        end
    end
    --normal path(as cfs mounted in '/')
    if fsdrivers['cfs'] then
        return fsdrivers['cfs'].isDir('/', path)
    else
        return oldfs.isDir(path)
    end
end
fs.open = function (path, mode, perm)
    for k,v in pairs(mounts) do
        if string.sub(path, 1, #k) == k and k ~= '/' then
            --mounted path ahead
            return fsdrivers[mounts[k]['fs']].open(k, string.sub(path, #k + 2), mode)
        end
    end
    --normal path
    if fsdrivers['cfs'] then
        return fsdrivers['cfs'].open('/', path, mode)
    else
        return oldfs.open(path, mode)
    end
end
function run_fstab()
    os.debug.debug_write("[run_fstab] reading fstab")
    if not fs.exists("/etc/fstab") then
        os.debug.kpanic("/etc/fstab not found")
    end
    local h = fs.open("/etc/fstab", 'r')
    local _fstab = h.readAll()
    h.close()
    local lines = os.strsplit(_fstab, '\n')
    for k,v in ipairs(lines) do
        local spl = os.strsplit(v, ';')
        local device = spl[1]
        local mpoint = spl[2]
        local fs = spl[3]
        local options = spl[4]
        fsmanager.mount(device, fs, mpoint)
    end
end
function libroutine()
    --os.deepcopy = deepcopy
    _G["permission"] = permission
    _G["fsmanager"] = fsmanager
    _G['oldfs'] = oldfs
    load_filesystems()
    run_fstab()
end
EndFile;
File;dev/MAKEDEV
#!/usr/bin/env lua
--/dev/MAKEDEV: create unix folder structure in /
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        --print("MAKEDEV: SIGKILL'd!", false)
        return 0
    end
end
function main(args)
    os.runfile = shell.run
    os.runfile("mkdir /proc") --proc_manager
    os.runfile("mkdir /bin") --binaries
    os.runfile("mkdir /sbin") --root binaries
    os.runfile("mkdir /boot") --boot things
    os.runfile("mkdir /etc") --system-wide configuration files and system databases
    os.runfile("mkdir /etc/rc0.d")
    os.runfile("mkdir /etc/rc1.d")
    os.runfile("mkdir /etc/rc2.d")
    os.runfile("mkdir /etc/rc3.d")
    os.runfile("mkdir /etc/rc5.d")
    os.runfile("mkdir /etc/rc6.d")
    os.runfile("mkdir /etc/scripts")
    os.runfile("mkdir /home") --home folder
    os.runfile("mkdir /home/cubix") --default user
    os.runfile("mkdir /lib") --libraries
    os.runfile("mkdir /mnt") --mounting
    os.runfile("mkdir /root") --home for root
    os.runfile("mkdir /usr") --user things
    os.runfile("mkdir /usr/bin")
    os.runfile("mkdir /usr/games")
    os.runfile("mkdir /usr/lib")
    os.runfile("mkdir /usr/sbin")
    os.runfile("mkdir /var") --variables
    os.runfile("mkdir /src") --source data
    os.runfile("rm /tmp") --removing temporary because yes
    os.runfile("mkdir /tmp") --temporary, deleted when shutdown/reboot
    os.runfile("mkdir /media") --mounting
    os.runfile("mkdir /usr/manuals") --manuals
    print("MAKEDEV: created folders")
end
main()
EndFile;
File;proc/1/stat
stat working
EndFile;
File;dev/loop1
EndFile;
File;sbin/sbl-mkconfig
#!/usr/bin/env lua
--/bin/sbl-mkconfig: make systems.cfg
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        --print("sbl-mkconfig: recieved SIGKILL")
        return 0
    end
end
function main(args)
    if #args == 0 then
        print("welcome to sbl-mkconfig!")
        print("here you can write a new systems.cfg file from scratch")
        local entries = {}
        while true do
            write("OS entry: ")
            local osentry = read()
            if osentry == '' then break end
            write("OS script: ")
            local oscmd = read()
            entries[osentry] = oscmd
        end
        print("writing to /boot/sblcfg/systems.cfg")
        if entries[''] == '' then
            local sResult = ''
            for k,v in pairs(entries) do
                sResult = sResult .. k .. ';' .. v .. '\n'
            end
            local h = oldfs.open("/boot/sblcfg/systems.cfg", 'w')
            h.write(sResult)
            h.close()
        else
            print("sbl-mkconfig: aborted.")
        end
        print("sbl-mkconfig: done!")
    elseif #args == 1 then
        local mode = args[1]
        if mode == 'default' then
            print("sbl-mkconfig: restoring system.cfg to default.cfg")
            local default = fs.open("/boot/sblcfg/default.cfg", 'r')
            local systems = fs.open("/boot/sblcfg/systems.cfg", 'w')
            systems.write(default.readAll())
            default.close()
            systems.close()
            print("Done!")
        end
    else
        print("usage: sbl-mkconfig [mode]")
    end
end
main({...})
EndFile;
File;tmp/current_user
cubix
EndFile;
File;bin/sudo
#!/usr/bin/env lua
--/bin/sudo: grants access to run programs in /sbin
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        os.debug.debug_write("sudo: SIGKILL'd!", false)
        return 0
    end
end
local __sudo_lock = true
function sudo_error(msg)
    ferror(msg)
    os.lib.login.close_sudo()
end
function run_program(_args)
    local program = _args[1]
    if program == nil then return 0 end
    local args = os.tail(_args)
    local h = fs.open("/tmp/current_path", 'r')
    local current_path = h.readAll()
    h.close()
    local found = false
    if fs.exists(program) then
        found = true
        os.runfile_proc(program, args)
    elseif fs.exists(fs.combine(current_path, program)) then
        found = true
        os.runfile_proc(fs.combine(current_path, program), args)
    end
    local _path = os.strsplit(os.cshell.PATH, ':')
    for k,v in ipairs(_path) do
        local K = fs.combine(v..'/', program)
        if fs.exists(K) then
            found = true
            os.runfile_proc(K, args)
        end
    end
    if fs.exists(fs.combine("/sbin/", program)) then
        found = true
        os.runfile_proc(fs.combine("/sbin/", program), args)
    end
    if program == '!!' then
        found = true
        local lst_cmd = os.lib.control.get('/bin/cshell_rewrite', 'last_cmd')
        local last_command = os.strsplit(lst_cmd, ' ')
        if lst_cmd == 'sudo !!' or lst_cmd == 'bin/sudo !!' or lst_cmd == '/bin/sudo !!' then
            ferror("Sorry user, you can't make a infinite loop.")
            return 1
        end
        os.runfile_proc(last_command[1], os.tail(last_command))
    end
    if not found then
        os.ferror("sudo: "..program.." program not found")
    end
    return 0
end
function main(args)
    os.lib.login.alert_sudo()
    local current_user = os.lib.login.currentUser()
    local isValid = os.lib.login.general_verify(current_user)
    --if valid, verify if current user can run programs with UID=0
    if isValid then
        if os.lib.login.sudoers_verify_user(current_user, 'root') then
            os.lib.login.use_ctok()
            run_program(args)
        else
            sudo_error("sudo: "..current_user.." is not in the sudoers file")
            return 1
        end
    else
        if os.lib.login.sudoers_verify_user(current_user, 'root') then
            if os.lib.login.front_login('sudo', current_user) then
                --os.lib.login.use_ctok()
                run_program(args)
            else
                sudo_error("sudo: Login incorrect")
                return 1
            end
        else
            sudo_error("sudo: "..current_user.." is not in the sudoers file")
            return 1
        end
    end
    os.lib.login.close_sudo()
    return 0
end
main({...})
EndFile;
File;boot/sbl
#!/usr/bin/env lua
--Simple Boot Loader
term.clear()
term.setCursorPos(1,1)
VERSION = '0.20'
function _halt()
    while true do os.sleep(0) end
end
function strsplit(inputstr, sep)
        if sep == nil then
                sep = "%s"
        end
        local t={} ; i=1
        for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
                t[i] = str
                i = i + 1
        end
        return t
end
os.viewTable = function (t)
    print(t)
    for k,v in pairs(t) do
        print(k..","..tostring(v).." ("..type(v)..")")
    end
end
function tail(t)
       if # t <= 1 then
          return nil
       end
       local newtable = {}
       for i, v in ipairs(t) do
          if i > 1 then
              table.insert(newtable, v)
          end
       end
       return newtable
end
term.set_term_color = function (c)
    if term.isColor() then
        term.setTextColor(c)
    end
end
local function cprint(text)
    local x,y = term.getSize()
    local x2,y2 = term.getCursorPos()
    term.setCursorPos(math.ceil((x / 2) - (text:len() / 2)), y2)
    write(text..'\n')
end
function CUI(m)
    n=1
    l=#m
    while true do
        term.clear()
        term.setCursorPos(1,2)
        cprint("SBL "..VERSION)
        cprint("")
        for i=1, l, 1 do
            if i==n then
                cprint(i .. " ["..m[i].."]")
            else
                cprint(i .. " " .. m[i])
            end
        end
        cprint("")
        cprint("Select a OS to load")
        cprint("[arrow up/arrow down/enter]")
        local kpress = nil
        a, b= os.pullEventRaw()
        if a == "key" then
            if b==200 and n>1 then n=n-1 end
            if b==208 and n<l then n=n+1 end
            if b==28 then kpress = 'ENTER' break end
            if b==18 then kpress = 'e' break end
        end
    end
    term.clear()
    term.setCursorPos(1,1)
    return {n, kpress}
end
function read_osfile()
    local systems_file = fs.open("/boot/sblcfg/systems.cfg", 'r')
    local systems = strsplit(systems_file.readAll(), "\n")
    local i = 1
    local detected_oses_name = {}
    local detected_oses_path = {}
    print("reading systems.cfg...")
    for k,v in pairs(systems) do
        local sysdat = strsplit(systems[k], ';')
        detected_oses_name[i] = sysdat[1]
        detected_oses_path[i] = sysdat[2]
        print(sysdat[1]..' -> '..sysdat[2])
        i = i + 1
        os.sleep(.1)
    end
    systems_file.close()
    return {detected_oses_name, detected_oses_path}
end
local availablemods = {}
availablemods['kernel'] = true
local loadmods = {}
function loadkernel(kfile, memory)
    --loads a .lua kernel file with its main function
    --TODO lineboot: parse commands, like set, to boot from hdd and from disk!
    --TODO lineboot: actually make SBL more GRUB-like
    local sbl_env = {}
    local lFile = ''
    local _CHAINLOADER = false
    if kfile == 'lineboot' then
        while true do
            write("SBL:> ")
            local k = strsplit(read(), ' ')
            if k[1] == 'kernel' then
                if loadmods['kernel'] then
                    lFile = table.concat(tail(k), ' ')
                else
                    print("SBL: kernel not loaded")
                end
            elseif k[1] == 'boot' then
                break
            elseif k[1] == 'set' then
                local _d = strsplit(k[2], '=')
                local location = _d[1]
                local set = _d[2]
                sbl_env[location] = set
            elseif k[1] == 'chainloader' then
                if k[2] == '+1' then
                    _CHAINLOADER = true
                end
            elseif k[1] == 'halt' then
                _halt()
            elseif k[1] == 'insmod' then
                local module = k[2]
                if availablemods[module] ~= nil then
                    print("SBL: loaded "..module)
                    loadmods[module] = true
                else
                    print("SBL: module not found")
                end
            elseif l[1] == 'load_video' then
                term.clear()
                term.setCursorPos(1,1)
            end
        end
    else
        local handler = fs.open(kfile, 'r')
        if handler == nil then print("SBL: error opening bootscript") return 0 end
        local lines = strsplit(handler.readAll(), '\n')
        for _,v in ipairs(lines) do
            local k = strsplit(v, ' ')
            if k[1] == 'kernel' then
                if loadmods['kernel'] then
                    lFile = table.concat(tail(k), ' ')
                else
                    print("SBL: kernel not loaded")
                end
            elseif k[1] == 'boot' then
                break
            elseif k[1] == 'set' then
                local _d = strsplit(k[2], '=')
                local location = _d[1]
                local set = _d[2]
                sbl_env[location] = set
            elseif k[1] == 'chainloader' then
                if k[2] == '+1' then
                    _CHAINLOADER = true
                end
            elseif k[1] == 'halt' then
                _halt()
            elseif k[1] == 'insmod' then
                local module = k[2]
                if availablemods[module] ~= nil then
                    print("SBL: loaded "..module)
                    loadmods[module] = true
                else
                    print("SBL: module not found")
                end
            elseif k[1] == 'load_video' then
                term.clear()
                term.setCursorPos(1,1)
            end
        end
    end
    --print("SBL: loading \""..lFile.."\"")
    os.sleep(.5)
    local tArgs = strsplit(lFile, ' ')
    local sCommand = tArgs[1]
    local sFrom = ''
    if sbl_env['root'] == '(hdd)' then
        sFrom = ''
    elseif sbl_env['root'] == '(disk)' then
        sFrom = '/disk'
    else
        print("SBL: error parsing root")
        return 0
    end
    if _CHAINLOADER then
        print("sbl: chainloading.")
        os.run({}, sFrom..'/sstartup')
    end
    print("SBL: loading \""..sFrom..'/'..sCommand.."\"\n")
    if sCommand == '/rom/programs/shell' then
        shell.run("/rom/programs/shell")
    else
        os.run({}, sFrom..'/'..sCommand, table.unpack(tArgs, 2))
    end
end
term.setBackgroundColor(colors.white)
term.set_term_color(colors.black)
print("Welcome to SBL!\n")
term.set_term_color(colors.white)
term.setBackgroundColor(colors.black)
os.sleep(.5)
oses = read_osfile()
table.insert(oses[1], "SBL Command Line")
table.insert(oses[2], "lineboot")
local user_selection = CUI(oses[1]) --only names
selected_os = user_selection[1]
--load kernel
loadkernel(oses[2][selected_os], 512)
_halt()
EndFile;
File;tmp/current_path
/home/cubix
EndFile;
File;dev/tty4
EndFile;
File;lib/luaX/lxServer.lua
--/lib/luaX/lxServer.lua
--luaX "makes forms" part
if not _G['LX_LUA_LOADED'] then
    os.ferror("lxServer: lx.lua not loaded")
    return 0
end
--term.redirect(term.native())
function write_vline(lX, lY, c, colorLine)
    term.setBackgroundColor(colorLine)
    term.setCursorPos(lX, lY)
    local tmpY = lY
    for i=0,c do
        os.lib.lx.write_pixel(c, tmpY, colorLine)
        tmpY = tmpY + 1
    end
    term.set_bg_default()
end
function write_hline(lX, lY, c, colorLine)
    term.setBackgroundColor(colorLine)
    term.setCursorPos(lX, lY)
    local tmpX = lX
    for i=0,c do
        os.lib.lx.write_pixel(tmpX, c, colorLine)
        tmpX = tmpX + 1
    end
    term.set_bg_default()
end
function write_rectangle(locX, locY, lenX, lenY, colorR)
    term.setBackgroundColor(colorR)
    term.setCursorPos(locX, locY)
    --black magic goes here
    for i=0, lenY do
        os.lib.lx.write_pixel(locX, locY+i, colorR)
    end
    for i=0, lenY do
        os.lib.lx.write_pixel(locX+lenX+1, locY+i, colorR)
    end
    for i=0, lenX do
        os.lib.lx.write_pixel(locY+i, locY, colorR)
    end
    for i=0, (lenX+1) do
        os.lib.lx.write_pixel((locY)+i, locY+lenY+1, colorR)
    end
    term.set_bg_default()
end
function write_square(lX, lY, l, colorR)
    return write_rectangle(lX, lY, l, l, colorR)
end
function write_solidRect(locX, locY, lenX, lenY, colorSR)
    write_rectangle(locX, locY, lenX, lenY, colorSR)
    for x = locX, (locX+lenX) do
        for y = locY, (locY+lenY) do
            os.lib.lx.write_pixel(x, y, colorSR)
        end
    end
    term.set_bg_default()
end
function lxError(lx_type, emsg)
    local message = lx_type..': '..emsg..'\n'
    local lxerrh = fs.open("/tmp/lxlog", 'a')
    lxerrh.write(message)
    lxerrh.close()
    if dev_available("/dev/stderr") then
        dev_write("/dev/stderr", message)
    else
        os.ferror(message)
    end
end
function demo_printMark()
    os.lib.lx.write_letter('l', 1, 1, colors.lightBlue, colors.blue)
    os.lib.lx.write_letter('x', 2, 1, colors.lightBlue, colors.blue)
    os.lib.lx.write_letter('S', 3, 1, colors.lightBlue, colors.blue)
    os.lib.lx.write_letter('e', 4, 1, colors.lightBlue, colors.blue)
    os.lib.lx.write_letter('r', 5, 1, colors.lightBlue, colors.blue)
    os.lib.lx.write_letter('v', 6, 1, colors.lightBlue, colors.blue)
    os.lib.lx.write_letter('e', 7, 1, colors.lightBlue, colors.blue)
    os.lib.lx.write_letter('r', 8, 1, colors.lightBlue, colors.blue)
end
function sv_demo()
    demo_printMark()
    write_vline(10, 10, 5, colors.green)
    os.sleep(1)
    write_hline(11, 11, 10, colors.yellow)
    os.sleep(1)
    os.lib.lx.blank()
    demo_printMark()
    write_rectangle(5, 5, 10, 5, colors.red)
    os.sleep(1)
    os.lib.lx.blank()
    demo_printMark()
    write_square(5, 5, 5, colors.red)
    os.sleep(1)
    os.lib.lx.blank()
    demo_printMark()
    for i=3,15 do
        write_square(i,i,6+i,os.lib.lx.random_color())
        sleep(.5)
    end
    sleep(3.5)
    os.lib.lx.blank()
    demo_printMark()
    os.debug.kpanic('lx kpanic test')
end
function libroutine()
    _G['LX_SERVER_LOADED'] = true
    _G['lxError'] = lxError
end
EndFile;
File;bin/yes
#!/usr/bin/env lua
--/bin/yes: outputs "y"
function print_y()
    while true do
        io.write('y\n')
        --os.sleep(0)
    end
end
function main(args)
    local cy = coroutine.create(print_y)
    coroutine.resume(cy)
    while true do
        local event, key = os.pullEvent( "key" )
        if event and key then
            break
        end
    end
end
main({...})
EndFile;
File;etc/shadow
cubix^8875ac1c6e6ab7b10ce9162cc3cc33c2330018df9664a58deb568b3cc1cb4fef^'d9M'W_}sD!6'Pv^cubix
root^63574847901e6d7f982c30ba96c4bc46a14e9503708085f2cc45295957c23462^,6@bQ+}k7@E7q45^root
EndFile;
File;lib/net/network.lua
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
EndFile;
File;bin/time
#!/usr/bin/env lua
--/bin/time: measure time used by a command (in minecraft ticks)
_handler = {}
_handler.signal_handler = function(sig)
    if sig == 'kill' then
        --print("time: SIGKILL")
        return 0
    end
end
function main(args)
    function tail(t)
       if # t <= 1 then
          return nil
       end
       local newtable = {}
       for i, v in ipairs(t) do
          if i > 1 then
              table.insert(newtable, v)
          end
       end
       return newtable
    end
    local program = args[1]
    local arguments = tail(args)
    local starting_ticks = (os.time() * 1000 + 18000)%24000
    if program == nil and arguments == nil then
    elseif program ~= nil and arguments == nil then
        os.runfile_proc(os.cshell.resolve(program), {})
    elseif program ~= nil and arguments ~= nil then
        os.runfile_proc(os.cshell.resolve(program), arguments)
    end
    local ending_ticks = (os.time() * 1000 + 18000)%24000
    print("ticks: "..(ending_ticks-starting_ticks))
    return 0
end
main({...})
EndFile;
File;etc/bootsplash.default
text
EndFile;
File;dev/tty3
EndFile;
File;.gitignore
#temporary things that always change
/dev/hda/CFSDATA
/tmp/syslog
/proc/sttime
/proc/build_date
#uninportant things to overall download of repo
/var/yapi/cache
EndFile;
File;lib/luaX/lx.lua
--/lib/luaX/lx.lua
--luaX "hardware" access
_G['_LUAX_VERSION'] = '0.0.2'
--function: manage basic access to CC screen, basic pixels and etc.
--[[Maximum dimensions of CCscreen -> 19x51]]
local SPECIAL_CHAR = ' '
local curX = 1
local curY = 1
local startColor = colors.lightBlue
function term.set_bg_default()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
end
local _oldcursorpos = term.setCursorPos
function _setCursorPos(x,y)
    curX = x
    curY = y
    _oldcursorpos(x,y)
end
term.setCursorPos = _setCursorPos
local oldprint = print
function _print(msg)
    oldprint(msg)
    local x, y = term.getCursorPos()
    curX = x
    curY = y
end
print = _print
function blank()
    term.clear()
    term.setCursorPos(1,1)
    term.setBackgroundColor(startColor)
    for x = 1, 51 do
        for y = 1, 19 do
            term.setCursorPos(x, y)
            write(SPECIAL_CHAR)
        end
    end
    term.set_bg_default()
    os.sleep(.5)
    return true
end
function scr_clear()
    term.clear()
    term.setCursorPos(1,1)
end
function write_pixel(locX, locY, color_pix)
    term.setCursorPos(locX, locY)
    term.setBackgroundColor(color_pix)
    write(SPECIAL_CHAR)
    term.set_bg_default()
end
function write_letter(letter, locX, locY, color_b, color_letter)
    if #letter > 1 then
        return false
    end
    if color_letter == nil then
        color_letter = colors.white
    end
    term.setCursorPos(locX, locY)
    term.setBackgroundColor(color_b)
    term.setTextColor(color_letter)
    write(letter)
    term.set_bg_default()
    return true
end
function write_string(str, locx, locy, color_str, color_b)
    --print("write_string "..tostring(#str)..' '..str)
    for i=1, #str do
        local letter = string.sub(str, i, i)
        write_letter(letter,
        locx+(i-1),
        locy,
        color_b,
        color_str)
    end
end
colorcodes = {
    ["0"] = colors.black,
    ["1"] = colors.blue,
    ["2"] = colors.lime,
    ["3"] = colors.green,
    ["4"] = colors.brown,
    ["5"] = colors.magenta,
    ["6"] = colors.orange,
    ["7"] = colors.lightGray,
    ["8"] = colors.gray,
    ["9"] = colors.cyan,
    ["a"] = colors.lime,
    ["b"] = colors.lightBlue,
    ["c"] = colors.red,
    ["d"] = colors.pink,
    ["e"] = colors.yellow,
    ["f"] = colors.white,
}
colores = {colors.black, colors.blue, colors.lime, colors.green, colors.brown, colors.magenta, colors.orange, colors.lightGray, colors.gray, colors.cyan, colors.lime, colors.red, colors.pink, colors.yellow, colors.white}
function random_color()
    return colores[math.random(1, #colores)]
end
function demo()
    write_letter('l', 1, 1, colors.lightBlue, colors.blue)
    write_letter('x', 2, 1, colors.lightBlue, colors.blue)
    --x
    --x
    --x
    --x
    --xxxxx
    write_pixel(5, 4, random_color())
    write_pixel(5, 5, random_color())
    write_pixel(5, 6, random_color())
    write_pixel(5, 7, random_color())
    write_pixel(5, 8, random_color())
    write_pixel(6, 8, random_color())
    write_pixel(7, 8, random_color())
    write_pixel(8, 8, random_color())
    --y 10
    --x   x
    -- x x
    --  x
    -- x x
    --x   x
    write_pixel(10, 4, random_color())
    write_pixel(14, 4, random_color())
    write_pixel(11, 5, random_color())
    write_pixel(13, 5, random_color())
    write_pixel(12, 6, random_color())
    write_pixel(11, 7, random_color())
    write_pixel(13, 7, random_color())
    write_pixel(10, 8, random_color())
    write_pixel(14, 8, random_color())
end
function get_status()
    if _G['LX_LUA_LOADED'] then
        return 'running'
    else
        return 'not running'
    end
end
function libroutine()
    _G['LX_LUA_LOADED'] = true
end
EndFile;
File;var/yapi/db/core
base;http://lkmnds.github.io/yapi/base.yap
devscripts;http://lkmnds.github.io/yapi/devscripts.yap
sbl;http://lkmnds.github.io/yapi/sbl.yap
netutils;http://lkmnds.github.io/yapi/netutils.yap
netshell;http://lkmnds.github.io/yapi/netshell.yap
cshell;http://lkmnds.github.io/yapi/cshell.yap
bootsplash;http://lkmnds.github.io/yapi/bootsplash.yap
initramfs-tools;http://lkmnds.github.io/yapi/initramfs-tools.yap
EndFile;
File;dev/loop3
EndFile;
File;dev/random
EndFile;
File;dev/disk/UFSDATA
/media/hell:0:777::0
EndFile;
File;lib/devices/mouse_device.lua
#!/usr/bin/env lua
--mouse device
dev_mouse = {}
dev_mouse.name = '/dev/mouse'
dev_mouse.device = {}
dev_mouse.device.device_read = function(bytes)
    local event, button, x, y = os.pullEvent("mouse_click")
    return x..':'..y..':'..button
end
dev_mouse.device.device_write = function(s)
    ferror("devmouse: cant write to mouse device")
    os.sys_signal(os.signals.SIGILL)
    return 1
end
EndFile;
File;bin/users
#!/usr/bin/env lua
--/bin/users: says what users are logged
-- TODO: logged users list
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        --print("users: recieved SIGKILL")
        return 0
    end
end
function main(args)
    local cuser = fs.open("/tmp/current_user", 'r')
    local current_user = cuser.readAll()
    cuser.close()
    print(current_user)
end
main({...})
EndFile;
File;sbin/modprobe
#!/usr/bin/env lua
--/bin/modprobe: load/reload cubix libraries
_handler = {}
_handler.signal_handler = function(sig)
    if sig == 'kill' then
        --print("modprobe: SIGKILL")
        return 0
    end
end
function usage()
    print("use: modprobe <module name> <path to module>")
end
function main(args)
    if #args ~= 2 then
        usage()
        return 0
    end
    local alias, path = args[1], args[2]
    os.internals.loadmodule(alias, path)
end
main({...})
EndFile;
File;src/base-pkg/makeyap
#!/usr/bin/env lua
--makeyap:
--based on pkgdata, creates a .yap file to be a package.
--compatible with Cubix and CraftOS
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        return 0
    end
end
cwd = ''
local strsplit = function (inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    if inputstr == nil then
        return ''
    end
    local t={} ; i=1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        t[i] = str
        i = i + 1
    end
    return t
end
local ferror = function(message)
    term.set_term_color(colors.red)
    print(message)
    term.set_term_color(colors.white)
end
local viewTable = function (t)
    print(t)
    for k,v in pairs(t) do
        print(k..","..tostring(v).." ("..type(v)..")")
    end
end
function listAll(p)
    local starting = '/'
    if p ~= nil then
        starting = p
    end
    if starting == '.git' or starting == '/.git' or starting == 'rom' or starting == '/rom' then
        return {folders={}, files={}}
    end
    local folders = {}
    local files = {}
    for _,v in ipairs(fs.list(starting)) do
        local node = fs.combine(starting, v)
        if fs.isDir(node) then
            if not (node == '.git' or node == '/.git' or node == 'rom' or node == '/rom') then
                table.insert(folders, node)
                local cache = listAll(node)
                for _,v in ipairs(cache['folders']) do
                    table.insert(folders, v)
                end
                for _,v in ipairs(cache['files']) do
                    table.insert(files, v)
                end
            end
        else
            table.insert(files, node)
        end
    end
    return {folders=folders, files=files}
end
function parse_pkgdata(lines)
    local pkgobj = {}
    pkgobj['file_assoc'] = {}
    pkgobj['folders'] = {}
    pkgobj['deps'] = {}
    for k,v in ipairs(lines) do
        if string.sub(v, 1, 1) ~= '#' then --comments
            local d = strsplit(v, ';')
            if d[1] == 'pkgname' then
                pkgobj['name'] = d[2]
            elseif d[1] == 'pkgver' then
                pkgobj['version'] = d[2]
            elseif d[1] == 'pkgbuild' then
                pkgobj['build'] = d[2]
            elseif d[1] == 'author' then
                pkgobj['author'] = d[2]
            elseif d[1] == 'eauthor' then
                pkgobj['email-author'] = d[2]
            elseif d[1] == 'desc' then
                pkgobj['description'] = d[2]
            elseif d[1] == 'url' then
                pkgobj['url'] = d[2]
            elseif d[1] == 'license' then
                pkgobj['license'] = d[2]
            elseif d[1] == 'file' then
                table.insert(pkgobj['file_assoc'], {d[2], d[3]})
            elseif d[1] == 'folder' then
                table.insert(pkgobj['folders'], d[2])
            elseif d[1] == 'dep' then
                table.insert(pkgobj['deps'], d[2])
            elseif d[1] == 'all' then
                pkgobj['SPECIAL_FLAG'] = true
                local nodes = listAll()
                for _,v in ipairs(nodes['folders']) do
                    table.insert(pkgobj['folders'], v)
                end
                for _,v in ipairs(nodes['files']) do
                    table.insert(pkgobj['file_assoc'], {v, v})
                end
            end
        end
    end
    return pkgobj
end
function create_yap(pkgdata, cwd)
    local yapdata = {}
    yapdata['name'] = pkgdata['name']
    yapdata['version'] = pkgdata['version']
    yapdata['build'] = pkgdata['build']
    yapdata['author'] = pkgdata['author']
    yapdata['email_author'] = pkgdata['email-author']
    yapdata['description'] = pkgdata['description']
    yapdata['folders'] = pkgdata['folders']
    yapdata['deps'] = pkgdata['deps']
    yapdata['url'] = pkgdata['url']
    yapdata['license'] = pkgdata['license']
    yapdata['files'] = {}
    for k,v in pairs(pkgdata['file_assoc']) do
        local original_file = ''
        if pkgdata['SPECIAL_FLAG'] then
            original_file = v[1]
        else
            original_file = fs.combine(cwd, v[1])
        end
        local absolute_path = v[2]
        yapdata['files'][absolute_path] = ''
        local handler = fs.open(original_file, 'r')
        if handler == nil then
            ferror("[create_yap] file error: "..original_file)
            return 1
        end
        local _lines = handler.readAll()
        handler.close()
        local lines = strsplit(_lines, '\n')
        for k,v in ipairs(lines) do
            yapdata['files'][absolute_path] = yapdata['files'][absolute_path] .. v .. '\n'
        end
    end
    return yapdata
end
function write_yapdata(yapdata)
    if yapdata['name'] == nil then
        ferror("[write_yapdata] pkgname is nil")
        return 1
    end
    local yp = fs.combine(cwd, yapdata['name']..'.yap')
    if fs.exists(yp) then
        term.setTextColor(colors.red)
        print("[write_yapdata] yap already exists, should remove to get new one.")
        term.setTextColor(colors.white)
        return 0
    end
    local yfile = fs.open(yp, 'w')
    yfile.write('Name;'..yapdata['name']..'\n')
    yfile.write('Version;'..yapdata['version']..'\n')
    yfile.write('Build;'..yapdata['build']..'\n')
    yfile.write('Author;'..yapdata['author']..'\n')
    yfile.write('Email-Author;'..yapdata['email_author']..'\n')
    yfile.write('Description;'..yapdata['description']..'\n')
    yfile.write("Url;"..yapdata['url']..'\n')
    yfile.write("License;"..yapdata['license']..'\n')
    --os.viewTable(yapdata['folders'])
    for k,v in pairs(yapdata['folders']) do
        yfile.write("Folder;"..v..'\n')
    end
    for k,v in pairs(yapdata['deps']) do
        yfile.write("Dep;"..v..'\n')
    end
    for k,v in pairs(yapdata['files']) do
        yfile.write("File;"..k..'\n')
        yfile.write(v)
        yfile.write("EndFile;\n")
    end
    yfile.close()
    return yp
end
function main(args)
    if type(os.cshell) == 'table' then
        cwd = os.cshell.getpwd()
    else
        cwd = shell.dir()
    end
    --black magic goes here
    local pkgdata_path = fs.combine(cwd, 'pkgdata')
    local handler = {}
    if fs.exists(pkgdata_path) and not fs.isDir(pkgdata_path) then
        handler = fs.open(pkgdata_path, 'r')
    else
        ferror('makeyap: pkgdata needs to exist')
        return 1
    end
    local _tLines = handler.readAll()
    handler.close()
    if _tLines == nil then
        ferror("yapdata: file is empty")
        return 1
    end
    local tLines = strsplit(_tLines, '\n')
    local pkgdata = parse_pkgdata(tLines)
    print("[parse_pkgdata]")
    print("creating yap...")
    local ydata = create_yap(pkgdata, cwd)
    print("[create_yap] created yapdata from pkgdata")
    local path = write_yapdata(ydata)
    print("[write_yapdata] "..path)
end
main({...})
EndFile;
File;dev/tty1
EndFile;
File;proc/70/cmd
bin/make rebuild 
EndFile;
File;developer_things
To developers wanting to create their own versions of base package:
Before "makeyap":
 * reboot into cubix(or craftos)
 * Clear /tmp/syslog(this is needed to clear boot messages)
  * rm /tmp/syslog && touch /tmp/syslog
 * remove CFSDATA(because of the long list of entries in UFSDATA, you need to do this)
  * rm /dev/hda/CFSDATA
 * clear yapi cache & update database
  * sudo yapi -Syc
Running makeyap takes quite a long time getting all files in the system
and creating the yap file, it will be over 9000 lines long, so don't open it with
editors(atom uses a lot of ram when opening, gedit works ok)
After "makeyap":
 * sync the buffers(recreate UFSDATA with current configuration)
EndFile;
File;usr/manuals/fsmngr.man
On the subject of the File System Manager
Task #1:
    Manage File Systems.
EndFile;
File;usr/manuals/loginmngr.man
On the Subject of Login Manager(os.lib.login)
Task #1:
    Manage user access to things in every security aspect of cubix.
    login(user, password) is the big boss here.
    Passwords are stored in the sha256(password + salt) form ["man hashmngr"]
    The defualt home folder for users is /home/<user>
EndFile;
File;bin/nano
#!/usr/bin/env lua
--/bin/nano: an alternative to program a good text editor.
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        os.debug.debug_write("nano: SIGKILL'd!", false)
        return 0
    end
end
function main(args)
    os.runfile_proc("/rom/programs/edit", {os.cshell.resolve(args[1])})
end
main({...})
EndFile;
File;proc/partitions
EndFile;
File;boot/sblcfg/cubixquiet
set root=(hdd)
load_video
insmod kernel
kernel /boot/cubix quiet nodebug
boot
EndFile;
File;boot/sblcfg/cubixboot
set root=(hdd)
load_video
insmod kernel
kernel /boot/cubix acpi splash
boot
EndFile;
File;dev/dummy
EndFile;
File;tmp/syslog
[310][proc_manager] SIGKILL -> bin/rm
[311][proc] new: bin/touch
[312][process]  bin/touch pid=73
[313][proc_manager] SIGKILL -> bin/touch
[314][proc] new: bin/rm
[315][process]  bin/rm pid=74
[316][proc_manager] SIGKILL -> bin/rm
[317][proc] new: bin/yapi
[318][process]  bin/yapi pid=75
[319][proc_manager] SIGKILL -> bin/yapi
[320][proc] new: src/base-pkg/makeyap
[321][process]  src/base-pkg/makeyap pid=76
EndFile;
File;var/pcid
cubix
EndFile;
File;lib/fs/tmpfs.lua
--Temporary File System
paths = {}
--[[
files(table of tables):
each table:
    KEY = filename - filename
    type - ("dir", "file")
    perm - permission (string)
    file - actual file (string)
]]
--using tmpfs(making a device first):
--mount /dev/loop2 /mnt/tmpfs tmpfs
function list_files(mountpath)
    --show one level of things
    local result = {}
    for k,v in pairs(paths[mountpath]) do
        if k:find("/") then
            if string.sub(k,1,1) == '/' and strcount(k, '/') == 1 then
                table.insert(result, string.sub(k, 1))
            end
        else
            table.insert(result, k)
        end
    end
    return result
end
function really_list_files(mountpath)
    local result = {}
    for k,v in pairs(paths[mountpath]) do
        table.insert(result, k)
    end
    return result
end
function canMount(uid)
    return true
end
function getSize(mountpath, path) return 0 end
function loadFS(mountpath)
    os.debug.debug_write("tmpfs: loading at "..mountpath)
    if not paths[mountpath] then
        paths[mountpath] = {}
    end
    return {}, true
end
function list(mountpath, path)
    if path == '/' or path == '' or path == nil then
        --all files in mountpath
        return list_files(mountpath)
    else
        --get relevant ones
        local all = really_list_files(mountpath)
        local res = {}
        for k,v in ipairs(all) do
            local cache = string.sub(v, 1, #path)
            if string.sub(v, 1, #path) == string.sub(path, 2)..'/' and cache ~= '' then
                table.insert(res, string.sub(v, #path + 1))
            end
        end
        return res
    end
end
function test()
    local k = fs.open("/root/mytmp/helpme", 'w')
    k.writeLine("help me i think i am lost")
    k.close()
    os.viewTable(fs.list("/root/mytmp"))
end
function exists(mountpath, path)
    --print("exists: "..path)
    if path == nil or path == '' then
        if paths[mountpath] then
            return true
        else
            return false
        end
    end
    --os.viewTable(paths[mountpath][path])
    return paths[mountpath][path] ~= nil
end
function isDir(mountpath, path)
    --os.viewTable(paths[mountpath][path])
    if path == nil or path == '' then
        if paths[mountpath] then
            return true
        else
            return false
        end
    end
    if paths[mountpath][path] == nil then
        ferror("tmpfs: path does not exist")
        return false
    end
    return paths[mountpath][path].type == 'dir'
end
function makeDir(mountpath, path)
    if not paths[mountpath][path] then
        paths[mountpath][path] = {
            type='dir',
            perm=permission.fileCurPerm(),
            owner=os.currentUID(),
        }
    end
end
function getInfo(mountpath, path)
    local data = paths[mountpath][path]
    return {
        owner = data.owner,
        perms = data.perm
    }
end
function vPerm(mountpath, path, mode)
    local info = getInfo(mountpath, path)
    local norm = fsmanager.normalizePerm(info.perms)
    if user == info.owner then
        if mode == "r" then return string.sub(norm[1], 1, 1) == "r" end
        if mode == "w" then return string.sub(norm[1], 2, 2) == "w" end
        if mode == "x" then return string.sub(norm[1], 3, 3) == "x" end
    elseif os.lib.login.isInGroup(user, info.gid) then
        if mode == "r" then return string.sub(norm[2], 1, 1) == "r" end
        if mode == "w" then return string.sub(norm[2], 2, 2) == "w" end
        if mode == "x" then return string.sub(norm[2], 3, 3) == "x" end
    else
        if mode == "r" then return string.sub(norm[3], 1, 1) == "r" end
        if mode == "w" then return string.sub(norm[3], 2, 2) == "w" end
        if mode == "x" then return string.sub(norm[3], 3, 3) == "x" end
    end
end
function general_file(mountpath, path, mode)
    local new_perm = 0
    if not paths[mountpath][path] then
        new_perm = fsmanager.fileCurPerm()
    else
        new_perm = paths[mountpath][path].perm
    end
    return {
        _perm = new_perm,
        --_mode = mode,
        _cursor = 1,
        _closed = false,
        write = function(data)
            if vPerm(mountpath, path, 'w') and mode == 'a' then --append
                paths[mountpath][path].file = paths[mountpath][path].file .. data
                return data
            elseif vPerm(mountpath, path, 'w') and mode == 'w' then --write from start
                paths[mountpath][path].file = paths[mountpath][path].file .. data
                return data
            else
                ferror("tmpfs: cant write to file")
            end
        end,
        writeLine = function(data)
            if vPerm(mountpath, path, 'w') and mode == 'a' then --append
                paths[mountpath][path].file = paths[mountpath][path].file .. data .. '\n'
                return data
            elseif vPerm(mountpath, path, 'w') and mode == 'w' then --write from start
                paths[mountpath][path].file = paths[mountpath][path].file .. data .. '\n'
                return data
            else
                ferror("tmpfs: cant writeLine to file")
            end
        end,
        read = function(bytes)
            if vPerm(mountpath, path, 'r') and mode == 'r' then
                local res = string.sub(paths[mountpath][path].file, _cursor, _cursor + bytes)
                _cursor = _cursor + bytes
                return res
            else
                ferror("tmpfs: cant read file")
            end
        end,
        readAll = function()
            if vPerm(mountpath, path, 'r') then
                local bytes = #paths[mountpath][path].file
                local res = string.sub(paths[mountpath][path].file, 1, bytes)
                return res
            else
                ferror('tmpfs: cant read file')
            end
        end,
        close = function()
            _perm = 0
            _cursor = 0
            _closed = true
            write = nil
            read = nil
            writeLine = nil
            readAll = nil
            return true
        end,
    }
end
function makeObject(mountpath, path, mode)
    if paths[mountpath][path] ~= nil then --file already exists
        if mode == 'w' then paths[mountpath][path].file = '' end
        return general_file(mountpath, path, mode)
    else
        --create file
        paths[mountpath][path] = {
            type='file',
            file='',
            perm=permission.fileCurPerm(),
            owner=os.currentUID()
        }
        if mode == 'r' then
            ferror("tmpfs: file does not exist")
            return nil
        elseif mode == 'w' then
            --create a file
            return general_file(mountpath, path, mode)
        elseif mode == 'a' then
            return general_file(mountpath, path, mode)
        end
    end
end
function open(mountpath, path, mode)
    return makeObject(mountpath, path, mode)
end
function delete(mountpoint, path)
    if vPerm(mountpath, path, 'w') then
        --remove file from paths
        paths[mountpath][path] = nil
        return true
    else
        ferror("tmpfs: not enough permission.")
        return false
    end
end
EndFile;
File;usr/manuals/cshell.man
On the subject of the Cubix Shell(cshell)
The Cubix Shell is located at /bin/cshell and referenced by /bin/sh.
By default the root user can run programs at /sbin and for a normal user to run it, it has to use "sudo" to do that
EndFile;
File;lib/devices/full_device.lua
#!/usr/bin/env lua
--full_device.lua
dev_full = {}
dev_full.name = '/dev/full'
dev_full.device = {}
dev_full.device.device_read = function (bytes)
    if bytes == nil then
        return 0
    else
        result = ''
        for i = 0, bytes do
            result = result .. safestr(0)
        end
        return result
    end
    return 0
end
dev_full.device.device_write = function(s)
    ferror("devwrite: disk full")
    os.sys_signal(os.signals.SIGILL)
    return 1
end
EndFile;
File;usr/manuals/devicemngr.man
On the subject of the Device Manager
Task #1:
    Manage /dev
    Devices available:
        /dev/null
            everything write() to it is ignored
        /dev/zero
            only gives zeros when read()
        /dev/random
            gives random characters when read()
        /dev/full
            sends a SIGILL(Illegal Instruction) when something is write() to it
EndFile;
File;lib/devices/err.lua
local devname = ''
local devpath = ''
local device_buffer = ''
function device_read(bytes)
    ferror("err: cannot read from err devices")
    os.sys_signal(os.signals.SIGILL)
    return 1
end
function device_write(message)
    term.set_term_color(colors.red)
    device_buffer = device_buffer .. message
    write(message)
    device_buffer = ''
    term.set_term_color(colors.white)
end
function flush_buffer()
    write(device_buffer)
    device_buffer = ''
end
function get_buffer()
    return device_buffer
end
function setup(name, path)
    devname = name
    devpath = path
    device_buffer = ''
    fs.open(path, 'w').close()
end
function libroutine()end
EndFile;
File;dev/loop0
EndFile;
File;lib/hash/sha256.lua
--
--  Adaptation of the Secure Hashing Algorithm (SHA-244/256)
--  Found Here: http://lua-users.org/wiki/SecureHashAlgorithm
--
--  Using an adapted version of the bit library
--  Found Here: https://bitbucket.org/Boolsheet/bslf/src/1ee664885805/bit.lua
--
local MOD = 2^32
local MODM = MOD-1
local function memoize(f)
	local mt = {}
	local t = setmetatable({}, mt)
	function mt:__index(k)
		local v = f(k)
		t[k] = v
		return v
	end
	return t
end
local function make_bitop_uncached(t, m)
	local function bitop(a, b)
		local res,p = 0,1
		while a ~= 0 and b ~= 0 do
			local am, bm = a % m, b % m
			res = res + t[am][bm] * p
			a = (a - am) / m
			b = (b - bm) / m
			p = p*m
		end
		res = res + (a + b) * p
		return res
	end
	return bitop
end
local function make_bitop(t)
	local op1 = make_bitop_uncached(t,2^1)
	local op2 = memoize(function(a) return memoize(function(b) return op1(a, b) end) end)
	return make_bitop_uncached(op2, 2 ^ (t.n or 1))
end
local bxor1 = make_bitop({[0] = {[0] = 0,[1] = 1}, [1] = {[0] = 1, [1] = 0}, n = 4})
local function bxor(a, b, c, ...)
	local z = nil
	if b then
		a = a % MOD
		b = b % MOD
		z = bxor1(a, b)
		if c then z = bxor(z, c, ...) end
		return z
	elseif a then return a % MOD
	else return 0 end
end
local function band(a, b, c, ...)
	local z
	if b then
		a = a % MOD
		b = b % MOD
		z = ((a + b) - bxor1(a,b)) / 2
		if c then z = bit32_band(z, c, ...) end
		return z
	elseif a then return a % MOD
	else return MODM end
end
local function bnot(x) return (-1 - x) % MOD end
local function rshift1(a, disp)
	if disp < 0 then return lshift(a,-disp) end
	return math.floor(a % 2 ^ 32 / 2 ^ disp)
end
local function rshift(x, disp)
	if disp > 31 or disp < -31 then return 0 end
	return rshift1(x % MOD, disp)
end
local function lshift(a, disp)
	if disp < 0 then return rshift(a,-disp) end
	return (a * 2 ^ disp) % 2 ^ 32
end
local function rrotate(x, disp)
    x = x % MOD
    disp = disp % 32
    local low = band(x, 2 ^ disp - 1)
    return rshift(x, disp) + lshift(low, 32 - disp)
end
local k = {
	0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
	0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
	0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
	0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
	0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
	0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
	0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
	0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
	0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
	0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
	0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
	0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
	0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
	0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
	0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
	0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
}
local function str2hexa(s)
	return (string.gsub(s, ".", function(c) return string.format("%02x", string.byte(c)) end))
end
local function num2s(l, n)
	local s = ""
	for i = 1, n do
		local rem = l % 256
		s = string.char(rem) .. s
		l = (l - rem) / 256
	end
	return s
end
local function s232num(s, i)
	local n = 0
	for i = i, i + 3 do n = n*256 + string.byte(s, i) end
	return n
end
local function preproc(msg, len)
	local extra = 64 - ((len + 9) % 64)
	len = num2s(8 * len, 8)
	msg = msg .. "\128" .. string.rep("\0", extra) .. len
	assert(#msg % 64 == 0)
	return msg
end
local function initH256(H)
	H[1] = 0x6a09e667
	H[2] = 0xbb67ae85
	H[3] = 0x3c6ef372
	H[4] = 0xa54ff53a
	H[5] = 0x510e527f
	H[6] = 0x9b05688c
	H[7] = 0x1f83d9ab
	H[8] = 0x5be0cd19
	return H
end
local function digestblock(msg, i, H)
	local w = {}
	for j = 1, 16 do w[j] = s232num(msg, i + (j - 1)*4) end
	for j = 17, 64 do
		local v = w[j - 15]
		local s0 = bxor(rrotate(v, 7), rrotate(v, 18), rshift(v, 3))
		v = w[j - 2]
		w[j] = w[j - 16] + s0 + w[j - 7] + bxor(rrotate(v, 17), rrotate(v, 19), rshift(v, 10))
	end
	local a, b, c, d, e, f, g, h = H[1], H[2], H[3], H[4], H[5], H[6], H[7], H[8]
	for i = 1, 64 do
		local s0 = bxor(rrotate(a, 2), rrotate(a, 13), rrotate(a, 22))
		local maj = bxor(band(a, b), band(a, c), band(b, c))
		local t2 = s0 + maj
		local s1 = bxor(rrotate(e, 6), rrotate(e, 11), rrotate(e, 25))
		local ch = bxor (band(e, f), band(bnot(e), g))
		local t1 = h + s1 + ch + k[i] + w[i]
		h, g, f, e, d, c, b, a = g, f, e, d + t1, c, b, a, t1 + t2
	end
	H[1] = band(H[1] + a)
	H[2] = band(H[2] + b)
	H[3] = band(H[3] + c)
	H[4] = band(H[4] + d)
	H[5] = band(H[5] + e)
	H[6] = band(H[6] + f)
	H[7] = band(H[7] + g)
	H[8] = band(H[8] + h)
end
function _sha256(msg) --returns string
	msg = preproc(msg, #msg)
	local H = initH256({})
	for i = 1, #msg, 64 do digestblock(msg, i, H) end
	return str2hexa(num2s(H[1], 4) .. num2s(H[2], 4) .. num2s(H[3], 4) .. num2s(H[4], 4) ..
		num2s(H[5], 4) .. num2s(H[6], 4) .. num2s(H[7], 4) .. num2s(H[8], 4))
end
hash_sha256 = _sha256
EndFile;
File;sbin/kill
#!/usr/bin/env lua
--/bin/kill: kills processes
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        os.debug.debug_write("kill: recieved SIGKILL", false)
        return 0
    end
end
function main(args)
    if #args == 1 then
        local pid = args[1]
        local p = os.lib.proc.get_by_pid(tonumber(pid))
        os.send_signal(p, os.signals.SIGKILL)
    elseif #args > 1 then
        for k,v in pairs(args) do
            local proc = os.lib.proc.get_by_pid(v)
            os.send_signal(proc, os.signals.SIGKILL)
        end
    else
        print("usage: kill <pid1> <pid2> <pid3> ...")
    end
end
main({...})
EndFile;
File;bin/passwd
#!/usr/bin/env lua
--/bin/passwd: change user password
_handler = {}
_handler.signal_handler = function(sig)
    if sig == 'kill' then
        --print("passwd: SIGKILL")
        return 0
    end
end
function main(args)
    local u = args[1]
    local cu = os.lib.login.currentUser()
    if u == nil then
        u = cu
    end
    if cu ~= 'root' and u == 'root' then
        os.ferror("passwd: you're not allowed to change root password, unless you get root access!")
        return 0
    end
    print("changing password from "..u)
    write(u.." password(actual): ")
    local apwd = read('')
    if os.lib.login.compare(u, apwd) and os.lib.login.login(u, apwd) then
        write("new "..u.." password: ")
        local npwd = read('')
        write('\n')
        if os.lib.login.changepwd(u, apwd, npwd) then
            print("changed password of "..u)
            return 0
        else
            os.ferror("passwd: error ocourred when calling changepwd()")
            return 1
        end
    else
        os.ferror("passwd: Authentication Error")
        os.ferror("passwd: password unaltered")
    end
    return 0
end
main({...})
EndFile;
File;bin/mount
#!/usr/bin/env lua
--/bin/mount: mount devices
_handler = {}
_handler.signal_handler = function(sig)
    if sig == 'kill' then
        --print("mount: SIGKILL")
        return 0
    end
end
function main(args)
    if permission.grantAccess(fs.perms.SYS) then
        --running as fucking root
        if #args == 3 then
            local device = os.cshell.resolve(args[1])
            local path = os.cshell.resolve(args[2])
            local fs = args[3]
            if fsmanager.mount(device, fs, path) then
                print("mount: mounted "..device)
            else
                os.ferror("mount: error")
            end
        elseif #args == 0 then
            local _mounts = fsmanager.getMounts()
            for k,v in pairs(_mounts) do
                print((v.dev).." on "..(k).." fs "..(v.fs))
            end
        end
    else
        if #args == 0 then
            local _mounts = fsmanager.getMounts()
            for k,v in pairs(_mounts) do
                print((v.dev).." on "..(k).." type "..(v.fs))
            end
        elseif #args == 3 then
            --view if user can mount
            local device = os.cshell.resolve(args[1])
            local path = os.cshell.resolve(args[2])
            local fs = args[3]
            if fsmanager.canMount(fs) then
                if fsmanager.mount(device, fs, path) then
                    print("mount: mounted "..device..' : '..fs)
                else
                    os.ferror("mount: error")
                end
            else
                os.ferror("mount: sorry, you cannot mount this filesystem.")
            end
        end
    end
end
main({...})
EndFile;
File;boot/sblcfg/bootdisk
set root=(disk)
chainloader +1
boot
EndFile;
File;usr/manuals/sbl.man
Simple Boot Loader
SBL was made to be a GRUB-like bootloader
BootScript commands:
  set <key>=<value>
      the set command sets a key to a value, in the SBL context, we have only one special key, "root", this key sets where SBL will load the file, the 2 values "root" can have is "(hdd)" and "(disk)"
  insmod <module>
      loads a module, the general purpose module for all OSes is the "kernel" module
  kernel <args>
      it will set the SBL to load that kernel in args, example: "kernel /boot/cubix acpi" will load "/boot/cubix acpi"
  boot
      boot the selected system
  chainloader +1
      this command makes SBL load the "sstartup" file in the "root" value
EndFile;
File;bin/lx
#!/usr/bin/env lua
--/bin/lx: manages luaX in user(spaaaaaaaaace)
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        os.debug.debug_write("lx frontend: ded", false)
        return 0
    end
end
function lx_start_default()
    --this is the default routine to start luaX with lxterm
    os.debug.debug_write("[lx] starting")
    os.internals.loadmodule("lx", "/lib/luaX/lx.lua")
    os.internals.loadmodule("lxServer", "/lib/luaX/lxServer.lua")
    os.internals.loadmodule("lxClient", "/lib/luaX/lxClient.lua")
    os.internals.loadmodule("lxWindow", "/lib/luaX/lxWindow.lua")
    os.internals.loadmodule("lxMouse", "/lib/luaX/lxMouse.lua")
    local lxterm = os.lib.lxWindow.Window.new("/g/lxterm/lxterm.lxw")
    os.lib.lx.blank()
    os.lib.lxClient.loadWindow(lxterm)
    sleep(2)
end
function lx_stop_default()
    os.internals.unloadmod("lx")
    os.internals.unloadmod("lxServer")
    os.internals.unloadmod("lxClient")
    os.lib.lxWindow.unload_all()
    os.internals.unloadmod("lxWindow")
    os.internals.unloadmod("lxMouse")
    return 0
end
function usage()
    print("lx <argument> <...>")
    print("argument: load start status stop mods demo")
end
function main(args)
    if os.lib.lx then
        print("lx ".._LUAX_VERSION)
    else
        print("lx frontend (backend not loaded)")
    end
    if args[1] == 'daemon' then
        print("lx: starting as daemon")
        os.viewLoadedMods()
    elseif args[1] == 'help' then
        usage()
    elseif args[1] == 'load' then
        --load windows here
        if os.lib.lxServer and os.lib.lxClient and os.lib.lxWindow then
            local lwindow = os.lib.lxWindow.Window.new(os.cshell.resolve(args[2]))
            os.lib.lxClient.loadWindow(lwindow)
        else
            os.ferror("lx: cannot load windows without lxServer, lxClient and lxWindow loaded")
            return 1
        end
    elseif args[1] == 'start' then
        if os.lib.login.currentUser().uid == 0 then
            os.ferror("lx: cannot start luaX while root")
            return 1
        end
        if os.lib.lx then
            if prompt("luaX backend already started, want to restart?\n", 'Y', 'n') then
                os.debug.debug_write("[lx] restarting")
                lx_stop_default()
                lx_start_default()
            end
        else
            lx_start_default()
        end
    elseif args[1] == 'mods' then
        if os.lib.lx then
            print("luaX loaded modules:")
            term.set_term_color(colors.green)
            for k,v in pairs(os.lib) do
                if string.sub(k, 1, 2) == 'lx' then
                    write(k..' ')
                end
            end
            write('\n')
            term.set_term_color(colors.white)
        else
            ferror("lx: luaX not loaded")
        end
    elseif args[1] == 'status' or args[1] == nil then
        if os.lib.lx then
            write("lx status: "..(os.lib.lx.get_status())..'\n')
        else
            write("lx backend not running\n")
        end
    elseif args[1] == 'demo' then
        if os.lib.lx then
            os.lib.lx.blank()
            os.lib.lx.demo()
            os.lib.lxServer.sv_demo()
            os.lib.lx.blank()
            local lxterm = os.lib.lxWindow.Window.new("/g/lxterm/lxterm.lxw")
            os.lib.lxClient.loadWindow(lxterm)
        else
            ferror("lx: lx backend not running\n")
        end
    elseif args[1] == 'stop' then
        os.debug.debug_write("[lx] stopping")
        lx_stop_default()
    end
end
main({...})
EndFile;
File;lib/acpi.lua
#!/usr/bin/env lua
--ACPI module
--Advanced Configuration and Power Interface
RELOADABLE = false
local _shutdown = os.shutdown
local _reboot = os.reboot
local __clear_temp = function()
    os.debug.debug_write("[acpi] cleaning temporary")
    fs.delete("/tmp")
    for _,v in ipairs(fs.list("/proc")) do
        local k = os.strsplit(v, '/')
        --os.debug.debug_write(k[#k]..";"..tostring(fs.isDir("/proc/"..v)), false)
        if tonumber(k[#k]) ~= nil and fs.isDir("/proc/"..v) then
            fs.delete("/proc/"..v)
        end
    end
    fs.makeDir("/tmp")
end
local function acpi_shutdown()
    os.debug.debug_write("[acpi_shutdown]")
    if permission.grantAccess(fs.perms.SYS) or _G['CANT_HANDLE_THE_FORCE'] then
        os.debug.debug_write("[shutdown] shutting down for system halt")
        _G['CUBIX_TURNINGOFF'] = true
        os.debug.debug_write("[shutdown] sending SIGKILL to all processes")
        if not os.__boot_flag then --still without proper userspace
            os.lib.proc.__killallproc()
            os.lib.fs_mngr.shutdown_procedure()
        end
        os.sleep(1)
        __clear_temp()
        os.debug.debug_write("[shutdown] sending HALT.")
        os.sleep(.5)
        _shutdown()
    else
        os.ferror("acpi_shutdown: cannot shutdown without SYSTEM permission")
    end
    permission.default()
end
local function acpi_reboot()
    os.debug.debug_write("[acpi_reboot]")
    if permission.grantAccess(fs.perms.SYS) then
        os.debug.debug_write("[reboot] shutting down for system reboot")
        _G['CUBIX_REBOOTING'] = true
        os.debug.debug_write("[reboot] sending SIGKILL to all processes")
        if not os.__boot_flag then --still without proper userspace
            os.lib.proc.__killallproc()
            os.debug.debug_write("[reboot] unmounting drives")
            os.lib.fs_mngr.shutdown_procedure()
        end
        os.sleep(1)
        __clear_temp()
        os.debug.debug_write("[reboot] sending RBT.")
        os.sleep(.5)
        _reboot()
    else
        os.ferror("acpi_reboot: cannot reboot without SYSTEM permission")
    end
    permission.default()
end
local function acpi_suspend()
    os.debug.debug_write('[suspend] starting', true)
    while true do
        term.clear()
        term.setCursorPos(1,1)
        local event, key = os.pullEvent('key')
        if key ~= nil then
            break
        end
    end
    os.debug.debug_write('[suspend] ending', true)
end
local function acpi_hibernate()
    --[[
        So, to hibernate we need to write the RAM into a file, and then
        in boot, read that file... WTF?
    ]]
    --after that, black magic happens (again)
    --[[
        Dear future Self,
        I don't know how to do this,
        Please, finish.
    ]]
    os.debug.debug_write("[acpi_hibernate] starting hibernation")
    local ramimg = fs.open("/dev/ram", 'w')
    ramimg.close()
    os.debug.debug_write("[acpi_hibernate] complete, shutting down.")
    acpi_shutdown()
end
function acpi_hwake()
    os.debug.debug_write("[acpi_hibernate] waking")
    fs.delete("/dev/ram")
    --local ramimg = fs.open("/dev/ram", 'r')
    --ramimg.close()
    acpi_reboot()
end
function libroutine()
    os.shutdown = acpi_shutdown
    os.reboot = acpi_reboot
    os.suspend = acpi_suspend
    os.hibernate = acpi_hibernate
end
EndFile;
File;etc/sudoers
#sudoers file
u root *
g root *
#user cubix can be anyone
u cubix *
#user cubix can be any group
g cubix *
#group sudo can be anyone
h sudo *
#group sudo can be any group
q sudo *
EndFile;
File;home/cubix/.cshrc
# ~/.cshrc: executed by cshell
#if [ $(exists /home/$USER/.csh_aliases) ] then
#    $(/home/$USER/.csh_aliases)
#fi
#setting aliases
alias yapisy='sudo yapi -Sy'
alias god='su'
EndFile;
File;lib/pipe_manager
#!/usr/bin/env lua
--pipe manager
--task: support piping, like bash
os.__pipes = {}
Pipe = {}
Pipe.__index = Pipe
function Pipe.new(ptype)
    local inst = {}
    setmetatable(inst, Pipe)
    inst.ptype = ptype
    inst.pipe_buffer = ''
    inst.point = 1
    return inst
end
function Pipe.copyPipe(npipe)
    local inst = {}
    setmetatable(inst, Pipe)
    inst.ptype = npipe.ptype
    inst.pipe_buffer = npipe.pipe_buffer
    inst.point = npipe.point
    return inst
end
function Pipe:flush()
    self.pipe_buffer = ''
end
function Pipe:write(message)
    self.pipe_buffer = self.pipe_buffer .. message
end
function Pipe:readAll()
    local A = os.strsplit(self.pipe_buffer, '\n')
    local buffer = self.pipe_buffer
    self.point = #A + 1
    return buffer
end
function Pipe:readLine()
    local K = os.strsplit(self.pipe_buffer, '\n')
    local data = K[self.point]
    self.point = self.point + 1
    return data
end
function test_pipe()
    local t = Pipe.new('empty')
    t:write("Hello\nWorld!\n")
    local h = Pipe.copyPipe(t)
    print(t.pipe_buffer == h.pipe_buffer)
    print(h:readLine())
end
function libroutine()end
EndFile;
File;bin/factor
#!/usr/bin/env lua
--/bin/factor: factors numbers
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        --print("uname: recieved SIGKILL")
        return 0
    end
end
function main(args)
    n = args[1]
    if tonumber(n) == 0 or tonumber(n) < 0 then return 0 end --bugfix
    function IsPrime(n)
        if n <= 1 or (n ~= 2 and n % 2 == 0) then
            return false
        end
        for i = 3, math.sqrt(n), 2 do
	    if n % i == 0 then
      	    return false
	    end
        end
        return true
    end
    function PrimeDecomposition(n)
        local f = {}
        if IsPrime(n) then
            f[1] = n
            return f
        end
        local i = 2
        repeat
            while n % i == 0 do
                f[#f+1] = i
                n = n / i
            end
            repeat
                i = i + 1
            until IsPrime(i)
        until n == 1
        return f
    end
    write(n .. ": ")
    for k,v in pairs(PrimeDecomposition(tonumber(n))) do
        write(v .. " ")
    end
    write('\n')
end
main({...})
EndFile;
File;dev/urandom
EndFile;
File;sbin/adduser
#!/usr/bin/env lua
--/sbin/adduser: adding new users to cubix
_handler = {}
_handler.signal_handler = function(sig)
    if sig == 'kill' then
        --print("adduser: SIGKILL")
        return 0
    end
end
function main(args)
    if #args == 0 then
        print("usage: adduser <user> <password>")
        return 0
    end
    local nu, np = args[1], args[2]
    if nu == 'root' then
        os.ferror("you cannot create a new root user")
    end
    if os.lib.login.add_new_user(nu, np) then
        print("created "..nu)
    else
        os.ferror("adduser: error creating new user")
    end
end
main({...})
EndFile;
File;lib/login_manager
#!/usr/bin/env lua
--rewrite of login manager from scratch
--things to do:
--  Tokens
--  Login thingy
--  Utils to /etc/ß?æðøw
--[[
Generating tokens:
15rounds_sha256(salt .. sessions .. user)
Verifying tokens:
check if the hash included in the token matches up
with the calculation up there
Example use:
if verify_token(myToken) then
    myToken:use()
else
    ferror("sorry mate")
end
]]
-- the major differences between old and new login modules is:
--  1 - the token logic is simplified, allowing me to fix it better
--  2 - the code is not spaghetti
--  3 - most of the functions that need to iterate with programs use deepcopy
--      to get local variables of the module
--  4 - user groups
--  5 - sudoers file
--reloading login module could be a major security flaw in cubix.
RELOADABLE = false
--current token in cubix
local current_token = {
    salt = '',
    sessions = -1,
    user = '',
    hash = ''
}
--current user
local current_user = {
    username = '',
    group = '',
    gid = -1,
    uid = -1
}
--group data
local groups = {}
--proof that a computer has worked to hash something(15 rounds of sha256)
function proof_work(data)
    local cache = data
    for i=0, 14 do --15 times
        cache = os.lib.hash.hash.sha256(cache)
    end
    return cache
end
--Token class
Token = {}
Token.__index = Token
function Token.new(user, sessions)
    inst = {}
    setmetatable(inst, Token)
    inst.salt = os.generateSalt(100)
    inst.sessions = sessions
    inst.user = user
    inst.hash = proof_work(inst.salt .. tostring(inst.sessions) .. inst.user)
    return inst
end
--using a token
function Token:use()
    --make sessions = sessions - 1
    self.sessions = self.sessions - 1
    --generate new salt and hash
    self.salt = os.generateSalt(100)
    self.hash = proof_work(self.salt .. tostring(self.sessions) .. self.user)
end
--check if a token is valid
function verify_token(token, user)
    if token == {} then
        return false
    end
    if token.sessions < 0 then
        return false
    end
    if token.hash == proof_work(token.salt .. tostring(token.sessions) .. token.user) and user == token.user then
        return true
    end
    return false
end
--because you can't access the current token, this is the
--general function to check the current token against a user
function general_verify(user)
    return verify_token(current_token, user)
end
--using current token
function use_ctok()
    current_token:use()
end
--getting current user by deepcopy
function currentUser()
    return os.deepcopy(current_user).username
end
--getting current group by deepcopy
function currentGroup()
    return os.deepcopy(current_user).group
end
--getting current uid by deepcopy
function userUID()
    return os.deepcopy(current_user).uid
end
--actual login function.
function login(usr, pwd)
    --if actual token is usable and is related to actual user, return true
    if verify_token(current_token, usr) then
        current_token:use()
        return true
    end
    --else, just do the normal login operation
    local handler = fs.open('/etc/shadow', 'r')
    local lines = os.strsplit(handler.readAll(), '\n')
    handler.close()
    for k,v in ipairs(lines) do
        local udata = os.strsplit(v, '^')
        local hashed = proof_work(pwd .. udata[3])
        --checking user and password with given password
        if udata[1] == usr and udata[2] == hashed then
            --ok, you won the password, generate a new token with 5 sessions in it
            local new_token = Token.new(usr, 4) -- 5 times(4, 3, 2, 1, 0)
            current_token = new_token
            current_user.username = usr
            current_user.group = udata[4]
            current_user.gid = get_group_gid(udata[4])
            if usr == 'root' then
                current_user.uid = 0
            else
                current_user.uid = 1
            end
            return true
        end
    end
    return false
end
--function to compare if user has typed correctly(don't use this as actual login operation)
function compare(usr, pwd)
    --this just has the login function without the Token partes btw
    local handler = fs.open('/etc/shadow', 'r')
    local lines = os.strsplit(handler.readAll(), '\n')
    handler.close()
    for k,v in ipairs(lines) do
        local udata = os.strsplit(v, '^')
        local hashed = proof_work(pwd .. udata[3])
        if udata[1] == usr and udata[2] == hashed then
            return true
        end
    end
    return false
end
--seriously, you shouldn't set this to true.
local _special_sudo = false
--alert the login module that sudo is running
function alert_sudo()
    local runningproc = os.lib.proc.get_processes()[os.getrunning()]
    if runningproc.file == '/bin/sudo' or runningproc.file == 'bin/sudo' then
        _special_sudo = true
    else
        ferror("alert_sudo: I know what you're doing")
    end
end
--alert login module sudo is closed
function close_sudo()
    _special_sudo = false
end
--check if sudo is running
function isSudo()
    return _special_sudo
end
--current sudoers file
local current_sudoers = {
    user = {},
    group = {}
}
--read and parse /etc/groups
local function read_groups()
    os.debug.debug_write("[login] reading groups")
    local h = fs.open("/etc/groups", 'r')
    if not h then
        os.debug.kpanic("error opening /etc/groups")
    end
    local d = h.readAll()
    h.close()
    local lines = os.strsplit(d, '\n')
    for _,line in ipairs(lines) do
        if string.sub(line, 1, 1) ~= '#' then
            local data = os.strsplit(line, ':')
            local gname = data[1]
            local gid = data[2]
            local _gmembers = data[3]
            local gmembers = {}
            if _gmembers == {} then
                gmembers = os.strsplit(_gmembers, ',')
            else
                gmembers = {}
            end
            groups[gid] = {
                members = gmembers,
                name = gname
            }
        end
    end
end
--get all groups(by deepcopy)
function getGroups()
    return os.deepcopy(groups)
end
local function read_sudoers()
    os.debug.debug_write("[login] reading sudoers")
    local h = fs.open("/etc/sudoers", 'r')
    if not h then
        os.debug.kpanic("error opening /etc/sudoers")
    end
    local d = h.readAll()
    h.close()
    local lines = os.strsplit(d, '\n')
    for _,line in ipairs(lines) do
        if string.sub(line, 1, 1) ~= '#' then
            if string.sub(line, 1, 1) == 'u' then
                local spl = os.strsplit(line, ' ')
                local user = spl[2]
                local _users = spl[3]
                if _users == '*' then
                    if current_sudoers.user[user] == nil then
                        current_sudoers.user[user] = {}
                    end
                    current_sudoers.user[user].users = '*'
                else
                    local users = os.strsplit(_users, ';')
                    for _,v in ipairs(users) do
                        table.insert(current_sudoers.user[user].users, v)
                    end
                end
            elseif string.sub(line, 1, 1) == 'g' then
                local spl = os.strsplit(line, ' ')
                local user = spl[2]
                local _groups = spl[3]
                if _groups == '*' then
                    if current_sudoers.user[user] == nil then
                        current_sudoers.user[user] = {}
                    end
                    current_sudoers.user[user].groups = '*'
                else
                    local groups = os.strsplit(_users, ';')
                    for _,v in ipairs(groups) do
                        table.insert(current_sudoers.user[user].groups, v)
                    end
                end
            elseif string.sub(line, 1, 1) == 'h' then
                local spl = os.strsplit(line, ' ')
                local group = spl[2]
                local _users = spl[3]
                if _users == '*' then
                    if current_sudoers.group[group] == nil then
                        current_sudoers.group[group] = {}
                    end
                    current_sudoers.group[group].users = '*'
                else
                    local users = os.strsplit(_users, ';')
                    for _,v in ipairs(users) do
                        table.insert(current_sudoers.group[group].users, v)
                    end
                end
            elseif string.sub(line, 1, 1) == 'q' then --TODO: this
                local spl = os.strsplit(line, ' ')
                local group = spl[2]
                local _groups = spl[3]
                if _groups == '*' then
                    if current_sudoers.group[group] == nil then
                        current_sudoers.group[group] = {}
                    end
                    current_sudoers.group[group].groups = '*'
                else
                    local groups = os.strsplit(_groups, ';')
                    for _,v in ipairs(groups) do
                        table.insert(current_sudoers.group[group].groups, v)
                    end
                end
            end
        end
    end
end
--getting sudoers by deepcopy
function sudoers()
    return os.deepcopy(current_sudoers)
end
--verify if a user can impersonate another user
function sudoers_verify_user(usr, other_usr)
    local user = current_sudoers.user[usr]
    if user == nil then
        return false
    end
    if user.users == '*' then
        return true
    end
    for k,v in pairs(user.users) do
        if v == other_usr then
            return true
        end
    end
    return false
end
function sudoers_verify_group(usr, group)
    local user = current_sudoers.user[usr]
    if user == nil then
        return false
    end
    if user.groups == '*' then
        return true
    end
    for k,v in pairs(user.groups) do
        if v == group then
            return true
        end
    end
    return false
end
--verify if a user from "grp" group can impersonate another user
function sudoers_gverify_user(grp, usr)
    local group = current_sudoers.group[grp]
    if group == nil then
        return false
    end
    if group.users == '*' then
        return true
    end
    for k,v in pairs(group.users) do
        if v == usr then
            return true
        end
    end
    return false
end
function sudoers_gverify_group(group, other_group)
    local grp = current_sudoers.group[group]
    if grp == nil then
        return false
    end
    if grp.groups == '*' then
        return true
    end
    for k,v in pairs(grp.groups) do
        if v == other_group then
            return true
        end
    end
    return false
end
--get gid of groups
function get_group_gid(group_name)
    for k,v in pairs(groups) do
        if v.name == group_name then
            return k
        end
    end
    return -1
end
--check if user is in group
function isInGroup(uid, gid)
    if groups[gid] then
        local g = groups[gid]
        for k,v in ipairs(g.members) do --iterating by all members
            if v == uid then
                return true
            end
        end
        return false
    else
        return false
    end
end
--you should use this function to login a user in your program
function front_login(program, user)
    local current_user = currentUser()
    if user == nil then user = current_user.username end
    write("["..program.."] password for "..user..": ")
    local try_pwd = read('')
    if login(current_user, try_pwd) then
        return true
    else
        os.ferror("front_login: Login incorrect")
        return false
    end
end
--check if a user exists
local function user_exists(u)
    local h = fs.open("/etc/shadow", 'r')
    if h == nil then
        os.debug.kpanic("error opening /etc/shadow")
    end
    local l = h.readAll()
    h.close()
    local lines = os.strsplit(l, '\n')
    for _,line in ipairs(lines) do --iterating through /etc/shadow
        local data = os.strsplit(line, '^')
        if data[1] == u then
            return true
        end
    end
    return false
end
function add_new_user(u, p)
    --adding new users to /etc/shadow
    if u == 'root' then
        return false
    end
    if user_exists(u) then
        return false
    end
    if permission.grantAccess(fs.perms.SYS) then --if permission is alright
        local _salt = os.generateSalt(15)
        local hp = proof_work(p .. _salt)
        local user_string = '\n' .. u .. '^' .. hp .. '^' .. _salt ..  '\n'
        local h = fs.open("/etc/shadow", 'a')
        h.write(user_string)
        h.close()
        fs.makeDir("/home/"..u)
        return true
    else
        ferror("add_new_user: error getting SYSTEM permission")
        return false
    end
end
--change password from a user(needs actual and new password, in plain text)
function changepwd(user, p, np)
    if login(user, p) then
        --change pwd
        local h = fs.open("/etc/shadow", 'r')
        if h == nil or h == {} then
            os.debug.kpanic("error opening /etc/shadow")
        end
        local fLines = os.strsplit(h.readAll(), '\n')
        h.close()
        for k,v in pairs(fLines) do
            local pair = os.strsplit(v, '^')
            if pair[1] == user then --if /etc/shadow has entry for that user, generate a new entry
                local _salt = os.generateSalt(15)
                pair[2] = proof_work(np .. _salt)
                fLines[k] = pair[1] .. '^' .. pair[2] .. '^' .. _salt .. '\n'
            else
                fLines[k] = fLines[k] .. '\n'
            end
        end
        local h2 = fs.open("/etc/shadow", 'w')
        for k,v in pairs(fLines) do
            h2.write(v)
        end
        h2.close()
        return true
    else
        return false
    end
end
function libroutine()
    os.login = {}
    os.login.login = login
    os.login.adduser = add_new_user
    os.login.changepwd = changepwd
    read_groups()
    read_sudoers()
end
EndFile;
File;bin/tee
#!/usr/bin/env lua
--/bin/tee: same as unix tee
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        return 0
    end
end
function main(args, pipe)
    --cmd1 | tee output_file | cmd2
    local hpipe = os.lib.pipe.Pipe.copyPipe(pipe)
    local from = ''
    while true do
        local line = hpipe:readLine()
        if not line or line == '' then break end
        from = from .. line .. '\n'
    end
    local CPATH = os.cshell.getpwd()
    local file = args[1]
    local h = fs.open(os.cshell.resolve(file), 'w')
    if h == nil then
        os.ferror("tee: error opening path")
        return 1
    end
    h.write(from)
    h.close()
    return 0
end
main({...})
EndFile;
File;sbin/login
#!/usr/bin/env lua
--/bin/login: login user to its shell access
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        --print("login: recieved SIGKILL")
        return 0
    end
end
function main(args)
    local user = args[1]
    if user == nil then user = "^" end
    local PC_LABEL = os.getComputerLabel()
    local try_user = ""
    local try_pwd = ""
    if user == "^" then
        write(PC_LABEL.." login: ")
        try_user = read()
        write("Password: ")
        try_pwd = read("")
    else
        try_user = user
        write("Password: ")
        try_pwd = read("")
    end
    if os.lib.login.login(try_user, try_pwd) then
        local k = fs.open("/tmp/current_user", 'w')
        if not k then os.debug.kpanic("cannot open /tmp/current_user") end
        k.write(try_user)
        k.close()
        local k2 = fs.open("/tmp/current_path", 'w')
        if not k2 then os.debug.kpanic("cannot open /tmp/current_path") end
        if try_user ~= 'root' then
            k2.write("/home/"..try_user)
        else
            k2.write("/root")
        end
        k2.close()
        --showing the initial path to csh
        os.lib.control.register('/sbin/login', 'cwd', '/home/'..try_user)
        --getting itself as a process
        os.lib.control.register('/sbin/login', 'login_lock', '1')
        local itself = os.lib.proc.get_by_pid(os.getrunning())
        os.lib.control.register('/sbin/login', 'login_lock', nil)
        --running csh
        os.runfile_proc("/bin/cshell_rewrite", nil, itself) --parenting with login
    else
        os.ferror("\nLogin incorrect")
    end
end
main({...})
EndFile;
File;lib/tty_manager
#!/usr/bin/env lua
--tty manager
--task: manage TTYs
local TTYS = {}
local __current_tty = ''
function get_tty(id)
    return TTYS[id]
end
function current_tty(id)
    __current_tty = id
    local h = fs.open("/tmp/current_tty", 'w')
    h.write(id)
    h.close()
end
function getcurrentTTY()
    return TTYS[__current_tty]
end
function get_ttys()
    return TTYS
end
TTY = {}
TTY.__index = TTY
function TTY.new(tid)
    local inst = {}
    setmetatable(inst, TTY)
    inst.buffer = ""
    inst.id = tid
    inst.using = false
    TTYS[tid] = inst
    return inst
end
function TTY:run_process(absolute_path)
    os.debug.debug_write("[tty] "..self.id..' running '..absolute_path, false)
end
function TTY:write(msg)
    self.buffer = self.buffer .. msg
    write(msg)
end
oldwrite = write
oldprint = print
function write(message)
    local current_tty = getcurrentTTY()
    return current_tty:write(message)
end
function libroutine()
    --10 ttys by default
    os.internals._kernel.register_tty("/dev/tty0", TTY.new("/dev/tty0"))
    os.internals._kernel.register_tty("/dev/tty1", TTY.new("/dev/tty1"))
    os.internals._kernel.register_tty("/dev/tty2", TTY.new("/dev/tty2"))
    os.internals._kernel.register_tty("/dev/tty3", TTY.new("/dev/tty3"))
    os.internals._kernel.register_tty("/dev/tty4", TTY.new("/dev/tty4"))
    os.internals._kernel.register_tty("/dev/tty5", TTY.new("/dev/tty5"))
    os.internals._kernel.register_tty("/dev/tty6", TTY.new("/dev/tty6"))
    os.internals._kernel.register_tty("/dev/tty7", TTY.new("/dev/tty7"))
    os.internals._kernel.register_tty("/dev/tty8", TTY.new("/dev/tty8"))
    os.internals._kernel.register_tty("/dev/tty9", TTY.new("/dev/tty9"))
    --os.internals._kernel.register_tty("/dev/tty10", TTY.new("/dev/tty10"))
end
EndFile;
File;bin/ps
#!/usr/bin/env lua
--/bin/ps
function isin(inputstr, wantstr)
    for i = 1, #inputstr do
        local v = string.sub(inputstr, i, i)
        if v == wantstr then return true end
    end
    return false
end
function main(args)
    if #args >= 1 then
        if isin(args[1], 'a') then
            flag_all_terminals = true
        elseif isin(args[1], 'x') then
            flag_all_proc = true
        elseif isin(args[1], 'o') then
            flag_show_ppid = true
        end
    end
    local procs = os.lib.proc.get_processes()
    --default action: show all processes from the current terminal
    if not flag_all_terminals and not flag_all_proc then
        local pcurrent_tty = os.lib.proc.filter_proc(os.lib.proc.FLAG_CTTY)
        os.pprint("PID  PROC")
        for _,v in pairs(pcurrent_tty) do
            os.pprint(v.pid.."  "..(v.file.." "..v.lineargs))
        end
    elseif flag_all_proc and not flag_all_terminals then
        local pallproc = os.lib.proc.filter_proc(os.lib.proc.FLAG_APRC)
        os.pprint("PID  PRNT  PROC")
        for _,v in pairs(pallproc) do
            if v.parent ~= nil then
                os.pprint(v.pid.."  "..(v.parent)..' > '..(v.file.." "..v.lineargs))
            else
                os.pprint(v.pid.."  "..(v.file.." "..v.lineargs))
            end
        end
    elseif not flag_all_proc and flag_all_terminals then
        --print('all tty')
        local palltty = os.lib.proc.filter_proc(os.lib.proc.FLAG_ATTY)
        os.pprint("PID  PRNT  PROC")
        for _,v in pairs(palltty) do
            if v.parent ~= nil then
                os.pprint(v.pid.."  "..(v.parent)..' > '..(v.file.." "..v.lineargs))
            else
                os.pprint(v.pid.."  "..(v.file.." "..v.lineargs))
            end
        end
    end
end
main({...})
EndFile;
File;lib/fs/cfs.lua
--Cubix File System
local res = {}
function canMount(uid)
    if uid == 0 then
        return true
    else
        return false
    end
end
function collectFiles(dir, stripPath, table)
    if not table then table = {} end
    dir = dir
    local fixPath = fsmanager.stripPath(stripPath, dir)
    table[dir] = fsmanager.getInformation(dir)
    local files = fs.list(dir)
    if dir == '/' then dir = '' end
    if fixPath == '/' then fixPath = '' end
    for k, v in pairs(files) do
        if string.sub(v, 1, 1) == '/' then v = string.sub(v, 2, #v) end
        table[fixPath .. "/" .. v] = fsmanager.getInformation(dir .. "/" .. v)
        if oldfs.isDir(dir .. "/" .. v) then collectFiles(dir .. "/" .. v, stripPath, table) end
    end
    return table
end
function _test()
    return collectFiles("/", "/", {})
end
function getSize(path)end
function saveFS(mountpath, dev)
    local p = dev
    if p == '/' then p = '' end
    local FSDATA = oldfs.open(p .. "/CFSDATA", "w")
    local WRITEDATA = ""
    for k, v in pairs(collectFiles(mountpath, mountpath, {})) do
        if string.sub(k, 1, 4) ~= '.git' and string.sub(k, 1, 5) ~= '/.git' and string.sub(k, 1, 6) ~= '/.git/' then
            WRITEDATA = WRITEDATA .. k .. ":" .. v.owner .. ":" .. v.perms .. ":"
            if v.linkto then WRITEDATA = WRITEDATA .. v.linkto end
            WRITEDATA = WRITEDATA .. ":" .. v.gid .. "\n"
        end
    end
    print("saveFS: ok")
    FSDATA.write(WRITEDATA)
    FSDATA.close()
end
function loadFS(mountpath, dev)
    local p = dev
    if p == '/' then p = '' end
    if not fs.exists(p..'/CFSDATA') then saveFS(mountpath, dev) end
    local _fsdata = oldfs.open(p..'/CFSDATA', 'r')
    local fsdata = _fsdata.readAll()
    _fsdata.close()
    local splitted = os.strsplit(fsdata, "\n")
    local res = {}
    for k,v in ipairs(splitted) do
        local tmp = os.strsplit(v, ":")
        if #tmp == 5 then
            res[tmp[1]] = {
                owner = tonumber(tmp[2]),
                perms = tmp[3],
                linkto = tmp[4],
                gid = tonumber(tmp[5])
            }
        elseif #tmp == 4 then
            res[tmp[1]] = {
                owner = tonumber(tmp[2]),
                perms = tmp[3],
                linkto = nil,
                gid = tonumber(tmp[4])
            }
        end
        if tmp[4] == "" then
            res[tmp[1]].linkto = nil
        end
        --os.viewTable(res[tmp[1]])
    end
    return res, true
end
function list(mountpath, path)
    return oldfs.list(path)
end
function exists(mountpath, path)
    return oldfs.exists(path)
end
function isDir(mountpath, path)
    return oldfs.isDir(path)
end
function delete(mountpath, path)
    return oldfs.delete(path)
end
function makeDir(mountpath, path)
    return oldfs.makeDir(path)
end
function open(mountpath, path, mode)
    return oldfs.open(path, mode)
end
function check(device)
    --sanity check
    if dev_available(device) then
        diskprobe(device, 'hell')
    else
        ferror("check: device not found")
        return false
    end
    --actually, check
    for i=0, len_blocks(device) do
        --n sei se eh jornal ou journal
        if get_block(device, i) ~= get_journal(device, i) then
            ferror("o shit nigga")
            correct(device, i)
        end
    end
    print("check: done")
end
function check_for_terrorists()
    check("/dev/airplane")
end
EndFile;
File;var/yapi/cache/base.yap
Name;base
Version;0.5.1
Build;51
Author;Lukas Mendes
Email-Author;lkmnds@gmail.com
Description;Cubix base system
Folder;mnt
Folder;mnt/tmpfs
Folder;etc
Folder;etc/scripts
Folder;etc/init.d
Folder;etc/rc2.d
Folder;etc/rc1.d
Folder;etc/rc5.d
Folder;etc/rc3.d
Folder;etc/rc6.d
Folder;etc/rc0.d
Folder;root
Folder;sbin
Folder;home
Folder;home/cubix
Folder;usr
Folder;usr/sbin
Folder;usr/games
Folder;usr/manuals
Folder;usr/manuals/kernel
Folder;usr/bin
Folder;usr/lib
Folder;media
Folder;proc
Folder;proc/2
Folder;proc/1
Folder;proc/14
Folder;proc/3
Folder;tmp
Folder;dev
Folder;dev/disk
Folder;dev/shm
Folder;dev/hda
Folder;bin
Folder;var
Folder;var/yapi
Folder;var/yapi/cache
Folder;var/yapi/db
Folder;boot
Folder;boot/sblcfg
Folder;g
Folder;g/lxterm
Folder;lib
Folder;lib/fs
Folder;lib/luaX
Folder;lib/hash
Folder;lib/multiuser
Folder;lib/net
Folder;lib/devices
Folder;lib/modules
File;lib/devices/urandom_device.lua
function rawread()
    while true do
        local sEvent, param = os.pullEvent("key")
        if sEvent == "key" then
            if param == 28 then
                break
            end
        end
    end
end
local RANDOM_BLOCKS = 256
local function getRandomString()
    local cache = ''
    for i=0, RANDOM_BLOCKS do
        cache = cache .. string.char(math.random(0, 255))
    end
    return cache
end
function print_rndchar()
    local newseed = ''
    while true do
        newseed = getRandomString()
        math.randomseed(newseed)
        io.write(os.safestr(s))
    end
end
dev_urandom = {}
dev_urandom.device = {}
dev_urandom.name = '/dev/urandom'
dev_urandom.device.device_write = function (message)
    print("cannot write to /dev/urandom")
end
dev_urandom.device.device_read = function (bytes)
    local crand = {}
    local cache = tostring(os.clock())
    local seed = 0
    for i=1,#cache do
        seed = seed + string.byte(string.sub(cache,i,i))
    end
    math.randomseed(tostring(seed))
    if bytes == nil then
        crand = coroutine.create(print_rndchar)
        coroutine.resume(crand)
        while true do
            local event, key = os.pullEvent( "key" )
            if event and key then
                break
            end
        end
    else
        result = ''
        for i = 0, bytes do
            s = string.char(math.random(0, 255))
            result = result .. os.safestr(s)
        end
        return result
    end
    return 0
end
return dev_random
EndFile;
File;bin/su
#!/usr/bin/env lua
--/bin/su: logins to root
function main(args)
    os.runfile_proc("/sbin/login", {"root"})
end
main({...})
EndFile;
File;bin/lsmod
#!/usr/bin/env lua
--/bin/lsmod: list loaded modules in cubix
_handler = {}
_handler.signal_handler = function(sig)
    if sig == 'kill' then
        return 0
    end
end
function main(args)
    term.set_term_color(colors.green)
    os.viewLoadedMods()
    term.set_term_color(colors.white)
end
main({...})
EndFile;
File;bin/man
#!/usr/bin/env lua
--/bin/man: program to open manual pages
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        --print("man: SIGKILL'd!")
        return 0
    end
end
MANPATH = "/usr/manuals"
function parse_cmfl(path)
    local h = fs.open(path, 'r')
    if h == nil then
        os.ferror("parse_cmfl: file not found")
        return 1
    end
    local file = h.readAll()
    h.close()
    local lines = os.strsplit(file, '\n')
    local new_lines = {}
    for k,v in ipairs(lines) do
        if v == '.name' then
            new_lines[#new_lines+1] = lines[k+1]..'\n'
        elseif v == '.cmd' then
            new_lines[#new_lines+1] = "Usage:"
            new_lines[#new_lines+1] = '\t'..lines[k+1]..'\n'
        elseif v == '.desc' then
            new_lines[#new_lines+1] = "Description:"
            new_lines[#new_lines+1] = '\t'..lines[k+1]..'\n'
        elseif os.strsplit(v, ' ')[1] == '.listop' then
            new_lines[#new_lines+1] = "Option "..os.strsplit(v, ' ')[2]
            local i = 1
            while lines[k+i] ~= '.e' do
                new_lines[#new_lines+1] = lines[k+i]
                i = i + 1
            end
        elseif v == '.m' then
            new_lines[#new_lines+1] = '\n'
            new_lines[#new_lines+1] = lines[k+1]
            local i = 2
            while lines[k+i] ~= '.e' do
                new_lines[#new_lines+1] = lines[k+i]
                i = i + 1
            end
        end
    end
    local w,h = term.getSize()
    local nLines = 0
    for k,v in ipairs(new_lines) do
        nLines = nLines + textutils.pagedPrint(v, (h-3) - nLines)
    end
end
function main(args)
    local topic, page = {0,0}
    if #args == 1 then
        topic = args[1]
    elseif #args == 2 then
        topic, page = args[1], args[2]
    else
        print("man: what manual do you want?")
        return 0
    end
    local file = {}
    local p = ''
    if topic == 'manuals' then
        pages = fs.list(MANPATH)
        for k,v in pairs(pages) do
            if not fs.isDir(fs.combine(MANPATH, v)) then
                pages[k] = string.sub(v, 0, #v - 4)
            end
        end
        textutils.tabulate(pages)
        return 0
    end
    if page == nil then
        --work for getting <topic>.man
        p = topic..".man"
        file = io.open(fs.combine(MANPATH, p))
    else
        --get <topic>/<page>.man
        p = topic..'/'..page..'.man'
        file = io.open(fs.combine(MANPATH, p))
    end
    local w,h = term.getSize()
    if file then
        --actual reading of the file
        term.clear()
        term.setCursorPos(1,1)
        os.central_print(p)
        local sLine = file:read()
        if sLine == '!cmfl!' then --Cubix Manuals Formatting Language
            os.debug.debug_write("[man] cmfl file!", false)
            file:close()
            parse_cmfl(fs.combine(MANPATH, p))
        else
            local nLines = 0
            while sLine do
                nLines = nLines + textutils.pagedPrint(sLine, (h-3) - nLines)
                sLine = file:read()
            end
    	    file:close()
        end
    elseif fs.isDir(fs.combine(MANPATH, topic)) then
        --print available pages in topic
        print('Pages in the topic "'..topic..'":\n')
        pages = fs.list(fs.combine(MANPATH, topic))
        for k,v in pairs(pages) do
            write(string.sub(v, 0, #v - 4) .. " ")
        end
        write('\n')
    else
        print("No manual available")
    end
    return 0
end
main({...})
EndFile;
File;bin/sync
#!/usr/bin/env lua
--/bin/sync: synchronize filesystems
_handler = {}
_handler.signal_handler = function(sig)
    if sig == 'kill' then
        --print("sync: SIGKILL")
        return 0
    end
end
function main()
    fsmanager.sync()
end
main({...})
EndFile;
File;bin/cshell_rewrite
#!/usr/bin/env lua
--/bin/cshell_rewrite: rewrite of cubix shell
local shellToken = {}
--local shell_wd = os.lib.control.get('/sbin/login', 'cwd')
local shell_wd = nil
--getting shell process
local itself = os.lib.proc.get_processes()[os.getrunning()]
if not os.cshell then
    os.cshell = {}
end
os.cshell.PATH = '/bin:/usr/bin'
local function normal_command(cmd)
    --normal routine to run commands
    local tokens = os.strsplit(cmd, ' ')
    local args = os.tail(tokens)
    local program = tokens[1]
    --built-in "programs"
    --echo, APATH, PPATH, getuid, getperm, alias, aliases
    if program == 'echo' then
        local message = os.strsplit(cmd, ';')[2]
        print(message)
        return 0
    elseif program == 'APATH' then
    elseif program == 'PPATH' then
        print(os.cshell.PATH)
        return 0
    elseif program == 'getuid' then
        print(os.lib.login.userUID())
        return 0
    elseif program == 'getperm' then
        permission.getPerm()
        return 0
    elseif program == 'CTTY' then
        print(os.lib.tty.getcurrentTTY().id)
        return 0
    end
    found = false
    --part where we see paths and permissions to run and everything
    --TODO: permission checks
    --[[
    if fs.verifyPerm(program, os.currentUser(), 'x') then
        exec_prog = true
    end
    if not exec_proc then
        ferror("csh: unable to run")
    end
    ]]
    --check absolute paths
    if fs.exists(program) then
        --security check: check if program is in /sbin
        local tok = os.strsplit(program, '/')
        if tok[1] ~= '/sbin' then
            found = true
            os.runfile_proc(program, args, itself)
        end
        --if its not, continue to other checks
        --(theorical) security check(still not implemented):
        --to make this possible, os.run needs to be reimplemented with permission checks to run a file
        -- if fs.checkPerm(program, 'r') then
        --     os.runfile_proc(program, args)
        -- end
    --check cwd .. program
    elseif not found and fs.exists(os.cshell.resolve(program)) then
        print(current_path)
        if shell_wd ~= '/sbin' or shell_wd ~= 'sbin' then
            found = true
            os.runfile_proc(os.cshell.resolve(program), args, itself)
        end
    end
    --check program in PATH
    local path = os.strsplit(os.cshell.PATH, ':')
    for _,token in ipairs(path) do
        local K = fs.combine(token..'/', program)
        if not found and fs.exists(K) then
            found = true
            os.runfile_proc(K, args, itself)
        end
    end
    --check /sbin
    if not found and fs.exists(fs.combine("/sbin/", program)) then
        if os.lib.login.userUID == 0 then
            found = true
            os.runfile_proc(fs.combine("/sbin/", program), args, itself)
        end
    end
    --not found
    if not found then
        ferror("csh: "..program..": program not found")
    end
end
local function shcmd(cmd)
    --parse command
    --nothing
    if cmd == nil or cmd == '' then return 0 end
    --comments
    if string.sub(cmd, 1, 1) == '#' then return 0 end
    --parse multiple commands
    for _, command in pairs(os.strsplit(cmd, "&&")) do
        if command:find("|") then --piping
            local count = 1
            local programs = os.strsplit(command, "|")
            local main_pipe = os.lib.pipe.Pipe.new('main')
            for _, prog in pairs(programs) do
                --[[
                For each program, run it with pipe support
                ]]
            end
        else
            --if command does not have |, run program normally
            --now parse the command, with args and everything
            normal_command(command)
        end
    end
end
os.cshell.change_path = function(newpath)
end
os.cshell.resolve = function()
end
os.cshell.run = function(command)
    return shcmd(command)
end
os.cshell.cwd = function(newpwd)
    --only cd can use this
    local cdlock = os.lib.control.get('/bin/cd', 'cd_lock')
    if cdlock == '1' then
        shell_wd = newpwd
    else
        ferror("csh: cwd: cdlock ~= '1'")
    end
end
os.cshell.getwd = function()
    return shell_wd
end
os.cshell.getpwd = os.cshell.getwd
os.cshell.resolve = function(pth)
    local wd = os.cshell.getwd()
    function _combine(c) return wd .. '/' .. c end
    function check_slash(s) return string.sub(s, 1, 1) == '/' end
    if check_slash(pth) then
        return pth
    else
        return _combine(pth)
    end
end
os.cshell.complete = function(pth)
end
function main(args)
    os.shell = os.cshell
    --get first cwd
    shell_wd = os.lib.control.get('/sbin/login', 'cwd')
    --generate a new token.
    shellToken = os.lib.login.Token.new(os.lib.login.currentUser(), 100)
    local HISTORY = {} --csh history
    while true do --main loop
        if shellToken.user == 'root' then --always check if user is root
            shell_char = '#'
        else
            shell_char = '$'
        end
        write(shellToken.user)
        write("@"..gethostname())
        write(":"..shell_wd)
        write(shell_char..' ')
        local cmd = read(nil, HISTORY, os.cshell.complete)
        if cmd == 'exit' then --hardcoded command
            return 0
        elseif cmd ~= nil then
            if command ~= '' or not command:find(" ") then
                table.insert(HISTORY, cmd)
            end
            shcmd(cmd)
        end
    end
end
--running
main({...})
EndFile;
File;etc/initramfs.modules
#This is the file that generate-initramfs uses to genenerate a cubix-initramfs file
#libcubix entry
libcubix
#boot splash entry(disabled by default):
#bootsplash
EndFile;
File;proc/2/cmd
/sbin/login 
EndFile;
File;usr/manuals/pipe.man
On the Subject of Pipes
A pipe is a communication interface between programs(not as well as unix, as unix links stdout of one program to stdin of another), the symbol used to create pipes(in cshell) is "|", a simple example would be:
ps | glep login
as a result, ps will show the list of processes, but glep filters that output, showing only the lines that contain "login", a example result would be:
2 /sbin/init > /sbin/login
EndFile;
File;lib/hash/md5.lua
local md5 = {
  _VERSION     = "md5.lua 1.0.2",
  _DESCRIPTION = "MD5 computation in Lua (5.1-3, LuaJIT)",
  _URL         = "https://github.com/kikito/md5.lua",
  _LICENSE     = [[
    MIT LICENSE
    Copyright (c) 2013 Enrique García Cota + Adam Baldwin + hanzao + Equi 4 Software
    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:
    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
  ]]
}
-- bit lib implementions
local char, byte, format, rep, sub =
  string.char, string.byte, string.format, string.rep, string.sub
local bit_or, bit_and, bit_not, bit_xor, bit_rshift, bit_lshift
local ok, bit = pcall(require, 'bit')
if ok then
  bit_or, bit_and, bit_not, bit_xor, bit_rshift, bit_lshift = bit.bor, bit.band, bit.bnot, bit.bxor, bit.rshift, bit.lshift
else
  ok, bit = pcall(require, 'bit32')
  if ok then
    bit_not = bit.bnot
    local tobit = function(n)
      return n <= 0x7fffffff and n or -(bit_not(n) + 1)
    end
    local normalize = function(f)
      return function(a,b) return tobit(f(tobit(a), tobit(b))) end
    end
    bit_or, bit_and, bit_xor = normalize(bit.bor), normalize(bit.band), normalize(bit.bxor)
    bit_rshift, bit_lshift = normalize(bit.rshift), normalize(bit.lshift)
  else
    local function tbl2number(tbl)
      local result = 0
      local power = 1
      for i = 1, #tbl do
        result = result + tbl[i] * power
        power = power * 2
      end
      return result
    end
    local function expand(t1, t2)
      local big, small = t1, t2
      if(#big < #small) then
        big, small = small, big
      end
      -- expand small
      for i = #small + 1, #big do
        small[i] = 0
      end
    end
    local to_bits -- needs to be declared before bit_not
    bit_not = function(n)
      local tbl = to_bits(n)
      local size = math.max(#tbl, 32)
      for i = 1, size do
        if(tbl[i] == 1) then
          tbl[i] = 0
        else
          tbl[i] = 1
        end
      end
      return tbl2number(tbl)
    end
    -- defined as local above
    to_bits = function (n)
      if(n < 0) then
        -- negative
        return to_bits(bit_not(math.abs(n)) + 1)
      end
      -- to bits table
      local tbl = {}
      local cnt = 1
      local last
      while n > 0 do
        last      = n % 2
        tbl[cnt]  = last
        n         = (n-last)/2
        cnt       = cnt + 1
      end
      return tbl
    end
    bit_or = function(m, n)
      local tbl_m = to_bits(m)
      local tbl_n = to_bits(n)
      expand(tbl_m, tbl_n)
      local tbl = {}
      for i = 1, #tbl_m do
        if(tbl_m[i]== 0 and tbl_n[i] == 0) then
          tbl[i] = 0
        else
          tbl[i] = 1
        end
      end
      return tbl2number(tbl)
    end
    bit_and = function(m, n)
      local tbl_m = to_bits(m)
      local tbl_n = to_bits(n)
      expand(tbl_m, tbl_n)
      local tbl = {}
      for i = 1, #tbl_m do
        if(tbl_m[i]== 0 or tbl_n[i] == 0) then
          tbl[i] = 0
        else
          tbl[i] = 1
        end
      end
      return tbl2number(tbl)
    end
    bit_xor = function(m, n)
      local tbl_m = to_bits(m)
      local tbl_n = to_bits(n)
      expand(tbl_m, tbl_n)
      local tbl = {}
      for i = 1, #tbl_m do
        if(tbl_m[i] ~= tbl_n[i]) then
          tbl[i] = 1
        else
          tbl[i] = 0
        end
      end
      return tbl2number(tbl)
    end
    bit_rshift = function(n, bits)
      local high_bit = 0
      if(n < 0) then
        -- negative
        n = bit_not(math.abs(n)) + 1
        high_bit = 0x80000000
      end
      local floor = math.floor
      for i=1, bits do
        n = n/2
        n = bit_or(floor(n), high_bit)
      end
      return floor(n)
    end
    bit_lshift = function(n, bits)
      if(n < 0) then
        -- negative
        n = bit_not(math.abs(n)) + 1
      end
      for i=1, bits do
        n = n*2
      end
      return bit_and(n, 0xFFFFFFFF)
    end
  end
end
-- convert little-endian 32-bit int to a 4-char string
local function lei2str(i)
  local f=function (s) return char( bit_and( bit_rshift(i, s), 255)) end
  return f(0)..f(8)..f(16)..f(24)
end
-- convert raw string to big-endian int
local function str2bei(s)
  local v=0
  for i=1, #s do
    v = v * 256 + byte(s, i)
  end
  return v
end
-- convert raw string to little-endian int
local function str2lei(s)
  local v=0
  for i = #s,1,-1 do
    v = v*256 + byte(s, i)
  end
  return v
end
-- cut up a string in little-endian ints of given size
local function cut_le_str(s,...)
  local o, r = 1, {}
  local args = {...}
  for i=1, #args do
    table.insert(r, str2lei(sub(s, o, o + args[i] - 1)))
    o = o + args[i]
  end
  return r
end
local swap = function (w) return str2bei(lei2str(w)) end
local function hex2binaryaux(hexval)
  return char(tonumber(hexval, 16))
end
local function hex2binary(hex)
  local result, _ = hex:gsub('..', hex2binaryaux)
  return result
end
-- An MD5 mplementation in Lua, requires bitlib (hacked to use LuaBit from above, ugh)
-- 10/02/2001 jcw@equi4.com
local CONSTS = {
  0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee,
  0xf57c0faf, 0x4787c62a, 0xa8304613, 0xfd469501,
  0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be,
  0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821,
  0xf61e2562, 0xc040b340, 0x265e5a51, 0xe9b6c7aa,
  0xd62f105d, 0x02441453, 0xd8a1e681, 0xe7d3fbc8,
  0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed,
  0xa9e3e905, 0xfcefa3f8, 0x676f02d9, 0x8d2a4c8a,
  0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c,
  0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70,
  0x289b7ec6, 0xeaa127fa, 0xd4ef3085, 0x04881d05,
  0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665,
  0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039,
  0x655b59c3, 0x8f0ccc92, 0xffeff47d, 0x85845dd1,
  0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1,
  0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391,
  0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476
}
local f=function (x,y,z) return bit_or(bit_and(x,y),bit_and(-x-1,z)) end
local g=function (x,y,z) return bit_or(bit_and(x,z),bit_and(y,-z-1)) end
local h=function (x,y,z) return bit_xor(x,bit_xor(y,z)) end
local i=function (x,y,z) return bit_xor(y,bit_or(x,-z-1)) end
local z=function (f,a,b,c,d,x,s,ac)
  a=bit_and(a+f(b,c,d)+x+ac,0xFFFFFFFF)
  -- be *very* careful that left shift does not cause rounding!
  return bit_or(bit_lshift(bit_and(a,bit_rshift(0xFFFFFFFF,s)),s),bit_rshift(a,32-s))+b
end
local function transform(A,B,C,D,X)
  local a,b,c,d=A,B,C,D
  local t=CONSTS
  a=z(f,a,b,c,d,X[ 0], 7,t[ 1])
  d=z(f,d,a,b,c,X[ 1],12,t[ 2])
  c=z(f,c,d,a,b,X[ 2],17,t[ 3])
  b=z(f,b,c,d,a,X[ 3],22,t[ 4])
  a=z(f,a,b,c,d,X[ 4], 7,t[ 5])
  d=z(f,d,a,b,c,X[ 5],12,t[ 6])
  c=z(f,c,d,a,b,X[ 6],17,t[ 7])
  b=z(f,b,c,d,a,X[ 7],22,t[ 8])
  a=z(f,a,b,c,d,X[ 8], 7,t[ 9])
  d=z(f,d,a,b,c,X[ 9],12,t[10])
  c=z(f,c,d,a,b,X[10],17,t[11])
  b=z(f,b,c,d,a,X[11],22,t[12])
  a=z(f,a,b,c,d,X[12], 7,t[13])
  d=z(f,d,a,b,c,X[13],12,t[14])
  c=z(f,c,d,a,b,X[14],17,t[15])
  b=z(f,b,c,d,a,X[15],22,t[16])
  a=z(g,a,b,c,d,X[ 1], 5,t[17])
  d=z(g,d,a,b,c,X[ 6], 9,t[18])
  c=z(g,c,d,a,b,X[11],14,t[19])
  b=z(g,b,c,d,a,X[ 0],20,t[20])
  a=z(g,a,b,c,d,X[ 5], 5,t[21])
  d=z(g,d,a,b,c,X[10], 9,t[22])
  c=z(g,c,d,a,b,X[15],14,t[23])
  b=z(g,b,c,d,a,X[ 4],20,t[24])
  a=z(g,a,b,c,d,X[ 9], 5,t[25])
  d=z(g,d,a,b,c,X[14], 9,t[26])
  c=z(g,c,d,a,b,X[ 3],14,t[27])
  b=z(g,b,c,d,a,X[ 8],20,t[28])
  a=z(g,a,b,c,d,X[13], 5,t[29])
  d=z(g,d,a,b,c,X[ 2], 9,t[30])
  c=z(g,c,d,a,b,X[ 7],14,t[31])
  b=z(g,b,c,d,a,X[12],20,t[32])
  a=z(h,a,b,c,d,X[ 5], 4,t[33])
  d=z(h,d,a,b,c,X[ 8],11,t[34])
  c=z(h,c,d,a,b,X[11],16,t[35])
  b=z(h,b,c,d,a,X[14],23,t[36])
  a=z(h,a,b,c,d,X[ 1], 4,t[37])
  d=z(h,d,a,b,c,X[ 4],11,t[38])
  c=z(h,c,d,a,b,X[ 7],16,t[39])
  b=z(h,b,c,d,a,X[10],23,t[40])
  a=z(h,a,b,c,d,X[13], 4,t[41])
  d=z(h,d,a,b,c,X[ 0],11,t[42])
  c=z(h,c,d,a,b,X[ 3],16,t[43])
  b=z(h,b,c,d,a,X[ 6],23,t[44])
  a=z(h,a,b,c,d,X[ 9], 4,t[45])
  d=z(h,d,a,b,c,X[12],11,t[46])
  c=z(h,c,d,a,b,X[15],16,t[47])
  b=z(h,b,c,d,a,X[ 2],23,t[48])
  a=z(i,a,b,c,d,X[ 0], 6,t[49])
  d=z(i,d,a,b,c,X[ 7],10,t[50])
  c=z(i,c,d,a,b,X[14],15,t[51])
  b=z(i,b,c,d,a,X[ 5],21,t[52])
  a=z(i,a,b,c,d,X[12], 6,t[53])
  d=z(i,d,a,b,c,X[ 3],10,t[54])
  c=z(i,c,d,a,b,X[10],15,t[55])
  b=z(i,b,c,d,a,X[ 1],21,t[56])
  a=z(i,a,b,c,d,X[ 8], 6,t[57])
  d=z(i,d,a,b,c,X[15],10,t[58])
  c=z(i,c,d,a,b,X[ 6],15,t[59])
  b=z(i,b,c,d,a,X[13],21,t[60])
  a=z(i,a,b,c,d,X[ 4], 6,t[61])
  d=z(i,d,a,b,c,X[11],10,t[62])
  c=z(i,c,d,a,b,X[ 2],15,t[63])
  b=z(i,b,c,d,a,X[ 9],21,t[64])
  return A+a,B+b,C+c,D+d
end
----------------------------------------------------------------
function md5_sumhexa(s)
  local msgLen = #s
  local padLen = 56 - msgLen % 64
  if msgLen % 64 > 56 then padLen = padLen + 64 end
  if padLen == 0 then padLen = 64 end
  s = s .. char(128) .. rep(char(0),padLen-1) .. lei2str(8*msgLen) .. lei2str(0)
  assert(#s % 64 == 0)
  local t = CONSTS
  local a,b,c,d = t[65],t[66],t[67],t[68]
  for i=1,#s,64 do
    local X = cut_le_str(sub(s,i,i+63),4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4)
    assert(#X == 16)
    X[0] = table.remove(X,1) -- zero based!
    a,b,c,d = transform(a,b,c,d,X)
  end
  return format("%08x%08x%08x%08x",swap(a),swap(b),swap(c),swap(d))
end
function md5_sum(s)
  return hex2binary(md5_sumhexa(s))
end
return md5
EndFile;
File;boot/sblcfg/craftos
set root=(hdd)
load_video
insmod kernel
kernel /rom/programs/shell
boot
EndFile;
File;bin/mknod
#!/usr/bin/env lua
--/bin/mknod: create devices
_handler = {}
_handler.signal_handler = function(sig)
    if sig == 'kill' then
        --print("mount: SIGKILL")
        return 0
    end
end
function main(args)
    if #args == 4 then
        local path = args[1]
        local type = args[2]
        local major = tonumber(args[3])
        local minor = tonumber(args[4])
        if os.lib.devices then
            os.lib.devices.lddev(path, type, major, minor)
        else
            ferror("mknod: how are you there in limbo?")
        end
    end
end
main({...})
EndFile;
File;proc/2/exe
/sbin/login
EndFile;
File;bin/rm
#!/usr/bin/env lua
--/bin/rm: removes files and folders
_handler = {}
_handler.signal_handler = function(sig)
    if sig == 'kill' then
        --print("rm: SIGKILL")
        return 0
    end
end
function main(args)
    --actually doing multiple args
    for i=1, #args do
        local file = os.cshell.resolve(args[i])
        if fs.exists(file) then
            fs.delete(file)
        else
            ferror("rm: node not found")
        end
    end
end
main({...})
EndFile;
File;bin/umount
#!/usr/bin/env lua
--/bin/umount: umount devices
_handler = {}
_handler.signal_handler = function(sig)
    if sig == 'kill' then
        --print("umount: SIGKILL")
        return 0
    end
end
function main(args)
    if permission.grantAccess(fs.perms.ROOT) then
        local path = args[1]
        local components = os.strsplit(path, '/')
        if components[1] == 'dev' then
            local ok = fsmanager.umount_dev(path)
            if ok[1] == true then
                os.debug.debug_write('[umount] '..path)
            else
                os.debug.debug_write('[umount_dev] error umounting '..path..' : '..ok[2], nil, true)
            end
        else
            local ok = fsmanager.umount_path(path)
            if ok[1] == true then
                os.debug.debug_write('[umount] '..path)
            else
                os.debug.debug_write('[umount_path] error umounting '..path..' : '..ok[2], nil, true)
            end
        end
    else
        os.ferror("umount: system permission is required to umount")
        return 0
    end
end
main({...})
EndFile;
File;usr/manuals/kernel/api.man
Cubix API
os.list_mfiles [table]
    managed files in cubix ["man procmngr"]
os.list_devices [table]
    list the devices registered in cubix ["man devicemngr"]
os.system_halt() [function, nil]
    halts the system execution.
os.viewTable(table) [function, nil]
    show the elements from a table.
os.ferror(s) [function, nil]
    error function
os.safestr(s) [function, string]
    turns a string into printable characters
os.strsplit(s, sep) [function, list]
    emulation of python 'split' function
os.lib.hash.sha256(s) [function, string]
    SHA256 hash of a string
os.lib.hash.md5(s) [function, string]
    MD5 hash of a string
term.set_term_color(color) [function, nil]
    a simple function to compatiblity between Computers and ADV. Computers
EndFile;
File;lib/hash_manager
#!/usr/bin/env lua
--hash manager
--task: automate hash management, using a global object "hash"
hash = {}
function libroutine()
    if os.loadAPI("/lib/hash/sha256.lua") then
        sha256 = _G["sha256.lua"]
        os.debug.debug_write("[hash] sha256: loaded")
        hash.sha256 = sha256.hash_sha256
        local H = hash.sha256("hell")
        if H == "0ebdc3317b75839f643387d783535adc360ca01f33c75f7c1e7373adcd675c0b" then
            os.debug.testcase("[hash] sha256('michigan') test = PASS")
        else
            os.debug.kpanic("[hash] sha256('michigan') test = NOT PASS")
        end
    else
        os.debug.kpanic("[hash] sha256: not loaded")
    end
    if os.loadAPI("/lib/hash/md5.lua") then
        md5 = _G["md5.lua"]
        os.debug.debug_write("[hash] md5: loaded")
        hash.md5 = md5.md5_sumhexa
        local H = hash.md5("hell")
        if H == "4229d691b07b13341da53f17ab9f2416" then
            os.debug.testcase("[hash] md5('michigan') test = PASS")
        else
            os.debug.kpanic("[hash] md5('michigan') test = NOT PASS")
        end
    else
        os.debug.kpanic("[hash] md5: not loaded")
    end
end
EndFile;
File;usr/manuals/kernel/internals.man
On the subject of Internal Functions
Internal Functions are used by the kernel to do its inner workings, the most of them are accesible by os.internals._kernel
WARNING: please, don't mess with them.
register_device(device)
    loads a device into DEVICES list
register_mfile(controller)
    registers a Managed File(MFILE) into cubix["man procmngr"]
register_tty(path, tty)
    registers a TTY to TTYS list
EndFile;
File;bin/cd
#!/usr/bin/env lua
--/bin/cd : change directory
_handler = {}
_handler.signal_handler = function(sig)
    if sig == 'kill' then
        --print("cd: SIGKILL")
        return 0
    end
end
CURRENT_PATH = ''
function strsplit(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t={} ; i=1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        t[i] = str
        i = i + 1
    end
    return t
end
function pth_goup(p)
    elements = strsplit(p, '/')
    res = ''
    for i = 1, (#elements - 1) do
        --print(res)
        res = res .. '/' .. elements[i]
    end
    return res
end
function cd(pth)
    local current_user = os.lib.login.currentUser()
    if CURRENT_PATH == nil then
        CURRENT_PATH = '/'
    elseif pth == nil then
        CURRENT_PATH = "/home/"..current_user
    elseif pth == '.' then
        CURRENT_PATH = CURRENT_PATH
    elseif pth == '..' then
        CURRENT_PATH = pth_goup(CURRENT_PATH)
    elseif pth == '/' then
        CURRENT_PATH = pth
    elseif fs.exists(CURRENT_PATH .. '/' .. pth) == true then
        CURRENT_PATH = CURRENT_PATH .. '/' .. pth
    elseif fs.exists(pth) == true then
        CURRENT_PATH = pth
    else
        print("cd: not found!")
    end --end
end
function main(args)
    local pth = args[1]
    CURRENT_PATH = os.cshell.getpwd()
    cd(pth)
    --local _cpath = fs.open("/tmp/current_path", 'w')
    --_cpath.write(CURRENT_PATH)
    --_cpath.close()
    os.lib.control.register('/bin/cd', 'cd_lock', '1')
    os.cshell.cwd(CURRENT_PATH)
    os.lib.control.register('/bin/cd', 'cd_lock', nil)
end
main({...})
EndFile;
File;lib/comm_manager
#!/usr/bin/env lua
--comm_manager: communication and control manager
-- This manager makes communication between processes without files(resolving the /tmp/current_path issue)
local data = {}
function register(process, label, h)
    local runningproc = os.lib.proc.get_processes()[os.getrunning()]
    if h == nil then h = '' end
    if runningproc == nil or runningproc == -1 then
        ferror("comm: no running process")
        return false
    end
    if runningproc.file == process then
        if data[runningproc.file] == nil then
            data[runningproc.file] = {}
        end
        data[runningproc.file][label] = h
    elseif '/'..runningproc.file == process then
        if data['/'..runningproc.file] == nil then
            data['/'..runningproc.file] = {}
        end
        data['/'..runningproc.file][label] = h
    else
        ferror("comm_manager: running process ~= process")
    end
end
function get(process, label)
    if not data[process] then
        return nil
    end
    return data[process][label]
end
function libroutine()
end
EndFile;
File;proc/3/stat
stat working
EndFile;
File;bin/yapi
#!/usr/bin/env lua
--/bin/yapi: Yet Another Package Installer (with a pacman syntax-like)
AUTHOR = 'Lukas Mendes'
VERSION = '0.1.2'
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        os.debug.debug_write("yapi: SIGKILL'd!", false)
        return 0
    end
end
--defining some things
local SERVERIP = 'lkmnds.github.io'
local SERVERDIR = '/yapi'
local YAPIDIR = '/var/yapi'
function download_file(url)
    local cache = os.strsplit(url, '/')
    local fname = cache[#cache]
    print('requesting ' .. fname)
    http.request(url)
    local req = true
    while req do
        local e, url, stext = os.pullEvent()
        if e == 'http_success' then
            local rText = stext.readAll()
            stext.close()
            return rText
        elseif e == 'http_failure' then
            req = false
            return {false, 'http_failure'}
        end
    end
end
function success(msg)
    term.set_term_color(colors.green)
    print(msg)
    term.set_term_color(colors.white)
end
function cache_file(data, filename)
    local h = fs.open(YAPIDIR..'/cache/'..filename, 'w')
    h.write(data)
    h.close()
    return 0
end
function isin(inputstr, wantstr)
    for i = 1, #inputstr do
        local v = string.sub(inputstr, i, i)
        if v == wantstr then return true end
    end
    return false
end
function create_default_struct()
    fs.makeDir(YAPIDIR.."/cache")
    fs.makeDir(YAPIDIR.."/db")
    fs.open(YAPIDIR..'/installedpkg', 'a').close()
end
function update_repos()
    --download core, community and extra
    local SPATH = 'http://'.. SERVERIP .. SERVERDIR .. '/database/core'
    local k = download_file(SPATH)
    if type(k) == 'table' then
        ferror("yapi: http error")
        return 1
    end
    local _h = fs.open(YAPIDIR..'/db/core', 'w')
    _h.write(k)
    _h.close()
    local SPATH = 'http://'.. SERVERIP .. SERVERDIR .. '/database/community'
    local k = download_file(SPATH)
    if type(k) == 'table' then
        ferror("yapi: http error")
        return 1
    end
    local _h = fs.open(YAPIDIR..'/db/community', 'w')
    _h.write(k)
    _h.close()
    local SPATH = 'http://'.. SERVERIP .. SERVERDIR .. '/database/extra'
    local k = download_file(SPATH)
    if type(k) == 'table' then
        ferror("yapi: http error")
        return 1
    end
    local _h = fs.open(YAPIDIR..'/db/extra', 'w')
    _h.write(k)
    _h.close()
end
--Yapi Database
yapidb = {}
yapidb.__index = yapidb
function yapidb.new(path)
    local inst = {}
    setmetatable(inst, yapidb)
    inst.path = path
    inst.db = ''
    return inst
end
function yapidb:update()
    self.db = ''
    self.db = self.db .. '\n'
    local h = fs.open(self.path..'/core', 'r')
    local _k = h.readAll()
    self.db = self.db .. _k
    h.close()
    self.db = self.db .. '\n'
    local h = fs.open(self.path..'/community', 'r')
    local _k = h.readAll()
    self.db = self.db .. '\n'
    self.db = self.db .. _k
    h.close()
    self.db = self.db .. '\n'
    local h = fs.open(self.path..'/extra', 'r')
    local _k = h.readAll()
    self.db = self.db .. '\n'
    self.db = self.db .. _k
    self.db = self.db .. '\n'
    h.close()
end
function yapidb:search(pkgname)
    self:update()
    local _lines = self.db
    local lines = os.strsplit(_lines, '\n')
    for k,v in pairs(lines) do
        local pkgdata = os.strsplit(v, ';')
        if pkgdata[1] == pkgname then
            return {true, v}
        end
    end
    return {false, nil}
end
function yapidb:search_wcache(pkgname)
    self:update()
    if fs.exists(YAPIDIR..'/cache/'..pkgname..'.yap') then
        local h = fs.open(YAPIDIR..'/cache/'..pkgname..'.yap', 'r')
        local f = h.readAll()
        h.close()
        return f
    else
        local _url = self:search(pkgname)
        local url = os.strsplit(_url[2], ';')[2]
        local yapdata = download_file(url)
        if type(yapdata) == 'table' then return -1 end
        cache_file(yapdata, pkgname..'.yap')
        return yapdata
    end
end
--parsing yap files
function parse_yap(yapf)
    local lines = os.strsplit(yapf, '\n')
    local yapobject = {}
    yapobject['folders'] = {}
    yapobject['files'] = {}
    yapobject['deps'] = {}
    if type(lines) ~= 'table' then
        os.ferror("::! [parse_yap] type(lines) ~= table")
        return 1
    end
    local isFile = false
    local rFile = ''
    for _,v in pairs(lines) do
        if isFile then
            local d = v
            if d ~= 'EndFile;' then
                if yapobject['files'][rFile] == nil then
                    yapobject['files'][rFile] = d .. '\n'
                else
                    yapobject['files'][rFile] = yapobject['files'][rFile] .. d .. '\n'
                end
            else
                isFile = false
                rFile = ''
            end
        end
        local splitted = os.strsplit(v, ';')
        if splitted[1] == 'Name' then
            yapobject['name'] = splitted[2]
        elseif splitted[1] == 'Version' then
            yapobject['version'] = splitted[2]
        elseif splitted[1] == 'Build' then
            yapobject['build'] = splitted[2]
        elseif splitted[1] == 'Author' then
            yapobject['author'] = splitted[2]
        elseif splitted[1] == 'Email-Author' then
            yapobject['email_author'] = splitted[2]
        elseif splitted[1] == 'Description' then
            yapobject['description'] = splitted[2]
        elseif splitted[1] == 'Folder' then
            table.insert(yapobject['folders'], splitted[2])
        elseif splitted[1] == 'File' then
            isFile = true
            rFile = splitted[2]
        elseif splitted[1] == 'Dep' then
            table.insert(yapobject['deps'], splitted[2])
        end
    end
    return yapobject
end
function yapidb:installed_pkgs()
    local handler = fs.open(YAPIDIR..'/installedpkg', 'r')
    local file = handler.readAll()
    handler.close()
    local lines = os.strsplit(file, '\n')
    return lines
end
function yapidb:is_installed(namepkg)
    local installed = self:installed_pkgs()
    for k,v in ipairs(installed) do
        local splitted = os.strsplit(v, ';')
        if splitted[1] == namepkg then return true end
    end
    return false
end
function yapidb:updatepkgs()
    self:update()
    for k,v in pairs(self:installed_pkgs()) do
        local pair = os.strsplit(v, ';')
        local w = self:search(pair[1])
        local yd = {}
        if w[1] == false then
            os.ferror("::! updatepkgs: search error")
            return false
        end
        local url = os.strsplit(w[2], ';')[2]
        local rawdata = download_file(url)
        if type(rawdata) == 'table' then
            os.ferror("::! [install] type(rawdata) == table : "..yapfile[2])
            return false
        end
        local yd = parse_yap(rawdata)
        if tonumber(pair[2]) < tonumber(yd['build']) then
            print(" -> new build of "..pair[1].." ["..pair[2].."->"..yd['build'].."] ")
            self:install(pair[1]) --install latest
        else
            print(" -> [updatepkgs] "..yd['name']..": OK")
        end
    end
end
function yapidb:register_pkg(yapdata)
    print("==> [register] "..yapdata['name'])
    local _h = fs.open(YAPIDIR..'/installedpkg', 'r')
    local _tLines = _h.readAll()
    _h.close()
    local pkg_found = false
    local tLines = os.strsplit(_tLines, '\n')
    for k,v in ipairs(tLines) do
        local pair = os.strsplit(v, ';')
        if pair[1] == yapdata['name'] then
            pkg_found = true
            tLines[k] = yapdata['name']..';'..yapdata['build']
        else
            tLines[k] = tLines[k] .. '\n'
        end
    end
    if not pkg_found then
        tLines[#tLines+1] = yapdata['name']..';'..yapdata['build'] .. '\n'
    end
    print(" -> writing to file")
    local h2 = fs.open(YAPIDIR..'/installedpkg', 'w')
    for k,v in pairs(tLines) do
        h2.write(v)
    end
    h2.close()
end
function yapidb:install_yap(yapdata)
    print("==> install_yap: "..yapdata['name'])
    for k,v in pairs(yapdata['folders']) do
        fs.makeDir(v)
    end
    for k,v in pairs(yapdata['files']) do
        local h = fs.open(k, 'w')
        h.write(v)
        h.close()
    end
    return true
end
function yapidb:return_dep_onepkg(pkgname)
    local _s = self:search(pkgname)
    if _s[1] == true then
        local result = os.strsplit(_s[2], ';')
        local yapfile = download_file(result[2])
        if type(yapfile) == 'table' then
            os.ferror("::! [getdep] "..yapfile[2])
            return false
        end
        cache_file(yapfile, pkgname..'.yap')
        local yapdata = parse_yap(yapfile)
        local dependencies = {}
        if yapdata['deps'] == nil then
            print(" -> no dependencies: "..pkgname)
            return {}
        end
        for _,dep in ipairs(yapdata['deps']) do
            if not self:is_installed(dep) then
                table.insert(dependencies, dep)
            end
        end
        return dependencies
    else
        return false
    end
end
function yapidb:return_deps(pkglist)
    local r = {}
    for _,pkg in ipairs(pkglist) do
        local c = self:return_dep_onepkg(pkg)
        if c == false then
            ferror("::! [getdeps] error getting deps: "..pkg)
            return nil
        end
        for i=0,#c do
            table.insert(r, c[i])
        end
        table.insert(r, pkg)
    end
    return r
end
function yapidb:install(pkgname)
    local _s = self:search(pkgname)
    if _s[1] == true then
        local result = os.strsplit(_s[2], ';')
        local yapfile = download_file(result[2])
        if type(yapfile) == 'table' then
            os.ferror("::! [install] "..yapfile[2])
            return false
        end
        cache_file(yapfile, pkgname..'.yap')
        local yapdata = parse_yap(yapfile)
        local missing_dep = {}
        if yapdata['deps'] == nil then
            print(" -> no dependencies: "..pkgname)
        else
            for _,dep in ipairs(yapdata['deps']) do
                if not self:is_installed(dep) then
                    table.insert(missing_dep, dep)
                end
            end
        end
        if #missing_dep > 0 then
            ferror("error: missing dependencies")
            for _,v in ipairs(missing_dep) do
                write(v..' ')
            end
            write('\n')
            return false
        end
        self:register_pkg(yapdata)
        self:install_yap(yapdata)
        return true
    else
        os.ferror("error: target not found: "..pkgname)
        return false
    end
end
function yapidb:remove(pkgname)
    --1st: read cached yapdata
    --2nd: remove all files made by yapdata['files']
    --3rd: remove entry in YAPIDIR..'/installedpkg'
    if not self:is_installed(pkgname) then
        os.ferror(" -> package not installed")
        return false
    end
    local yfile = self:search_wcache(pkgname)
    local ydata = parse_yap(yfile)
    --2nd part
    print("==> remove: "..ydata['name'])
    for k,v in pairs(ydata['files']) do
        --print(" -> removing "..k)
        fs.delete(k)
    end
    for k,v in pairs(ydata['folders']) do
        --print(" -> removing folder "..v)
        fs.delete(v)
    end
    --3rd part
    --print(" -> remove_entry: "..ydata['name'])
    local _h = fs.open(YAPIDIR..'/installedpkg', 'r')
    local _tLines = _h.readAll()
    _h.close()
    local pkg_found = false
    local tLines = os.strsplit(_tLines, '\n')
    for k,v in ipairs(tLines) do
        local pair = os.strsplit(v, ';')
        if pair[1] == ydata['name'] then
            tLines[k] = '\n'
        else
            tLines[k] = tLines[k] .. '\n'
        end
    end
    --print(" -> writing empty entry")
    local h2 = fs.open(YAPIDIR..'/installedpkg', 'w')
    for k,v in pairs(tLines) do
        h2.write(v)
    end
    h2.close()
    return true
end
function yapidb:clear_cache()
    fs.delete(YAPIDIR..'/cache')
    fs.makeDir(YAPIDIR..'/cache')
end
function main(args)
    if not permission.grantAccess(fs.perms.SYS) then
        os.ferror("yapi: not running as root")
        return 1
    end
    create_default_struct()
    if #args == 0 then
        print("usage: yapi <mode> ...")
    else
        local option = args[1]
        if string.sub(option, 1, 1) == '-' then
            if string.sub(option, 2,2) == 'S' then
                local packages = os.tail(args)
                if packages ~= nil then
                    local database = yapidb.new(YAPIDIR..'/db')
                    database:update()
                    for k,pkg in ipairs(packages) do
                        if not database:search(pkg)[1] then
                            os.ferror("error: target not found: "..pkg)
                            return 1
                        end
                    end
                    print("resolving dependencies...")
                    packages = database:return_deps(packages)
                    print("")
                    if packages == nil then
                        os.ferror("yapi: error getting deps")
                        return 1
                    end
                    write("Packages ("..#packages..") ")
                    for _,pkg in ipairs(packages) do
                        write(pkg..' ')
                    end
                    print("\n")
                    if not prompt(":: Proceed with installation?", "Y", "n") then
                        print("==> Aborted")
                        return true
                    end
                    for k,package in ipairs(packages) do
                        print(":: Installing packages ...")
                        local completed = 1
                        if database:install(package) then
                            success("("..completed.."/"..tostring(#packages)..")"..package.." : SUCCESS")
                            completed = completed + 1
                        else
                            return 1
                        end
                    end
                end
                if isin(option, 'c') then
                    local database = yapidb.new(YAPIDIR..'/db')
                    print("==> [clear_cache]")
                    database:clear_cache()
                end
                if isin(option, 'y') then
                    print(":: Update from "..SERVERIP)
                    if not http then
                        os.ferror("yapi: http not enabled")
                        return 1
                    end
                    update_repos()
                end
                if isin(option, 'u') then
                    local database = yapidb.new(YAPIDIR..'/db')
                    print(":: Starting full system upgrade")
                    if prompt("Confirm full system upgrade", "Y", "n") then
                        database:updatepkgs()
                    else
                        print("==> Aborted")
                    end
                end
            elseif string.sub(option,2,2) == 'U' then
                local yfile = os.cshell.resolve(args[2])
                print("==> [install_yap] "..yfile)
                if not fs.exists(yfile) then
                    ferror("-> file does not exist")
                    return 0
                end
                local h = fs.open(yfile, 'r')
                local _data = h.readAll()
                h.close()
                local ydata = parse_yap(_data)
                local database = yapidb.new(YAPIDIR..'/db')
                if database:install_yap(ydata) then
                    success("==> [install_yap] "..ydata['name'])
                else
                    os.ferror("::! [install_yap] "..ydata['name'])
                end
            elseif string.sub(option,2,2) == 'Q' then
                local database = yapidb.new(YAPIDIR..'/db')
                local pkg = args[2]
                local _k = database:search(pkg)
                if pkg then
                    if _k[1] == true then
                        local _c = database:search_wcache(pkg)
                        local yobj = parse_yap(_c)
                        if type(yobj) ~= 'table' then
                            os.ferror("::! [list -> parse_yap] error (yobj ~= table)")
                            return 1
                        end
                        print(yobj.name .. ' ' .. yobj.build .. ':' .. yobj.version)
                        print("Maintainer: "..yobj.author.." <"..yobj['email_author']..">")
                        print("Description: "..yobj.description)
                    else
                        os.ferror("::! package not found")
                    end
                end
                if isin(option, 'e') then
                    local database = yapidb.new(YAPIDIR..'/db')
                    database:update()
                    local ipkg = database:installed_pkgs()
                    for _,ntv in ipairs(ipkg) do
                        local v = os.strsplit(ntv, ';')
                        write(v[1] .. ':' .. v[2] .. '\n')
                    end
                end
            elseif string.sub(option,2,2) == 'R' then
                local packages = os.tail(args)
                if packages ~= nil then
                    local database = yapidb.new(YAPIDIR..'/db')
                    database:update()
                    for k,pkg in ipairs(packages) do
                        if not database:search(pkg)[1] then
                            os.ferror("error: target not found: "..pkg)
                            return 1
                        end
                    end
                    if not prompt("Proceed with remotion?", "Y", "n") then
                        print("==> Aborted")
                        return true
                    end
                    for k,package in ipairs(packages) do
                        --local database = yapidb.new(YAPIDIR..'/db')
                        --database:update()
                        print(":: removing "..package)
                        if database:remove(package) then
                            success("==> [remove] "..package.." : SUCCESS")
                        else
                            os.ferror("::! [remove] "..package.." : FAILURE")
                            return 1
                        end
                    end
                end
            end
        else
            os.ferror("yapi: sorry, see \"man yapi\" for details")
        end
    end
end
main({...})
EndFile;
File;bin/hashrate
#!/usr/bin/env lua
--/bin/hashrate_test
--livre,
hc = 1
seconds = 0
function hashing_start()
    print("hashing_start here")
    while true do
        local k = os.lib.hash.hash.sha256('constant1' .. 'constant2' .. tostring(hc))
        write(k..'\n')
        hc = hc + 1
        sleep(0)
    end
    print("hashing_start ded")
end
function hashing_count()
    print("hashing_count here")
    while true do
        local hrate = hc / seconds
        term.set_term_color(colors.red)
        term.setCursorPos(1,1)
        print("hashrate: "..tostring(hrate)..' h/s')
        term.set_term_color(colors.white)
        seconds = seconds + 1
        sleep(1)
    end
    print("hashing_count ded")
end
function main(args)
    print("starting Hashrate program")
    local seconds = 0
    os.startThread(hashing_count)
    os.startThread(hashing_start)
    return 0
end
--thread API
local threads = {}
local starting = {}
local eventFilter = nil
rawset(os, "startThread", function(fn, blockTerminate)
        table.insert(starting, {
                cr = coroutine.create(fn),
                blockTerminate = blockTerminate or false,
                error = nil,
                dead = false,
                filter = nil
        })
end)
local function tick(t, evt, ...)
        if t.dead then return end
        if t.filter ~= nil and evt ~= t.filter then return end
        if evt == "terminate" and t.blockTerminate then return end
        coroutine.resume(t.cr, evt, ...)
        t.dead = (coroutine.status(t.cr) == "dead")
end
local function tickAll()
        if #starting > 0 then
                local clone = starting
                starting = {}
                for _,v in ipairs(clone) do
                        tick(v)
                        table.insert(threads, v)
                end
        end
        local e
        if eventFilter then
                e = {eventFilter(coroutine.yield())}
        else
                e = {coroutine.yield()}
        end
        local dead = nil
        for k,v in ipairs(threads) do
                tick(v, unpack(e))
                if v.dead then
                        if dead == nil then dead = {} end
                        table.insert(dead, k - #dead)
                end
        end
        if dead ~= nil then
                for _,v in ipairs(dead) do
                        table.remove(threads, v)
                end
        end
end
rawset(os, "setGlobalEventFilter", function(fn)
        if eventFilter ~= nil then error("This can only be set once!") end
        eventFilter = fn
        rawset(os, "setGlobalEventFilter", nil)
end)
if type(main) == "function" then
        os.startThread(main)
else
        os.startThread(function() shell.run("shell") end)
end
while #threads > 0 or #starting > 0 do
        tickAll()
end
EndFile;
File;usr/manuals/debugmngr.man
Debug Manager
Task #1:
    Manage debug information from the OS and from other managers
    All of the functions of the Debug Manager can be found in os.debug (no, the debug manager isn't loaded like other modules(with loadmodule), instead, loadAPI is used)
    The system log can be found in /tmp/syslog(will be deleted when shutdown["man acpi"])
    debug_write(message[, toScreen, isErrorMessage])
        writes message to screen if toscreen is nil
        if toscreen is false it does not write a message
        but in any of the cases it writes the message to the __debug_buffer
    dmesg()
        shows __debug_buffer
    kpanic()
        Kernel Panic!
EndFile;
File;dev/stdin
EndFile;
File;changelog
0.5.1 - 0.5.2 (17-01-2015) [just writing changes before official release]
  tl;dr this is not finished
  Major changes:
    +login manager rewrited (sudoers, groups, and more)!
    +added better support for devices
  Devices:
    +changed way /dev/random and /dev/urandom get random seeds(based on os.clock(), not os.time())
0.4.0 - 0.5.1 (12-21-2015)
  tl;dr you should use this now
  Major changes:
    +yapi works! (more details in commit 596ce81)
    +luaX, a graphical interface to cubix!
  General changes(cubixli and cubix):
    *bugfix: running runlevel as a kernel option
    */tmp/debug_info is now /tmp/syslog
    +os.ferror is in _G too(as only ferror)
    +external device support(stdin, stdout and stderr almost finished)
    +new device: /dev/full
    +added more signals in os.signals
    +loadmodule_ret: returns the module _G, instead of putting it on os.lib
    +device_write and device_read are the default interfaces to devices now.
    +/sbin/sbl-mkconfig: 'default' mode now generates system.cfg based of default.cfg, not in a hardcoded way anymore
    +dev_available(path): simply returns true if the device exists, false if its not
  Libraries:
    +proc:
        +os.getrunning() returns the running PID of the system
        +generate_pfolder(process, procfolder) generates a /proc/<pid> folder, with the executable and the status of the process
    +os.debug.kpanic: when lx is loaded, shows a beautiful panic message
    +login: kpanic when opening /tmp/current_user or /tmp/current_path gives an error
    +acpi:
        +clears /proc/<pid> folders when __clear_temp is called
        +sets CUBIX_TURNINGOFF to true when acpi_shutdown is called
        +sets CUBIX_REBOOTING to true when acpi_reboot is called
          +because of that, init won't cause a reboot to be a shutdown
  Added programs:
    +/bin/panic: just calls kpanic
    +/bin/curtime: shows current time(GMT 0)
    +/bin/hashrate: just a utility.
  CubixLI:
    +yapstrap creates /tmp/install_lock, not unloadenv
    +sbl_bcfg: restores systems.cfg to default configurations(just in case if the cubix repo provides a broken systems.cfg or a different one from the recommended)
    +timesetup: writes servers to /etc/time-servers
    +genfstab: coming in another commit, but it is there
  Manuals:
    +CMFL, Cubix Manual Formatting Language.
        yapi manual is written in cmfl, you should see it
0.3.7 - 0.4.0 (11-28-2015)
  +Finally, a stable version(still has its bugs but yeah)
  ![/bin/sleep /bin/read] bugs everything, deleted for now
  +cubixli has some workarounds to deldisk
    this includes deleting the partitions cubixli created
    (leading to a halt)
  +cubixli: lsblk, cat, shutdown, sethostname
  +cubixli: "override", when the override flag is activated, all the commands that are not allowed are done
  +/sbin/init: runlevels 3 and 5 being made
0.3.6 - 0.3.7 (11-16-2015)
  +Writing a Installer(cubix_live_installer or cubixli for short)
  -/boot/cubix_minimal does not exist anymore
  +rewrited manuals for 0.3.7
  -os.runfile (yes, this is now marked as bad)
  +finally, /bin/cksum works(only with files)!
  +/bin/cat works with pipes(getting from file and throwing into a pipe)
  +rewrited [/bin/cp /bin/mkdir /bin/mv], using os.chell.resolve now
  +os.cshell.getpwd
  +/bin/eject works using disk.eject, not os.runfile
  -[/bin/read /bin/sleep] is not working [proposital as I'm working on a solution]
  +/bin/rm does not use os.runfile, using fs.delete now
  +/bin/sh uses os.runfile_proc, not os.runfile
  !/bin/wget: working on problems
  !/bin/yapi: still WIP
  +/bin/yes: rewrite based on dev_random
  +/boot/cubix sets IS_CUBIX = true when booting
  *bugfix: runlevel= wasnt working
  +_prompt(message, yescmd, ncmd)
    -Shows a prompt to the user, if he types the same as yescmd, return true
  *bugfix_sbl: kernel module works
  +/dev/MAKEDEV removes /tmp
  +acpi deletes and creates /tmp, not using os.runfile
  +Pipe:readAll()
  +check in proc_manager if p.rfile.main ~= nil and p.rfile.main == function
  +os.run_process sends SIGKILL to process after its execution
  *bugfix: /sbin/adduser crashed when #args == 0
  +/sbin/adduser uses os.lib.login
  +/sbin/init runs scripts in /etc/rc1.d using shell.run, not os.runfile
  +Rewrite of some manual pages
0.3.5 - 0.3.6 (11-07-2015)
  *bugfix: /dev/MAKEDEV does not work more on craftOS, fixed installation
  +SBL: bootscripts!
  +Yet Another Package Installer: /bin/yapi
  +NEW: os.tail
  !os.strsplit now warns you if the type of inputstr isn't string
  +/startup now runs /boot/sbl
0.3.4 - 0.3.5 (10-31-2015)
  +Cubix is now MIT licensed
  +new (not new) security lock: when kernel is stable, "os.pullEvent = os.pullEventRaw" is applied
  +new: /sbin/modprobe
  +when loadmodule() loads a module that RELOADABLE = false is defined, it does not load the module
    This helps when trying to "modprobe proc /lib/proc_manager", since this would wipe os.processes,
    leaving no trace of init or other processes
  *bugfix: /bin/cshell does not run /sbin/, even if you provide the path
  +/bin/ls does not depend of os.runfile (own algorithim now)
  -os.runfile: DEPRECATED!
  +/bin/sudo uses permission module and front_login
  +os.system_halt does not use os.sleep(10000...) anymore
  !SBL: CraftOS does not boot anymore, still working on it
  +acpi uses permission now
  +acpi: acpi_suspend() works (/sbin/pm-suspend)!
  +debug_write(message, screen) -> debug_write(message, screen, isError)
  +new: debug.warning(message)
  {disclaimer here: I used quite a lot of code from UberOS to create
  the filesystem manager to now, because of this, cubix is now MIT licensed}
  +fs_manager: permissions in unix format, load filesystems(for now its
  CFS, cubix file system, but there will be more), nodes and mounting devices(/bin/mount and /bin/umount) :D
  +/sbin/kill: now can kill multiple PIDs!
  !sudo: because of magic, sudo still makes it way to os.processes, even
  if killed, so, don't trust it
  +/bin/license: shows /LICENSE
0.3.3 - 0.3.4 (10-21-2015)
  +new loading mechanism for kernel, decreasing its size
  +login now uses sha256(password + salt) instead of sha256(password)
  +login: session tokens!
  +ACPI management now possible(SBL loads it by default)!
  +new: os.generateSalt
  *bugfix: /proc/cpuinfo & /proc/temperature now support stripping
  +new: /proc/partitions
  +new TTY logic
0.3.2 - 0.3.3 (10-13-2015)
  +new pipe logic using classes
  +starting fs_manager
  +/bin/tee now works!
  *bugfix: "while true do" in /bin/yes
  +/bin/cshell: now searches in path
  +/bin/sudo: now ignores if current user is root
  +/bin/init: runlevels (incomplete)
  +debug: kernel panic complete
  *fix: proc_manager: now the first PID is 1, not 2!
  +/bin/cpkg: Cubix Packages [wip]
  +reboot moved to /sbin
0.3.1 - 0.3.2 (10-10-2015)
  *bugfix: factor makes a infinite loop when n <= 0
  +/bin/cscript: CubixScript [going to create a manual]!
  +/bin/glep: grep in lua!
  +SBL: now you can load a kernel manually!
  +/bin/cubix
    +added boot options, for now its just "quiet" and "nodebug".
    +NEW os.pprint, stands for "pipe print"
  +/sbin/init
    +runlevels (still working)
  +/bin/cshell: FINALLY, PIPES! ("ps | glep login" works)
0.3.0 - 0.3.1 (10-07-2015)
  +/bin/cshell: now has a history
  +/bin/wget
  +/bin/cubix: NEW os.safestr, os.strsplit
    +about init: now init has some control about how the system will load (just loads /sbin/login, but its a thing!)
  +/dev/random: not using os.time(), using os.clock() instead!
  +procmanager: calls to debug are being written to os.debug
0.2.1 - 0.3.0 (10-05-2015)
  -bugfix in cp, rn, mv, mkdir, touch (including the draft nano)... (string comparison, "s[1] == 'a'" does not work)
  -consistency fix on cat: opening a file and not closing it after use
  -cp: does not require absolute paths now!
  -su and sulogin: using os.runfile() now
  -cleanup: not using /bin/shell and /bin/wshell anymore!
  -/dev/MAKEDEV now creates /usr
  -login manager: add users and change password of a user
0.1.0a - 0.2.1 (by 09-30-2015)
  -proc_manager now can kill processes, including their children!
    -every program has to have its main(args) function defined!, it's a rule.
    -proc_manager runs this function when the process of a file is created and run(using os.run_process)
  -Manuals!, use man to run, following the syntax:
    -man <topic> <manual>
      -follows to /usr/manuals/topic/manual.man
    -man <manual>
      -follows to /usr/manuals/manual.man
EndFile;
File;FINISHINSTALL
_G['shell'] = shell
os.loadAPI("/dev/MAKEDEV")
EndFile;
File;lib/proc_manager
#!/usr/bin/env lua
--proc manager
--task: manage /proc, creating its special files;
--manage processes, threads and signals to processes.
RELOADABLE = false
--os.processes = {}
--secutiry fix
local processes = {}
os.pid_last = 0
local running = 0
os.signals = {}
os.signals.SIGKILL = 0
os.signals.SIGINT = 2
os.signals.SIGQUIT = 3
os.signals.SIGILL = 4 --illegal instruction
os.signals.SIGFPE = 8
os.signals.SIGTERM = 15 --termination
os.sys_signal = function (signal)
    --this just translates the recieved signal to a printable string
    local signal_str = ''
    if signal == os.signals.SIGILL then
        signal_str = 'Illegal instruction'
    elseif signal == os.signals.SIGFPE then
        signal_str = 'Floating Point Exception'
    end
    ferror(signal_str)
    return 0
end
os.call_handle = function(process, sig)
    program_env = {}
    program_env.__PS_SIGNAL = sig
    os.run(program_env, process.file)
end
os.send_signal = function (proc, signal)
    if proc == nil then
        os.ferror("proc.send_signal: process == nil")
    elseif proc == -1 then
        os.ferror("proc.send_signal: process was killed")
    elseif signal == os.signals.SIGKILL then
        os.debug.debug_write("[proc_manager] SIGKILL -> "..proc.file, false)
        processes[proc.pid] = -1 --removing anything related to the process in os.processes
        for k,v in pairs(proc.childs) do
            os.terminate(v)
        end
        os.terminate(proc)
    end
end
function __killallproc()
    for k,v in ipairs(processes) do
        if v ~= -1 then
            os.send_signal(v, os.signals.SIGKILL)
        end
    end
end
os.terminate = function (p)
    --os.call_handle(p, "kill")
    if p.pid == 1 then
        if CUBIX_TURNINGOFF or CUBIX_REBOOTING then
            return 0
        else
            os.shutdown()
        end
    end
    p = nil
    --os.sleep(1)
end
os.getrunning = function()
    return running
end
function generate_pfolder(proc, folder, arguments)
    --[[
    exe - executable
    stat - status
    status - status (human readable)
    ]]
    local exe_handler = fs.open(fs.combine(folder, 'exe'), 'w')
    exe_handler.write(proc.file)
    exe_handler.close()
    local stat_handler = fs.open(fs.combine(folder, 'stat'), 'w')
    stat_handler.write("stat working")
    stat_handler.close()
    local line_args = ''
    for k,v in ipairs(arguments) do
        line_args = line_args .. v .. ' '
    end
    local cmd_handler = fs.open(fs.combine(folder, 'cmd'), 'w')
    cmd_handler.write(proc.file..' '..line_args)
    cmd_handler.close()
end
os.run_process = function(process, arguments, pipe)
    --[[
    So, about the issue of non-compatibility with
    "CraftOS" designed programs with
    "Cubix" programs, mostly because of the main() function
    this new os.run_process is able to solve this
    all "Cubix" programs must run the main function by themselves,
    since I will use os.run to run them
    Issue #1: pipe does not work as old
    since the programs are  by os.run, the manager will not
    be able to comunicate
    ]]
    if arguments == nil then arguments = {} end
    --if pipe == nil then pipe = {} end
    os.debug.debug_write("[process]  "..process.file.." pid="..tostring(process.pid), false)
    permission.default()
    running = process.pid
    processes[process.pid] = process
    local cu = os.lib.login.currentUser()
    if cu == '' then
        process.user = 'root'
    else
        process.user = cu
    end
    local ctty = os.lib.tty.getcurrentTTY()
    if ctty == nil or ctty == {} or ctty == '' then
        process.tty = '/dev/ttde'
    else
        process.tty = ctty.id
    end
    local line_args = ''
    for k,v in ipairs(arguments) do
        line_args = line_args .. v .. ' '
    end
    process.lineargs = line_args
    local proc_folder = "/proc/"..tostring(process.pid)
    fs.makeDir(proc_folder)
    generate_pfolder(process, proc_folder, arguments)
    process.uid = os.lib.login.userUID()
    --_G['pipe'] = pipe
    os.run({pipe=pipe}, process.file, unpack(arguments,1))
    --finish process
    fs.delete(proc_folder)
    os.send_signal(process, os.signals.SIGKILL)
end
os.set_child = function(prnt, proc)
    prnt.childs[#prnt.childs + 1] = proc
end
os.set_parent = function(proc, parent)
    os.set_child(parent, proc)
    proc.parent = parent.file
end
os.new_process = function(executable)
    local cls = {}
    os.pid_last = os.pid_last + 1
    cls.pid = os.pid_last
    cls.file = executable
    cls.parent = nil
    cls.childs = {}
    cls.rfile = nil
    cls.uid = -1
    cls.lineargs = ''
    cls.user = ''
    cls.tty = ''
    os.debug.debug_write("[proc] new: "..cls.file, false)
    return cls
end
os.currentUID = function()
    local proc = processes[running]
    if proc == nil or proc == -1 then
        return nil
    else
        return proc.uid
    end
end
--executable: string
--arguments: table
--parent: process
--pipe: Pipe
os.runfile_proc = function(executable, arguments, parent, pipe)
    if parent == nil then
        _parent = os.__parent_init --making sure /sbin/init is parent of all processes(without parent)
    else
        _parent = parent
    end
    if arguments == nil then arguments = {} end
    --if pipe == nil then pipe = pipemngr.new_pipe("empty") end
    _process = os.new_process(executable) --creating
    os.set_parent(_process, _parent) --parenting
    os.run_process(_process, arguments, pipe) --running.
end
function get_processes()
    return deepcopy(processes)
end
function get_by_pid(pid)
    --get a process by its PID(not of deepcopy, but the original process) with permission
    if permission.grantAccess(fs.perms.SYS)
     or processes[running].file == '/sbin/login'
     or processes[running] == '/sbin/kill'
     or processes[running] == 'sbin/kill' then
        return processes[pid]
    else
        ferror("get_by_pid: perm error")
    end
end
FLAG_CTTY = 0 --all processes in the same tty(the tty)
FLAG_ATTY = 1 --all process in all tty
FLAG_APRC = 2 --all process in the system
--filters processes by its flag
function filter_proc(filter_flag)
    if filter_flag == FLAG_CTTY then
        local ctty = os.lib.tty.getcurrentTTY()
        local filtered = {}
        for k,v in pairs(get_processes()) do
            if v ~= -1 then
                if v.tty == ctty.id then
                    filtered[v.pid] = v
                end
            end
        end
        return filtered
    elseif filter_flag == FLAG_ATTY or filter_flag == FLAG_APRC then
        local filtered = {}
        for k,v in pairs(get_processes()) do
            if v ~= -1 then
                filtered[v.pid] = v
            end
        end
        return filtered
    else
        ferror("proc.filter_proc: no flag")
        return nil
    end
end
function test_processes()
    p1 = os.new_process("/sbin/init")
    os.run_process(p1)
    os.send_signal(p1, os.signals.SIGKILL)
end
--test_processes()
cinfo = [[processor       : 0
vendor_id       : ComputerCraft
cpu family      : -1
model           : 17
model name      : ComputerCraft CraftCPU @ TickGHZ
stepping        : 0
microcode       : 0x17
cpu MHz         : 1
cache size      : 0 KB
physical id     : 0
siblings        : 1
core id         : 0
cpu cores       : 1
apicid          : 0
initial apicid  : 0
fpu             : yes
fpu_exception   : yes
cpuid level     : -1
wp              : yes
flags           : fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx rdtscp lm constant_tsc arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc aperfmperf eagerfpu pni pclmulqdq dtes64 monitor ds_cpl vmx est tm2 ssse3 cx16 xtpr pdcm pcid sse4_1 sse4_2 x2apic popcnt tsc_deadline_timer xsave avx f16c rdrand lahf_lm ida arat epb xsaveopt pln pts dtherm tpr_shadow vnmi flexpriority ept vpid fsgsbase smep erms
bogomips        : 0
clflush size    : 0
cache_alignment : 32
address sizes   : 36 bits physical, 48 bits virtual
power management:
]]
function CPUINFO()
    return cinfo
end
cpuinfo_file = {}
cpuinfo_file.name = "/proc/cpuinfo"
cpuinfo_file.file = {}
cpuinfo_file.file.write = function(data)
    os.ferror("cannot write to /proc/cpuinfo")
end
cpuinfo_file.file.read = function(bytes)
    if bytes == nil then
        return CPUINFO()
    else
        return string.sub(CPUINFO(), 0, bytes)
    end
end
temperature_file = {}
temperature_file.name = "/proc/temperature"
temperature_file.file = {}
temperature_file.file.write = function(data)
    os.ferror("cannot write to /proc/temperature")
end
temperature_file.file.read = function(bytes)
    return 'computer: 30C'
end
partitions_file = {}
partitions_file.name = "/proc/partitions"
partitions_file.file = {}
partitions_file.file.write = function(data)
    os.ferror("cannot write to /proc/partitions")
end
partitions_file.file.read = function(bytes)
    k = [[major minor  #blocks name
8      0      1024876  hdd]]
    if bytes == nil then
        return k
    else
        return string.sub(k, 0, bytes)
    end
end
function libroutine()
    os.internals._kernel.register_mfile(cpuinfo_file)
    os.internals._kernel.register_mfile(temperature_file)
    os.internals._kernel.register_mfile(partitions_file)
end
EndFile;
File;boot/sblcfg/systems.cfg
Cubix;/boot/sblcfg/cubixboot
Cubix(luaX);/boot/sblcfg/cubixlx
Cubix(quiet,nodebug);/boot/sblcfg/cubixquiet
CraftOS;/boot/sblcfg/craftos
Boot Disk;/boot/sblcfg/bootdisk
EndFile;
File;startup
#!/usr/bin/env lua
--load SBL
_G['shell'] = shell
term.set_term_color = function (c)
    if term.isColor() then
        term.setTextColor(c)
    end
end
if fs.exists('/boot/sbl') then
    print("mbr: loading sbl.")
    os.run({}, "/boot/sbl")
else
    term.set_term_color(colors.red)
    print("error: sbl not found")
    term.set_term_color(colors.white)
    return 0
end
EndFile;
File;lib/devices/zero_device.lua
#!/usr/bin/env lua
--zero_device.lua
function safestr(s)
    if string.byte(s) > 191 then
        return '#'
    end
    return s
end
dev_zero = {}
dev_zero.name = '/dev/zero'
dev_zero.device = {}
dev_zero.device.device_read = function (bytes)
    if bytes == nil then
        return 0
    else
        result = ''
        for i = 0, bytes do
            result = result .. safestr(0)
        end
        return result
    end
    return 0
end
dev_zero.device.device_write = function(s)
    os.sys_signal(os.signals.SIGILL)
    return 0
end
EndFile;
File;bin/mv
#!/usr/bin/env lua
--/bin/mv: move files or folders
_handler = {}
_handler.signal_handler = function(sig)
    if sig == 'kill' then
        --print("mv: SIGKILL")
        return 0
    end
end
function main(args)
    if #args == 0 then
        print("usage: mv <file> <destination>")
    end
    local from, to = args[1], args[2]
    if fs.exists(os.cshell.resolve(from)) then
        fs.move(os.cshell.resolve(from), os.cshell.resolve(to))
    else
        os.ferror("mv: input node does not exist")
        return 1
    end
    return 0
end
main({...})
EndFile;
File;bin/touch
#!/usr/bin/env lua
--/bin/touch: creates empty files
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        --print("touch: recieved SIGKILL")
        return 0
    end
end
function main(args)
    local d = os.cshell.resolve(args[1])
    if not fs.exists(d) then
        fs.open(d, 'w').close()
    end
end
main({...})
EndFile;
File;LICENSE
Copyright (c) 2014-2015 Tsarev Nikita
Copyright (c) 2015-2016 Lukas Mendes
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
EndFile;
File;dev/mouse
EndFile;
File;dev/tty8
EndFile;
File;usr/manuals/yapi.man
!cmfl!
.name
yapi - Yet Another Package Installer
.cmd
yapi <MODE> [...]
.desc
yapi - The default package management system in cubix.
.listop MODE
    -S <pkg1 pkg2 ...>
        installs packages
    -U <file>
        installs <file> as a YAP file
    -Q <package>
        queries the database to show details of a package
    -R <pkg1 pkg2 ...>
        removes packages
.e
.m
Options applied to -S(in order they're applied)
    c
        clears yapi cache
    y
        updates yapi database
    u
        updates all installed packages
.e
.m
Options applied to -Q
    e
        shows all installed packages and their builds
.e
EndFile;
File;bin/hwclock
#!/usr/bin/env lua
--/bin/hwclock: """"hardware"""" clock
_handler = {}
_handler.signal_handler = function(sig)
    if sig == 'kill' then
        --print("hwclock: SIGKILL")
        return 0
    end
end
function main(args)
    print(textutils.formatTime(tonumber(os.time()), false))
end
main({...})
EndFile;
File;lib/luaX/lxMouse.lua
--[[while true do
  local event, button, x, y = os.pullEvent( "mouse_click" )
  print( "The mouse button ", button, " was pressed at ", x, " and ", y )
end
]]
EndFile;
File;bin/uname
#!/usr/bin/env lua
--/bin/uname: system information
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        --print("uname: recieved SIGKILL")
        return 0
    end
end
function main(args)
    local argmt = args[1]
    local fpcid = fs.open("/var/pcid", 'r')
    local fversion = fs.open("/proc/version", 'r')
    local fbuilddate = fs.open("/proc/build_date", 'r')
    local PC_ID = fpcid.readAll()
    local VERSION = fversion.readAll()
    local BUILD_DATE = fbuilddate.readAll()
    fpcid.close()
    fversion.close()
    fbuilddate.close()
    function uname(arg)
        args = {0, arg}
        if args == nil then
            return 'Cubix'
        elseif args[2] == '-a' then
            return 'Cubix '..PC_ID..' v'..VERSION..'-ccraft  Cubix '..VERSION..' ('..BUILD_DATE..') x86 Cubix'
        elseif args[2] == '-s' then
            return 'Cubix'
        elseif args[2] == '-n' then
            return PC_ID
        elseif args[2] == '-r' then
            return VERSION..'-ccraft'
        elseif args[2] == '-v' then
            return 'Cubix '..VERSION..' ('..BUILD_DATE..')'
        elseif args[2] == '-m' then
            return 'x86'
        elseif args[2] == '-p' then
            return 'unknown'
        elseif args[2] == '-i' then
            return 'unknown'
        elseif args[2] == '-o' then
            return 'Cubix'
        else
            return 'Cubix'
        end
    end
    print(uname(argmt))
end
main({...})
EndFile;
File;boot/sblcfg/default.cfg
Cubix;/boot/sblcfg/cubixboot
Cubix(luaX);/boot/sblcfg/cubixlx
Cubix(quiet,nodebug);/boot/sblcfg/cubixquiet
CraftOS;/boot/sblcfg/craftos
Boot Disk;/boot/sblcfg/bootdisk
EndFile;
File;etc/hostname
cubix
EndFile;
File;bin/dd
#!/usr/bin/env lua
--/bin/dd
--TODO: support for devices
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        --print("dd: recieved SIGKILL")
        return 0
    end
end
function main(args)
    local infile = os.cshell.resolve(args[1])
    local outfile = os.cshell.resolve(args[2])
    local bytes = tonumber(args[3])
    local bs = 0
    if args[4] then
        bs = tonumber(args[4])
    else
        bs = 1
    end
    if infile == nil or outfile == nil or bytes == nil then
        print("usage: dd infile outfile bytes [bs]")
        return 0
    end
    local data = {}
    local DEVICES = os.list_devices
    if DEVICES[infile] ~= nil then
        local cache = DEVICES[infile].device_read(bs*bytes)
        for i=0, #cache do
            table.insert(data, string.byte(string.sub(cache, i, i)))
        end
    else
        local h = fs.open(infile, 'rb')
        for i=0, bs*bytes do
            table.insert(data, h.read())
        end
        h.close()
    end
    local o = fs.open(outfile, 'wb')
    if o == nil then
        ferror("dd: error opening file")
        return false
    end
    for i=0, bs*bytes do
        o.write(data[i])
    end
    o.close()
    return true
end
main({...})
EndFile;
File;proc/build_date
2016-02-28
EndFile;
File;bin/lua
#!/usr/bin/env lua
--/bin/lua: lua interpreter (based on the rom interpreter)
_handler = {}
_handler.signal_handler = function(sig)
    if sig == 'kill' then
        os.debug.debug_write("lua: recieved SIGKILL", false, true)
        return 0
    end
end
function main(args)
    local tArgs = args
    if #tArgs > 0 then
    	print( "This is an interactive Lua prompt." )
    	print( "To run a lua program, just type its name." )
    	return
    end
    local bRunning = true
    local tCommandHistory = {}
    local tEnv = {
    	["exit"] = function()
    		bRunning = false
    	end,
    	["_echo"] = function( ... )
    	    return ...
    	end,
    }
    setmetatable( tEnv, { __index = _ENV } )
    if term.isColour() then
    	term.setTextColour( colours.yellow )
    end
    print( "Interactive Lua prompt." )
    print( "Call exit() to exit." )
    term.setTextColour( colours.white )
    while bRunning do
    	--if term.isColour() then
    	--	term.setTextColour( colours.yellow )
    	--end
    	write("> ")
    	--term.setTextColour( colours.white )
    	local s = read( nil, tCommandHistory, function( sLine )
    	    local nStartPos = string.find( sLine, "[a-zA-Z0-9_%.]+$" )
    	    if nStartPos then
    	        sLine = string.sub( sLine, nStartPos )
    	    end
    	    if #sLine > 0 then
                return textutils.complete( sLine, tEnv )
            end
            return nil
    	end )
    	table.insert( tCommandHistory, s )
    	local nForcePrint = 0
    	local func, e = load( s, "lua", "t", tEnv )
    	local func2, e2 = load( "return _echo("..s..");", "lua", "t", tEnv )
    	if not func then
    		if func2 then
    			func = func2
    			e = nil
    			nForcePrint = 1
    		end
    	else
    		if func2 then
    			func = func2
    		end
    	end
    	if func then
            local tResults = { pcall( func ) }
            if tResults[1] then
            	local n = 1
            	while (tResults[n + 1] ~= nil) or (n <= nForcePrint) do
            	    local value = tResults[ n + 1 ]
            	    if type( value ) == "table" then
                	    local ok, serialised = pcall( textutils.serialise, value )
                	    if ok then
                	        print( serialised )
                	    else
                	        print( tostring( value ) )
                	    end
                	else
                	    print( tostring( value ) )
                	end
            		n = n + 1
            	end
            else
            	printError( tResults[2] )
            end
        else
        	printError( e )
        end
    end
end
main({...})
EndFile;
File;var/yapi/installedpkg
base;51
EndFile;
File;bin/license
#!/usr/bin/env lua
--/bin/license: how cubix license
_handler = {}
_handler.signal_handler = function(sig)
    if sig == 'kill' then
        --print("license: SIGKILL")
        return 0
    end
end
function main(args,pipe)
    local h = fs.open("/LICENSE", 'r')
    print(h.readAll())
    h.close()
    return 0
end
main({...})
EndFile;
File;bin/glep
#!/usr/bin/env lua
--/bin/glep: port of ClamShell's glep to Cubix (http://github.com/Team-CC-Corp/ClamShell)
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        --print("glep: recieved SIGKILL")
        return 0
    end
end
function work_files(pattern, files)
    local RFiles = {}
    for k,v in pairs(files) do
        RFiles[k] = fs.open(v, 'r')
    end
    for i, fh in pairs(RFiles) do
        while true do
            local line = fh.readLine()
            if not line then break end
            if line:find(pattern) then
                print(line)
            end
        end
        fh.close()
    end
end
function work_pipe(pat, pipe)
    local k = os.lib.pipe.Pipe.copyPipe(pipe)
    pipe:flush()
    while true do
        local line = k:readLine()
        if not line or line == nil then break end
        local K = line:find(pat)
        if K ~= nil then
            os.pprint(line, pipe, true)
        end
    end
end
function main(args, pipe)
    function tail(t)
       if # t <= 1 then
          return nil
       end
       local newtable = {}
       for i, v in ipairs(t) do
          if i > 1 then
              table.insert(newtable, v)
          end
       end
       return newtable
    end
    if #args == 0 then
        print("usage: glep <pattern> <files>")
        print("usage(pipe): glep <pattern>")
        return 0
    end
    if pipe ~= nil then
        --print("recieved pipe")
        local pattern = args[1]
        work_pipe(pattern, pipe)
    else
        local pattern, files = args[1], tail(args)
        work_files(pattern, files)
    end
    return 0
end
main({...})
EndFile;
File;dev/loop2
EndFile;
File;g/lxterm/lxterm.lxw
#LXW data for lxTerm
# maximum is 19x51
name:lxterm
hw:9,30
changeable:false
main:/g/lxterm/lxterm.lua
EndFile;
File;bin/cscript
#!/usr/bin/env lua
--/bin/cscript: CubixScript
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        --print("cscript: recieved SIGKILL")
        return 0
    end
end
--$("echo ;Hello World!")
function parseCommand(cmd)
    local _k = cmd:find('"')
    local command = string.sub(cmd, _k, #cmd-2)
    os.cshell.__shell_command(command)
end
function parseEcho(cmd)
    local _k = string.sub(cmd, 1, #cmd)
    print(cmd)
end
function main(args)
    local file = args[1]
    if file == nil then
        print("usage: cscript <file>")
        return 0
    end
    local _h = fs.open("/tmp/current_path", 'r')
    local CPATH = _h.readAll()
    _h.close()
    local fh = {}
    if string.sub(file, 0, 1) == '/' then
        fh = fs.open(file, 'r')
    elseif fs.exists(fs.combine(CPATH, file)) then
        fh = fs.open(fs.combine(CPATH, file), 'r')
    else
        os.ferror("cscript: file not found")
        return 0
    end
    local fLines = {}
    local F = fh.readAll()
    local K = os.strsplit(F, "\n")
    for k,v in pairs(K) do
        fLines[k] = v
    end
    fh.close()
    for k,v in pairs(fLines) do
        if string.sub(v, 0, 1) == '$' then
            parseCommand(v)
        elseif string.sub(v, 0, 1) == '!' then
            parseEcho(v)
        elseif string.sub(v, 0, 1) == '#' then
            parseRootCommand(v)
        end
    end
end
main({...})
EndFile;
File;lib/time
#!/usr/bin/env lua
--time: manages time calls
local fallback2 = "http://luca.spdns.eu/time.php"
local fallback1 = 'http://www.timeapi.org/utc/now?format=%7B%25d%2C%25m%2C%25Y%2C%25H%2C%25M%2C%25S%7D'
local servers = {}
local function readServers()
    local ts_file = fs.open("/etc/time-servers", 'r')
    local ts_data = ts_file.readAll()
    ts_file.close()
    servers = {}
    local data = os.strsplit(ts_data, '\n')
    for k,v in ipairs(data) do
        table.insert(servers, v)
    end
    table.insert(servers, fallback1)
    table.insert(servers, fallback2)
end
local function getTimeData()
    local res = ''
    for k,v in pairs(servers) do
        os.debug.debug_write("[time] getting time data from "..v, false)
        local s = http.get(v)
        if s ~= nil then
            local d = s.readAll()
            s.close()
            if d ~= nil then
                return d
            else
                os.debug.debug_write("getTimeData: d == nil", true, true)
            end
        else
            os.debug.debug_write("getTimeData: s == nil", true, true)
        end
    end
    return nil
end
function getTime_fmt(_tZoneH, _tZoneM)
    readServers()
    local tZoneH = _tZoneH or 0
    local tZoneM = _tZoneM or 0
    local d = getTimeData()
    if d == nil then
        os.debug.debug_write("getTime_fmt: getTimeData returned nil, returning time zero", true, true)
        return {0,0,0,0,0,0,0}
    end
    local t = textutils.unserialise(d)
    local gh = t[4]
    local gm = t[5]
    local s = t[6]
    local m = gm + tZoneM
    local h = gh + tZoneH + math.floor(m/60)
    local m = m%60
    h = h%24
    return {h,m,s}
end
function localtime(tz1, tz2)
    local k = getTime_fmt(tz1, tz2)
    return {hours=k[1], minutes=k[2], seconds=k[3]}
end
function asctime(tm)
    local h,m,s = tm.hours, tm.minutes, tm.seconds
    local formatted = string.format("%2d:%2d:%2d",h,m,s):gsub(" ","0")
    return formatted
end
function strtime(tz1, tz2)
    return asctime(localtime(tz1,tz2))
end
function libroutine()
    os.debug.debug_write("[time] testing time")
    os.debug.debug_write("[time] GMT -3: "..asctime(localtime(-3,0)))
    os.debug.debug_write("[time] Greenwich: "..strtime())
end
EndFile;
File;proc/sttime
13.205
EndFile;
File;dev/zero
EndFile;
File;proc/version
0.5.1
EndFile;
File;lib/devices/null_device.lua
dev_null = {}
dev_null.name = '/dev/null'
dev_null.device = {}
dev_null.device.device_read = function (bytes)
    print("cannot read from /dev/null")
end
dev_null.device.device_write = function(s)
    return 0
end
EndFile;
File;cubix_live_installer
#!/usr/bin/env lua
--cubix_live_installer(cubixli): starts a enviroment where the user can install cubix
AUTHOR = "Lukas Mendes"
VERSION = "0.1.0"
BUILD_DATE = "2016-01-26"
--[[
    The Cubix Live Installer has the basic utilities to install cubix
    It has these Arch Linux vibe going on so, yeah
    CubixLI has everything in one script: a shell, a downloader to install cubix, setting label, hostname and so on
    pastebin: B1t3L4Uw
]]
function do_halt()
    while true do sleep(0) end
end
tail = function(t)
       if # t <= 1 then
          return nil
       end
       local newtable = {}
       for i, v in ipairs(t) do
          if i > 1 then
              table.insert(newtable, v)
          end
       end
       return newtable
end
strsplit = function (inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    if inputstr == nil then
        return ''
    end
    local t={} ; i=1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        t[i] = str
        i = i + 1
    end
    return t
end
viewtable = function (t)
    print(t)
    for k,v in pairs(t) do
        print(k..","..tostring(v).." ("..type(v)..")")
    end
end
function _prompt(message, yes, nope)
    write(message..'['..yes..'/'..nope..'] ')
    local result = read()
    if result == yes then
        return true
    else
        return false
    end
end
prompt = _prompt
term.set_term_color = function (c)
    if term.isColor() then
        term.setTextColor(c)
    end
end
function ferror(msg)
    term.set_term_color(colors.red)
    print(msg)
    term.set_term_color(colors.white)
end
function normal(msg)
    term.set_term_color(colors.yellow)
    print(msg)
    term.set_term_color(colors.white)
end
function load_env()
    normal("[cubixli:load_screen]")
    term.clear()
    term.setCursorPos(1,1)
    normal("[cubixli:load_disk]")
    print("[cubixli:main->run_shell]")
end
local current_path = '/'
local current_envir = ''
local current_disks = {
    hdd = {
        {"hdd", "part", "/"}
    },
    cubixli_ramdisk = {
        {"edev", "edevfs", "./dev"},
        {"cbxli", "cbxlifs", "./cbxli"}
    }
}
local override = false
function cubixli_delete_disk(args)
    local disk = args[1]
    if disk == 'hdd' or disk == '/' then
        normal("[cubixli:delete_disk] wiping hdd")
        for k,v in pairs(fs.list('/'))do
            if v ~= 'rom' then
                fs.delete(v)
            end
        end
    elseif disk == 'cubixli_ramdisk' or disk == 'cbxli' or disk == 'emudev' then
        if not override then
            ferror("cubixli_delete_disk: perm_error formatting "..disk)
            return 1
        else
            ferror("[HALT_ERROR] cubixli needs a manual reboot. (ctrl+r btw)")
            do_halt()
        end
    else
        ferror("cubixli_delete_disk: error getting disk")
        return 1
    end
    return 0
end
_G['cubixli_delete_disk'] = cubixli_delete_disk
function cubixli_call(func, args)
    if current_envir ~= 'cubixli' then
        ferror("cubixli_call: cubixli env not loaded")
        return false
    end
    normal("[cubix:"..func.."]")
    local result = _G['cubixli_'..func](args)
    if result == 0 then return true end
    return false
end
--deldisk util
function deldisk(args)
    if #args == 0 then print("usage: deldisk <disk>") return 0 end
    if _prompt("Do you want to delete your disk?", "Y", "n") then
        if cubixli_call("delete_disk", args) then
            print("deldisk: deleted /")
        else
            ferror("deldisk: error doing delete_disk")
        end
    else
        return 0
    end
end
--lsblk binary
function lsblk()
    for k,vl in pairs(current_disks) do
        write(k..':\n')
        for _, v in pairs(vl) do
            write("  "..v[1].." type "..v[2].." mounted in "..v[3]..'\n')
        end
    end
    write('\n')
    return 0
end
--yapstrap binary
function run_build_hook(hook)
    if hook == 'initramfs' then
        if os.loadAPI("/boot/libcubix") then
            libcubix.generate_lcubix('all', '/boot/cubix-initramfs')
        else
            ferror("error loading libcubix.")
        end
    else
        ferror("build hook not found")
    end
end
function yapstrap(args)
    if current_envir ~= 'cubixli' then
        ferror("yapstrap: cubixli env not loaded")
        return 1
    end
    if #args == 0 then print("usage: yapstrap <task>") return 0 end
    for k,v in pairs(args) do
        if v == 'cubix' then
            shellcmd("yapi -Sy")
            shellcmd("yapi -S base")
            shell.run("FINISHINSTALL")
            local handler = fs.open("/tmp/install_lock", 'w')
            handler.close()
            normal("created /tmp/install_lock")
            normal("running build hook: initramfs")
            run_build_hook('initramfs')
            normal("yapstrap: finished "..v.." task")
        end
    end
    return 0
end
--ls binary
local chars = {}
for i = 32, 126 do chars[string.char(i)] = i end
local function sortingComparsion(valueA, valueB)
    local strpos = 0
    local difference = 0
    while strpos < #valueA and strpos < #valueB and difference == 0 do
        strpos = strpos + 1
        if chars[string.sub(valueA, strpos, strpos)] > chars[string.sub(valueB, strpos, strpos)] then
            difference = 1
        elseif chars[string.sub(valueA, strpos, strpos)] < chars[string.sub(valueB, strpos, strpos)] then
            difference = -1
        end
    end
    if difference == -1 then
        return true
    else
        return false
    end
end
function _ls(pth)
    local nodes = fs.list(pth)
    local files = {}
    local folders = {}
    for k,v in ipairs(nodes) do
        if fs.isDir(pth..'/'..v) then
            table.insert(folders, v)
        else
            table.insert(files, v)
        end
    end
    table.sort(folders, sortingComparsion)
    table.sort(files, sortingComparsion)
    --printing folders
    term.set_term_color(colors.green)
    for k,v in ipairs(folders) do
        write(v..' ')
    end
    term.set_term_color(colors.white)
    --printing files
    for k,v in ipairs(files) do
        write(v..' ')
    end
    write('\n')
end
function ls(args)
    local p = args[1]
    if p == nil then
        _ls(current_path)
    elseif fs.exists(p) then
        _ls(p)
    elseif fs.exists(fs.combine(current_path, p)) then
        _ls(fs.combine(current_path, p))
    end
end
--cd binary
function pth_goup(p)
    elements = strsplit(p, '/')
    res = ''
    for i = 1, (#elements - 1) do
        print(res)
        res = res .. '/' .. elements[i]
    end
    return res
end
function _cd(pth)
    local CURRENT_PATH = current_path
    if CURRENT_PATH == nil then
        CURRENT_PATH = '/'
    elseif pth == '.' then
        CURRENT_PATH = CURRENT_PATH
    elseif pth == '..' then
        CURRENT_PATH = pth_goup(CURRENT_PATH)
    elseif pth == '/' then
        CURRENT_PATH = pth
    elseif fs.exists(CURRENT_PATH .. '/' .. pth) == true then
        CURRENT_PATH = CURRENT_PATH .. '/' .. pth
    elseif fs.exists(pth) == true then
        CURRENT_PATH = pth
    elseif pth == nil then
        --CURRENT_PATH = "/home/"..current_user
    else
        print("cd: not found!")
    end
    return CURRENT_PATH
end
function cd(args)
    local pth = args[1]
    local npwd = _cd(pth)
    current_path = npwd
end
--"cat"ing
function cat(args)
    if #args == 0 then print("usage: cat <absolute path>") return 0 end
    local file = args[1]
    if fs.exists(file) then
        local f = fs.open(file, 'r')
        local data = f.readAll()
        f.close()
        print(data)
        return 0
    else
        ferror("cat: file not found")
        return 1
    end
end
--interface for rebooting
function front_reboot(args)
    if current_envir == 'cubixli' then
        ferror("front_reboot: cannot reboot with cubixli enviroment loaded, please use unloadenv")
        return 1
    end
    print("[cubixli:front_reboot] sending RBT")
    os.sleep(1.5)
    os.reboot()
end
--interface for "shutdowning"
function front_shutdown(args)
    if current_envir == 'cubixli' then
        ferror("front_shutdown: cannot reboot with cubixli enviroment loaded, please use unloadenv")
        return 1
    end
    print("[cubixli:front_shutdown] sending HALT")
    os.sleep(1.5)
    os.shutdown()
end
--set label
function setlabel(args)
    if #args == 0 then print("usage: setlabel <newlabel>") return 0 end
    os.setComputerLabel(tostring(args[1]))
end
--version of cubixLI
function version()
    print("CubixLI "..VERSION.." in "..BUILD_DATE)
end
--load enviroment for cubix to start
function loadenviroment(args)
    if #args == 0 then return 0 end
    normal("[cubixli:loadenviroment] loading "..tostring(args[1]))
    current_envir = tostring(args[1])
end
--unload enviroment
function unloadenv()
    normal("[cubixli:unloadenv] unloading current enviroment ")
    current_envir = ''
end
--sethostname binary
function sethostname(args)
    if current_envir ~= 'cubixli' then
        ferror("sethostname: cubixli enviroment not loaded")
        return 1
    end
    local nhostname = tostring(args[1])
    normal("[cubixli:sethostname] setting hostname to "..nhostname)
    local hostname_handler = fs.open("/etc/hostname", 'w')
    hostname_handler.write(nhostname)
    hostname_handler.close()
    return 0
end
function sbl_bcfg(args)
    local default = fs.open("/boot/sblcfg/default.cfg", 'r')
    local systems = fs.open("/boot/sblcfg/systems.cfg", 'w')
    systems.write(default.readAll())
    default.close()
    systems.close()
    print("sbl-bcfg: systems.cfg restored to default.cfg")
end
function timesetup(args)
    local timeservers = fs.open("/etc/time-servers", 'w')
    for k,v in ipairs(args) do
        timeservers.write(v..'\n')
    end
    timeservers.close()
end
--install help
function insthelp()
    print([[
Installing cubix:
    loadenv cubixli
    lsblk
    deldisk hdd
    yapstrap cubix
    genfstab /etc/fstab
    setlabel <your label here>
    sethostname <your hostname here>
    timesetup <server 1> <server 2> ...
    sbl-bcfg
    unloadenv
    reboot
]])
    return 0
end
function runpath(args)
    --PLEASE DONT USE THIS
    os.run({}, args[1], unpack(tail(args)))
end
function override_shell()
    write("command to run with override=true: ")
    local cmd = read()
    override = true
    shellcmd(cmd)
    override = false
    return 0
end
function genfstab(args)
    local file = args[1]
    local fh = fs.open(file, 'w')
    --device;mountpoint;fs;options;\n
    fh.write("/dev/hda;/;cfs;;\n")
    fh.write("/dev/loop1;/dev/shm;tmpfs;;\n")
    fh.close()
    print("genfstab: generated fstab in "..file)
end
os.tail = function(t)
    if # t <= 1 then
        return nil
    end
    local newtable = {}
    for i, v in ipairs(t) do
        if i > 1 then
            table.insert(newtable, v)
        end
    end
    return newtable
end
os.strsplit = function (inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    if type(inputstr) ~= 'string' then
        os.ferror("os.strsplit: type(inputstr) == "..type(inputstr))
        return 1
    end
    if inputstr == nil then
        return ''
    end
    local t={} ; i=1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        t[i] = str
        i = i + 1
    end
    return t
end
os.ferror = ferror
function yapi(args)
    if current_envir ~= 'cubixli' then
        ferror("yapi: cannot run without cubixli enviroment loaded")
        return 1
    end
    VERSION = '0.1.1'
    --defining some things
    local SERVERIP = 'lkmnds.github.io'
    local SERVERDIR = '/yapi'
    local YAPIDIR = '/var/yapi'
    function download_file(url)
        local cache = os.strsplit(url, '/')
        local fname = cache[#cache]
        print('requesting ' .. fname)
        http.request(url)
        local req = true
        while req do
            local e, url, stext = os.pullEvent()
            if e == 'http_success' then
                local rText = stext.readAll()
                stext.close()
                return rText
            elseif e == 'http_failure' then
                req = false
                return {false, 'http_failure'}
            end
        end
    end
    function success(msg)
        term.set_term_color(colors.green)
        print(msg)
        term.set_term_color(colors.white)
    end
    function cache_file(data, filename)
        local h = fs.open(YAPIDIR..'/cache/'..filename, 'w')
        h.write(data)
        h.close()
        return 0
    end
    function isin(inputstr, wantstr)
        for i = 1, #inputstr do
            local v = string.sub(inputstr, i, i)
            if v == wantstr then return true end
        end
        return false
    end
    function create_default_struct()
        fs.makeDir(YAPIDIR.."/cache")
        fs.makeDir(YAPIDIR.."/db")
        fs.open(YAPIDIR..'/installedpkg', 'a').close()
    end
    function update_repos()
        --download core, community and extra
        local SPATH = 'http://'.. SERVERIP .. SERVERDIR .. '/database/core'
        local k = download_file(SPATH)
        if type(k) == 'table' then
            ferror("yapi: http error")
            return 1
        end
        local _h = fs.open(YAPIDIR..'/db/core', 'w')
        _h.write(k)
        _h.close()
        local SPATH = 'http://'.. SERVERIP .. SERVERDIR .. '/database/community'
        local k = download_file(SPATH)
        if type(k) == 'table' then
            ferror("yapi: http error")
            return 1
        end
        local _h = fs.open(YAPIDIR..'/db/community', 'w')
        _h.write(k)
        _h.close()
        local SPATH = 'http://'.. SERVERIP .. SERVERDIR .. '/database/extra'
        local k = download_file(SPATH)
        if type(k) == 'table' then
            ferror("yapi: http error")
            return 1
        end
        local _h = fs.open(YAPIDIR..'/db/extra', 'w')
        _h.write(k)
        _h.close()
    end
    --Yapi Database
    yapidb = {}
    yapidb.__index = yapidb
    function yapidb.new(path)
        local inst = {}
        setmetatable(inst, yapidb)
        inst.path = path
        inst.db = ''
        return inst
    end
    function yapidb:update()
        self.db = ''
        self.db = self.db .. '\n'
        local h = fs.open(self.path..'/core', 'r')
        local _k = h.readAll()
        self.db = self.db .. _k
        h.close()
        self.db = self.db .. '\n'
        local h = fs.open(self.path..'/community', 'r')
        local _k = h.readAll()
        self.db = self.db .. '\n'
        self.db = self.db .. _k
        h.close()
        self.db = self.db .. '\n'
        local h = fs.open(self.path..'/extra', 'r')
        local _k = h.readAll()
        self.db = self.db .. '\n'
        self.db = self.db .. _k
        self.db = self.db .. '\n'
        h.close()
    end
    function yapidb:search(pkgname)
        self:update()
        local _lines = self.db
        local lines = os.strsplit(_lines, '\n')
        for k,v in pairs(lines) do
            local pkgdata = os.strsplit(v, ';')
            if pkgdata[1] == pkgname then
                return {true, v}
            end
        end
        return {false, nil}
    end
    function yapidb:search_wcache(pkgname)
        self:update()
        if fs.exists(YAPIDIR..'/cache/'..pkgname..'.yap') then
            local h = fs.open(YAPIDIR..'/cache/'..pkgname..'.yap', 'r')
            local f = h.readAll()
            h.close()
            return f
        else
            local _url = self:search(pkgname)
            local url = os.strsplit(_url[2], ';')[2]
            local yapdata = download_file(url)
            if type(yapdata) == 'table' then return -1 end
            cache_file(yapdata, pkgname..'.yap')
            return yapdata
        end
    end
    --parsing yap files
    function parse_yap(yapf)
        local lines = os.strsplit(yapf, '\n')
        local yapobject = {}
        yapobject['folders'] = {}
        yapobject['files'] = {}
        yapobject['deps'] = {}
        if type(lines) ~= 'table' then
            os.ferror("::! [parse_yap] type(lines) ~= table")
            return 1
        end
        local isFile = false
        local rFile = ''
        for _,v in pairs(lines) do
            if isFile then
                local d = v
                if d ~= 'EndFile;' then
                    if yapobject['files'][rFile] == nil then
                        yapobject['files'][rFile] = d .. '\n'
                    else
                        yapobject['files'][rFile] = yapobject['files'][rFile] .. d .. '\n'
                    end
                else
                    isFile = false
                    rFile = ''
                end
            end
            local splitted = os.strsplit(v, ';')
            if splitted[1] == 'Name' then
                yapobject['name'] = splitted[2]
            elseif splitted[1] == 'Version' then
                yapobject['version'] = splitted[2]
            elseif splitted[1] == 'Build' then
                yapobject['build'] = splitted[2]
            elseif splitted[1] == 'Author' then
                yapobject['author'] = splitted[2]
            elseif splitted[1] == 'Email-Author' then
                yapobject['email_author'] = splitted[2]
            elseif splitted[1] == 'Description' then
                yapobject['description'] = splitted[2]
            elseif splitted[1] == 'Folder' then
                table.insert(yapobject['folders'], splitted[2])
            elseif splitted[1] == 'File' then
                isFile = true
                rFile = splitted[2]
            elseif splitted[1] == 'Dep' then
                table.insert(yapobject['deps'], splitted[2])
            end
        end
        return yapobject
    end
    function yapidb:installed_pkgs()
        local handler = fs.open(YAPIDIR..'/installedpkg', 'r')
        local file = handler.readAll()
        handler.close()
        local lines = os.strsplit(file, '\n')
        return lines
    end
    function yapidb:is_installed(namepkg)
        local installed = self:installed_pkgs()
        for k,v in ipairs(installed) do
            local splitted = os.strsplit(v, ';')
            if splitted[1] == namepkg then return true end
        end
        return false
    end
    function yapidb:updatepkgs()
        self:update()
        for k,v in pairs(self:installed_pkgs()) do
            local pair = os.strsplit(v, ';')
            local w = self:search(pair[1])
            local yd = {}
            if w[1] == false then
                os.ferror("::! updatepkgs: search error")
                return false
            end
            local url = os.strsplit(w[2], ';')[2]
            local rawdata = download_file(url)
            if type(rawdata) == 'table' then
                os.ferror("::! [install] type(rawdata) == table : "..yapfile[2])
                return false
            end
            local yd = parse_yap(rawdata)
            if tonumber(pair[2]) < tonumber(yd['build']) then
                print(" -> new build of "..pair[1].." ["..pair[2].."->"..yd['build'].."] ")
                self:install(pair[1]) --install latest
            else
                print(" -> [updatepkgs] "..yd['name']..": OK")
            end
        end
    end
    function yapidb:register_pkg(yapdata)
        print("==> [register] "..yapdata['name'])
        local _h = fs.open(YAPIDIR..'/installedpkg', 'r')
        local _tLines = _h.readAll()
        _h.close()
        local pkg_found = false
        local tLines = os.strsplit(_tLines, '\n')
        for k,v in ipairs(tLines) do
            local pair = os.strsplit(v, ';')
            if pair[1] == yapdata['name'] then
                pkg_found = true
                tLines[k] = yapdata['name']..';'..yapdata['build']
            else
                tLines[k] = tLines[k] .. '\n'
            end
        end
        if not pkg_found then
            tLines[#tLines+1] = yapdata['name']..';'..yapdata['build'] .. '\n'
        end
        print(" -> writing to file")
        local h2 = fs.open(YAPIDIR..'/installedpkg', 'w')
        for k,v in pairs(tLines) do
            h2.write(v)
        end
        h2.close()
    end
    function yapidb:install_yap(yapdata)
        print("==> install_yap: "..yapdata['name'])
        for k,v in pairs(yapdata['folders']) do
            fs.makeDir(v)
        end
        for k,v in pairs(yapdata['files']) do
            local h = fs.open(k, 'w')
            h.write(v)
            h.close()
        end
        return true
    end
    function yapidb:return_dep_onepkg(pkgname)
        local _s = self:search(pkgname)
        if _s[1] == true then
            local result = os.strsplit(_s[2], ';')
            local yapfile = download_file(result[2])
            if type(yapfile) == 'table' then
                os.ferror("::! [getdep] "..yapfile[2])
                return false
            end
            cache_file(yapfile, pkgname..'.yap')
            local yapdata = parse_yap(yapfile)
            local dependencies = {}
            if yapdata['deps'] == nil then
                print(" -> no dependencies: "..pkgname)
                return {}
            end
            for _,dep in ipairs(yapdata['deps']) do
                table.insert(dependencies, dep)
            end
            return dependencies
        else
            return false
        end
    end
    function yapidb:return_deps(pkglist)
        local r = {}
        for _,pkg in ipairs(pkglist) do
            local c = self:return_dep_onepkg(pkg)
            if c == false then
                ferror("::! [getdeps] error getting deps: "..pkg)
                return 1
            end
            for i=0,#c do
                table.insert(r, c[i])
            end
            table.insert(r, pkg)
        end
        return r
    end
    function yapidb:install(pkgname)
        local _s = self:search(pkgname)
        if _s[1] == true then
            local result = os.strsplit(_s[2], ';')
            local yapfile = download_file(result[2])
            if type(yapfile) == 'table' then
                os.ferror("::! [install] "..yapfile[2])
                return false
            end
            cache_file(yapfile, pkgname..'.yap')
            local yapdata = parse_yap(yapfile)
            local missing_dep = {}
            if yapdata['deps'] == nil or pkgname == 'base' then
                print(" -> no dependencies: "..pkgname)
            else
                for _,dep in ipairs(yapdata['deps']) do
                    if not self:is_installed(dep) then
                        table.insert(missing_dep, dep)
                    end
                end
            end
            if #missing_dep > 0 then
                ferror("error: missing dependencies")
                for _,v in ipairs(missing_dep) do
                    write(v..' ')
                end
                write('\n')
                return false
            end
            self:register_pkg(yapdata)
            self:install_yap(yapdata)
            return true
        else
            os.ferror("error: target not found: "..pkgname)
            return false
        end
    end
    function yapidb:remove(pkgname)
        --1st: read cached yapdata
        --2nd: remove all files made by yapdata['files']
        --3rd: remove entry in YAPIDIR..'/installedpkg'
        if not self:is_installed(pkgname) then
            os.ferror(" -> package not installed")
            return false
        end
        local yfile = self:search_wcache(pkgname)
        local ydata = parse_yap(yfile)
        --2nd part
        print("==> remove: "..ydata['name'])
        for k,v in pairs(ydata['files']) do
            fs.delete(k)
        end
        for k,v in pairs(ydata['folders']) do
            fs.delete(v)
        end
        local _h = fs.open(YAPIDIR..'/installedpkg', 'r')
        local _tLines = _h.readAll()
        _h.close()
        local pkg_found = false
        local tLines = os.strsplit(_tLines, '\n')
        for k,v in ipairs(tLines) do
            local pair = os.strsplit(v, ';')
            if pair[1] == ydata['name'] then
                tLines[k] = '\n'
            else
                tLines[k] = tLines[k] .. '\n'
            end
        end
        local h2 = fs.open(YAPIDIR..'/installedpkg', 'w')
        for k,v in pairs(tLines) do
            h2.write(v)
        end
        h2.close()
        return true
    end
    function yapidb:clear_cache()
        fs.delete(YAPIDIR..'/cache')
        fs.makeDir(YAPIDIR..'/cache')
    end
    function main(args)
        create_default_struct()
        if #args == 0 then
            print("usage: yapi <mode> ...")
        else
            --print("yapi "..VERSION)
            local option = args[1]
            if string.sub(option, 1, 1) == '-' then
                if string.sub(option, 2,2) == 'S' then
                    local packages = os.tail(args)
                    if packages ~= nil then
                        local database = yapidb.new(YAPIDIR..'/db')
                        database:update()
                        for k,pkg in ipairs(packages) do
                            if not database:search(pkg)[1] then
                                os.ferror("error: target not found: "..pkg)
                                return 1
                            end
                        end
                        print("resolving dependencies...")
                        packages = database:return_deps(packages)
                        print("")
                        write("Packages ("..#packages..") ")
                        for _,pkg in ipairs(packages) do
                            write(pkg..' ')
                        end
                        print("\n")
                        if not prompt(":: Proceed with installation?", "Y", "n") then
                            print("==> Aborted")
                            return true
                        end
                        for k,package in ipairs(packages) do
                            --local database = yapidb.new(YAPIDIR..'/db')
                            --database:update()
                            --print("==> [install] "..package)
                            print(":: Installing packages ...")
                            local completed = 1
                            if database:install(package) then
                                success("("..completed.."/"..tostring(#packages)..")"..package.." : SUCCESS")
                                completed = completed + 1
                            else
                                --os.ferror("==> "..package.." : FAILURE")
                                return 1
                            end
                        end
                    end
                    if isin(option, 'c') then
                        local database = yapidb.new(YAPIDIR..'/db')
                        print("==> [clear_cache]")
                        database:clear_cache()
                    end
                    if isin(option, 'y') then
                        print(":: Update from "..SERVERIP)
                        if not http then
                            os.ferror("yapi: http not enabled")
                            return 1
                        end
                        update_repos()
                    end
                    if isin(option, 'u') then
                        local database = yapidb.new(YAPIDIR..'/db')
                        print(":: Starting full system upgrade")
                        if prompt("Confirm full system upgrade", "Y", "n") then
                            database:updatepkgs()
                        else
                            print("==> Aborted")
                        end
                    end
                elseif string.sub(option,2,2) == 'U' then
                    local yfile = fs.combine(current_path, args[2])
                    print("==> [install_yap] "..yfile)
                    local h = fs.open(yfile, 'r')
                    local _data = h.readAll()
                    h.close()
                    local ydata = parse_yap(_data)
                    local database = yapidb.new(YAPIDIR..'/db')
                    if database:install_yap(ydata) then
                        success("==> [install_yap] "..ydata['name'])
                    else
                        os.ferror("::! [install_yap] "..ydata['name'])
                    end
                elseif string.sub(option,2,2) == 'Q' then
                    local database = yapidb.new(YAPIDIR..'/db')
                    local pkg = args[2]
                    local _k = database:search(pkg)
                    if pkg then
                        if _k[1] == true then
                            local _c = database:search_wcache(pkg)
                            local yobj = parse_yap(_c)
                            if type(yobj) ~= 'table' then
                                os.ferror("::! [list -> parse_yap] error (yobj ~= table)")
                                return 1
                            end
                            print(yobj.name .. ' ' .. yobj.build .. ':' .. yobj.version)
                            print("Maintainer: "..yobj.author.." <"..yobj['email_author']..">")
                            print("Description: "..yobj.description)
                        else
                            os.ferror("::! package not found")
                        end
                    end
                    if isin(option, 'e') then
                        local database = yapidb.new(YAPIDIR..'/db')
                        database:update()
                        --print("Installed packages: ")
                        local ipkg = database:installed_pkgs()
                        for _,ntv in ipairs(ipkg) do
                            local v = os.strsplit(ntv, ';')
                            write(v[1] .. ':' .. v[2] .. '\n')
                        end
                    end
                elseif string.sub(option,2,2) == 'R' then
                    local packages = os.tail(args)
                    if packages ~= nil then
                        local database = yapidb.new(YAPIDIR..'/db')
                        database:update()
                        for k,pkg in ipairs(packages) do
                            if not database:search(pkg)[1] then
                                os.ferror("error: target not found: "..pkg)
                                return 1
                            end
                        end
                        if not prompt("Proceed with remotion?", "Y", "n") then
                            print("==> Aborted")
                            return true
                        end
                        for k,package in ipairs(packages) do
                            --local database = yapidb.new(YAPIDIR..'/db')
                            --database:update()
                            print(":: removing "..package)
                            if database:remove(package) then
                                success("==> [remove] "..package.." : SUCCESS")
                            else
                                os.ferror("::! [remove] "..package.." : FAILURE")
                                return 1
                            end
                        end
                    end
                end
            else
                os.ferror("yapi: sorry, see \"man yapi\" for details")
            end
        end
    end
    main(args)
end
local SHELLCMD = {}
SHELLCMD['ls'] = ls
SHELLCMD['cd'] = cd
SHELLCMD['yapstrap'] = yapstrap
SHELLCMD['deldisk'] = deldisk
SHELLCMD['setlabel'] = setlabel
SHELLCMD['loadenv'] = loadenviroment
SHELLCMD['unloadenv'] = unloadenv
SHELLCMD['version'] = version
SHELLCMD['help'] = insthelp
SHELLCMD['reboot'] = front_reboot
SHELLCMD['shutdown'] = front_shutdown
SHELLCMD['run'] = runpath
SHELLCMD['lsblk'] = lsblk
SHELLCMD['sethostname'] = sethostname
SHELLCMD['cat'] = cat
SHELLCMD['override'] = override_shell
SHELLCMD['sbl-bcfg'] = sbl_bcfg
SHELLCMD['timesetup'] = timesetup
SHELLCMD['genfstab'] = genfstab
SHELLCMD['yapi'] = yapi
function list_cmds(args)
    print("Available commands:")
    for k,v in pairs(SHELLCMD) do
        write(k..' ')
    end
    write('\n')
end
SHELLCMD['cmds'] = list_cmds
function shellcmd(cmd)
    local k = strsplit(cmd, ' ')
    local _args = tail(k)
    if _args == nil then _args = {} end
    if SHELLCMD[k[1]] ~= nil then
        SHELLCMD[k[1]](_args)
    else
        ferror("clish: command not found")
    end
end
function run_shell()
    --THIS IS NOT CSHELL!!!!11!!!ELEVEN!!
    local command = ""
    local shell_char = '# '
    local current_user = 'root'
    local HISTORY = {}
    while true do
        write(current_user .. ':' .. current_path .. shell_char)
        command = read(nil, HISTORY)
        table.insert(HISTORY, command)
        if command == "exit" then
            return 0
        elseif command ~= nil then
            shellcmd(command)
        end
    end
    return 0
end
function main()
    if _G["IS_CUBIX"] then
        ferror("cubixli: in cubix, cubixli must run as root")
        return 0
    end
    load_env()
    run_shell()
end
if not IS_CUBIX then
    main()
end
EndFile;
File;sstartup
shell.run("/boot/cubix acpi")
EndFile;
File;dev/full
EndFile;
File;proc/2/stat
stat working
EndFile;
File;boot/sblcfg/cubixlx
set root=(hdd)
load_video
insmod kernel
kernel /boot/cubix acpi runlevel=5
boot
EndFile;
File;lib/devices/term.lua
local devname = ''
local devpath = ''
function device_read(bytes)
    ferror("term: cannot read from term deivces")
    os.sys_signal(os.signals.SIGILL)
    return 1
end
function device_write(data)
    write(data)
end
function setup(name, path)
    devname = name
    devpath = path
    fs.open(path, 'w').close()
end
function libroutine()end
EndFile;
File;dev/loop4
EndFile;
File;dev/stderr
EndFile;
File;lib/debug_manager
#!/usr/bin/env lua
--debug manager
--task: simplify debug information from program to user
__debug_buffer = ''
__debug_counter = 0
function debug_write_tobuffer(dmessage)
    __debug_buffer = __debug_buffer .. '[' .. __debug_counter ..']' .. dmessage
    local dfile = fs.open("/tmp/syslog", 'a')
    dfile.write('[' .. __debug_counter ..']' .. dmessage)
    dfile.close()
    __debug_counter = __debug_counter + 1
end
function debug_write(dmessage, screen, isErrorMsg)
    if os.__kflag.nodebug == false or os.__kflag.nodebug == nil then
        if isErrorMsg then
            term.set_term_color(colors.red)
        end
        if screen == nil then
            print('[' .. __debug_counter ..']' .. dmessage)
        elseif screen == false and os.__boot_flag or _G['CUBIX_REBOOTING'] or _G['CUBIX_TURNINGOFF'] then
            print('[' .. __debug_counter ..']' .. dmessage)
        end
        debug_write_tobuffer(dmessage..'\n')
        os.sleep(math.random() / 16)
        --os.sleep(.5)
        term.set_term_color(colors.white)
    end
end
function testcase(message, correct)
    term.set_term_color(colors.green)
    debug_write(message)
    term.set_term_color(colors.white)
end
function warning(msg)
    term.set_term_color(colors.yellow)
    debug_write(msg)
    term.set_term_color(colors.white)
end
function dmesg()
    print(__debug_buffer)
end
function kpanic(message)
    if _G['LX_SERVER_LOADED'] == nil or _G['LX_SERVER_LOADED'] == false then
        term.set_term_color(colors.yellow)
        debug_write("[cubix] Kernel Panic!")
        if os.__boot_flag then --early kernel
            debug_write("Proc: /boot/cubix")
        else
            debug_write("Proc: "..tostring(os.getrunning()))
        end
        term.set_term_color(colors.red)
        debug_write(message)
        term.set_term_color(colors.white)
        os.system_halt()
    else
        os.lib.lxServer.write_solidRect(3,3,25,7,colors.red)
        os.lib.lxServer.write_rectangle(3,3,25,7,colors.black)
        local kpanic_title = 'Kernel Panic!'
        for i=1, #kpanic_title do
            os.lib.lx.write_letter(string.sub(kpanic_title,i,i), 9+i, 3, colors.red, colors.white)
        end
        local process_line = ''
        if not os.lib.proc or os.__boot_flag then --how are you in early boot?
            process_line = "proc: /boot/cubix"
        else
            process_line = "pid: "..tostring(os.getrunning())
        end
        for i=1, #process_line do
            os.lib.lx.write_letter(string.sub(process_line,i,i), 4+i, 5, colors.red, colors.white)
        end
        local procname = ''
        if not os.lib.proc or os.__boot_flag then --how are you in early boot(seriously, how)?
            procname = "name: /boot/cubix"
        else
            procname = "pname: "..tostring(os.lib.proc.get_processes()[os.getrunning()].file)
        end
        for i=1, #procname do
            os.lib.lx.write_letter(string.sub(procname,i,i), 4+i, 6, colors.red, colors.white)
        end
        for i=1, #message do
            os.lib.lx.write_letter(string.sub(message,i,i), 4+i, 7, colors.red, colors.white)
        end
        os.system_halt()
    end
end
EndFile;
File;usr/manuals/kernel/bootseq.man
On the subject of Cubix Boot Sequence
 * SBL is loaded in startup file and reads /boot/sblcfg/systems.cfg file, then, SBL loads a menu and the user select which OS to load, then it will load the bootscript related to it in systems.cfg and passes control to it["man sbl"].
Then, if Cubix was selected at the menu, /boot/cubix starts to manage the system bootup:
Tasks of /boot/cubix:
 * First Stage:
    load label and put it in /var/pcid
    write version of cubix to /proc/version
    write the build time to /proc/build_date and the time the OS started in /proc/sttime.
 * Second Stage: loads the Managers:
    video_manager
    debug_manager["man debugmngr"]
    acpi["man acpi"]
    fs_manager["man fsmngr"]
    proc_manager["man procmngr"]
    hash_manager["man kernel api"]
    device_manager["man devicemngr"]
    tty_manager: loads support for ttys in /dev/ttyX
    login_manager["man loginmngr"]
    pipe_manager["man pipe"]
 * Third Stage:
    Load /sbin/init, which, depending of the runlevel, could start /sbin/login or luaX(the "graphical manager")
 * Shutdown:
    Shutdown starts when /sbin/init gets a SIGKILL or when user runs /sbin/shutdown, they call os.shutdown() (assuming acpi is loaded)
    then acpi_(shutdown|reboot) will:
     * kill all processes
     * delete /tmp and /proc/<number> folders
     * recreate /tmp
     * do a native shutdown
     * bang.
EndFile;
File;lib/multiuser/multiuser.lua
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
function create_multitty()
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
    create_multitty()
    create_switch()
    for k,v in pairs(os.lib.tty.get_ttys()) do
        --every active tty running login
        v:run_process("/sbin/login")
    end
end
function libroutine()
    run_all_ttys()
end
EndFile;
File;usr/manuals/programs.man
On the Subject of Programs
Cubix starts a program by its main() function, if the program doesnt have a main() function, it will run without arguments.
 * Main Function:
    A main function of a program will recieve two arguments:
        args [list] - argumetns to program
        pipe [pipe] - just a Pipe object["man pipe"]
EndFile;
File;tmp/current_tty
/dev/tty1
EndFile;
File;proc/cpuinfo
EndFile;
File;sbin/pm-hibernate
#!/usr/bin/env lua
--/bin/pm-hibernate: wrapper to (acpi) hibernate
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        os.debug.debug_write("pm-suspend: recieved SIGKILL")
        return 0
    end
end
function main(args)
    os.hibernate()
end
main({...})
EndFile;
File;lib/fs_manager
#!/usr/bin/env lua
--filesystem manager
--task: Manage Filesystems
--TODO: filesystem drivers(vfat, ext3, devfs, tmpfs)
oldfs = deepcopy(fs)
fsdrivers = {}
function load_fs(fsname)
    os.debug.debug_write("[load_fs] loading "..fsname)
    local pth = '/lib/fs/'..fsname..'.lua'
    if os.loadAPI(pth) then
        fsdrivers[fsname] = _G[fs.getName(pth)]
        os.debug.debug_write('[load_fs] loaded: '..fsname)
    else
        os.debug.kpanic("[load_fs] not loaded: "..fsname)
    end
end
function load_filesystems()
    load_fs('cfs') --Cubix File System
    load_fs('tmpfs') --Temporary File System
    --load_fs('ext2')
    --load_fs('ext3')
    --load_fs('ext4')
    --load_fs('vfat')
end
_G["fsdrivers"] = fsdrivers
--yes, this was from uberOS
--local nodes = {} --{ {owner, gid, perms[, linkto]} }
nodes = {}
local mounts = {} --{ {fs, dev}, ... }
fs.perms = {}
fs.perms.ROOT = 1
fs.perms.SYS = 2
fs.perms.NORMAL = 3
fs.perms.FOOL = 4
fs.perm = function (path)
    local perm_obj = {}
    local information = nodes[path]
    perm_obj.writeperm = true
    return perm_obj
end
permission = {}
local __using_perm = nil
local __afterkperm = false
permission.grantAccess = function(perm)
    local _uid = nil
    if not os.__boot_flag then
        if os.lib.login.isSudo() then
            _uid = 0
        else
            _uid = os.lib.login.userUID()
        end
    end
    if (perm == fs.perms.ROOT or perm == fs.perms.SYS) and (_uid == 0 or os.__boot_flag == true) then
        return true
    elseif perm == fs.perms.NORMAL then
        return true
    end
    return false
end
permission.initKernelPerm = function()
    if not __afterkperm then
        __using_perm = fs.perms.SYS
        __afterkperm = true
    end
end
permission.default = function()
    local _uid = os.lib.login.userUID()
    if _uid == 0 then
        __using_perm = fs.perms.ROOT
    elseif _uid > 0 then
        __using_perm = fs.perms.NORMAL
    elseif _uid == -1 then
        __using_perm = fs.perms.FOOL
    end
end
permission.getPerm = function()
    print(__using_perm)
end
fsmanager = {}
fsmanager.normalizePerm = function(perms)
    local tmp = tostring(perms)
    local arr = {}
    for i = 1, 3 do
        local n = tonumber(string.sub(tmp, i, i))
        if n == 0 then arr[i] = "---" end
        if n == 1 then arr[i] = "--x" end
        if n == 2 then arr[i] = "-w-" end
        if n == 3 then arr[i] = "-wx" end
        if n == 4 then arr[i] = "r--" end
        if n == 5 then arr[i] = "r-x" end
        if n == 6 then arr[i] = "rw-" end
        if n == 7 then arr[i] = "rwx" end
    end
    return arr
end
fsmanager.strPerm = function(perms)
    local k = fsmanager.normalizePerm(perms)
    return k[1] .. k[2] .. k[3]
end
fs.verifyPerm = function(path, user, mode)
    local info = fsmanager.getInformation(path)
    local norm = fsmanager.normalizePerm(info.perms)
    if user == info.owner then
        if mode == "r" then return string.sub(norm[1], 1, 1) == "r" end
        if mode == "w" then return string.sub(norm[1], 2, 2) == "w" end
        if mode == "x" then return string.sub(norm[1], 3, 3) == "x" end
    elseif os.lib.login.isInGroup(user, info.gid) then
        if mode == "r" then return string.sub(norm[2], 1, 1) == "r" end
        if mode == "w" then return string.sub(norm[2], 2, 2) == "w" end
        if mode == "x" then return string.sub(norm[2], 3, 3) == "x" end
    else
        if mode == "r" then return string.sub(norm[3], 1, 1) == "r" end
        if mode == "w" then return string.sub(norm[3], 2, 2) == "w" end
        if mode == "x" then return string.sub(norm[3], 3, 3) == "x" end
    end
end
--{owner, owner group, others}
--[[
PERMISSIONS:
---------- 	0000 	no permissions
---x--x--x 	0111 	execute
--w--w--w- 	0222 	write
--wx-wx-wx 	0333 	write & execute
-r--r--r-- 	0444 	read
-r-xr-xr-x 	0555 	read & execute
-rw-rw-rw- 	0666 	read & write
-rwxrwxrwx 	0777 	read, write, & execute
]]
permission.fileCurPerm = function()
    if os.currentUID() == 0 then
        --root here
        return '770'
    elseif os.currentUID() ~= 0 then
        return '777'
    end
end
fsmanager.stripPath = function(base, full)
    if base == full then return '/' end
    return string.sub(full, #base + 1, #full)
end
fsmanager.loadFS = function(mountpath)
    local x = fsdrivers[mounts[mountpath].fs].loadFS
    if x then
        local tmp, r = x(mountpath, mounts[mountpath].dev)
        if not r then return false end
        if mountpath == '/' then mountpath = '' end
        for k,v in pairs(tmp) do
            nodes[mountpath .. k] = v
        end
    end
    return true
end
fsmanager.saveFS = function(mountpath)
    local x = fsdrivers[fsmanager.getMount(mountpath).fs].saveFS
    if x then
        x(mountpath, fsmanager.getMount(mountpath).dev)
    end
end
fsmanager.sync = function()
    os.debug.debug_write('[fsmanager:sync]')
    for k,v in pairs(mounts) do
        os.debug.debug_write('[sync] saveFS: '..k)
        fsmanager.saveFS(k)
    end
end
fsmanager.deleteNode = function(node)
    if not nodes[node] then return true end
    if fs.verifyPerm(node, os.currentUID(), 'w') then
    --if fs.perm(node).writeperm then
        nodes[node] = nil
        return true
    else
        os.ferror("fsmanager.deleteNode: Access Denied")
    end
    return false
end
fsmanager.getInformation = function(node)
    local p = node
    if node == '/' then
        return {owner = 0, perms = '755', gid = 0}
    end
    if nodes[p] then
        return deepcopy(nodes[p])
    end
    return {owner = 0, perms = '777', gid = 0}
end
fsmanager.setNode = function(node, owner, perms, linkto, gid)
    if node == '/' then
        nodes['/'] = {owner = 0, perms = '755', gid = 0}
        return true
    end
    if not nodes[node] then
        --create node
        if fs.verifyPerm(node, os.currentUID(), 'w') then
            nodes[node] = deepcopy(fsmanager.getInformation(node))
        else
            os.ferror("fsmanager.setNode [perm]: Access denied")
            return false
        end
    end
    owner = owner or nodes[node].owner
    perms = perms or nodes[node].perms
    gid = gid or nodes[node].gid
    perms = tonumber(perms)
    if nodes[node].owner == os.currentUID() then
        nodes[node].owner = owner
        nodes[node].gid = gid
        nodes[node].perms = perms
        nodes[node].linkto = linkto
    else
        os.ferror("fsmanager.setNode [uid]: Access denied")
        return false
    end
end
fsmanager.viewNodes = function()
    os.viewTable(nodes)
end
fsmanager.canMount = function(fs)
    if os.__boot_flag then
        return true
    else
        return fsdrivers[fs].canMount(os.currentUID())
    end
end
fsmanager.mount = function(device, filesystem, path)
    --if not permission.grantAccess(fs.perms.SYS) then
    --    os.ferror("mount: system permission is required to mount")
    --    return false
    --end
    if not fsmanager.canMount(filesystem) then
        os.ferror("mount: current user can't mount "..filesystem)
        return false
    end
    if not fsdrivers[filesystem] then
        os.ferror("mount: can't mount "..device..": filesystem not loaded")
        return false
    end
    if mounts[path] then
        os.ferror("mount: filesystem already mounted")
        return false
    end
    if not oldfs.exists(path) then
        ferror("mount: mountpath "..path.." doesn't exist")
        return false
    end
    if not oldfs.isDir(path) then
        ferror("mount: mountpath is not a folder")
        return false
    end
    os.debug.debug_write("[mount] mounting "..device..": "..filesystem.." at "..path, false)
    mounts[path] = {["fs"] = filesystem, ["dev"] = device}
    local r = fsmanager.loadFS(path, device)
    if not r then
        mounts[path] = nil
        os.ferror("mount: unable to mount")
        return false
    end
    return true
end
fsmanager.umount_path = function(mpath)
    if not permission.grantAccess(fs.perms.SYS) then
        --os.ferror("umount: system permission is required to umount")
        return {false, 'system permission is required to umount'}
    end
    if mpath == '/' then
        return {false, "device is busy"}
    end
    if mounts[mpath] then
        fsmanager.saveFS(mpath)
        mounts[mpath] = nil
        return {true}
    end
    return {false, 'mountpath not found'}
end
fsmanager.umount_dev = function(dev)
    if not permission.grantAccess(fs.perms.SYS) then
        --os.ferror("umount: system permission is required to umount")
        return {false, 'system permission is required to umount'}
    end
    if dev == '/dev/hdd' then
        return {false, "device is busy"}
    end
    local k = next(mounts)
    while k do
        if mounts[k] then
            if mounts[k]['dev'] == dev then
                fsmanager.saveFS(k)
                mounts[k] = nil
                return {true}
            end
        end
        k = next(mounts)
    end
    return {false, 'device not found'}
end
fsmanager.getMount = function(mountpath)
    return deepcopy(mounts[mountpath])
end
fsmanager.getMounts = function()
    return deepcopy(mounts)
end
fsmanager._test = function()
    fsmanager.setNode("/startup", 0, 755, nil, 0)
end
function shutdown_procedure()
    local k = next(mounts)
    while k do
        if mounts[k] then
            os.debug.debug_write('[fs_mngr] umounting '..mounts[k]['dev']..' at '..k)
            fsmanager.saveFS(k)
            mounts[k] = nil
            --return {true}
        end
        k = next(mounts)
    end
    sleep(.5)
end
-- how to basic: fs.complete
-- fs.find
-- fs.getDir
fs.combine = oldfs.combine
fs.getSize = function (path)
    for k,v in pairs(mounts) do
        if string.sub(path, 1, #k) == k and k ~= '/' then
            --mounted path ahead
            return fsdrivers[mounts[k]['fs']].getSize(k, string.sub(path, #k + 1))
        end
    end
    --normal path
    if fsdrivers['cfs'] then
        return fsdrivers['cfs'].getSize('/', path)
    else
        return oldfs.getSize(path)
    end
end
fs.getFreeSpace = oldfs.getFreeSpace
fs.getDrive = oldfs.getDrive --???
fs.getDir = oldfs.getDir
fs.exists = function(path)
    for k,v in pairs(mounts) do
        if string.sub(path, 1, #k) == k and k ~= '/' then
            --mounted path ahead
            return fsdrivers[mounts[k]['fs']].exists(k, string.sub(path, #k + 2))
        end
    end
    --normal path(as cfs mounted in '/')
    if fsdrivers['cfs'] then
        return fsdrivers['cfs'].exists('/', path)
    else
        return oldfs.exists(path)
    end
end
fs.move = function(fpath, tpath)
    return oldfs.move(fpath, tpath)
end
fs.copy = function(fpath, tpath)
    return oldfs.copy(fpath, tpath)
end
fs.delete = function(path)
    for k,v in pairs(mounts) do
        if string.sub(path, 1, #k) == k and k ~= '/' then
            --mounted path ahead
            return fsdrivers[mounts[k]['fs']].delete(k, string.sub(path, #k + 2))
        end
    end
    --normal path(as cfs mounted in '/')
    if fsdrivers['cfs'] then
        return fsdrivers['cfs'].delete('/', path)
    else
        return oldfs.delete(path)
    end
end
fs.isReadOnly = oldfs.isReadOnly
fs.list = function(path)
    for k,v in pairs(mounts) do
        if string.sub(path, 1, #k) == k and k ~= '/' then
            --mounted path ahead
            return fsdrivers[mounts[k]['fs']].list(k, string.sub(path, #k + 1))
        end
    end
    --normal path(as cfs mounted in '/')
    if fsdrivers['cfs'] then
        return fsdrivers['cfs'].list('/', path)
    else
        return oldfs.list(path)
    end
end
fs.makeDir = function(path)
    for k,v in pairs(mounts) do
        if string.sub(path, 1, #k) == k and k ~= '/' then
            --mounted path ahead
            return fsdrivers[mounts[k]['fs']].makeDir(k, string.sub(path, #k + 2))
        end
    end
    --normal path(as cfs mounted in '/')
    if fsdrivers['cfs'] then
        return fsdrivers['cfs'].makeDir('/', path)
    else
        return oldfs.makeDir(path)
    end
end
fs.isDir = function(path)
    for k,v in pairs(mounts) do
        if string.sub(path, 1, #k) == k and k ~= '/' then
            --mounted path ahead
            return fsdrivers[mounts[k]['fs']].isDir(k, string.sub(path, #k + 2))
        end
    end
    --normal path(as cfs mounted in '/')
    if fsdrivers['cfs'] then
        return fsdrivers['cfs'].isDir('/', path)
    else
        return oldfs.isDir(path)
    end
end
fs.open = function (path, mode, perm)
    for k,v in pairs(mounts) do
        if string.sub(path, 1, #k) == k and k ~= '/' then
            --mounted path ahead
            return fsdrivers[mounts[k]['fs']].open(k, string.sub(path, #k + 2), mode)
        end
    end
    --normal path
    if fsdrivers['cfs'] then
        return fsdrivers['cfs'].open('/', path, mode)
    else
        return oldfs.open(path, mode)
    end
end
function run_fstab()
    os.debug.debug_write("[run_fstab] reading fstab")
    if not fs.exists("/etc/fstab") then
        os.debug.kpanic("/etc/fstab not found")
    end
    local h = fs.open("/etc/fstab", 'r')
    local _fstab = h.readAll()
    h.close()
    local lines = os.strsplit(_fstab, '\n')
    for k,v in ipairs(lines) do
        local spl = os.strsplit(v, ';')
        local device = spl[1]
        local mpoint = spl[2]
        local fs = spl[3]
        local options = spl[4]
        fsmanager.mount(device, fs, mpoint)
    end
end
function libroutine()
    --os.deepcopy = deepcopy
    _G["permission"] = permission
    _G["fsmanager"] = fsmanager
    _G['oldfs'] = oldfs
    load_filesystems()
    run_fstab()
end
EndFile;
File;bin/mkdir
#!/usr/bin/env lua
--/bin/mkdir: wrapper to CC mkdir
_handler = {}
_handler.signal_handler = function(sig)
    if sig == 'kill' then
        --print("mkdir: SIGKILL")
        return 0
    end
end
function main(args)
    if #args == 0 then return 0 end
    local newfolder = args[1]
    fs.makeDir(os.cshell.resolve(newfolder))
    return 0
end
main({...})
EndFile;
File;proc/1/exe
/sbin/init
EndFile;
File;bin/cat
#!/usr/bin/env lua
--/bin/cat
_handler = {}
_handler.signal_handler = function(sig)
    if sig == 'kill' then
        --print("cat: SIGKILL")
        return 0
    end
end
function cat(file, bytes)
    local DEVICES = os.list_devices
    local MFILES = os.list_mfiles
    local cpth = fs.open("/tmp/current_path", 'r')
    local CURRENT_PATH = cpth.readAll()
    cpth.close()
    local pth = os.cshell.resolve(file)
    local _result = ''
    if DEVICES[file] ~= nil then
        _result = DEVICES[file].device_read(bytes)
    elseif MFILES[file] ~= nil then
        _result = MFILES[file].read(bytes)
    elseif fs.exists(pth) and not fs.isDir(pth) then
        local h = fs.open(pth, 'r')
        if h == nil then ferror("cat: error opening file") return 0 end
        _result = h.readAll()
        h.close()
    elseif fs.exists(file) and fs.isDir(file) then
        os.ferror("cat: cannot cat into folders")
    else
        os.ferror("cat: file not found")
    end
    return _result
end
function cat_pipe(file, pipe)
    local _r = cat(file)
    os.pprint(_r, pipe)
end
function main(args, pipe)
    if #args == 0 then return 0 end
    if pipe == nil then
        print(cat(args[1], args[2]))
    else
        cat_pipe(args[1], pipe)
    end
end
main({...})
EndFile;
File;dev/tty5
EndFile;
File;bin/cshell
#!/usr/bin/env lua
--/bin/wshell: cubix shell
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        print("cshell: recieved SIGKILL")
        return 0
    end
end
function strsplit(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t={} ; i=1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        t[i] = str
        i = i + 1
    end
    return t
end
local cuser = fs.open("/tmp/current_user", 'r')
local cpath = fs.open("/tmp/current_path", 'r')
current_user = cuser.readAll()
current_path = cpath.readAll()
cuser.close()
cpath.close()
os.cshell = {}
os.cshell.PATH = '/bin:/usr/bin'
os.cshell.getpwd = function()
    local handler = fs.open("/tmp/current_path", 'r')
    local result = handler.readAll()
    handler.close()
    return result
end
os.cshell.resolve = function(pth)
    local current_path = os.cshell.getpwd()
    function _combine(c) return current_path .. '/' .. c end
    function check_slash(s) return string.sub(s, 1, 1) == '/' end
    if check_slash(pth) then
        return pth
    else
        return _combine(pth)
    end
end
aliases = {}
function shell_command(k)
    --TODO: add support for & (multitasking)
    --if k == nil or k == "" then return 0 end
    if k == nil or k == '' then return 0 end
    if string.sub(k, 1, 1) == '#' then return 0 end
    for _, k in pairs(os.strsplit(k, "&&")) do
    if k:find("|") then
        local count = 1
        local programs = os.strsplit(k, "|")
        local npipe = os.lib.pipe.Pipe.new('main')
        for k,v in pairs(programs) do
            local c = os.strsplit(v, ' ')
            local program = c[1]
            local pargs = {}
            for k,v in pairs(c) do
                if v ~= program then
                    pargs[#pargs+1] = tostring(v)
                end
            end
            local found = false
            if fs.exists(program) then
                found = true
                os.runfile_proc(program, pargs, nil, npipe)
            elseif fs.exists(fs.combine(current_path, program)) then
                found = true
                os.runfile_proc(fs.combine(current_path, program), pargs, nil, npipe)
            end
            local _path = os.strsplit(os.cshell.PATH, ':')
            for k,v in ipairs(_path) do
                local K = fs.combine(v..'/', program)
                if fs.exists(K) then
                    found = true
                    os.runfile_proc(K, pargs, nil, npipe)
                end
            end
            if fs.exists(fs.combine("/sbin/", program)) then
                if current_user == "root" then
                    found = true
                    os.runfile_proc(fs.combine("/sbin/", program), pargs, nil, npipe)
                end
            end
            if not found then
                os.ferror("cshell: Program not found")
            end
        end
    else
        local c = strsplit(k, " ")
        local program = c[1]
        if program == 'echo' then
            args = strsplit(k, ';')
            print(args[2])
            return 0
        elseif program == 'APATH' then
            args = strsplit(k, ' ')
            os.cshell.PATH = os.cshell.PATH .. ':' .. args[2]
            return 0
        elseif program == 'PPATH' then
            print(os.cshell.PATH)
            return 0
        elseif program == "getuid" then
            print(os.lib.login.currentUser().uid)
            return 0
        elseif program == 'getperm' then
            permission.getPerm()
            return 0
        elseif program == 'alias' then
            local arg = string.sub(k, #program + 1, #k)
            local spl = os.strsplit(arg, '=')
            local key = spl[1]
            local alias = spl[2]
            aliases[key] = string.sub(alias, 2, #alias - 1)
            return 0
        elseif program == 'aliases' then
            os.viewTable(aliases)
            return 0
        end
        local args = {}
        for k,v in pairs(c) do
            if v == program then
            else
                args[#args+1] = v
            end
        end
        local found = false
        if fs.exists(program) then
            _l = os.strsplit(program, '/')
            if _l[1] ~= 'sbin' then
                found = true
                os.runfile_proc(program, args)
            end
        elseif not found and fs.exists(fs.combine(current_path, program)) then
            print(current_path)
            if current_path ~= '/sbin' or current_path ~= 'sbin' then
                found = true
                os.runfile_proc(fs.combine(current_path, program), args)
            end
        end
        local _path = os.strsplit(os.cshell.PATH, ':')
        for k,v in ipairs(_path) do
            local K = fs.combine(v..'/', program)
            if not found and fs.exists(K) then
                found = true
                os.runfile_proc(K, args)
            end
        end
        if not found and fs.exists(fs.combine("/sbin/", program)) then
            if current_user == "root" then
                found = true
                os.runfile_proc(fs.combine("/sbin/", program), args)
            end
        end
        if not found then
            os.ferror("cshell: "..program..": Program not found")
        end
    end
    end
end
os.cshell.__shell_command = shell_command
os.cshell.complete = function()
    --return fs.complete(current_path)
end
local aliases = {}
function new_shcommand(cmd)
    shell_command(cmd)
end
function run_cshrc(user)
    if not fs.exists('/home/'..user..'/.cshrc') then
        os.debug.debug_write("[cshell] .cshrc not found", nil, true)
        return 1
    end
    local cshrc_handler = fs.open('/home/'..user..'/.cshrc', 'r')
    local _lines = cshrc_handler.readAll()
    cshrc_handler.close()
    local lines = os.strsplit(_lines, '\n')
    for k,v in ipairs(lines) do
        new_shcommand(v)
    end
    return 0
end
function main(args)
    os.shell = os.cshell --compatibility
    --TODO: -c
    if fs.exists("/tmp/install_lock") then
        term.set_term_color(colors.green)
        print("Hey, it seems that you installed cubix recently, do you know you can create a new user using 'sudo adduser' in the shell, ok?(remember that the default password is 123)")
        term.set_term_color(colors.white)
        fs.delete("/tmp/install_lock")
    end
    local command = ""
    local HISTORY = {}
    if #args > 0 then
        local ecmd = args[1]
        print(ecmd)
        --print(string.sub(ecmd, 1, #ecmd -1))
        local h = fs.open(os.cshell.resolve(ecmd), 'r')
        local _l = h.readAll()
        h.close()
        local lines = os.strsplit(_l, '\n')
        for k,v in ipairs(lines) do
            shell_command(v)
        end
        return 0
    end
    local cuser = fs.open("/tmp/current_user", 'r')
    current_user = cuser.readAll()
    cuser.close()
    run_cshrc(current_user)
    while true do
        local cuser = fs.open("/tmp/current_user", 'r')
        local cpath = fs.open("/tmp/current_path", 'r')
        current_user = cuser.readAll()
        current_path = cpath.readAll()
        cuser.close()
        cpath.close()
        if current_user == 'root' then
            shell_char = '# '
        else
            shell_char = '$ '
        end
        write(current_user .. ':' .. current_path .. shell_char)
        command = read(nil, HISTORY, os.cshell.complete)
        if command == "exit" then
            return 0
        elseif command ~= nil then
            if command ~= '' or not command:find(" ") then
                --i dont know why this isnt working, sorry.
                table.insert(HISTORY, command)
            end
            shell_command(command)
        end
    end
    return 0
end
main({...})
EndFile;
File;boot/cubix
#!/usr/bin/env lua
--/boot/cubix: well, cubix!
AUTHOR = "Lukas Mendes"
BUILD_DATE = "2016-02-28"
--  version format: major.revision.minor
--      major: linear
--      revision: odd: unstable
--      revision: even: stable
--      minor: number of RELEASES necessary to get to this version, not including BUILDS
--  0.3.8 < 0.3.9 < 0.3.10 < 0.3.11 < 0.4.0 < 0.4.1 [...]
--  {           UNSTABLE           }  {  STABLE   }
VERSION_MAJOR = 0
VERSION_REV   = 5
VERSION_MINOR = 1
VERSION = VERSION_MAJOR.."."..VERSION_REV.."."..VERSION_MINOR
STABLE = ((VERSION_REV % 2) == 0)
if STABLE then
    local pullEvent = os.pullEvent
    os.pullEvent = os.pullEventRaw
else
    print("[cubix] warning, loading a unstable")
end
_G['IS_CUBIX'] = true
--frontend for compatibility
term.set_term_color = function (c)
    if term.isColor() then
        term.setTextColor(c)
    end
end
if os.loadAPI("/boot/cubix-initramfs") then
    print("[cubix] loaded initramfs.")
else
    term.set_term_color(colors.red)
    print("[cubix] initramfs error, can't start kernel.")
    os.system_halt()
end
local Args = {...} --arguments to cubix
os.__boot_flag = true
kflag = {}
for k,v in ipairs(Args) do
    if v == 'quiet' then
        kflag.quiet = true
    elseif v == 'splash' then
        kflag.splash = true
    elseif v == 'acpi' then
        kflag.acpi = true
    elseif string.sub(v, 0, 4) == 'init' then
        k = os.strsplit(v, '=')
        kflag.init = k[2]
    elseif string.sub(v, 0, 8) == 'runlevel' then
        k = os.strsplit(v, '=')
        kflag.sRunlevel = k[2]
    end
end
if kflag.init == nil then
    kflag.init = "/sbin/init"
end
os.__kflag = kflag
local pcid = fs.open("/var/pcid", 'w')
local _label = os.getComputerLabel()
if _label == nil then _label = 'generic' end
pcid.write(_label)
pcid.close()
--some default things in /proc
local version = fs.open("/proc/version", 'w')
version.write(VERSION)
version.close()
local build = fs.open("/proc/build_date", 'w')
build.write(BUILD_DATE)
build.close()
local sttime = fs.open("/proc/sttime", 'w')
sttime.write(tostring(os.time()))
sttime.close()
DEVICES = {}
MANAGED_FILES = {}
TTYS = {}
os.list_mfiles = {}
--halting.
os.system_halt = function()
    while true do sleep(0) end
end
os._read = read
os._sleep = os.sleep
os.ferror = function(message)
    --TODO: stdin, stdout and stderr
    --[[
    device_write("/dev/stderr", message)
    ]]
    term.set_term_color(colors.red)
    print(message)
    term.set_term_color(colors.white)
end
_G['ferror'] = os.ferror
if os.loadAPI("/lib/video_manager") then
    print("loaded video")
end
if os.loadAPI("/lib/debug_manager") then
    __debug = _G["debug_manager"]
    __debug.debug_write("debug: loaded")
else
    __debug.debug_write = print
    term.set_term_color(colors.red)
    __debug.debug_write("debug: not loaded")
    term.set_term_color(colors.white)
end
os.debug = __debug
debug = os.debug
cubix = {}
_G['cubix'] = cubix
cubix.boot_kernel = function()
if kflag.quiet then
    --if quiet, just make normal debug functions as nothing.
    __debug.debug_write = function()
        os.sleep(math.random() / 16)
    end
    __debug.testcase = function()
    end
    __debug.ferror = function()end
end
--Welcome message
term.set_term_color(colors.green)
os.debug.debug_write("Welcome to Cubix "..VERSION..'!')
print('\n')
term.set_term_color(colors.white)
os.sleep(.5)
os.lib = {}
os.internals = {}
os.internals._kernel = {}
local isReloadable = {}
--default function to load modules
function loadmodule(nmodule, path)
    os.debug.debug_write('[mod] loading: '..nmodule)
    if isReloadable[nmodule] ~= nil and isReloadable[nmodule] == false then
        os.debug.debug_write("[mod] cannot reload "..nmodule..", please reboot!", nil, true)
        return 0
    end
    if os.loadAPI(path) then
        _G[nmodule] = _G[fs.getName(path)]
        if _G[nmodule].libroutine ~= nil then
            _G[nmodule].libroutine()
        else
            os.debug.debug_write("[mod] libroutine() not found", nil, true)
            sleep(.3)
        end
        os.lib[nmodule] = _G[fs.getName(path)]
        isReloadable[nmodule] = os.lib[nmodule].RELOADABLE
        os.debug.debug_write('[mod] loaded: '..nmodule)
    else
        os.debug.kpanic("[mod] not loaded: "..nmodule)
    end
end
--unload a module
function unloadmod(mod)
    if os.lib[mod] then
        os.debug.debug_write("[unloadmod] unloading "..mod)
        os.lib[mod] = nil
        return true
    else
        ferror("unloadmod: module not found")
        return false
    end
end
function loadmodule_ret(path)
    -- instead of putting the library into os.lib, just return it
    os.debug.debug_write('[loadmodule:ret] loading: '..path)
    local ret = {}
    if os.loadAPI(path) then
        ret = _G[fs.getName(path)]
        if ret.libroutine ~= nil then
            ret.libroutine()
        else
            os.debug.debug_write("[loadmodule:ret] libroutine() not found", nil, true)
            sleep(.3)
        end
        os.debug.debug_write('[loadmodule:ret] loaded: '..path)
        return ret
    else
        ferror("[loadmodule:ret] not loaded: "..path)
        return nil
    end
end
os.internals.loadmodule = loadmodule
os.internals.unloadmod = unloadmod
--show all loaded modules in the system(shows to stdout)
os.viewLoadedMods = function()
    for k,v in pairs(os.lib) do
        write(k..' ')
    end
    write('\n')
end
--hack
os.lib.proc = {}
os.lib.proc.running = 0
os.processes = {}
function make_readonly(table)
    local temporary = {}
    setmetatable(temporary, {
        __index = table,
        __newindex = function(_t, k, v)
            local runningproc = os.processes[os.lib.proc.running]
            if runningproc == nil then
                os.debug.debug_write("[readonly -> proc] cubix is not running any process now!", nil, true)
                table[k] = v
                return 0
            end
            if runningproc.uid ~= 0 then
                os.debug.debug_write("[readonly] Attempt to modify read-only table", nil, true)
            else
                table[k] = v
            end
        end,
        __metatable = false
    })
    os.debug.debug_write("[readonly] new read-only table!")
    return temporary
end
_G['make_readonly'] = make_readonly
--acpi module
if kflag.acpi then
    loadmodule("acpi", "/lib/acpi.lua")
end
--another hack
os.lib.login = {}
os.lib.login.currentUser = function()
    return {uid = 2}
end
--filesystem manager
loadmodule("fs_mngr", "/lib/fs_manager")
--start permission system for kernel boot
permission.initKernelPerm()
--hibernation detection
if fs.exists("/dev/ram") and os.lib.acpi then
    os.lib.acpi.acpi_hwake()
else
--process manager
function os.internals._kernel.register_mfile(controller) --register Managed Files
    debug.debug_write("[mfile] "..controller.name.." created")
    os.list_mfiles[controller.name] = controller.file
    fs.open(controller.name, 'w', fs.perms.SYS).close()
    -- debug.debug_Write("[mfile] "..controller.name)
    -- new_mfile(controller)
end
loadmodule("proc", "/lib/proc_manager")
--hash manager
loadmodule("hash", "/lib/hash_manager")
function os.internals._kernel.register_device(path, d)
    os.debug.debug_write("[dev] "..path.." created")
    DEVICES[path] = d.device
    fs.open(path, 'w', fs.perms.SYS).close()
end
--device manager
loadmodule("devices", "/lib/device_manager")
--external devices
function from_extdev(name_dev, path_dev, type_dev)
    --path_dev -> /dev/
    --name -> only a id
    --type_dev -> device drivers(something.lua)
    --returns a table with the device methods
    local devmod = loadmodule_ret("/lib/devices/"..type_dev..".lua")
    devmod.setup(name_dev, path_dev)
    return devmod
end
EXTDEVICES = {}
function os.internals._kernel.new_device(typedev, name, pth)
    os.debug.debug_write("[extdev] "..name.." ("..typedev..") -> "..pth)
    EXTDEVICES[name] = {devtype=typedev, path=pth}
    os.internals._kernel.register_device(pth, {name=pth, device=from_extdev(name,pth,typedev)})
end
--default devices
os.internals._kernel.new_device("kbd", "cckbd", "/dev/stdin")
os.internals._kernel.new_device("term", "ccterm", "/dev/stdout")
os.internals._kernel.new_device("err", "ccterm-err", "/dev/stderr")
os.list_devices = deepcopy(DEVICES)
function dev_write(path, data)
    return os.list_devices[path].device_write(data)
end
_G['dev_write'] = dev_write
--device functions
function dev_read(path, bytes) --read from devices
    local result = os.list_devices[path].device_read(bytes)
    return result
end
_G['dev_read'] = dev_read
function dev_available(path) --check if device is available
    local av = os.list_devices[path] ~= nil
    return av
end
_G['dev_available'] = dev_available
function get_device(pth) --get the device object from its path
    return os.list_devices[pth]
end
_G['get_device'] = get_device
function os.list_dev() --list all devices(shows to stdout automatically)
    for k,v in pairs(os.list_devices) do
        write(k..' ')
    end
    write('\n')
end
local perilist = peripheral.getNames()
os.debug.debug_write("[peripheral:st]")
for i = 1, #perilist do
    os.internals._kernel.new_device("peripheral", tostring(peripheral.getType(perilist[i])))
end
--tty, login and pipe managers
function os.internals._kernel.register_tty(path, tty) --register TTY to the system
    os.debug.debug_write("[tty] new tty: "..path)
    fs.open(path, 'w', fs.perms.SYS).close()
end
loadmodule("tty", "/lib/tty_manager")
loadmodule("login", "/lib/login_manager")
loadmodule("pipe", "/lib/pipe_manager")
loadmodule("time", "/lib/time")
loadmodule("control", "/lib/comm_manager")
os.pprint = function(message, pipe, double)
    if double == nil then double = false end
    if message == nil then message = '' end
    if pipe ~= nil then
        pipe:write(message..'\n')
        if double then
            print(message)
        end
    else
        print(message)
    end
end
term.clear()
term.setCursorPos(1,1)
--finishing boot
os.__debug_buffer = debug.__debug_buffer
os.__boot_flag = false
--setting tty
os.lib.tty.current_tty("/dev/tty0")
--if quiet, return debug to original state(you know, debug is important)
if kflag.quiet then
    if os.loadAPI("/lib/debug_manager") then
        __debug = _G["debug_manager"]
        debug.debug_write("debug: loaded")
    else
        __debug.debug_write = print
        term.set_term_color(colors.red)
        __debug.debug_write("debug: not loaded")
        term.set_term_color(colors.white)
    end
end
os.debug = __debug
term.clear()
term.setCursorPos(1,1)
--finally, run!
os.__parent_init = os.new_process(kflag.init)
if kflag.sRunlevel ~= nil then
    os.run_process(os.__parent_init, {kflag.sRunlevel})
else
    os.run_process(os.__parent_init)
end
--if something goes wrong in kflag.init(such as kill of a monster), just halt
os.system_halt()
end
end
if kflag.splash then
    if bootsplash then
        kflag.quiet = true
        bootsplash.load_normal()
    else
        ferror("splash: bootsplash not loaded at initramfs.")
        sleep(.5)
        kflag.quiet = false
        cubix.boot_kernel()
    end
else
    cubix.boot_kernel()
end
--if the boot_kernel() returns or something, just print a message saying it
print("cubix kernel: end of kernel execution.")
EndFile;
File;lib/video_manager
#!/usr/bin/env lua
-- cubix: video_manager
os.central_print = function(text)
    local x,y = term.getSize()
    local x2,y2 = term.getCursorPos()
    term.setCursorPos(math.ceil((x / 2) - (text:len() / 2)), y2)
    write(text..'\n')
end
EndFile;
File;boot/cubix-initramfs
#!/usr/bin/env lua
--libcubix: compatibility for cubix
AUTHOR = 'Lukas Mendes'
VERSION = '0.1'
--[[
Libcubix serves as a library that contains all the functions
that do not use any "cubix" thing(like ferror for example)
Libcubix is used in installation stage to create a cubix initramfs,
this servers as the basic functions that are needed in systemboot and
after it(os.strsplit, os.tail, etc.)
As there can be other versions of initramfs created by the community,
this version serves as the "official" libcubix and initramfs generator
for cubix.
Libcubix was created to make programs writed in Pure Lua to use some of
the functions in Cubix, without making the programs to be run at Cubix enviroment
]]
os.viewTable = function (t)
    if t == nil then return 0 end
    print(t)
    for k,v in pairs(t) do
        print(k..","..tostring(v).." ("..type(v)..")")
    end
end
os.tail = function(t)
    if # t <= 1 then
        return nil
    end
    local newtable = {}
    for i, v in ipairs(t) do
        if i > 1 then
            table.insert(newtable, v)
        end
    end
    return newtable
end
os.strsplit = function (inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    if type(inputstr) ~= 'string' then
        term.set_term_color(colors.red)
        print("os.strsplit: type(inputstr) == "..type(inputstr))
        term.set_term_color(colors.white)
        return 1
    end
    if inputstr == nil then
        return ''
    end
    local t={} ; i=1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        t[i] = str
        i = i + 1
    end
    return t
end
function strcount(str, char)
    local c = 0
    for i=1, #str do
        local v = string.sub(str, i, i)
        if v == char then
            c = c + 1
        end
    end
    return c
end
_G['strcount'] = strcount
os.safestr = function (s)
    if string.byte(s) > 191 then
        return '@'..string.byte(s)
    end
    return s
end
os.generateSalt = function(l)
    if l < 1 then
        return nil
    end
    local res = ''
    for i = 1, l do
        res = res .. string.char(math.random(32, 126))
    end
    return res
end
function _prompt(message, yes, nope)
    write(message..'['..yes..'/'..nope..'] ')
    local result = read()
    if result == yes then
        return true
    else
        return false
    end
end
_G['prompt'] = _prompt
function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
        return copy
    else -- number, string, boolean, etc
        return orig
    end
    --return copy
end
os.deepcopy = deepcopy
_G['deepcopy'] = deepcopy
function gethostname()
    local h = fs.open("/etc/hostname", 'r')
    if h == nil then
        return ''
    end
    local hstn = h.readAll()
    h.close()
    return hstn
end
_G['gethostname'] = gethostname
function class(base, init)
   local c = {}    -- a new class instance
   if not init and type(base) == 'function' then
      init = base
      base = nil
   elseif type(base) == 'table' then
    -- our new class is a shallow copy of the base class!
      for i,v in pairs(base) do
         c[i] = v
      end
      c._base = base
   end
   -- the class will be the metatable for all its objects,
   -- and they will look up their methods in it.
   c.__index = c
   -- expose a constructor which can be called by <classname>(<args>)
   local mt = {}
   mt.__call = function(class_tbl, ...)
   local obj = {}
   setmetatable(obj,c)
   if init then
      init(obj,...)
   else
      -- make sure that any stuff from the base class is initialized!
      if base and base.init then
      base.init(obj, ...)
      end
   end
   return obj
   end
   c.init = init
   c.is_a = function(self, klass)
      local m = getmetatable(self)
      while m do
         if m == klass then return true end
         m = m._base
      end
      return false
   end
   setmetatable(c, mt)
   return c
end
_G['class'] = class
function generate_lcubix(type, path)
    if type == 'all' then
        local h = fs.open("/boot/libcubix", 'r')
        local all_lcubix = h.readAll()
        h.close()
        local h2 = fs.open(path, 'w')
        h2.write(all_lcubix)
        h2.close()
    end
end
EndFile;
File;dev/null
EndFile;
File;dev/tty6
EndFile;
File;dev/MAKEDEV
#!/usr/bin/env lua
--/dev/MAKEDEV: create unix folder structure in /
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        --print("MAKEDEV: SIGKILL'd!", false)
        return 0
    end
end
function main(args)
    os.runfile = shell.run
    os.runfile("mkdir /proc") --proc_manager
    os.runfile("mkdir /bin") --binaries
    os.runfile("mkdir /sbin") --root binaries
    os.runfile("mkdir /boot") --boot things
    os.runfile("mkdir /etc") --system-wide configuration files and system databases
    os.runfile("mkdir /etc/rc0.d")
    os.runfile("mkdir /etc/rc1.d")
    os.runfile("mkdir /etc/rc2.d")
    os.runfile("mkdir /etc/rc3.d")
    os.runfile("mkdir /etc/rc5.d")
    os.runfile("mkdir /etc/rc6.d")
    os.runfile("mkdir /etc/scripts")
    os.runfile("mkdir /home") --home folder
    os.runfile("mkdir /home/cubix") --default user
    os.runfile("mkdir /lib") --libraries
    os.runfile("mkdir /mnt") --mounting
    os.runfile("mkdir /root") --home for root
    os.runfile("mkdir /usr") --user things
    os.runfile("mkdir /usr/bin")
    os.runfile("mkdir /usr/games")
    os.runfile("mkdir /usr/lib")
    os.runfile("mkdir /usr/sbin")
    os.runfile("mkdir /var") --variables
    os.runfile("rm /tmp") --removing temporary because yes
    os.runfile("mkdir /tmp") --temporary, deleted when shutdown/reboot
    os.runfile("mkdir /media") --mounting
    os.runfile("mkdir /usr/manuals") --manuals
    print("MAKEDEV: created folders")
end
main()
EndFile;
File;proc/1/stat
stat working
EndFile;
File;dev/loop1
EndFile;
File;sbin/sbl-mkconfig
#!/usr/bin/env lua
--/bin/sbl-mkconfig: make systems.cfg
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        --print("sbl-mkconfig: recieved SIGKILL")
        return 0
    end
end
function main(args)
    if #args == 0 then
        print("welcome to sbl-mkconfig!")
        print("here you can write a new systems.cfg file from scratch")
        local entries = {}
        while true do
            write("OS entry: ")
            local osentry = read()
            if osentry == '' then break end
            write("OS script: ")
            local oscmd = read()
            entries[osentry] = oscmd
        end
        print("writing to /boot/sblcfg/systems.cfg")
        if entries[''] == '' then
            local sResult = ''
            for k,v in pairs(entries) do
                sResult = sResult .. k .. ';' .. v .. '\n'
            end
            local h = oldfs.open("/boot/sblcfg/systems.cfg", 'w')
            h.write(sResult)
            h.close()
        else
            print("sbl-mkconfig: aborted.")
        end
        print("sbl-mkconfig: done!")
    elseif #args == 1 then
        local mode = args[1]
        if mode == 'default' then
            print("sbl-mkconfig: restoring system.cfg to default.cfg")
            local default = fs.open("/boot/sblcfg/default.cfg", 'r')
            local systems = fs.open("/boot/sblcfg/systems.cfg", 'w')
            systems.write(default.readAll())
            default.close()
            systems.close()
            print("Done!")
        end
    else
        print("usage: sbl-mkconfig [mode]")
    end
end
main({...})
EndFile;
File;tmp/current_user
cubix
EndFile;
File;bin/sudo
#!/usr/bin/env lua
--/bin/sudo: grants access to run programs in /sbin
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        os.debug.debug_write("sudo: SIGKILL'd!", false)
        return 0
    end
end
local __sudo_lock = true
function sudo_error(msg)
    ferror(msg)
    os.lib.login.close_sudo()
end
function run_program(_args)
    local program = _args[1]
    if program == nil then return 0 end
    local args = os.tail(_args)
    local h = fs.open("/tmp/current_path", 'r')
    local current_path = h.readAll()
    h.close()
    local found = false
    if fs.exists(program) then
        found = true
        os.runfile_proc(program, args)
    elseif fs.exists(fs.combine(current_path, program)) then
        found = true
        os.runfile_proc(fs.combine(current_path, program), args)
    end
    local _path = os.strsplit(os.cshell.PATH, ':')
    for k,v in ipairs(_path) do
        local K = fs.combine(v..'/', program)
        if fs.exists(K) then
            found = true
            os.runfile_proc(K, args)
        end
    end
    if fs.exists(fs.combine("/sbin/", program)) then
        found = true
        os.runfile_proc(fs.combine("/sbin/", program), args)
    end
    if not found then
        os.ferror("sudo: Program not found")
    end
    return 0
end
function main(args)
    os.lib.login.alert_sudo()
    local current_user = os.lib.login.currentUser()
    local isValid = os.lib.login.general_verify(current_user)
    --if valid, verify if current user can run programs with UID=0
    if isValid then
        if os.lib.login.sudoers_verify_user(current_user, 'root') then
            os.lib.login.use_ctok()
            run_program(args)
        else
            sudo_error("sudo: "..current_user.." is not in the sudoers file")
            return 1
        end
    else
        if os.lib.login.sudoers_verify_user(current_user, 'root') then
            if os.lib.login.front_login('sudo', current_user) then
                --os.lib.login.use_ctok()
                run_program(args)
            else
                sudo_error("sudo: Login incorrect")
                return 1
            end
        else
            sudo_error("sudo: "..current_user.." is not in the sudoers file")
            return 1
        end
    end
    os.lib.login.close_sudo()
    return 0
end
main({...})
EndFile;
File;boot/sbl
#!/usr/bin/env lua
--Simple Boot Loader
term.clear()
term.setCursorPos(1,1)
VERSION = '0.20'
function _halt()
    while true do os.sleep(0) end
end
function strsplit(inputstr, sep)
        if sep == nil then
                sep = "%s"
        end
        local t={} ; i=1
        for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
                t[i] = str
                i = i + 1
        end
        return t
end
os.viewTable = function (t)
    print(t)
    for k,v in pairs(t) do
        print(k..","..tostring(v).." ("..type(v)..")")
    end
end
function tail(t)
       if # t <= 1 then
          return nil
       end
       local newtable = {}
       for i, v in ipairs(t) do
          if i > 1 then
              table.insert(newtable, v)
          end
       end
       return newtable
end
term.set_term_color = function (c)
    if term.isColor() then
        term.setTextColor(c)
    end
end
local function cprint(text)
    local x,y = term.getSize()
    local x2,y2 = term.getCursorPos()
    term.setCursorPos(math.ceil((x / 2) - (text:len() / 2)), y2)
    write(text..'\n')
end
function CUI(m)
    n=1
    l=#m
    while true do
        term.clear()
        term.setCursorPos(1,2)
        cprint("SBL "..VERSION)
        cprint("")
        for i=1, l, 1 do
            if i==n then
                cprint(i .. " ["..m[i].."]")
            else
                cprint(i .. " " .. m[i])
            end
        end
        cprint("")
        cprint("Select a OS to load")
        cprint("[arrow up/arrow down/enter]")
        local kpress = nil
        a, b= os.pullEventRaw()
        if a == "key" then
            if b==200 and n>1 then n=n-1 end
            if b==208 and n<l then n=n+1 end
            if b==28 then kpress = 'ENTER' break end
            if b==18 then kpress = 'e' break end
        end
    end
    term.clear()
    term.setCursorPos(1,1)
    return {n, kpress}
end
function read_osfile()
    local systems_file = fs.open("/boot/sblcfg/systems.cfg", 'r')
    local systems = strsplit(systems_file.readAll(), "\n")
    local i = 1
    local detected_oses_name = {}
    local detected_oses_path = {}
    print("reading systems.cfg...")
    for k,v in pairs(systems) do
        local sysdat = strsplit(systems[k], ';')
        detected_oses_name[i] = sysdat[1]
        detected_oses_path[i] = sysdat[2]
        print(sysdat[1]..' -> '..sysdat[2])
        i = i + 1
        os.sleep(.1)
    end
    systems_file.close()
    return {detected_oses_name, detected_oses_path}
end
local availablemods = {}
availablemods['kernel'] = true
local loadmods = {}
function loadkernel(kfile, memory)
    --loads a .lua kernel file with its main function
    --TODO lineboot: parse commands, like set, to boot from hdd and from disk!
    --TODO lineboot: actually make SBL more GRUB-like
    local sbl_env = {}
    local lFile = ''
    local _CHAINLOADER = false
    if kfile == 'lineboot' then
        while true do
            write("SBL:> ")
            local k = strsplit(read(), ' ')
            if k[1] == 'kernel' then
                if loadmods['kernel'] then
                    lFile = table.concat(tail(k), ' ')
                else
                    print("SBL: kernel not loaded")
                end
            elseif k[1] == 'boot' then
                break
            elseif k[1] == 'set' then
                local _d = strsplit(k[2], '=')
                local location = _d[1]
                local set = _d[2]
                sbl_env[location] = set
            elseif k[1] == 'chainloader' then
                if k[2] == '+1' then
                    _CHAINLOADER = true
                end
            elseif k[1] == 'halt' then
                _halt()
            elseif k[1] == 'insmod' then
                local module = k[2]
                if availablemods[module] ~= nil then
                    print("SBL: loaded "..module)
                    loadmods[module] = true
                else
                    print("SBL: module not found")
                end
            elseif l[1] == 'load_video' then
                term.clear()
                term.setCursorPos(1,1)
            end
        end
    else
        local handler = fs.open(kfile, 'r')
        if handler == nil then print("SBL: error opening bootscript") return 0 end
        local lines = strsplit(handler.readAll(), '\n')
        for _,v in ipairs(lines) do
            local k = strsplit(v, ' ')
            if k[1] == 'kernel' then
                if loadmods['kernel'] then
                    lFile = table.concat(tail(k), ' ')
                else
                    print("SBL: kernel not loaded")
                end
            elseif k[1] == 'boot' then
                break
            elseif k[1] == 'set' then
                local _d = strsplit(k[2], '=')
                local location = _d[1]
                local set = _d[2]
                sbl_env[location] = set
            elseif k[1] == 'chainloader' then
                if k[2] == '+1' then
                    _CHAINLOADER = true
                end
            elseif k[1] == 'halt' then
                _halt()
            elseif k[1] == 'insmod' then
                local module = k[2]
                if availablemods[module] ~= nil then
                    print("SBL: loaded "..module)
                    loadmods[module] = true
                else
                    print("SBL: module not found")
                end
            elseif k[1] == 'load_video' then
                term.clear()
                term.setCursorPos(1,1)
            end
        end
    end
    --print("SBL: loading \""..lFile.."\"")
    os.sleep(.5)
    local tArgs = strsplit(lFile, ' ')
    local sCommand = tArgs[1]
    local sFrom = ''
    if sbl_env['root'] == '(hdd)' then
        sFrom = ''
    elseif sbl_env['root'] == '(disk)' then
        sFrom = '/disk'
    else
        print("SBL: error parsing root")
        return 0
    end
    if _CHAINLOADER then
        print("sbl: chainloading.")
        os.run({}, sFrom..'/sstartup')
    end
    print("SBL: loading \""..sFrom..'/'..sCommand.."\"\n")
    if sCommand == '/rom/programs/shell' then
        shell.run("/rom/programs/shell")
    else
        os.run({}, sFrom..'/'..sCommand, table.unpack(tArgs, 2))
    end
end
term.setBackgroundColor(colors.white)
term.set_term_color(colors.black)
print("Welcome to SBL!\n")
term.set_term_color(colors.white)
term.setBackgroundColor(colors.black)
os.sleep(.5)
oses = read_osfile()
table.insert(oses[1], "SBL Command Line")
table.insert(oses[2], "lineboot")
local user_selection = CUI(oses[1]) --only names
selected_os = user_selection[1]
--load kernel
loadkernel(oses[2][selected_os], 512)
_halt()
EndFile;
File;tmp/current_path
/home/cubix
EndFile;
File;dev/tty4
EndFile;
File;lib/luaX/lxServer.lua
--/lib/luaX/lxServer.lua
--luaX "makes forms" part
if not _G['LX_LUA_LOADED'] then
    os.ferror("lxServer: lx.lua not loaded")
    return 0
end
--term.redirect(term.native())
function write_vline(lX, lY, c, colorLine)
    term.setBackgroundColor(colorLine)
    term.setCursorPos(lX, lY)
    local tmpY = lY
    for i=0,c do
        os.lib.lx.write_pixel(c, tmpY, colorLine)
        tmpY = tmpY + 1
    end
    term.set_bg_default()
end
function write_hline(lX, lY, c, colorLine)
    term.setBackgroundColor(colorLine)
    term.setCursorPos(lX, lY)
    local tmpX = lX
    for i=0,c do
        os.lib.lx.write_pixel(tmpX, c, colorLine)
        tmpX = tmpX + 1
    end
    term.set_bg_default()
end
function write_rectangle(locX, locY, lenX, lenY, colorR)
    term.setBackgroundColor(colorR)
    term.setCursorPos(locX, locY)
    --black magic goes here
    for i=0, lenY do
        os.lib.lx.write_pixel(locX, locY+i, colorR)
    end
    for i=0, lenY do
        os.lib.lx.write_pixel(locX+lenX+1, locY+i, colorR)
    end
    for i=0, lenX do
        os.lib.lx.write_pixel(locY+i, locY, colorR)
    end
    for i=0, (lenX+1) do
        os.lib.lx.write_pixel((locY)+i, locY+lenY+1, colorR)
    end
    term.set_bg_default()
end
function write_square(lX, lY, l, colorR)
    return write_rectangle(lX, lY, l, l, colorR)
end
function write_solidRect(locX, locY, lenX, lenY, colorSR)
    write_rectangle(locX, locY, lenX, lenY, colorSR)
    for x = locX, (locX+lenX) do
        for y = locY, (locY+lenY) do
            os.lib.lx.write_pixel(x, y, colorSR)
        end
    end
    term.set_bg_default()
end
function lxError(lx_type, emsg)
    local message = lx_type..': '..emsg..'\n'
    local lxerrh = fs.open("/tmp/lxlog", 'a')
    lxerrh.write(message)
    lxerrh.close()
    if dev_available("/dev/stderr") then
        dev_write("/dev/stderr", message)
    else
        os.ferror(message)
    end
end
function demo_printMark()
    os.lib.lx.write_letter('l', 1, 1, colors.lightBlue, colors.blue)
    os.lib.lx.write_letter('x', 2, 1, colors.lightBlue, colors.blue)
    os.lib.lx.write_letter('S', 3, 1, colors.lightBlue, colors.blue)
    os.lib.lx.write_letter('e', 4, 1, colors.lightBlue, colors.blue)
    os.lib.lx.write_letter('r', 5, 1, colors.lightBlue, colors.blue)
    os.lib.lx.write_letter('v', 6, 1, colors.lightBlue, colors.blue)
    os.lib.lx.write_letter('e', 7, 1, colors.lightBlue, colors.blue)
    os.lib.lx.write_letter('r', 8, 1, colors.lightBlue, colors.blue)
end
function sv_demo()
    demo_printMark()
    write_vline(10, 10, 5, colors.green)
    os.sleep(1)
    write_hline(11, 11, 10, colors.yellow)
    os.sleep(1)
    os.lib.lx.blank()
    demo_printMark()
    write_rectangle(5, 5, 10, 5, colors.red)
    os.sleep(1)
    os.lib.lx.blank()
    demo_printMark()
    write_square(5, 5, 5, colors.red)
    os.sleep(1)
    os.lib.lx.blank()
    demo_printMark()
    for i=3,15 do
        write_square(i,i,6+i,os.lib.lx.random_color())
        sleep(.5)
    end
    sleep(3.5)
    os.lib.lx.blank()
    demo_printMark()
    os.debug.kpanic('lx kpanic test')
end
function libroutine()
    _G['LX_SERVER_LOADED'] = true
    _G['lxError'] = lxError
end
EndFile;
File;bin/yes
#!/usr/bin/env lua
--/bin/yes: outputs "y"
function print_y()
    while true do
        io.write('y\n')
        --os.sleep(0)
    end
end
function main(args)
    local cy = coroutine.create(print_y)
    coroutine.resume(cy)
    while true do
        local event, key = os.pullEvent( "key" )
        if event and key then
            break
        end
    end
end
main({...})
EndFile;
File;etc/shadow
cubix^8875ac1c6e6ab7b10ce9162cc3cc33c2330018df9664a58deb568b3cc1cb4fef^'d9M'W_}sD!6'Pv^cubix
root^63574847901e6d7f982c30ba96c4bc46a14e9503708085f2cc45295957c23462^,6@bQ+}k7@E7q45^root
EndFile;
File;lib/net/network.lua
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
EndFile;
File;bin/time
#!/usr/bin/env lua
--/bin/time: measure time used by a command (in minecraft ticks)
_handler = {}
_handler.signal_handler = function(sig)
    if sig == 'kill' then
        --print("time: SIGKILL")
        return 0
    end
end
function main(args)
    function tail(t)
       if # t <= 1 then
          return nil
       end
       local newtable = {}
       for i, v in ipairs(t) do
          if i > 1 then
              table.insert(newtable, v)
          end
       end
       return newtable
    end
    local program = args[1]
    local arguments = tail(args)
    local starting_ticks = (os.time() * 1000 + 18000)%24000
    if program == nil and arguments == nil then
    elseif program ~= nil and arguments == nil then
        os.runfile_proc(os.cshell.resolve(program), {})
    elseif program ~= nil and arguments ~= nil then
        os.runfile_proc(os.cshell.resolve(program), arguments)
    end
    local ending_ticks = (os.time() * 1000 + 18000)%24000
    print("ticks: "..(ending_ticks-starting_ticks))
    return 0
end
main({...})
EndFile;
File;etc/bootsplash.default
text
EndFile;
File;dev/tty3
EndFile;
File;.gitignore
#temporary things that always change
/dev/hda/CFSDATA
/tmp/syslog
/proc/sttime
/proc/build_date
#uninportant things to overall download of repo
/var/yapi/cache
EndFile;
File;lib/luaX/lx.lua
--/lib/luaX/lx.lua
--luaX "hardware" access
_G['_LUAX_VERSION'] = '0.0.2'
--function: manage basic access to CC screen, basic pixels and etc.
--[[Maximum dimensions of CCscreen -> 19x51]]
local SPECIAL_CHAR = ' '
local curX = 1
local curY = 1
local startColor = colors.lightBlue
function term.set_bg_default()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
end
local _oldcursorpos = term.setCursorPos
function _setCursorPos(x,y)
    curX = x
    curY = y
    _oldcursorpos(x,y)
end
term.setCursorPos = _setCursorPos
local oldprint = print
function _print(msg)
    oldprint(msg)
    local x, y = term.getCursorPos()
    curX = x
    curY = y
end
print = _print
function blank()
    term.clear()
    term.setCursorPos(1,1)
    term.setBackgroundColor(startColor)
    for x = 1, 51 do
        for y = 1, 19 do
            term.setCursorPos(x, y)
            write(SPECIAL_CHAR)
        end
    end
    term.set_bg_default()
    os.sleep(.5)
    return true
end
function scr_clear()
    term.clear()
    term.setCursorPos(1,1)
end
function write_pixel(locX, locY, color_pix)
    term.setCursorPos(locX, locY)
    term.setBackgroundColor(color_pix)
    write(SPECIAL_CHAR)
    term.set_bg_default()
end
function write_letter(letter, locX, locY, color_b, color_letter)
    if #letter > 1 then
        return false
    end
    if color_letter == nil then
        color_letter = colors.white
    end
    term.setCursorPos(locX, locY)
    term.setBackgroundColor(color_b)
    term.setTextColor(color_letter)
    write(letter)
    term.set_bg_default()
    return true
end
function write_string(str, locx, locy, color_str, color_b)
    --print("write_string "..tostring(#str)..' '..str)
    for i=1, #str do
        local letter = string.sub(str, i, i)
        write_letter(letter,
        locx+(i-1),
        locy,
        color_b,
        color_str)
    end
end
colorcodes = {
    ["0"] = colors.black,
    ["1"] = colors.blue,
    ["2"] = colors.lime,
    ["3"] = colors.green,
    ["4"] = colors.brown,
    ["5"] = colors.magenta,
    ["6"] = colors.orange,
    ["7"] = colors.lightGray,
    ["8"] = colors.gray,
    ["9"] = colors.cyan,
    ["a"] = colors.lime,
    ["b"] = colors.lightBlue,
    ["c"] = colors.red,
    ["d"] = colors.pink,
    ["e"] = colors.yellow,
    ["f"] = colors.white,
}
colores = {colors.black, colors.blue, colors.lime, colors.green, colors.brown, colors.magenta, colors.orange, colors.lightGray, colors.gray, colors.cyan, colors.lime, colors.red, colors.pink, colors.yellow, colors.white}
function random_color()
    return colores[math.random(1, #colores)]
end
function demo()
    write_letter('l', 1, 1, colors.lightBlue, colors.blue)
    write_letter('x', 2, 1, colors.lightBlue, colors.blue)
    --x
    --x
    --x
    --x
    --xxxxx
    write_pixel(5, 4, random_color())
    write_pixel(5, 5, random_color())
    write_pixel(5, 6, random_color())
    write_pixel(5, 7, random_color())
    write_pixel(5, 8, random_color())
    write_pixel(6, 8, random_color())
    write_pixel(7, 8, random_color())
    write_pixel(8, 8, random_color())
    --y 10
    --x   x
    -- x x
    --  x
    -- x x
    --x   x
    write_pixel(10, 4, random_color())
    write_pixel(14, 4, random_color())
    write_pixel(11, 5, random_color())
    write_pixel(13, 5, random_color())
    write_pixel(12, 6, random_color())
    write_pixel(11, 7, random_color())
    write_pixel(13, 7, random_color())
    write_pixel(10, 8, random_color())
    write_pixel(14, 8, random_color())
end
function get_status()
    if _G['LX_LUA_LOADED'] then
        return 'running'
    else
        return 'not running'
    end
end
function libroutine()
    _G['LX_LUA_LOADED'] = true
end
EndFile;
File;var/yapi/db/core
base;http://lkmnds.github.io/yapi/base.yap
devscripts;http://lkmnds.github.io/yapi/devscripts.yap
sbl;http://lkmnds.github.io/yapi/sbl.yap
netutils;http://lkmnds.github.io/yapi/netutils.yap
osh;http://lkmnds.github.io/yapi/osh.yap
cshell;http://lkmnds.github.io/yapi/cshell.yap
bootsplash;http://lkmnds.github.io/yapi/bootsplash.yap
initramfs-tools;http://lkmnds.github.io/yapi/initramfs-tools.yap
EndFile;
File;dev/loop3
EndFile;
File;dev/random
EndFile;
File;dev/disk/UFSDATA
/media/hell:0:777::0
EndFile;
File;lib/devices/mouse_device.lua
#!/usr/bin/env lua
--mouse device
dev_mouse = {}
dev_mouse.name = '/dev/mouse'
dev_mouse.device = {}
dev_mouse.device.device_read = function(bytes)
    local event, button, x, y = os.pullEvent("mouse_click")
    return x..':'..y..':'..button
end
dev_mouse.device.device_write = function(s)
    ferror("devmouse: cant write to mouse device")
    os.sys_signal(os.signals.SIGILL)
    return 1
end
EndFile;
File;bin/users
#!/usr/bin/env lua
--/bin/users: says what users are logged
-- TODO: logged users list
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        --print("users: recieved SIGKILL")
        return 0
    end
end
function main(args)
    local cuser = fs.open("/tmp/current_user", 'r')
    local current_user = cuser.readAll()
    cuser.close()
    print(current_user)
end
main({...})
EndFile;
File;sbin/modprobe
#!/usr/bin/env lua
--/bin/modprobe: load/reload cubix libraries
_handler = {}
_handler.signal_handler = function(sig)
    if sig == 'kill' then
        --print("modprobe: SIGKILL")
        return 0
    end
end
function usage()
    print("use: modprobe <module name> <path to module>")
end
function main(args)
    if #args ~= 2 then
        usage()
        return 0
    end
    local alias, path = args[1], args[2]
    os.internals.loadmodule(alias, path)
end
main({...})
EndFile;
File;dev/tty1
EndFile;
File;bin/nano
#!/usr/bin/env lua
--/bin/nano: an alternative to program a good text editor.
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        os.debug.debug_write("nano: SIGKILL'd!", false)
        return 0
    end
end
function main(args)
    os.runfile_proc("/rom/programs/edit", {os.cshell.resolve(args[1])})
end
main({...})
EndFile;
File;lib/devices/err.lua
local devname = ''
local devpath = ''
local device_buffer = ''
function device_read(bytes)
    ferror("err: cannot read from err devices")
    os.sys_signal(os.signals.SIGILL)
    return 1
end
function device_write(message)
    term.set_term_color(colors.red)
    device_buffer = device_buffer .. message
    write(message)
    device_buffer = ''
    term.set_term_color(colors.white)
end
function flush_buffer()
    write(device_buffer)
    device_buffer = ''
end
function get_buffer()
    return device_buffer
end
function setup(name, path)
    devname = name
    devpath = path
    device_buffer = ''
    fs.open(path, 'w').close()
end
function libroutine()end
EndFile;
File;developer_things
To developers wanting to create their own versions of base package:
Before "makeyap":
 * reboot into cubix(or craftos)
 * Clear /tmp/syslog(this is needed to clear boot messages)
  * rm /tmp/syslog && touch /tmp/syslog
 * remove CFSDATA(because of the long list of entries in UFSDATA, you need to do this)
  * rm /dev/hda/CFSDATA
 * clear yapi cache & update database
  * sudo yapi -Syc
Running makeyap takes quite a long time getting all files in the system
and creating the yap file, it will be over 9000 lines long, so don't open it with
editors(atom uses a lot of ram when opening, gedit works ok)
After "makeyap":
 * sync the buffers(recreate UFSDATA with current configuration)
EndFile;
File;usr/manuals/fsmngr.man
On the subject of the File System Manager
Task #1:
    Manage File Systems.
EndFile;
File;usr/manuals/loginmngr.man
On the Subject of Login Manager(os.lib.login)
Task #1:
    Manage user access to things in every security aspect of cubix.
    login(user, password) is the big boss here.
    Passwords are stored in the sha256(password + salt) form ["man hashmngr"]
    The defualt home folder for users is /home/<user>
EndFile;
File;dev/dummy
EndFile;
File;proc/partitions
EndFile;
File;boot/sblcfg/cubixquiet
set root=(hdd)
load_video
insmod kernel
kernel /boot/cubix quiet nodebug
boot
EndFile;
File;boot/sblcfg/cubixboot
set root=(hdd)
load_video
insmod kernel
kernel /boot/cubix acpi splash
boot
EndFile;
File;usr/manuals/cshell.man
On the subject of the Cubix Shell(cshell)
The Cubix Shell is located at /bin/cshell and referenced by /bin/sh.
By default the root user can run programs at /sbin and for a normal user to run it, it has to use "sudo" to do that
EndFile;
File;tmp/syslog
[120][proc_manager] SIGKILL -> bin/rm
[121][proc] new: bin/touch
[122][process]  bin/touch pid=9
[123][proc_manager] SIGKILL -> bin/touch
[124][proc] new: bin/rm
[125][process]  bin/rm pid=10
[126][proc_manager] SIGKILL -> bin/rm
[127][proc] new: bin/sudo
[128][process]  bin/sudo pid=11
[129][proc] new: bin/yapi
[130][process]  bin/yapi pid=12
[131][proc_manager] SIGKILL -> bin/yapi
[132][proc_manager] SIGKILL -> bin/sudo
[133][proc] new: makeyap
[134][process]  makeyap pid=13
[135][proc_manager] SIGKILL -> makeyap
[136][proc] new: makeyap
[137][process]  makeyap pid=14
EndFile;
File;var/pcid
cubix
EndFile;
File;lib/devices/full_device.lua
#!/usr/bin/env lua
--full_device.lua
dev_full = {}
dev_full.name = '/dev/full'
dev_full.device = {}
dev_full.device.device_read = function (bytes)
    if bytes == nil then
        return 0
    else
        result = ''
        for i = 0, bytes do
            result = result .. safestr(0)
        end
        return result
    end
    return 0
end
dev_full.device.device_write = function(s)
    ferror("devwrite: disk full")
    os.sys_signal(os.signals.SIGILL)
    return 1
end
EndFile;
File;lib/fs/tmpfs.lua
--Temporary File System
paths = {}
--[[
files(table of tables):
each table:
    KEY = filename - filename
    type - ("dir", "file")
    perm - permission (string)
    file - actual file (string)
]]
--using tmpfs(making a device first):
--mount /dev/loop2 /mnt/tmpfs tmpfs
function list_files(mountpath)
    --show one level of things
    local result = {}
    for k,v in pairs(paths[mountpath]) do
        if k:find("/") then
            if string.sub(k,1,1) == '/' and strcount(k, '/') == 1 then
                table.insert(result, string.sub(k, 1))
            end
        else
            table.insert(result, k)
        end
    end
    return result
end
function really_list_files(mountpath)
    local result = {}
    for k,v in pairs(paths[mountpath]) do
        table.insert(result, k)
    end
    return result
end
function canMount(uid)
    return true
end
function getSize(mountpath, path) return 0 end
function loadFS(mountpath)
    os.debug.debug_write("tmpfs: loading at "..mountpath)
    if not paths[mountpath] then
        paths[mountpath] = {}
    end
    return {}, true
end
function list(mountpath, path)
    if path == '/' or path == '' or path == nil then
        --all files in mountpath
        return list_files(mountpath)
    else
        --get relevant ones
        local all = really_list_files(mountpath)
        local res = {}
        for k,v in ipairs(all) do
            local cache = string.sub(v, 1, #path)
            if string.sub(v, 1, #path) == string.sub(path, 2)..'/' and cache ~= '' then
                table.insert(res, string.sub(v, #path + 1))
            end
        end
        return res
    end
end
function test()
    local k = fs.open("/root/mytmp/helpme", 'w')
    k.writeLine("help me i think i am lost")
    k.close()
    os.viewTable(fs.list("/root/mytmp"))
end
function exists(mountpath, path)
    --print("exists: "..path)
    if path == nil or path == '' then
        if paths[mountpath] then
            return true
        else
            return false
        end
    end
    --os.viewTable(paths[mountpath][path])
    return paths[mountpath][path] ~= nil
end
function isDir(mountpath, path)
    --os.viewTable(paths[mountpath][path])
    if path == nil or path == '' then
        if paths[mountpath] then
            return true
        else
            return false
        end
    end
    if paths[mountpath][path] == nil then
        ferror("tmpfs: path does not exist")
        return false
    end
    return paths[mountpath][path].type == 'dir'
end
function makeDir(mountpath, path)
    if not paths[mountpath][path] then
        paths[mountpath][path] = {
            type='dir',
            perm=permission.fileCurPerm(),
            owner=os.currentUID(),
        }
    end
end
function getInfo(mountpath, path)
    local data = paths[mountpath][path]
    return {
        owner = data.owner,
        perms = data.perm
    }
end
function vPerm(mountpath, path, mode)
    local info = getInfo(mountpath, path)
    local norm = fsmanager.normalizePerm(info.perms)
    if user == info.owner then
        if mode == "r" then return string.sub(norm[1], 1, 1) == "r" end
        if mode == "w" then return string.sub(norm[1], 2, 2) == "w" end
        if mode == "x" then return string.sub(norm[1], 3, 3) == "x" end
    elseif os.lib.login.isInGroup(user, info.gid) then
        if mode == "r" then return string.sub(norm[2], 1, 1) == "r" end
        if mode == "w" then return string.sub(norm[2], 2, 2) == "w" end
        if mode == "x" then return string.sub(norm[2], 3, 3) == "x" end
    else
        if mode == "r" then return string.sub(norm[3], 1, 1) == "r" end
        if mode == "w" then return string.sub(norm[3], 2, 2) == "w" end
        if mode == "x" then return string.sub(norm[3], 3, 3) == "x" end
    end
end
function general_file(mountpath, path, mode)
    local new_perm = 0
    if not paths[mountpath][path] then
        new_perm = fsmanager.fileCurPerm()
    else
        new_perm = paths[mountpath][path].perm
    end
    return {
        _perm = new_perm,
        --_mode = mode,
        _cursor = 1,
        _closed = false,
        write = function(data)
            if vPerm(mountpath, path, 'w') and mode == 'a' then --append
                paths[mountpath][path].file = paths[mountpath][path].file .. data
                return data
            elseif vPerm(mountpath, path, 'w') and mode == 'w' then --write from start
                paths[mountpath][path].file = paths[mountpath][path].file .. data
                return data
            else
                ferror("tmpfs: cant write to file")
            end
        end,
        writeLine = function(data)
            if vPerm(mountpath, path, 'w') and mode == 'a' then --append
                paths[mountpath][path].file = paths[mountpath][path].file .. data .. '\n'
                return data
            elseif vPerm(mountpath, path, 'w') and mode == 'w' then --write from start
                paths[mountpath][path].file = paths[mountpath][path].file .. data .. '\n'
                return data
            else
                ferror("tmpfs: cant writeLine to file")
            end
        end,
        read = function(bytes)
            if vPerm(mountpath, path, 'r') and mode == 'r' then
                local res = string.sub(paths[mountpath][path].file, _cursor, _cursor + bytes)
                _cursor = _cursor + bytes
                return res
            else
                ferror("tmpfs: cant read file")
            end
        end,
        readAll = function()
            if vPerm(mountpath, path, 'r') then
                local bytes = #paths[mountpath][path].file
                local res = string.sub(paths[mountpath][path].file, 1, bytes)
                return res
            else
                ferror('tmpfs: cant read file')
            end
        end,
        close = function()
            _perm = 0
            _cursor = 0
            _closed = true
            write = nil
            read = nil
            writeLine = nil
            readAll = nil
            return true
        end,
    }
end
function makeObject(mountpath, path, mode)
    if paths[mountpath][path] ~= nil then --file already exists
        if mode == 'w' then paths[mountpath][path].file = '' end
        return general_file(mountpath, path, mode)
    else
        --create file
        paths[mountpath][path] = {
            type='file',
            file='',
            perm=permission.fileCurPerm(),
            owner=os.currentUID()
        }
        if mode == 'r' then
            ferror("tmpfs: file does not exist")
            return nil
        elseif mode == 'w' then
            --create a file
            return general_file(mountpath, path, mode)
        elseif mode == 'a' then
            return general_file(mountpath, path, mode)
        end
    end
end
function open(mountpath, path, mode)
    return makeObject(mountpath, path, mode)
end
function delete(mountpoint, path)
    if vPerm(mountpath, path, 'w') then
        --remove file from paths
        paths[mountpath][path] = nil
        return true
    else
        ferror("tmpfs: not enough permission.")
        return false
    end
end
EndFile;
File;usr/manuals/devicemngr.man
On the subject of the Device Manager
Task #1:
    Manage /dev
    Devices available:
        /dev/null
            everything write() to it is ignored
        /dev/zero
            only gives zeros when read()
        /dev/random
            gives random characters when read()
        /dev/full
            sends a SIGILL(Illegal Instruction) when something is write() to it
EndFile;
File;dev/loop0
EndFile;
File;lib/hash/sha256.lua
--
--  Adaptation of the Secure Hashing Algorithm (SHA-244/256)
--  Found Here: http://lua-users.org/wiki/SecureHashAlgorithm
--
--  Using an adapted version of the bit library
--  Found Here: https://bitbucket.org/Boolsheet/bslf/src/1ee664885805/bit.lua
--
local MOD = 2^32
local MODM = MOD-1
local function memoize(f)
	local mt = {}
	local t = setmetatable({}, mt)
	function mt:__index(k)
		local v = f(k)
		t[k] = v
		return v
	end
	return t
end
local function make_bitop_uncached(t, m)
	local function bitop(a, b)
		local res,p = 0,1
		while a ~= 0 and b ~= 0 do
			local am, bm = a % m, b % m
			res = res + t[am][bm] * p
			a = (a - am) / m
			b = (b - bm) / m
			p = p*m
		end
		res = res + (a + b) * p
		return res
	end
	return bitop
end
local function make_bitop(t)
	local op1 = make_bitop_uncached(t,2^1)
	local op2 = memoize(function(a) return memoize(function(b) return op1(a, b) end) end)
	return make_bitop_uncached(op2, 2 ^ (t.n or 1))
end
local bxor1 = make_bitop({[0] = {[0] = 0,[1] = 1}, [1] = {[0] = 1, [1] = 0}, n = 4})
local function bxor(a, b, c, ...)
	local z = nil
	if b then
		a = a % MOD
		b = b % MOD
		z = bxor1(a, b)
		if c then z = bxor(z, c, ...) end
		return z
	elseif a then return a % MOD
	else return 0 end
end
local function band(a, b, c, ...)
	local z
	if b then
		a = a % MOD
		b = b % MOD
		z = ((a + b) - bxor1(a,b)) / 2
		if c then z = bit32_band(z, c, ...) end
		return z
	elseif a then return a % MOD
	else return MODM end
end
local function bnot(x) return (-1 - x) % MOD end
local function rshift1(a, disp)
	if disp < 0 then return lshift(a,-disp) end
	return math.floor(a % 2 ^ 32 / 2 ^ disp)
end
local function rshift(x, disp)
	if disp > 31 or disp < -31 then return 0 end
	return rshift1(x % MOD, disp)
end
local function lshift(a, disp)
	if disp < 0 then return rshift(a,-disp) end
	return (a * 2 ^ disp) % 2 ^ 32
end
local function rrotate(x, disp)
    x = x % MOD
    disp = disp % 32
    local low = band(x, 2 ^ disp - 1)
    return rshift(x, disp) + lshift(low, 32 - disp)
end
local k = {
	0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
	0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
	0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
	0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
	0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
	0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
	0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
	0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
	0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
	0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
	0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
	0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
	0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
	0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
	0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
	0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
}
local function str2hexa(s)
	return (string.gsub(s, ".", function(c) return string.format("%02x", string.byte(c)) end))
end
local function num2s(l, n)
	local s = ""
	for i = 1, n do
		local rem = l % 256
		s = string.char(rem) .. s
		l = (l - rem) / 256
	end
	return s
end
local function s232num(s, i)
	local n = 0
	for i = i, i + 3 do n = n*256 + string.byte(s, i) end
	return n
end
local function preproc(msg, len)
	local extra = 64 - ((len + 9) % 64)
	len = num2s(8 * len, 8)
	msg = msg .. "\128" .. string.rep("\0", extra) .. len
	assert(#msg % 64 == 0)
	return msg
end
local function initH256(H)
	H[1] = 0x6a09e667
	H[2] = 0xbb67ae85
	H[3] = 0x3c6ef372
	H[4] = 0xa54ff53a
	H[5] = 0x510e527f
	H[6] = 0x9b05688c
	H[7] = 0x1f83d9ab
	H[8] = 0x5be0cd19
	return H
end
local function digestblock(msg, i, H)
	local w = {}
	for j = 1, 16 do w[j] = s232num(msg, i + (j - 1)*4) end
	for j = 17, 64 do
		local v = w[j - 15]
		local s0 = bxor(rrotate(v, 7), rrotate(v, 18), rshift(v, 3))
		v = w[j - 2]
		w[j] = w[j - 16] + s0 + w[j - 7] + bxor(rrotate(v, 17), rrotate(v, 19), rshift(v, 10))
	end
	local a, b, c, d, e, f, g, h = H[1], H[2], H[3], H[4], H[5], H[6], H[7], H[8]
	for i = 1, 64 do
		local s0 = bxor(rrotate(a, 2), rrotate(a, 13), rrotate(a, 22))
		local maj = bxor(band(a, b), band(a, c), band(b, c))
		local t2 = s0 + maj
		local s1 = bxor(rrotate(e, 6), rrotate(e, 11), rrotate(e, 25))
		local ch = bxor (band(e, f), band(bnot(e), g))
		local t1 = h + s1 + ch + k[i] + w[i]
		h, g, f, e, d, c, b, a = g, f, e, d + t1, c, b, a, t1 + t2
	end
	H[1] = band(H[1] + a)
	H[2] = band(H[2] + b)
	H[3] = band(H[3] + c)
	H[4] = band(H[4] + d)
	H[5] = band(H[5] + e)
	H[6] = band(H[6] + f)
	H[7] = band(H[7] + g)
	H[8] = band(H[8] + h)
end
function _sha256(msg) --returns string
	msg = preproc(msg, #msg)
	local H = initH256({})
	for i = 1, #msg, 64 do digestblock(msg, i, H) end
	return str2hexa(num2s(H[1], 4) .. num2s(H[2], 4) .. num2s(H[3], 4) .. num2s(H[4], 4) ..
		num2s(H[5], 4) .. num2s(H[6], 4) .. num2s(H[7], 4) .. num2s(H[8], 4))
end
hash_sha256 = _sha256
EndFile;
File;lib/login_manager
#!/usr/bin/env lua
--rewrite of login manager from scratch
--things to do:
--  Tokens
--  Login thingy
--  Utils to /etc/ß?æðøw
--[[
Generating tokens:
15rounds_sha256(salt .. sessions .. user)
Verifying tokens:
check if the hash included in the token matches up
with the calculation up there
Example use:
if verify_token(myToken) then
    myToken:use()
else
    ferror("sorry mate")
end
]]
-- the major differences between old and new login modules is:
--  1 - the token logic is simplified, allowing me to fix it better
--  2 - the code is not spaghetti
--  3 - most of the functions that need to iterate with programs use deepcopy
--      to get local variables of the module
--  4 - user groups
--  5 - sudoers file
--reloading login module could be a major security flaw in cubix.
RELOADABLE = false
--current token in cubix
local current_token = {
    salt = '',
    sessions = -1,
    user = '',
    hash = ''
}
--current user
local current_user = {
    username = '',
    group = '',
    gid = -1,
    uid = -1
}
--group data
local groups = {}
--proof that a computer has worked to hash something(15 rounds of sha256)
function proof_work(data)
    local cache = data
    for i=0, 14 do --15 times
        cache = os.lib.hash.hash.sha256(cache)
    end
    return cache
end
--Token class
Token = {}
Token.__index = Token
function Token.new(user, sessions)
    inst = {}
    setmetatable(inst, Token)
    inst.salt = os.generateSalt(100)
    inst.sessions = sessions
    inst.user = user
    inst.hash = proof_work(inst.salt .. tostring(inst.sessions) .. inst.user)
    return inst
end
--using a token
function Token:use()
    --make sessions = sessions - 1
    self.sessions = self.sessions - 1
    --generate new salt and hash
    self.salt = os.generateSalt(100)
    self.hash = proof_work(self.salt .. tostring(self.sessions) .. self.user)
end
--check if a token is valid
function verify_token(token, user)
    if token == {} then
        return false
    end
    if token.sessions < 0 then
        return false
    end
    if token.hash == proof_work(token.salt .. tostring(token.sessions) .. token.user) and user == token.user then
        return true
    end
    return false
end
--because you can't access the current token, this is the
--general function to check the current token against a user
function general_verify(user)
    return verify_token(current_token, user)
end
--using current token
function use_ctok()
    current_token:use()
end
--getting current user by deepcopy
function currentUser()
    return os.deepcopy(current_user).username
end
--getting current group by deepcopy
function currentGroup()
    return os.deepcopy(current_user).group
end
--getting current uid by deepcopy
function userUID()
    return os.deepcopy(current_user).uid
end
--actual login function.
function login(usr, pwd)
    --if actual token is usable and is related to actual user, return true
    if verify_token(current_token, usr) then
        current_token:use()
        return true
    end
    --else, just do the normal login operation
    local handler = fs.open('/etc/shadow', 'r')
    local lines = os.strsplit(handler.readAll(), '\n')
    handler.close()
    for k,v in ipairs(lines) do
        local udata = os.strsplit(v, '^')
        local hashed = proof_work(pwd .. udata[3])
        --checking user and password with given password
        if udata[1] == usr and udata[2] == hashed then
            --ok, you won the password, generate a new token with 5 sessions in it
            local new_token = Token.new(usr, 4) -- 5 times(4, 3, 2, 1, 0)
            current_token = new_token
            current_user.username = usr
            current_user.group = udata[4]
            current_user.gid = get_group_gid(udata[4])
            if usr == 'root' then
                current_user.uid = 0
            else
                current_user.uid = 1
            end
            return true
        end
    end
    return false
end
--function to compare if user has typed correctly(don't use this as actual login operation)
function compare(usr, pwd)
    --this just has the login function without the Token partes btw
    local handler = fs.open('/etc/shadow', 'r')
    local lines = os.strsplit(handler.readAll(), '\n')
    handler.close()
    for k,v in ipairs(lines) do
        local udata = os.strsplit(v, '^')
        local hashed = proof_work(pwd .. udata[3])
        if udata[1] == usr and udata[2] == hashed then
            return true
        end
    end
    return false
end
--seriously, you shouldn't set this to true.
local _special_sudo = false
--alert the login module that sudo is running
function alert_sudo()
    local runningproc = os.lib.proc.get_processes()[os.getrunning()]
    if runningproc.file == '/bin/sudo' or runningproc.file == 'bin/sudo' then
        _special_sudo = true
    else
        ferror("alert_sudo: I know what you're doing")
    end
end
--alert login module sudo is closed
function close_sudo()
    _special_sudo = false
end
--check if sudo is running
function isSudo()
    return _special_sudo
end
--current sudoers file
local current_sudoers = {
    user = {},
    group = {}
}
--read and parse /etc/groups
local function read_groups()
    os.debug.debug_write("[login] reading groups")
    local h = fs.open("/etc/groups", 'r')
    if not h then
        os.debug.kpanic("error opening /etc/groups")
    end
    local d = h.readAll()
    h.close()
    local lines = os.strsplit(d, '\n')
    for _,line in ipairs(lines) do
        if string.sub(line, 1, 1) ~= '#' then
            local data = os.strsplit(line, ':')
            local gname = data[1]
            local gid = data[2]
            local _gmembers = data[3]
            local gmembers = {}
            if _gmembers == {} then
                gmembers = os.strsplit(_gmembers, ',')
            else
                gmembers = {}
            end
            groups[gid] = {
                members = gmembers,
                name = gname
            }
        end
    end
end
--get all groups(by deepcopy)
function getGroups()
    return os.deepcopy(groups)
end
local function read_sudoers()
    os.debug.debug_write("[login] reading sudoers")
    local h = fs.open("/etc/sudoers", 'r')
    if not h then
        os.debug.kpanic("error opening /etc/sudoers")
    end
    local d = h.readAll()
    h.close()
    local lines = os.strsplit(d, '\n')
    for _,line in ipairs(lines) do
        if string.sub(line, 1, 1) ~= '#' then
            if string.sub(line, 1, 1) == 'u' then
                local spl = os.strsplit(line, ' ')
                local user = spl[2]
                local _users = spl[3]
                if _users == '*' then
                    if current_sudoers.user[user] == nil then
                        current_sudoers.user[user] = {}
                    end
                    current_sudoers.user[user].users = '*'
                else
                    local users = os.strsplit(_users, ';')
                    for _,v in ipairs(users) do
                        table.insert(current_sudoers.user[user].users, v)
                    end
                end
            elseif string.sub(line, 1, 1) == 'g' then
                local spl = os.strsplit(line, ' ')
                local user = spl[2]
                local _groups = spl[3]
                if _groups == '*' then
                    if current_sudoers.user[user] == nil then
                        current_sudoers.user[user] = {}
                    end
                    current_sudoers.user[user].groups = '*'
                else
                    local groups = os.strsplit(_users, ';')
                    for _,v in ipairs(groups) do
                        table.insert(current_sudoers.user[user].groups, v)
                    end
                end
            elseif string.sub(line, 1, 1) == 'h' then
                local spl = os.strsplit(line, ' ')
                local group = spl[2]
                local _users = spl[3]
                if _users == '*' then
                    if current_sudoers.group[group] == nil then
                        current_sudoers.group[group] = {}
                    end
                    current_sudoers.group[group].users = '*'
                else
                    local users = os.strsplit(_users, ';')
                    for _,v in ipairs(users) do
                        table.insert(current_sudoers.group[group].users, v)
                    end
                end
            elseif string.sub(line, 1, 1) == 'q' then --TODO: this
                local spl = os.strsplit(line, ' ')
                local group = spl[2]
                local _groups = spl[3]
                if _groups == '*' then
                    if current_sudoers.group[group] == nil then
                        current_sudoers.group[group] = {}
                    end
                    current_sudoers.group[group].groups = '*'
                else
                    local groups = os.strsplit(_groups, ';')
                    for _,v in ipairs(groups) do
                        table.insert(current_sudoers.group[group].groups, v)
                    end
                end
            end
        end
    end
end
--getting sudoers by deepcopy
function sudoers()
    return os.deepcopy(current_sudoers)
end
--verify if a user can impersonate another user
function sudoers_verify_user(usr, other_usr)
    local user = current_sudoers.user[usr]
    if user == nil then
        return false
    end
    if user.users == '*' then
        return true
    end
    for k,v in pairs(user.users) do
        if v == other_usr then
            return true
        end
    end
    return false
end
function sudoers_verify_group(usr, group)
    local user = current_sudoers.user[usr]
    if user == nil then
        return false
    end
    if user.groups == '*' then
        return true
    end
    for k,v in pairs(user.groups) do
        if v == group then
            return true
        end
    end
    return false
end
--verify if a user from "grp" group can impersonate another user
function sudoers_gverify_user(grp, usr)
    local group = current_sudoers.group[grp]
    if group == nil then
        return false
    end
    if group.users == '*' then
        return true
    end
    for k,v in pairs(group.users) do
        if v == usr then
            return true
        end
    end
    return false
end
function sudoers_gverify_group(group, other_group)
    local grp = current_sudoers.group[group]
    if grp == nil then
        return false
    end
    if grp.groups == '*' then
        return true
    end
    for k,v in pairs(grp.groups) do
        if v == other_group then
            return true
        end
    end
    return false
end
--get gid of groups
function get_group_gid(group_name)
    for k,v in pairs(groups) do
        if v.name == group_name then
            return k
        end
    end
    return -1
end
--check if user is in group
function isInGroup(uid, gid)
    if groups[gid] then
        local g = groups[gid]
        for k,v in ipairs(g.members) do --iterating by all members
            if v == uid then
                return true
            end
        end
        return false
    else
        return false
    end
end
--you should use this function to login a user in your program
function front_login(program, user)
    local current_user = currentUser()
    if user == nil then user = current_user.username end
    write("["..program.."] password for "..user..": ")
    local try_pwd = read('')
    if login(current_user, try_pwd) then
        return true
    else
        os.ferror("front_login: Login incorrect")
        return false
    end
end
--check if a user exists
local function user_exists(u)
    local h = fs.open("/etc/shadow", 'r')
    if h == nil then
        os.debug.kpanic("error opening /etc/shadow")
    end
    local l = h.readAll()
    h.close()
    local lines = os.strsplit(l, '\n')
    for _,line in ipairs(lines) do --iterating through /etc/shadow
        local data = os.strsplit(line, '^')
        if data[1] == u then
            return true
        end
    end
    return false
end
function add_new_user(u, p)
    --adding new users to /etc/shadow
    if u == 'root' then
        return false
    end
    if user_exists(u) then
        return false
    end
    if permission.grantAccess(fs.perms.SYS) then --if permission is alright
        local _salt = os.generateSalt(15)
        local hp = proof_work(p .. _salt)
        local user_string = '\n' .. u .. '^' .. hp .. '^' .. _salt ..  '\n'
        local h = fs.open("/etc/shadow", 'a')
        h.write(user_string)
        h.close()
        fs.makeDir("/home/"..u)
        return true
    else
        ferror("add_new_user: error getting SYSTEM permission")
        return false
    end
end
--change password from a user(needs actual and new password, in plain text)
function changepwd(user, p, np)
    if login(user, p) then
        --change pwd
        local h = fs.open("/etc/shadow", 'r')
        if h == nil or h == {} then
            os.debug.kpanic("error opening /etc/shadow")
        end
        local fLines = os.strsplit(h.readAll(), '\n')
        h.close()
        for k,v in pairs(fLines) do
            local pair = os.strsplit(v, '^')
            if pair[1] == user then --if /etc/shadow has entry for that user, generate a new entry
                local _salt = os.generateSalt(15)
                pair[2] = proof_work(np .. _salt)
                fLines[k] = pair[1] .. '^' .. pair[2] .. '^' .. _salt .. '\n'
            else
                fLines[k] = fLines[k] .. '\n'
            end
        end
        local h2 = fs.open("/etc/shadow", 'w')
        for k,v in pairs(fLines) do
            h2.write(v)
        end
        h2.close()
        return true
    else
        return false
    end
end
function libroutine()
    os.login = {}
    os.login.login = login
    os.login.adduser = add_new_user
    os.login.changepwd = changepwd
    read_groups()
    read_sudoers()
end
EndFile;
File;bin/passwd
#!/usr/bin/env lua
--/bin/passwd: change user password
_handler = {}
_handler.signal_handler = function(sig)
    if sig == 'kill' then
        --print("passwd: SIGKILL")
        return 0
    end
end
function main(args)
    local u = args[1]
    local cu = os.lib.login.currentUser()
    if u == nil then
        u = cu
    end
    if cu ~= 'root' and u == 'root' then
        os.ferror("passwd: you're not allowed to change root password, unless you get root access!")
        return 0
    end
    print("changing password from "..u)
    write(u.." password(actual): ")
    local apwd = read('')
    if os.lib.login.compare(u, apwd) and os.lib.login.login(u, apwd) then
        write("new "..u.." password: ")
        local npwd = read('')
        write('\n')
        if os.lib.login.changepwd(u, apwd, npwd) then
            print("changed password of "..u)
            return 0
        else
            os.ferror("passwd: error ocourred when calling changepwd()")
            return 1
        end
    else
        os.ferror("passwd: Authentication Error")
        os.ferror("passwd: password unaltered")
    end
    return 0
end
main({...})
EndFile;
File;sbin/kill
#!/usr/bin/env lua
--/bin/kill: kills processes
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        os.debug.debug_write("kill: recieved SIGKILL", false)
        return 0
    end
end
function main(args)
    if #args == 1 then
        local pid = args[1]
        local p = os.lib.proc.get_by_pid(tonumber(pid))
        os.send_signal(p, os.signals.SIGKILL)
    elseif #args > 1 then
        for k,v in pairs(args) do
            local proc = os.lib.proc.get_by_pid(v)
            os.send_signal(proc, os.signals.SIGKILL)
        end
    else
        print("usage: kill <pid1> <pid2> <pid3> ...")
    end
end
main({...})
EndFile;
File;bin/mount
#!/usr/bin/env lua
--/bin/mount: mount devices
_handler = {}
_handler.signal_handler = function(sig)
    if sig == 'kill' then
        --print("mount: SIGKILL")
        return 0
    end
end
function main(args)
    if permission.grantAccess(fs.perms.SYS) then
        --running as fucking root
        if #args == 3 then
            local device = os.cshell.resolve(args[1])
            local path = os.cshell.resolve(args[2])
            local fs = args[3]
            if fsmanager.mount(device, fs, path) then
                print("mount: mounted "..device)
            else
                os.ferror("mount: error")
            end
        elseif #args == 0 then
            local _mounts = fsmanager.getMounts()
            for k,v in pairs(_mounts) do
                print((v.dev).." on "..(k).." fs "..(v.fs))
            end
        end
    else
        if #args == 0 then
            local _mounts = fsmanager.getMounts()
            for k,v in pairs(_mounts) do
                print((v.dev).." on "..(k).." type "..(v.fs))
            end
        elseif #args == 3 then
            --view if user can mount
            local device = os.cshell.resolve(args[1])
            local path = os.cshell.resolve(args[2])
            local fs = args[3]
            if fsmanager.canMount(fs) then
                if fsmanager.mount(device, fs, path) then
                    print("mount: mounted "..device..' : '..fs)
                else
                    os.ferror("mount: error")
                end
            else
                os.ferror("mount: sorry, you cannot mount this filesystem.")
            end
        end
    end
end
main({...})
EndFile;
File;usr/manuals/sbl.man
Simple Boot Loader
SBL was made to be a GRUB-like bootloader
BootScript commands:
  set <key>=<value>
      the set command sets a key to a value, in the SBL context, we have only one special key, "root", this key sets where SBL will load the file, the 2 values "root" can have is "(hdd)" and "(disk)"
  insmod <module>
      loads a module, the general purpose module for all OSes is the "kernel" module
  kernel <args>
      it will set the SBL to load that kernel in args, example: "kernel /boot/cubix acpi" will load "/boot/cubix acpi"
  boot
      boot the selected system
  chainloader +1
      this command makes SBL load the "sstartup" file in the "root" value
EndFile;
File;bin/lx
#!/usr/bin/env lua
--/bin/lx: manages luaX in user(spaaaaaaaaace)
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        os.debug.debug_write("lx frontend: ded", false)
        return 0
    end
end
function lx_start_default()
    --this is the default routine to start luaX with lxterm
    os.debug.debug_write("[lx] starting")
    os.internals.loadmodule("lx", "/lib/luaX/lx.lua")
    os.internals.loadmodule("lxServer", "/lib/luaX/lxServer.lua")
    os.internals.loadmodule("lxClient", "/lib/luaX/lxClient.lua")
    os.internals.loadmodule("lxWindow", "/lib/luaX/lxWindow.lua")
    os.internals.loadmodule("lxMouse", "/lib/luaX/lxMouse.lua")
    local lxterm = os.lib.lxWindow.Window.new("/g/lxterm/lxterm.lxw")
    os.lib.lx.blank()
    os.lib.lxClient.loadWindow(lxterm)
    sleep(2)
end
function lx_stop_default()
    os.internals.unloadmod("lx")
    os.internals.unloadmod("lxServer")
    os.internals.unloadmod("lxClient")
    os.lib.lxWindow.unload_all()
    os.internals.unloadmod("lxWindow")
    os.internals.unloadmod("lxMouse")
    return 0
end
function usage()
    print("lx <argument> <...>")
    print("argument: load start status stop mods demo")
end
function main(args)
    if os.lib.lx then
        print("lx ".._LUAX_VERSION)
    else
        print("lx frontend (backend not loaded)")
    end
    if args[1] == 'daemon' then
        print("lx: starting as daemon")
        os.viewLoadedMods()
    elseif args[1] == 'help' then
        usage()
    elseif args[1] == 'load' then
        --load windows here
        if os.lib.lxServer and os.lib.lxClient and os.lib.lxWindow then
            local lwindow = os.lib.lxWindow.Window.new(os.cshell.resolve(args[2]))
            os.lib.lxClient.loadWindow(lwindow)
        else
            os.ferror("lx: cannot load windows without lxServer, lxClient and lxWindow loaded")
            return 1
        end
    elseif args[1] == 'start' then
        if os.lib.login.currentUser().uid == 0 then
            os.ferror("lx: cannot start luaX while root")
            return 1
        end
        if os.lib.lx then
            if prompt("luaX backend already started, want to restart?\n", 'Y', 'n') then
                os.debug.debug_write("[lx] restarting")
                lx_stop_default()
                lx_start_default()
            end
        else
            lx_start_default()
        end
    elseif args[1] == 'mods' then
        if os.lib.lx then
            print("luaX loaded modules:")
            term.set_term_color(colors.green)
            for k,v in pairs(os.lib) do
                if string.sub(k, 1, 2) == 'lx' then
                    write(k..' ')
                end
            end
            write('\n')
            term.set_term_color(colors.white)
        else
            ferror("lx: luaX not loaded")
        end
    elseif args[1] == 'status' or args[1] == nil then
        if os.lib.lx then
            write("lx status: "..(os.lib.lx.get_status())..'\n')
        else
            write("lx backend not running\n")
        end
    elseif args[1] == 'demo' then
        if os.lib.lx then
            os.lib.lx.blank()
            os.lib.lx.demo()
            os.lib.lxServer.sv_demo()
            os.lib.lx.blank()
            local lxterm = os.lib.lxWindow.Window.new("/g/lxterm/lxterm.lxw")
            os.lib.lxClient.loadWindow(lxterm)
        else
            ferror("lx: lx backend not running\n")
        end
    elseif args[1] == 'stop' then
        os.debug.debug_write("[lx] stopping")
        lx_stop_default()
    end
end
main({...})
EndFile;
File;lib/acpi.lua
#!/usr/bin/env lua
--ACPI module
--Advanced Configuration and Power Interface
RELOADABLE = false
local _shutdown = os.shutdown
local _reboot = os.reboot
local __clear_temp = function()
    os.debug.debug_write("[acpi] cleaning temporary")
    fs.delete("/tmp")
    for _,v in ipairs(fs.list("/proc")) do
        local k = os.strsplit(v, '/')
        --os.debug.debug_write(k[#k]..";"..tostring(fs.isDir("/proc/"..v)), false)
        if tonumber(k[#k]) ~= nil and fs.isDir("/proc/"..v) then
            fs.delete("/proc/"..v)
        end
    end
    fs.makeDir("/tmp")
end
local function acpi_shutdown()
    os.debug.debug_write("[acpi_shutdown]")
    if permission.grantAccess(fs.perms.SYS) or _G['CANT_HANDLE_THE_FORCE'] then
        os.debug.debug_write("[shutdown] shutting down for system halt")
        _G['CUBIX_TURNINGOFF'] = true
        os.debug.debug_write("[shutdown] sending SIGKILL to all processes")
        if not os.__boot_flag then --still without proper userspace
            os.lib.proc.__killallproc()
            os.lib.fs_mngr.shutdown_procedure()
        end
        os.sleep(1)
        __clear_temp()
        os.debug.debug_write("[shutdown] sending HALT.")
        os.sleep(.5)
        _shutdown()
    else
        os.ferror("acpi_shutdown: cannot shutdown without SYSTEM permission")
    end
    permission.default()
end
local function acpi_reboot()
    os.debug.debug_write("[acpi_reboot]")
    if permission.grantAccess(fs.perms.SYS) then
        os.debug.debug_write("[reboot] shutting down for system reboot")
        _G['CUBIX_REBOOTING'] = true
        os.debug.debug_write("[reboot] sending SIGKILL to all processes")
        if not os.__boot_flag then --still without proper userspace
            os.lib.proc.__killallproc()
            os.debug.debug_write("[reboot] unmounting drives")
            os.lib.fs_mngr.shutdown_procedure()
        end
        os.sleep(1)
        __clear_temp()
        os.debug.debug_write("[reboot] sending RBT.")
        os.sleep(.5)
        _reboot()
    else
        os.ferror("acpi_reboot: cannot reboot without SYSTEM permission")
    end
    permission.default()
end
local function acpi_suspend()
    os.debug.debug_write('[suspend] starting', true)
    while true do
        term.clear()
        term.setCursorPos(1,1)
        local event, key = os.pullEvent('key')
        if key ~= nil then
            break
        end
    end
    os.debug.debug_write('[suspend] ending', true)
end
local function acpi_hibernate()
    --[[
        So, to hibernate we need to write the RAM into a file, and then
        in boot, read that file... WTF?
    ]]
    --after that, black magic happens (again)
    --[[
        Dear future Self,
        I don't know how to do this,
        Please, finish.
    ]]
    os.debug.debug_write("[acpi_hibernate] starting hibernation")
    local ramimg = fs.open("/dev/ram", 'w')
    ramimg.close()
    os.debug.debug_write("[acpi_hibernate] complete, shutting down.")
    acpi_shutdown()
end
function acpi_hwake()
    os.debug.debug_write("[acpi_hibernate] waking")
    fs.delete("/dev/ram")
    --local ramimg = fs.open("/dev/ram", 'r')
    --ramimg.close()
    acpi_reboot()
end
function libroutine()
    os.shutdown = acpi_shutdown
    os.reboot = acpi_reboot
    os.suspend = acpi_suspend
    os.hibernate = acpi_hibernate
end
EndFile;
File;etc/sudoers
#sudoers file
u root *
g root *
#user cubix can be anyone
u cubix *
#user cubix can be any group
g cubix *
#group sudo can be anyone
h sudo *
#group sudo can be any group
q sudo *
EndFile;
File;home/cubix/.cshrc
# ~/.cshrc: executed by cshell
#if [ $(exists /home/$USER/.csh_aliases) ] then
#    $(/home/$USER/.csh_aliases)
#fi
#setting aliases
alias yapisy='sudo yapi -Sy'
alias god='su'
EndFile;
File;lib/pipe_manager
#!/usr/bin/env lua
--pipe manager
--task: support piping, like bash
os.__pipes = {}
Pipe = {}
Pipe.__index = Pipe
function Pipe.new(ptype)
    local inst = {}
    setmetatable(inst, Pipe)
    inst.ptype = ptype
    inst.pipe_buffer = ''
    inst.point = 1
    return inst
end
function Pipe.copyPipe(npipe)
    local inst = {}
    setmetatable(inst, Pipe)
    inst.ptype = npipe.ptype
    inst.pipe_buffer = npipe.pipe_buffer
    inst.point = npipe.point
    return inst
end
function Pipe:flush()
    self.pipe_buffer = ''
end
function Pipe:write(message)
    self.pipe_buffer = self.pipe_buffer .. message
end
function Pipe:readAll()
    local A = os.strsplit(self.pipe_buffer, '\n')
    local buffer = self.pipe_buffer
    self.point = #A + 1
    return buffer
end
function Pipe:readLine()
    local K = os.strsplit(self.pipe_buffer, '\n')
    local data = K[self.point]
    self.point = self.point + 1
    return data
end
function test_pipe()
    local t = Pipe.new('empty')
    t:write("Hello\nWorld!\n")
    local h = Pipe.copyPipe(t)
    print(t.pipe_buffer == h.pipe_buffer)
    print(h:readLine())
end
function libroutine()end
EndFile;
File;bin/factor
#!/usr/bin/env lua
--/bin/factor: factors numbers
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        --print("uname: recieved SIGKILL")
        return 0
    end
end
function main(args)
    n = args[1]
    if tonumber(n) == 0 or tonumber(n) < 0 then return 0 end --bugfix
    function IsPrime(n)
        if n <= 1 or (n ~= 2 and n % 2 == 0) then
            return false
        end
        for i = 3, math.sqrt(n), 2 do
	    if n % i == 0 then
      	    return false
	    end
        end
        return true
    end
    function PrimeDecomposition(n)
        local f = {}
        if IsPrime(n) then
            f[1] = n
            return f
        end
        local i = 2
        repeat
            while n % i == 0 do
                f[#f+1] = i
                n = n / i
            end
            repeat
                i = i + 1
            until IsPrime(i)
        until n == 1
        return f
    end
    write(n .. ": ")
    for k,v in pairs(PrimeDecomposition(tonumber(n))) do
        write(v .. " ")
    end
    write('\n')
end
main({...})
EndFile;
File;dev/urandom
EndFile;
File;boot/sblcfg/bootdisk
set root=(disk)
chainloader +1
boot
EndFile;
File;sbin/adduser
#!/usr/bin/env lua
--/sbin/adduser: adding new users to cubix
_handler = {}
_handler.signal_handler = function(sig)
    if sig == 'kill' then
        --print("adduser: SIGKILL")
        return 0
    end
end
function main(args)
    if #args == 0 then
        print("usage: adduser <user> <password>")
        return 0
    end
    local nu, np = args[1], args[2]
    if nu == 'root' then
        os.ferror("you cannot create a new root user")
    end
    if os.lib.login.add_new_user(nu, np) then
        print("created "..nu)
    else
        os.ferror("adduser: error creating new user")
    end
end
main({...})
EndFile;
File;bin/tee
#!/usr/bin/env lua
--/bin/tee: same as unix tee
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        return 0
    end
end
function main(args, pipe)
    --cmd1 | tee output_file | cmd2
    local hpipe = os.lib.pipe.Pipe.copyPipe(pipe)
    local from = ''
    while true do
        local line = hpipe:readLine()
        if not line or line == '' then break end
        from = from .. line .. '\n'
    end
    local CPATH = os.cshell.getpwd()
    local file = args[1]
    local h = fs.open(os.cshell.resolve(file), 'w')
    if h == nil then
        os.ferror("tee: error opening path")
        return 1
    end
    h.write(from)
    h.close()
    return 0
end
main({...})
EndFile;
File;sbin/login
#!/usr/bin/env lua
--/bin/login: login user to its shell access
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        --print("login: recieved SIGKILL")
        return 0
    end
end
function main(args)
    local user = args[1]
    if user == nil then user = "^" end
    local PC_LABEL = os.getComputerLabel()
    local try_user = ""
    local try_pwd = ""
    if user == "^" then
        write(PC_LABEL.." login: ")
        try_user = read()
        write("Password: ")
        try_pwd = read("")
    else
        try_user = user
        write("Password: ")
        try_pwd = read("")
    end
    if os.lib.login.login(try_user, try_pwd) then
        local k = fs.open("/tmp/current_user", 'w')
        if not k then os.debug.kpanic("cannot open /tmp/current_user") end
        k.write(try_user)
        k.close()
        local k2 = fs.open("/tmp/current_path", 'w')
        if not k2 then os.debug.kpanic("cannot open /tmp/current_path") end
        if try_user ~= 'root' then
            k2.write("/home/"..try_user)
        else
            k2.write("/root")
        end
        k2.close()
        --showing the initial path to csh
        os.lib.control.register('/sbin/login', 'cwd', '/home/'..try_user)
        --getting itself as a process
        os.lib.control.register('/sbin/login', 'login_lock', '1')
        local itself = os.lib.proc.get_by_pid(os.getrunning())
        os.lib.control.register('/sbin/login', 'login_lock', nil)
        --running csh
        os.runfile_proc("/bin/cshell_rewrite", nil, itself) --parenting with login
    else
        os.ferror("\nLogin incorrect")
    end
end
main({...})
EndFile;
File;lib/tty_manager
#!/usr/bin/env lua
--tty manager
--task: manage TTYs
local TTYS = {}
local __current_tty = ''
function get_tty(id)
    return TTYS[id]
end
function current_tty(id)
    __current_tty = id
    local h = fs.open("/tmp/current_tty", 'w')
    h.write(id)
    h.close()
end
function getcurrentTTY()
    return TTYS[__current_tty]
end
function get_ttys()
    return TTYS
end
TTY = {}
TTY.__index = TTY
function TTY.new(tid)
    local inst = {}
    setmetatable(inst, TTY)
    inst.buffer = ""
    inst.id = tid
    inst.using = false
    TTYS[tid] = inst
    return inst
end
function TTY:run_process(absolute_path)
    os.debug.debug_write("[tty] "..self.id..' running '..absolute_path, false)
end
function TTY:write(msg)
    self.buffer = self.buffer .. msg
    write(msg)
end
oldwrite = write
oldprint = print
function write(message)
    local current_tty = getcurrentTTY()
    return current_tty:write(message)
end
function libroutine()
    --10 ttys by default
    os.internals._kernel.register_tty("/dev/tty0", TTY.new("/dev/tty0"))
    os.internals._kernel.register_tty("/dev/tty1", TTY.new("/dev/tty1"))
    os.internals._kernel.register_tty("/dev/tty2", TTY.new("/dev/tty2"))
    os.internals._kernel.register_tty("/dev/tty3", TTY.new("/dev/tty3"))
    os.internals._kernel.register_tty("/dev/tty4", TTY.new("/dev/tty4"))
    os.internals._kernel.register_tty("/dev/tty5", TTY.new("/dev/tty5"))
    os.internals._kernel.register_tty("/dev/tty6", TTY.new("/dev/tty6"))
    os.internals._kernel.register_tty("/dev/tty7", TTY.new("/dev/tty7"))
    os.internals._kernel.register_tty("/dev/tty8", TTY.new("/dev/tty8"))
    os.internals._kernel.register_tty("/dev/tty9", TTY.new("/dev/tty9"))
    --os.internals._kernel.register_tty("/dev/tty10", TTY.new("/dev/tty10"))
end
EndFile;
File;proc/14/stat
stat working
EndFile;
File;bin/ps
#!/usr/bin/env lua
--/bin/ps
function isin(inputstr, wantstr)
    for i = 1, #inputstr do
        local v = string.sub(inputstr, i, i)
        if v == wantstr then return true end
    end
    return false
end
function main(args)
    if #args >= 1 then
        if isin(args[1], 'a') then
            flag_all_terminals = true
        elseif isin(args[1], 'x') then
            flag_all_proc = true
        elseif isin(args[1], 'o') then
            flag_show_ppid = true
        end
    end
    local procs = os.lib.proc.get_processes()
    --default action: show all processes from the current terminal
    if not flag_all_terminals and not flag_all_proc then
        local pcurrent_tty = os.lib.proc.filter_proc(os.lib.proc.FLAG_CTTY)
        os.pprint("PID  PROC")
        for _,v in pairs(pcurrent_tty) do
            os.pprint(v.pid.."  "..(v.file.." "..v.lineargs))
        end
    elseif flag_all_proc and not flag_all_terminals then
        local pallproc = os.lib.proc.filter_proc(os.lib.proc.FLAG_APRC)
        os.pprint("PID  PRNT  PROC")
        for _,v in pairs(pallproc) do
            if v.parent ~= nil then
                os.pprint(v.pid.."  "..(v.parent)..' > '..(v.file.." "..v.lineargs))
            else
                os.pprint(v.pid.."  "..(v.file.." "..v.lineargs))
            end
        end
    elseif not flag_all_proc and flag_all_terminals then
        --print('all tty')
        local palltty = os.lib.proc.filter_proc(os.lib.proc.FLAG_ATTY)
        os.pprint("PID  PRNT  PROC")
        for _,v in pairs(palltty) do
            if v.parent ~= nil then
                os.pprint(v.pid.."  "..(v.parent)..' > '..(v.file.." "..v.lineargs))
            else
                os.pprint(v.pid.."  "..(v.file.." "..v.lineargs))
            end
        end
    end
end
main({...})
EndFile;
File;lib/fs/cfs.lua
--Cubix File System
local res = {}
function canMount(uid)
    if uid == 0 then
        return true
    else
        return false
    end
end
function collectFiles(dir, stripPath, table)
    if not table then table = {} end
    dir = dir
    local fixPath = fsmanager.stripPath(stripPath, dir)
    table[dir] = fsmanager.getInformation(dir)
    local files = fs.list(dir)
    if dir == '/' then dir = '' end
    if fixPath == '/' then fixPath = '' end
    for k, v in pairs(files) do
        if string.sub(v, 1, 1) == '/' then v = string.sub(v, 2, #v) end
        table[fixPath .. "/" .. v] = fsmanager.getInformation(dir .. "/" .. v)
        if oldfs.isDir(dir .. "/" .. v) then collectFiles(dir .. "/" .. v, stripPath, table) end
    end
    return table
end
function _test()
    return collectFiles("/", "/", {})
end
function getSize(path)end
function saveFS(mountpath, dev)
    local p = dev
    if p == '/' then p = '' end
    local FSDATA = oldfs.open(p .. "/CFSDATA", "w")
    local WRITEDATA = ""
    for k, v in pairs(collectFiles(mountpath, mountpath, {})) do
        if string.sub(k, 1, 4) ~= '.git' and string.sub(k, 1, 5) ~= '/.git' and string.sub(k, 1, 6) ~= '/.git/' then
            WRITEDATA = WRITEDATA .. k .. ":" .. v.owner .. ":" .. v.perms .. ":"
            if v.linkto then WRITEDATA = WRITEDATA .. v.linkto end
            WRITEDATA = WRITEDATA .. ":" .. v.gid .. "\n"
        end
    end
    print("saveFS: ok")
    FSDATA.write(WRITEDATA)
    FSDATA.close()
end
function loadFS(mountpath, dev)
    local p = dev
    if p == '/' then p = '' end
    if not fs.exists(p..'/CFSDATA') then saveFS(mountpath, dev) end
    local _fsdata = oldfs.open(p..'/CFSDATA', 'r')
    local fsdata = _fsdata.readAll()
    _fsdata.close()
    local splitted = os.strsplit(fsdata, "\n")
    local res = {}
    for k,v in ipairs(splitted) do
        local tmp = os.strsplit(v, ":")
        if #tmp == 5 then
            res[tmp[1]] = {
                owner = tonumber(tmp[2]),
                perms = tmp[3],
                linkto = tmp[4],
                gid = tonumber(tmp[5])
            }
        elseif #tmp == 4 then
            res[tmp[1]] = {
                owner = tonumber(tmp[2]),
                perms = tmp[3],
                linkto = nil,
                gid = tonumber(tmp[4])
            }
        end
        if tmp[4] == "" then
            res[tmp[1]].linkto = nil
        end
        --os.viewTable(res[tmp[1]])
    end
    return res, true
end
function list(mountpath, path)
    return oldfs.list(path)
end
function exists(mountpath, path)
    return oldfs.exists(path)
end
function isDir(mountpath, path)
    return oldfs.isDir(path)
end
function delete(mountpath, path)
    return oldfs.delete(path)
end
function makeDir(mountpath, path)
    return oldfs.makeDir(path)
end
function open(mountpath, path, mode)
    return oldfs.open(path, mode)
end
function check(device)
    --sanity check
    if dev_available(device) then
        diskprobe(device, 'hell')
    else
        ferror("check: device not found")
        return false
    end
    --actually, check
    for i=0, len_blocks(device) do
        --n sei se eh jornal ou journal
        if get_block(device, i) ~= get_journal(device, i) then
            ferror("o shit nigga")
            correct(device, i)
        end
    end
    print("check: done")
end
function check_for_terrorists()
    check("/dev/airplane")
end
EndFile;
File;makeyap
#!/usr/bin/env lua
--makeyap:
--based on pkgdata, creates a .yap file to be a package.
--compatible with Cubix and CraftOS
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        return 0
    end
end
cwd = ''
local strsplit = function (inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    if inputstr == nil then
        return ''
    end
    local t={} ; i=1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        t[i] = str
        i = i + 1
    end
    return t
end
local ferror = function(message)
    term.set_term_color(colors.red)
    print(message)
    term.set_term_color(colors.white)
end
local viewTable = function (t)
    print(t)
    for k,v in pairs(t) do
        print(k..","..tostring(v).." ("..type(v)..")")
    end
end
function listAll(p)
    local starting = '/'
    if p ~= nil then
        starting = p
    end
    if starting == '.git' or starting == '/.git' or starting == 'rom' or starting == '/rom' then
        return {folders={}, files={}}
    end
    local folders = {}
    local files = {}
    for _,v in ipairs(fs.list(starting)) do
        local node = fs.combine(starting, v)
        if fs.isDir(node) then
            if not (node == '.git' or node == '/.git' or node == 'rom' or node == '/rom') then
                table.insert(folders, node)
                local cache = listAll(node)
                for _,v in ipairs(cache['folders']) do
                    table.insert(folders, v)
                end
                for _,v in ipairs(cache['files']) do
                    table.insert(files, v)
                end
            end
        else
            table.insert(files, node)
        end
    end
    return {folders=folders, files=files}
end
function parse_pkgdata(lines)
    local pkgobj = {}
    pkgobj['file_assoc'] = {}
    pkgobj['folders'] = {}
    pkgobj['deps'] = {}
    for k,v in ipairs(lines) do
        if string.sub(v, 1, 1) ~= '#' then --comments
            local d = strsplit(v, ';')
            if d[1] == 'pkgName' then
                pkgobj['name'] = d[2]
            elseif d[1] == 'pkgVersion' then
                pkgobj['version'] = d[2]
            elseif d[1] == 'pkgBuild' then
                pkgobj['build'] = d[2]
            elseif d[1] == 'pkgAuthor' then
                pkgobj['author'] = d[2]
            elseif d[1] == 'pkgEAuthor' then
                pkgobj['email-author'] = d[2]
            elseif d[1] == 'pkgDescription' then
                pkgobj['description'] = d[2]
            elseif d[1] == 'pkgFile' then
                table.insert(pkgobj['file_assoc'], {d[2], d[3]})
            elseif d[1] == 'pkgFolder' then
                table.insert(pkgobj['folders'], d[2])
            elseif d[1] == 'pkgDep' then
                table.insert(pkgobj['deps'], d[2])
            elseif d[1] == 'pkgAll' then
                local nodes = listAll()
                for _,v in ipairs(nodes['folders']) do
                    table.insert(pkgobj['folders'], v)
                end
                for _,v in ipairs(nodes['files']) do
                    table.insert(pkgobj['file_assoc'], {v, v})
                end
            end
        end
    end
    return pkgobj
end
function create_yap(pkgdata, cwd)
    local yapdata = {}
    yapdata['name'] = pkgdata['name']
    yapdata['version'] = pkgdata['version']
    yapdata['build'] = pkgdata['build']
    yapdata['author'] = pkgdata['author']
    yapdata['email_author'] = pkgdata['email-author']
    yapdata['description'] = pkgdata['description']
    yapdata['folders'] = pkgdata['folders']
    yapdata['deps'] = pkgdata['deps']
    yapdata['files'] = {}
    for k,v in pairs(pkgdata['file_assoc']) do
        local original_file = fs.combine(cwd, v[1])
        local absolute_path = v[2]
        yapdata['files'][absolute_path] = ''
        local handler = fs.open(original_file, 'r')
        local _lines = handler.readAll()
        handler.close()
        local lines = strsplit(_lines, '\n')
        for k,v in ipairs(lines) do
            yapdata['files'][absolute_path] = yapdata['files'][absolute_path] .. v .. '\n'
        end
    end
    return yapdata
end
function write_yapdata(yapdata)
    local yp = fs.combine(cwd, yapdata['name']..'.yap')
    if fs.exists(yp) then
        fs.delete(yp)
    end
    local yfile = fs.open(yp, 'w')
    yfile.write('Name;'..yapdata['name']..'\n')
    yfile.write('Version;'..yapdata['version']..'\n')
    yfile.write('Build;'..yapdata['build']..'\n')
    yfile.write('Author;'..yapdata['author']..'\n')
    yfile.write('Email-Author;'..yapdata['email_author']..'\n')
    yfile.write('Description;'..yapdata['description']..'\n')
    os.viewTable(yapdata['folders'])
    for k,v in pairs(yapdata['folders']) do
        yfile.write("Folder;"..v..'\n')
    end
    for k,v in pairs(yapdata['deps']) do
        yfile.write("Dep;"..v..'\n')
    end
    for k,v in pairs(yapdata['files']) do
        yfile.write("File;"..k..'\n')
        yfile.write(v)
        yfile.write("EndFile;\n")
    end
    yfile.close()
    return yp
end
function main(args)
    if type(os.cshell) == 'table' then
        cwd = os.cshell.getpwd()
    else
        cwd = shell.dir()
    end
    --black magic goes here
    local pkgdata_path = fs.combine(cwd, 'pkgdata')
    local handler = {}
    if fs.exists(pkgdata_path) and not fs.isDir(pkgdata_path) then
        handler = fs.open(pkgdata_path, 'r')
    else
        ferror('makeyap: pkgdata needs to exist')
        return 1
    end
    local _tLines = handler.readAll()
    handler.close()
    if _tLines == nil then
        ferror("yapdata: file is empty")
        return 1
    end
    local tLines = strsplit(_tLines, '\n')
    local pkgdata = parse_pkgdata(tLines)
    print("[parse_pkgdata]")
    print("creating yap...")
    local ydata = create_yap(pkgdata, cwd)
    print("[create_yap] created yapdata from pkgdata")
    local path = write_yapdata(ydata)
    print("[write_yapdata] "..path)
end
main({...})
EndFile;
File;proc/14/exe
makeyap
EndFile;
File;usr/bin/helloworld
#!/usr/bin/env lua
--/bin/helloworld
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        --print("helloworld: recieved SIGKILL")
        return 0
    end
end
function main(args)
    textutils.slowPrint("Hello World!")
end
main({...})
EndFile;
File;etc/time-servers
EndFile;
File;bin/sh
#!/usr/bin/env lua
--/bin/sh: wrapper for /bin/cshell
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        --print("sh: recieved SIGKILL")
        return 0
    end
end
function main(args)
    os.runfile_proc("/bin/cshell", args)
end
main({...})
EndFile;
File;README.md
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
EndFile;
File;bin/ls
#!/usr/bin/env lua
--/bin/ls : wrapper to CC "ls"
_handler = {}
_handler.signal_handler = function(sig)
    if sig == 'kill' then
        --print("ls: SIGKILL")
        return 0
    end
end
local chars = {}
for i = 32, 126 do chars[string.char(i)] = i end
--[[ You can redefine this table, but this way the entries will be sorted by ASCII values.
     So "A" (0x41) will be before "B" (0x42), but "a" (0x61) will be after "C" (0x43) ]]
local function sortingComparsion(valueA, valueB)
    --[[ This is like strcmp in C++. Not sure if the return values are
         correct or not though. I mean, not sure if strcmp returns +1
         or -1 if the first argument is lower.
         The function itself works though... ]]
    local strpos = 0
    local difference = 0
    while strpos < #valueA and strpos < #valueB and difference == 0 do
        strpos = strpos + 1
        if chars[string.sub(valueA, strpos, strpos)] > chars[string.sub(valueB, strpos, strpos)] then
            difference = 1
        elseif chars[string.sub(valueA, strpos, strpos)] < chars[string.sub(valueB, strpos, strpos)] then
            difference = -1
        end
    end
    if difference == -1 then
        return true -- return true if we want valueA to be before valueB
    else
        return false -- or return false if we want valueB to be before valueA
    end
end
function ls(pth)
    local nodes = fs.list(pth)
    local files = {}
    local folders = {}
    for k,v in ipairs(nodes) do
        if fs.isDir(pth..'/'..v) then
            table.insert(folders, v)
        else
            table.insert(files, v)
        end
    end
    table.sort(folders, sortingComparsion)
    table.sort(files, sortingComparsion)
    --printing folders
    term.set_term_color(colors.green)
    for k,v in ipairs(folders) do
        write(v..' ')
    end
    term.set_term_color(colors.white)
    --printing files
    for k,v in ipairs(files) do
        write(v..' ')
    end
    write('\n')
end
function main(args)
    local p = args[1]
    local cpath = os.cshell.getpwd()
    if p == nil then
        ls(cpath)
    elseif fs.exists(os.cshell.resolve(p)) then
        ls(os.cshell.resolve(p))
    else
        os.ferror("ls: node not found")
    end
end
main({...})
EndFile;
File;lib/luaX/lxClient.lua
--/lib/luaX/lxClient.lua
--luaX manager, manages libraries and other things
if not _G['LX_SERVER_LOADED'] then
    os.ferror("lxClient: lxServer not loaded")
    return 0
end
local windows = {}
local focused = nil
function loadWindow(window)
    windows[window.lxwFile] = window
    window:load_itself()
end
function unloadWindow(window)
    windows[window.lxwFile] = nil
    window = nil
    --???
end
function libroutine()
    _G['LX_CLIENT_LOADED'] = true
end
EndFile;
File;var/yapi/db/community
EndFile;
File;bin/whoami
#!/usr/bin/env lua
--/bin/whoami: says who you are
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        return 0
    end
end
function main(args)
    print(os.lib.login.currentUser())
end
main({...})
EndFile;
File;lib/devices/dummy_device.lua
dev_dummy = {}
dev_dummy.name = '/dev/dummy'
dev_dummy.device = {}
dev_dummy.device.device_read = function (bytes)
    return nil
end
dev_dummy.device.device_write = function(s)
    return nil
end
EndFile;
File;etc/scripts/set_env.csp
$("/bin/cshell")
EndFile;
File;dev/tty10
EndFile;
File;bin/curtime
#!/usr/bin/env lua
--/bin/curtime: shows current time
_handler = {}
_handler.signal_handler = function(sig)
    if sig == 'kill' then
        --print("curtime: SIGKILL")
        return 0
    end
end
function main()
    print(os.lib.time.strtime())
end
main({...})
EndFile;
File;bin/clear
#!/usr/bin/env lua
--/bin/clear
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        --print("clear: recieved SIGKILL")
        return 0
    end
end
function main(args)
    term.clear()
    term.setCursorPos(1,1)
end
main({...})
EndFile;
File;proc/14/cmd
makeyap 
EndFile;
File;bin/wget
#!/usr/bin/env lua
--/bin/wget
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        return 0
    end
end
if not http then
    os.ferror("wget: can't use HTTP API")
    return 0
end
function usage()
    print("usage: wget <url> <file>")
end
function download_file_http(url)
    print("[http] "..url)
    http.request(url)
    local req = true
    while req do
        local e, url, stext = os.pullEvent()
        if e == 'http_success' then
            local rText = stext.readAll()
            stext.close()
            return rText
        elseif e == 'http_failure' then
            req = false
            return {false, 'http_failure'}
        end
    end
end
function download_pastebin(pastebin_id)
    return download_file_http('http://pastebin.com/raw/'..pastebin_id)
end
function download_file(url)
    if string.sub(url, 1,7) == 'http://' then
        return download_file_http(url)
    elseif string.sub(url, 1,9) == 'pastebin:' then
        return download_pastebin(string.sub(url, 10, #url))
    end
end
function main(args)
    if #args ~= 2 then
        usage()
        return 0
    end
    local url, destination = args[1], args[2]
    local response = download_file(url)
    if type(response) == 'string' then
        print("wget: response ok")
    elseif type(response) == 'table' and response[1] == false then
        ferror("wget: response == table")
        ferror("wget: "..response[2])
        return 1
    else
        ferror("wget: ???")
        return 1
    end
    local p = os.cshell.resolve(destination)
    local h = fs.open(p, 'w')
    h.write(response)
    h.close()
    print("wget: saved as "..p)
end
main({...})
EndFile;
File;usr/manuals/wget.man
!cmfl!
.name
wget - download files through http
.cmd
wget <URL> <DESTFILE>
.listop URL
    URL could be a normal http url, like "http://lkmnds.github.io" (and it needs the http://, HTTP ONLY, not https)
    or URL could be a pastebin link, like "pastebin:pastebinid"
.e
.listop DESTFILE
    as normal operation, wget will rewrite DESTFILE when called, so don't mess things up
.e
EndFile;
File;bin/tty
#!/usr/bin/env lua
--/bin/tty: shows the current tty by reading /tmp/current_tty
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        --print("tty: recieved SIGKILL")
        return 0
    end
end
function main(args)
    k = fs.open("/tmp/current_tty", 'r')
    print(k.readAll())
    k.close()
end
main({...})
EndFile;
File;lib/devices/kbd.lua
local devname = ''
local devpath = ''
function mread(x)
    count = 0
    txt = ""
    repeat
        id,chr = os.pullEvent()
        if id == "char" then
            term.write(chr)
            txt = txt..chr
            count = count + 1
        end
        if id == "key" and chr == 28 then
            return txt
        end
    until count == x
    write('\n')
    return txt
end
function device_read(bytes)
    return mread(bytes)
end
function device_write(data)
end
function setup(name, path)
    devname = name
    devpath = path
    fs.open(path, 'w').close()
end
function libroutine()end
EndFile;
File;lib/device_manager
#!/usr/bin/env lua
--device manager
--task: create devices in /dev
--devices:
--  device.name = string
--  device.device = table
--  device.device.read = function
--  device.device.devwrite = function
function loadDevice(name, path)
    os.debug.debug_write("[devman] loading "..name)
    if os.loadAPI(path) then
        _G[name] = _G[fs.getName(path)]
        os.debug.debug_write("[devman] loaded "..name)
    else
        os.debug.kpanic("[devman] not loaded "..name)
    end
end
MAPDEVICES_BLOCK = {}
MAPDEVICES_BLOCK[7] = {
    [0]={key='dev_dummy', name='/dev/dummy', lib='dummy_device.lua'}
}
MAPDEVICES_CHAR = {}
MAPDEVICES_CHAR[1] = {
    [3]={key='dev_null', name='/dev/null', lib='null_device.lua'},
    [5]={key='dev_zero', name='/dev/zero', lib='zero_device.lua'},
    [7]={key='dev_full', name='/dev/full', lib='full_device.lua'},
    [8]={key='dev_random', name='/dev/random', lib='random_device.lua'},
    [9]={key='dev_urandom', name='/dev/urandom', lib='urandom_device.lua'},
}
MAPDEVICES_CHAR[10] = {
    [8]={key='dev_mouse', name='/dev/mouse', lib='mouse_device.lua'}
}
--create virtual disks(without loopback)
--fs-tools:
-- * copy from a fs to another fs
function lddev(path, type, major, minor)
    if type == 'b' then
        local d = MAPDEVICES_BLOCK[major][minor]
        if d == nil then
            ferror("lddev: device not found")
            return false
        end
        loadDevice(d.name, '/lib/devices/'..d.lib)
        os.internals._kernel.register_device(path, _G[d.name][d.key])
    elseif type == 'c' then
        local d = MAPDEVICES_CHAR[major][minor]
        if d == nil then
            ferror("lddev: device not found")
            return false
        end
        loadDevice(d.name, '/lib/devices/'..d.lib)
        os.internals._kernel.register_device(path, _G[d.name][d.key])
    end
end
function libroutine()
    --normal devices
    lddev('/dev/null', 'c', 1, 3)
    lddev('/dev/zero', 'c', 1, 5)
    lddev('/dev/full', 'c', 1, 7)
    lddev('/dev/random', 'c', 1, 8)
    lddev('/dev/urandom', 'c', 1, 9)
    --loopback devices
    lddev('/dev/loop0', 'b', 7, 0)
    lddev('/dev/loop1', 'b', 7, 0)
    lddev('/dev/loop2', 'b', 7, 0)
    lddev('/dev/loop3', 'b', 7, 0)
    lddev('/dev/loop4', 'b', 7, 0)
    --mouse
    lddev("/dev/mouse", 'c', 10, 8)
end
EndFile;
File;bin/sulogin
#!/usr/bin/env lua
--/bin/sulogin: logins to root
function main(args)
    os.runfile_proc("/sbin/login", {"root"})
end
main({...})
EndFile;
File;dev/tty0
EndFile;
File;sbin/reboot
#!/usr/bin/env lua
--/bin/reboot: wrapper to CC reboot
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        print("reboot: recieved SIGKILL")
        return 0
    end
end
function main(args)
    print("reboot: rebooting system.")
    os.reboot()
end
main({...})
EndFile;
File;etc/inittab
id:1:inittab
EndFile;
File;pkgdata
#base pkgdata
#Basic data
pkgName;base
pkgVersion;0.5.1
pkgBuild;51
#Maintainer
pkgAuthor;Lukas Mendes
pkgEAuthor;lkmnds@gmail.com
pkgDescription;Cubix base system
#files
#pkgFile;*;/
pkgAll;/
EndFile;
File;boot/libcubix
#!/usr/bin/env lua
--libcubix: compatibility for cubix
AUTHOR = 'Lukas Mendes'
VERSION = '0.1'
--[[
Libcubix serves as a library that contains all the functions
that do not use any "cubix" thing(like ferror for example)
Libcubix is used in installation stage to create a cubix initramfs,
this servers as the basic functions that are needed in systemboot and
after it(os.strsplit, os.tail, etc.)
As there can be other versions of initramfs created by the community,
this version serves as the "official" libcubix and initramfs generator
for cubix.
Libcubix was created to make programs writed in Pure Lua to use some of
the functions in Cubix, without making the programs to be run at Cubix enviroment
]]
os.viewTable = function (t)
    if t == nil then return 0 end
    print(t)
    for k,v in pairs(t) do
        print(k..","..tostring(v).." ("..type(v)..")")
    end
end
os.tail = function(t)
    if # t <= 1 then
        return nil
    end
    local newtable = {}
    for i, v in ipairs(t) do
        if i > 1 then
            table.insert(newtable, v)
        end
    end
    return newtable
end
os.strsplit = function (inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    if type(inputstr) ~= 'string' then
        term.set_term_color(colors.red)
        print("os.strsplit: type(inputstr) == "..type(inputstr))
        term.set_term_color(colors.white)
        return 1
    end
    if inputstr == nil then
        return ''
    end
    local t={} ; i=1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        t[i] = str
        i = i + 1
    end
    return t
end
function strcount(str, char)
    local c = 0
    for i=1, #str do
        local v = string.sub(str, i, i)
        if v == char then
            c = c + 1
        end
    end
    return c
end
_G['strcount'] = strcount
os.safestr = function (s)
    if string.byte(s) > 191 then
        return '@'..string.byte(s)
    end
    return s
end
os.generateSalt = function(l)
    if l < 1 then
        return nil
    end
    local res = ''
    for i = 1, l do
        res = res .. string.char(math.random(32, 126))
    end
    return res
end
function _prompt(message, yes, nope)
    write(message..'['..yes..'/'..nope..'] ')
    local result = read()
    if result == yes then
        return true
    else
        return false
    end
end
_G['prompt'] = _prompt
function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end
os.deepcopy = deepcopy
_G['deepcopy'] = deepcopy
function gethostname()
    local h = fs.open("/etc/hostname", 'r')
    if h == nil then
        return ''
    end
    local hstn = h.readAll()
    h.close()
    return hstn
end
_G['gethostname'] = gethostname
function class(base, init)
   local c = {}    -- a new class instance
   if not init and type(base) == 'function' then
      init = base
      base = nil
   elseif type(base) == 'table' then
    -- our new class is a shallow copy of the base class!
      for i,v in pairs(base) do
         c[i] = v
      end
      c._base = base
   end
   -- the class will be the metatable for all its objects,
   -- and they will look up their methods in it.
   c.__index = c
   -- expose a constructor which can be called by <classname>(<args>)
   local mt = {}
   mt.__call = function(class_tbl, ...)
   local obj = {}
   setmetatable(obj,c)
   if init then
      init(obj,...)
   else
      -- make sure that any stuff from the base class is initialized!
      if base and base.init then
      base.init(obj, ...)
      end
   end
   return obj
   end
   c.init = init
   c.is_a = function(self, klass)
      local m = getmetatable(self)
      while m do
         if m == klass then return true end
         m = m._base
      end
      return false
   end
   setmetatable(c, mt)
   return c
end
_G['class'] = class
function generate_lcubix(type, path)
    if type == 'all' then
        local h = fs.open("/boot/libcubix", 'r')
        local all_lcubix = h.readAll()
        h.close()
        local h2 = fs.open(path, 'w')
        h2.write(all_lcubix)
        h2.close()
    end
end
EndFile;
File;proc/3/exe
/bin/cshell_rewrite
EndFile;
File;etc/shadow.safecopy
cubix^8875ac1c6e6ab7b10ce9162cc3cc33c2330018df9664a58deb568b3cc1cb4fef^'d9M'W_}sD!6'Pv^cubix
root^63574847901e6d7f982c30ba96c4bc46a14e9503708085f2cc45295957c23462^,6@bQ+}k7@E7q45^root
EndFile;
File;etc/fstab
/dev/hda;/;cfs;;
/dev/loop1;/dev/shm;tmpfs;;
EndFile;
File;sbin/shutdown
#!/usr/bin/env lua
--/sbin/reboot: wrapper to CC shutdown
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        print("shutdown: recieved SIGKILL")
        return 0
    end
end
function main(args)
    os.shutdown()
end
main({...})
EndFile;
File;dev/tty7
EndFile;
File;bin/cp
#!/usr/bin/env lua
--/bin/cp: wrapper to CC cp (absolute paths)
_handler = {}
_handler.signal_handler = function(sig)
    if sig == 'kill' then
        --print("cp: SIGKILL")
        return 0
    end
end
function main(args)
    if #args == 0 then
        print("usage: cp <file> <destination>")
    end
    local from, to = args[1], args[2]
    if fs.exists(os.cshell.resolve(from)) then
        fs.copy(os.cshell.resolve(from), os.cshell.resolve(to))
    else
        os.ferror("cp: input file does not exist")
        return 1
    end
    return 0
end
main({...})
EndFile;
File;dev/stdout
EndFile;
File;etc/groups
#Group file for cubix
root:0:
disk:4:cubix
lx:5:cubix
network:6:cubix
power:7:
storage:8:cubix
video:9:cubix
EndFile;
File;bin/arch
#!/usr/bin/env lua
--/bin/arch: same as uname -m
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        --print("arch: recieved SIGKILL")
        return 0
    end
end
function main(args)
    os.runfile_proc("/bin/uname", {"-m"})
end
main({...})
EndFile;
File;bin/panic
#!/usr/bin/env lua
--/bin/panic: panics the kernel
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        --print("panic: recieved SIGKILL(?????)")
        return 0
    end
end
function main()
    os.debug.kpanic('panic')
end
main({...})
EndFile;
File;bin/pwd
#!/usr/bin/env lua
--/bin/pwd: print working directory
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        --print("pwd: recieved SIGKILL")
        return 0
    end
end
function main()
    print(os.cshell.getpwd())
end
main({...})
EndFile;
File;sbin/fsck
#!/usr/bin/env lua
--/sbin/fsck: file system check
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        --print("users: recieved SIGKILL")
        return 0
    end
end
VERSION = '0.0.1'
function main(args)
    print("cubix fsck v"..VERSION)
    if #args > 1 then
        local device = args[1]
        local fs = args[2]
        if fsdrivers[fs].check then
            fsdrivers[fs].check(device)
        else
            print("check function in "..fs.." not found")
        end
    else
        print("usage: fsck <device> <filesystem>")
    end
end
main({...})
EndFile;
File;bin/cksum
#!/usr/bin/env lua
--/bin/cksum
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        --print("cksum: recieved SIGKILL")
        return 0
    end
end
--local string = require("string")
--local bit = require("bit")
local tostring = tostring
--module('crc32')
local CRC32 = {
    0x00000000, 0x77073096, 0xee0e612c, 0x990951ba,
    0x076dc419, 0x706af48f, 0xe963a535, 0x9e6495a3,
    0x0edb8832, 0x79dcb8a4, 0xe0d5e91e, 0x97d2d988,
    0x09b64c2b, 0x7eb17cbd, 0xe7b82d07, 0x90bf1d91,
    0x1db71064, 0x6ab020f2, 0xf3b97148, 0x84be41de,
    0x1adad47d, 0x6ddde4eb, 0xf4d4b551, 0x83d385c7,
    0x136c9856, 0x646ba8c0, 0xfd62f97a, 0x8a65c9ec,
    0x14015c4f, 0x63066cd9, 0xfa0f3d63, 0x8d080df5,
    0x3b6e20c8, 0x4c69105e, 0xd56041e4, 0xa2677172,
    0x3c03e4d1, 0x4b04d447, 0xd20d85fd, 0xa50ab56b,
    0x35b5a8fa, 0x42b2986c, 0xdbbbc9d6, 0xacbcf940,
    0x32d86ce3, 0x45df5c75, 0xdcd60dcf, 0xabd13d59,
    0x26d930ac, 0x51de003a, 0xc8d75180, 0xbfd06116,
    0x21b4f4b5, 0x56b3c423, 0xcfba9599, 0xb8bda50f,
    0x2802b89e, 0x5f058808, 0xc60cd9b2, 0xb10be924,
    0x2f6f7c87, 0x58684c11, 0xc1611dab, 0xb6662d3d,
    0x76dc4190, 0x01db7106, 0x98d220bc, 0xefd5102a,
    0x71b18589, 0x06b6b51f, 0x9fbfe4a5, 0xe8b8d433,
    0x7807c9a2, 0x0f00f934, 0x9609a88e, 0xe10e9818,
    0x7f6a0dbb, 0x086d3d2d, 0x91646c97, 0xe6635c01,
    0x6b6b51f4, 0x1c6c6162, 0x856530d8, 0xf262004e,
    0x6c0695ed, 0x1b01a57b, 0x8208f4c1, 0xf50fc457,
    0x65b0d9c6, 0x12b7e950, 0x8bbeb8ea, 0xfcb9887c,
    0x62dd1ddf, 0x15da2d49, 0x8cd37cf3, 0xfbd44c65,
    0x4db26158, 0x3ab551ce, 0xa3bc0074, 0xd4bb30e2,
    0x4adfa541, 0x3dd895d7, 0xa4d1c46d, 0xd3d6f4fb,
    0x4369e96a, 0x346ed9fc, 0xad678846, 0xda60b8d0,
    0x44042d73, 0x33031de5, 0xaa0a4c5f, 0xdd0d7cc9,
    0x5005713c, 0x270241aa, 0xbe0b1010, 0xc90c2086,
    0x5768b525, 0x206f85b3, 0xb966d409, 0xce61e49f,
    0x5edef90e, 0x29d9c998, 0xb0d09822, 0xc7d7a8b4,
    0x59b33d17, 0x2eb40d81, 0xb7bd5c3b, 0xc0ba6cad,
    0xedb88320, 0x9abfb3b6, 0x03b6e20c, 0x74b1d29a,
    0xead54739, 0x9dd277af, 0x04db2615, 0x73dc1683,
    0xe3630b12, 0x94643b84, 0x0d6d6a3e, 0x7a6a5aa8,
    0xe40ecf0b, 0x9309ff9d, 0x0a00ae27, 0x7d079eb1,
    0xf00f9344, 0x8708a3d2, 0x1e01f268, 0x6906c2fe,
    0xf762575d, 0x806567cb, 0x196c3671, 0x6e6b06e7,
    0xfed41b76, 0x89d32be0, 0x10da7a5a, 0x67dd4acc,
    0xf9b9df6f, 0x8ebeeff9, 0x17b7be43, 0x60b08ed5,
    0xd6d6a3e8, 0xa1d1937e, 0x38d8c2c4, 0x4fdff252,
    0xd1bb67f1, 0xa6bc5767, 0x3fb506dd, 0x48b2364b,
    0xd80d2bda, 0xaf0a1b4c, 0x36034af6, 0x41047a60,
    0xdf60efc3, 0xa867df55, 0x316e8eef, 0x4669be79,
    0xcb61b38c, 0xbc66831a, 0x256fd2a0, 0x5268e236,
    0xcc0c7795, 0xbb0b4703, 0x220216b9, 0x5505262f,
    0xc5ba3bbe, 0xb2bd0b28, 0x2bb45a92, 0x5cb36a04,
    0xc2d7ffa7, 0xb5d0cf31, 0x2cd99e8b, 0x5bdeae1d,
    0x9b64c2b0, 0xec63f226, 0x756aa39c, 0x026d930a,
    0x9c0906a9, 0xeb0e363f, 0x72076785, 0x05005713,
    0x95bf4a82, 0xe2b87a14, 0x7bb12bae, 0x0cb61b38,
    0x92d28e9b, 0xe5d5be0d, 0x7cdcefb7, 0x0bdbdf21,
    0x86d3d2d4, 0xf1d4e242, 0x68ddb3f8, 0x1fda836e,
    0x81be16cd, 0xf6b9265b, 0x6fb077e1, 0x18b74777,
    0x88085ae6, 0xff0f6a70, 0x66063bca, 0x11010b5c,
    0x8f659eff, 0xf862ae69, 0x616bffd3, 0x166ccf45,
    0xa00ae278, 0xd70dd2ee, 0x4e048354, 0x3903b3c2,
    0xa7672661, 0xd06016f7, 0x4969474d, 0x3e6e77db,
    0xaed16a4a, 0xd9d65adc, 0x40df0b66, 0x37d83bf0,
    0xa9bcae53, 0xdebb9ec5, 0x47b2cf7f, 0x30b5ffe9,
    0xbdbdf21c, 0xcabac28a, 0x53b39330, 0x24b4a3a6,
    0xbad03605, 0xcdd70693, 0x54de5729, 0x23d967bf,
    0xb3667a2e, 0xc4614ab8, 0x5d681b02, 0x2a6f2b94,
    0xb40bbe37, 0xc30c8ea1, 0x5a05df1b, 0x2d02ef8d
}
local xor = bit.bxor
local lshift = bit.blshift
local rshift = bit.brshift
local band = bit.band
function hash(str)
    str = tostring(str)
    local count = string.len(str)
    local crc = 2 ^ 32 - 1
    local i = 1
    while count > 0 do
        local byte = string.byte(str, i)
        crc = xor(rshift(crc, 8), CRC32[xor(band(crc, 0xFF), byte) + 1])
        i = i + 1
        count = count - 1
    end
    crc = xor(crc, 0xFFFFFFFF)
    -- dirty hack for bitop return number < 0
    if crc < 0 then crc = crc + 2 ^ 32 end
    return crc
end
function work_pipe(pipe)
    local k = os.lib.pipe.Pipe.copyPipe(pipe)
    pipe:flush()
    local line = k:readAll()
    local cksum = hash(line)
    print(cksum)
end
function main(args, pipe)
    if pipe ~= nil then
        work_pipe(pipe)
        return 0
    else
        if #args == 0 then
            print("usage: cksum <file>")
            print("usage(pipe): cksum")
            return 0
        end
        local file = args[1]
        print("damn son")
    end
end
main({...})
EndFile;
File;usr/manuals/time-server.man
On the subject of Time Servers
Time servers in cubix have to follow a simple syntax, when made a GET request to them, without any arguments, they need to return this:
{day,month,year,hours,minutes,seconds,}
getTime_fmt unserialises the data and it will get the current time, applying timezone calculations as it does so.
strtime(timezone1, timezone2) is the default method to get hours, minutes and seconds, all in a string
EndFile;
File;var/yapi/db/extra
lx-base;http://lkmnds.github.io/yapi/extra/lx-base.yap
lx-extra;http://lkmnds.github.io/yapi/extra/lx-extra.yap
libcubix;http://lkmnds.github.io/yapi/extra/libcubix.yap
EndFile;
File;usr/manuals/procmngr.man
On the subject of the Process Manager
Primary task:
    Process Manager creates, kills and interfaces process with the userspace.
  Global variables:
    -os.processes [table] - shows the list of actual processes running at the system
    -os.pid_last [number] - the last PID of a process, used to create the PID of the next process
    -os.signals [table] - system signals(SIGKILL, SIGINT, SIGILL, SIGFPE...)
  Functions:
    -Process related:
      -os.call_handle(process, handler)
        -calls a process _handler, which calls a program _handler
      -os.send_signal(process, signal)
        -sends a signal to a process, depending of what signal
          -SIGKILL: kills the process and its children
      -os.terminate(process)
        -terminates a process, first it calls its _handle using os.call_handle
      -os.run_process(process, arguments)
        -runs a process with its arguments in a table
      -os.set_child(parent, child)
        -sets a relation between parent process and child process
      -os.set_parent(child, parent)
        -inverse of os.set_child
      -os.new_process(executable)
        -creates a process
      -os.runfile_proc(executable, arguments, parent)
        -creates a process, set its parent and runs it with specified arguments, after that, sends a SIGKILL to it
 * Secondary task:
    The concept of /proc is around Managed Files, they're files that the kernel can show information to the user.
     * /proc/cpuinfo
     * /proc/temperature
     * /proc/partitions
EndFile;
File;bin/dmesg
#!/usr/bin/env lua
--/bin/dmesg: debug messages
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        --print("dmesg: recieved SIGKILL")
        return 0
    end
end
function main(args)
    local debug_file = fs.open("/tmp/syslog", 'r')
    print(debug_file.readAll())
    debug_file.close()
end
main({...})
EndFile;
File;sbin/init
#!/usr/bin/env lua
--/sbin/init: manages (some part of) the user space
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        _G['CANT_HANDLE_THE_FORCE'] = true
        os.ferror("init: SIGKILL")
    end
end
local RUNLEVELFUNC = {}
function runlevel_0()
    if permission.grantAccess(fs.perms.ROOT) then
        os.shutdown()
    end
    permission.default()
end
function runlevel_1()
    --single-user
    for k,v in pairs(fs.list("/etc/rc1.d/")) do
        shell.run(fs.combine("/etc/rc1.d",v))
    end
    while true do
        os.runfile_proc("/sbin/login")
    end
end
function runlevel_2()
    --multiuser(all ttys running login) withtout network service
    loadmodule("multiuser", "/lib/multiuser/multiuser.lua")
end
function runlevel_3()
    --multiuser and network service
    os.internals.loadmodule("network", "/lib/net/network.lua")
    os.internals.loadmodule("multiuser", "/lib/multiuser/multiuser.lua")
end
function runlevel_5()
    --start LuaX, multiuser and network support
    os.internals.loadmodule("network", "/lib/net/network.lua")
    os.internals.loadmodule("multiuser", "/lib/multiuser/multiuser.lua")
    os.runfile_proc("/bin/lx", {'start'})
end
function runlevel_6()
    --reboot
    if permission.grantAccess(fs.perms.ROOT) then
        os.debug.debug_write("[init] rebooting with root permission")
        os.runfile_proc("/sbin/reboot")
    else
        --rebooting without permissions
        os.debug.debug_write("[init] rebooting withOUT root permission")
        os.reboot()
    end
    permission.default()
end
RUNLEVELFUNC[0] = runlevel_0
RUNLEVELFUNC[1] = runlevel_1
RUNLEVELFUNC[2] = runlevel_2
RUNLEVELFUNC[3] = runlevel_3
RUNLEVELFUNC[5] = runlevel_5
RUNLEVELFUNC[6] = runlevel_6
function main(args)
    if args[1] ~= nil then
        runlevel = tonumber(args[1])
    else
        if fs.exists("/etc/inittab") then
            local inittab = fs.open("/etc/inittab", 'r')
            local r = os.strsplit(inittab.readAll(), ':')[2]
            runlevel = tonumber(r)
            inittab.close()
        else
            os.debug.kpanic("[init] /etc/inittab not found")
            return 1
        end
    end
    os.lib.tty.current_tty("/dev/tty1")
    RUNLEVELFUNC[runlevel]()
    return 0
end
main({...})
EndFile;
File;proc/temperature
EndFile;
File;bin/who
#!/usr/bin/env lua
--/bin/whoami: who am i?
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        --print("who: recieved SIGKILL")
        return 0
    end
end
function main(args)
    local fsttime = fs.open("/proc/sttime", 'r')
    local ST_TIME = fsttime.readAll()
    fsttime.close()
    local cuser = fs.open("/tmp/current_user", 'r')
    local current_user = cuser.readAll()
    cuser.close()
    print(current_user .. '   :0  ' .. textutils.formatTime(tonumber(ST_TIME), false) .. '  (:0)')
end
main({...})
EndFile;
File;dev/tty9
EndFile;
File;usr/games/gameoflife
board = {}
tArgs = { ... }
generation = 0
sleeptime = 0.5
if(tArgs[1] == "left" or tArgs[1] == "right" or tArgs[1] == "top" or tArgs[1] == "bottom" or tArgs[1] == "front" or tArgs[1] == "back")then
	mon = peripheral.wrap(tArgs[1])
else
	mon = term
end
if(mon.isColor() or mon.isColor)then
	colored = true
else
	colored = false
end
w, h = mon.getSize()
for x = 1, w do
	board[x] = {}
	for y = 1, h do
		board[x][y] = 0
	end
end
function drawScreen()
	w, h = mon.getSize()
	for x = 1, w do
		for y = 1, h do
			nei = getNeighbours(x, y)
			if(board[x][y] == 1)then
				if colored then
					if(nei < 2 or nei > 3)then
						mon.setBackgroundColor(colors.red)
					else
						mon.setBackgroundColor(colors.green)
					end
				else
					mon.setBackgroundColor(colors.white)
				end
			else
				if colored then
					if(nei == 3)then
						mon.setBackgroundColor(colors.yellow)
					else
						mon.setBackgroundColor(colors.black)
					end
				else
					mon.setBackgroundColor(colors.black)
				end
			end
			mon.setCursorPos(x, y)
			mon.write(" ")
		end
	end
	mon.setCursorPos(1,1)
	if colored then
		mon.setTextColor(colors.blue)
	end
	mon.write(generation)
end
function getNeighbours(x, y)
	w, h = mon.getSize()
	total = 0
	if(x > 1 and y > 1)then if(board[x-1][y-1] == 1)then total = total + 1 end end
	if(y > 1)then if(board[x][y-1] == 1)then total = total + 1 end end
	if(x < w and y > 1)then if(board[x+1][y-1] == 1)then total = total + 1 end end
	if(x > 1)then if(board[x-1][y] == 1)then total = total + 1 end end
	if(x < w)then if(board[x+1][y] == 1)then total = total + 1 end end
	if(x > 1 and y < h)then if(board[x-1][y+1] == 1)then total = total + 1 end end
	if(y < h)then if(board[x][y+1] == 1)then total = total + 1 end end
	if(x < w and y < h)then if(board[x+1][y+1] == 1)then total = total + 1 end end
	return total
end
function compute()
	w, h = mon.getSize()
	while true do
		newBoard = {}
		for x = 1, w do
			newBoard[x] = {}
			for y = 1, h do
				nei = getNeighbours(x, y)
				if(board[x][y] == 1)then
					if(nei < 2)then
						newBoard[x][y] = 0
					elseif(nei > 3)then
						newBoard[x][y] = 0
					else
						newBoard[x][y] = 1
					end
				else
					if(nei == 3)then
						newBoard[x][y] = 1
					end
				end
			end
		end
		board = newBoard
		generation = generation + 1
		sleep(sleeptime)
	end
end
function loop()
	while true do
		event, variable, xPos, yPos = os.pullEvent()
		if event == "mouse_click" or event == "monitor_touch" or event == "mouse_drag" then
			if variable == 1 then
				board[xPos][yPos] = 1
			else
				board[xPos][yPos] = 0
			end
		end
		if event == "key" then
			if tostring(variable) == "28" then
				return true
			elseif tostring(variable) == "57" then
				if(mon.isColor() or mon.isColor)then
					colored = not colored
				end
			elseif tostring(variable) == "200" then
				if sleeptime > 0.1 then
					sleeptime = sleeptime - 0.1
				end
			elseif tostring(variable) == "208" then
				if sleeptime < 1 then
					sleeptime = sleeptime + 0.1
				end
			end
		end
		drawScreen()
	end
end
function intro()
	mon.setBackgroundColor(colors.black)
	mon.clear()
	mon.setCursorPos(1,1)
	mon.write("Conway's Game Of Life")
	mon.setCursorPos(1,2)
	mon.write("It is a game which represents life.")
	mon.setCursorPos(1,3)
	mon.write("The game runs by 4 basic rules:")
	mon.setCursorPos(1,4)
	mon.write("1. If a cell has less than 2 neighbours, it dies.")
	mon.setCursorPos(1,5)
	mon.write("2. If a cell has 2 or 3 neightbours, it lives.")
	mon.setCursorPos(1,6)
	mon.write("3. If a cell has more than 3 neighbours, it dies.")
	mon.setCursorPos(1,7)
	mon.write("4. If a cell has exactly 3 neighbours it is born.")
	mon.setCursorPos(1,9)
	mon.write("At the top left is the generation count.")
	mon.setCursorPos(1,10)
	mon.write("Press spacebar to switch between color modes")
	mon.setCursorPos(1,11)
	mon.write("Press enter to start  the game")
	mon.setCursorPos(1,13)
	mon.write("Colors:")
	mon.setCursorPos(1,14)
	mon.write("Red - Cell will die in next generation")
	mon.setCursorPos(1,15)
	mon.write("Green - Cell will live in next generation")
	mon.setCursorPos(1,16)
	mon.write("Yellow - Cell will be born in next generation")
	mon.setCursorPos(1,18)
	mon.write("Press any key to continue!")
	event, variable, xPos, yPos = os.pullEvent("key")
end
intro()
drawScreen()
while true do
	loop()
	parallel.waitForAny(loop, compute)
end
EndFile;
File;lib/luaX/lxWindow.lua
--/lib/luaX/lxWindow.lua
--luaX window library
--function: create, delete, buttons, etc
if not _G['LX_CLIENT_LOADED'] then
    os.ferror("lxWindow: lxClient not loaded")
    return 0
end
local window_data = {}
local windows = {}
function unload_all()
    windows = {}
end
function get_window_location()
    return {5 + #windows, 5 + #windows}
end
Window = {}
Window.__index = Window
function Window.new(path_lxw)
    local inst = {}
    setmetatable(inst, Window)
    inst.title = 'luaX Window'
    inst.focus = false
    inst.actions = {}
    inst.coords = {}
    inst.elements = {}
    inst.lxwFile = path_lxw
    return inst
end
function Window:add(element, x, y)
    local i = #self.elements + 1
    self.coords[i] = {x,y}
    self.elements[i] = element
end
function Window:call_handler(ev)
    if self.handler == nil then
        os.lib.lxServer.lxError("lxWindow: no handler set")
        return 0
    end
    print("call self.handler "..type(ev))
    self.handler(ev)
end
function Window:set_handler(f)
    self.handler = f
end
function Window:set_title(newtitle)
    self.title = newtitle
end
function write_window(window_location, lenX, lenY, window_title)
    local locX = window_location[1]
    local locY = window_location[2]
    --basic window borders
    os.lib.lxServer.write_rectangle(locX-1, locY-1, lenY+2, lenX+2, colors.black)
    os.lib.lxServer.write_solidRect(locX, locY, lenY, lenX, colors.white)
    --window title
    os.lib.lx.write_string(window_title, locX+3, locY-1, colors.white, colors.black)
end
function Window:show()
    tx = self.lxwdata['hw'][1]
    ty = self.lxwdata['hw'][2]
    sx = get_window_location()[1]
    sy = get_window_location()[2]
    write_window(get_window_location(), tx, ty, self.title)
    for i=1,#self.elements do
        element = self.elements[i]
        coordinates = self.coords[i]
        --print("show " .. coordinates[1] ..';'.. coordinates[2])
        element:_show(sx, sy)
    end
    while true do
        local e, p1, p2, p3, p4, p5 = os.pullEvent()
        local event = {e, p1, p2, p3, p4, p5}
        print(type(event))
        self:call_handler(event)
    end
end
function nil_handler(event)
    return nil
end
--[[
name:lxterm
hw:9,30
changeable:false
main:lxterm.lua
]]
function parse_lxw(path)
    local handler = fs.open(path, 'r')
    if handler == nil then
        lxError("lxWindow", "File not found")
        return false
    end
    local _data = handler.readAll()
    handler.close()
    local lxwdata = {}
    local data = os.strsplit(_data, '\n')
    for k,v in pairs(data) do
        if string.sub(v, 1, 1) ~= '#' then --comments
            --comparisons here
            local splitted_line = os.strsplit(v, ':')
            if splitted_line[1] == 'name' then
                lxwdata['name'] = splitted_line[2]
            elseif splitted_line[1] == 'hw' then
                lxwdata['hw'] = os.strsplit(splitted_line[2], ',')
            elseif splitted_line[1] == 'changeable' then
                lxwdata['changeable'] = splitted_line[2]
            elseif splitted_line[1] == 'main' then
                lxwdata['mainfile'] = splitted_line[2]
            end
        end
    end
    window_data[lxwdata['name']] = lxwdata
    return lxwdata
end
function main_run(file, window)
    --run a file with determined _ENV
    --it seems that i can not do this so i've put the window object into args
    os.run({}, file, {window})
end
function Window:load_itself()
    os.debug.debug_write("[lxWindow] load lxw: "..self.lxwFile, false)
    local lxwdata = parse_lxw(self.lxwFile)
    if lxwdata == false then
        lxError("lxWindow", "cannot load window")
        return 1
    else
        os.debug.debug_write("[lxWindow] load window: "..lxwdata['name'], false)
        self.lxwdata = lxwdata
        main_run(lxwdata['mainfile'], self)
    end
end
Object = class(function(self, xpos, ypos, x1pos, y2pos)
    self.posX = xpos
    self.posY = ypos
    self.finX = x1pos
    self.finY = y2pos
end)
Label = class(Object, function(self, label, x1, y1)
    local lenlabel = #label
    Object.init(self, x1, y1, x1, y1+lenlabel)
    self.ltext = label
end)
function Label:_show(location_x, location_y)
    os.lib.lx.write_string(self.ltext,
    location_x,
    location_y,
    os.lib.lx.random_color(), os.lib.lx.random_color()
    )
end
EventObject = class(Object, function(self, x, y, x1, y1)
    Object.init(self, x, y, x1, y1)
end)
function EventObject:_addListener(listener_func)
    self['listener'] = listener_func
end
--TextField class
TextField = class(EventObject, function(self, x, y, tfX, tfY)
    EventObject.init(self, x, y, tfX, tfY)
end)
tf1 = TextField(0, 0)
--create CommandBox
CommandBox = class(TextField, function(self, x, y, shellPath)
    TextField.init(self, x, y, x+20, y+20)
    self.spath = shellPath
    self.cmdbuffer = ''
    local cbox_listener = {} --default event listener
    function cbox_listener:evPerformed(event)
        print(type(event))
        if event[1] == 'key' then
            if event[2] == 98 then
                self.send_command(self.cmdbuffer)
                output = self.get_data()
                self.append_text(output)
            end
        end
    end
    self.event_handler = cbox_listener['evPerformed']
    self:addEventListener(cbox_listener)
end)
function CommandBox:_show(locX, locY)
    wd = window_data['lxterm']
    os.lib.lxServer.write_solidRect(locX, locY, wd['hw'][2], wd['hw'][1], colors.blue)
end
function CommandBox:addEventListener(listener_obj)
    self:_addListener(listener_obj['evPerformed'])
end
function libroutine()
end
EndFile;
File;proc/1/cmd
/sbin/init 
EndFile;
File;proc/3/cmd
/bin/cshell_rewrite 
EndFile;
File;bin/eject
#!/usr/bin/env lua
--/bin/eject: wrapper to CC "eject"
_handler = {}
_handler.signal_handler = function(sig)
    if sig == 'kill' then
        --print("eject: SIGKILL")
        return 0
    end
end
function main(args)
    if #args == 0 then print("usage: eject <side> ") return 0 end
    local side = args[1]
    disk.eject(side)
end
main({...})
EndFile;
File;g/lxterm/lxterm.lua
--/g/lxterm/lxterm.lua
--the lxterm.lxw will load lxterm.lua, which will configure the window and register the events as expected
local windowl = ...
function main()
    if not os.lib.lxWindow then
        os.ferror("lxterm: lxWindow not loaded")
        return 0
    end
    local Main = windowl[1]
    --local l1 = os.lib.lxWindow.Label('TestLabel', 0, 0)
    --Main:add(l1, 5, 5)
    --Main:set_handler(os.lib.lxWindow.nil_handler)
    --Main:show()
    Main:set_title("luaX Terminal")
    local cbox1 = os.lib.lxWindow.CommandBox(10, 10, '/sbin/login')
    Main:add(cbox1, 0, 0)
    Main:set_handler(cbox1.event_handler)
    --Main:show()
    while true do
        os.runfile_proc(cbox1.spath)
    end
end
main()
EndFile;
File;sbin/pm-suspend
#!/usr/bin/env lua
--/bin/pm-suspend: wrapper to ACPI suspend function
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        os.debug.debug_write("pm-suspend: recieved SIGKILL", false)
        return 0
    end
end
function main(args)
    os.suspend()
    return 0
end
main({...})
EndFile;
File;usr/manuals/acpi.man
ACPI Module
ACPI or Advanced Configuration and Power Interface is a interface for the OS to make power commands right away, without the direct interference on the hardware.
In CC, acpi works by making some cleanup tasks(deleting /tmp and /proc/<number>) and killing processes before the CC (shutdown/reboot) kicks in
Suspend(acpi_suspend or os.suspend): acpi just suspends the computer until a key is pressed
Hibernate(acpi_hibernate or os.hibernate): does not work now
EndFile;
File;dev/tty2
EndFile;
File;lib/devices/random_device.lua
function rawread()
    while true do
        local sEvent, param = os.pullEvent("key")
        if sEvent == "key" then
            if param == 28 then
                break
            end
        end
    end
end
function print_rndchar()
    local cache = tostring(os.clock())
    local seed = 0
    for i=1,#cache do
        seed = seed + string.byte(string.sub(cache,i,i))
    end
    math.randomseed(tostring(seed))
    while true do
        s = string.char(math.random(0, 255))
        io.write(s)
    end
end
dev_random = {}
dev_random.device = {}
dev_random.name = '/dev/random'
dev_random.device.device_write = function (message)
    print("cannot write to /dev/random")
end
dev_random.device.device_read = function (bytes)
    local crand = {}
    if bytes == nil then
        crand = coroutine.create(print_rndchar)
        coroutine.resume(crand)
        while true do
            local event, key = os.pullEvent( "key" )
            if event and key then
                break
            end
        end
    else
        local cache = tostring(os.clock())
        local seed = 0
        for i=1,#cache do
            seed = seed + string.byte(string.sub(cache,i,i))
        end
        math.randomseed(tostring(seed))
        result = ''
        for i = 0, bytes do
            s = string.char(math.random(0, 255))
            result = result .. s
        end
        return result
    end
    return 0
end
return dev_random
EndFile;
EndFile;
File;usr/bin/helloworld
#!/usr/bin/env lua
--/bin/helloworld
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        --print("helloworld: recieved SIGKILL")
        return 0
    end
end
function main(args)
    textutils.slowPrint("Hello World!")
end
main({...})
EndFile;
File;etc/time-servers
EndFile;
File;bin/sh
#!/usr/bin/env lua
--/bin/sh: wrapper for /bin/cshell
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        --print("sh: recieved SIGKILL")
        return 0
    end
end
function main(args)
    os.runfile_proc("/bin/cshell", args)
end
main({...})
EndFile;
File;README.md
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
EndFile;
File;bin/ls
#!/usr/bin/env lua
--/bin/ls : wrapper to CC "ls"
_handler = {}
_handler.signal_handler = function(sig)
    if sig == 'kill' then
        --print("ls: SIGKILL")
        return 0
    end
end
local chars = {}
for i = 32, 126 do chars[string.char(i)] = i end
--[[ You can redefine this table, but this way the entries will be sorted by ASCII values.
     So "A" (0x41) will be before "B" (0x42), but "a" (0x61) will be after "C" (0x43) ]]
local function sortingComparsion(valueA, valueB)
    --[[ This is like strcmp in C++. Not sure if the return values are
         correct or not though. I mean, not sure if strcmp returns +1
         or -1 if the first argument is lower.
         The function itself works though... ]]
    local strpos = 0
    local difference = 0
    while strpos < #valueA and strpos < #valueB and difference == 0 do
        strpos = strpos + 1
        if chars[string.sub(valueA, strpos, strpos)] > chars[string.sub(valueB, strpos, strpos)] then
            difference = 1
        elseif chars[string.sub(valueA, strpos, strpos)] < chars[string.sub(valueB, strpos, strpos)] then
            difference = -1
        end
    end
    if difference == -1 then
        return true -- return true if we want valueA to be before valueB
    else
        return false -- or return false if we want valueB to be before valueA
    end
end
function ls(pth)
    local nodes = fs.list(pth)
    local files = {}
    local folders = {}
    for k,v in ipairs(nodes) do
        if fs.isDir(pth..'/'..v) then
            table.insert(folders, v)
        else
            table.insert(files, v)
        end
    end
    table.sort(folders, sortingComparsion)
    table.sort(files, sortingComparsion)
    --printing folders
    term.set_term_color(colors.green)
    for k,v in ipairs(folders) do
        write(v..' ')
    end
    term.set_term_color(colors.white)
    --printing files
    for k,v in ipairs(files) do
        write(v..' ')
    end
    write('\n')
end
function main(args)
    local p = args[1]
    local cpath = os.cshell.getpwd()
    if p == nil then
        ls(cpath)
    elseif fs.exists(os.cshell.resolve(p)) then
        ls(os.cshell.resolve(p))
    else
        os.ferror("ls: node not found")
    end
end
main({...})
EndFile;
File;lib/luaX/lxClient.lua
--/lib/luaX/lxClient.lua
--luaX manager, manages libraries and other things
if not _G['LX_SERVER_LOADED'] then
    os.ferror("lxClient: lxServer not loaded")
    return 0
end
local windows = {}
local focused = nil
function loadWindow(window)
    windows[window.lxwFile] = window
    window:load_itself()
end
function unloadWindow(window)
    windows[window.lxwFile] = nil
    window = nil
    --???
end
function libroutine()
    _G['LX_CLIENT_LOADED'] = true
end
EndFile;
File;var/yapi/db/community
EndFile;
File;bin/whoami
#!/usr/bin/env lua
--/bin/whoami: says who you are
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        return 0
    end
end
function main(args)
    print(os.lib.login.currentUser())
end
main({...})
EndFile;
File;etc/scripts/set_env.csp
$("/bin/cshell")
EndFile;
File;lib/devices/dummy_device.lua
dev_dummy = {}
dev_dummy.name = '/dev/dummy'
dev_dummy.device = {}
dev_dummy.device.device_read = function (bytes)
    return nil
end
dev_dummy.device.device_write = function(s)
    return nil
end
EndFile;
File;dev/tty10
EndFile;
File;bin/curtime
#!/usr/bin/env lua
--/bin/curtime: shows current time
_handler = {}
_handler.signal_handler = function(sig)
    if sig == 'kill' then
        --print("curtime: SIGKILL")
        return 0
    end
end
function main()
    print(os.lib.time.strtime())
end
main({...})
EndFile;
File;bin/clear
#!/usr/bin/env lua
--/bin/clear
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        --print("clear: recieved SIGKILL")
        return 0
    end
end
function main(args)
    term.clear()
    term.setCursorPos(1,1)
end
main({...})
EndFile;
File;bin/wget
#!/usr/bin/env lua
--/bin/wget
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        return 0
    end
end
if not http then
    os.ferror("wget: can't use HTTP API")
    return 0
end
function usage()
    print("usage: wget <url> <file>")
end
function download_file_http(url)
    print("[http] "..url)
    http.request(url)
    local req = true
    while req do
        local e, url, stext = os.pullEvent()
        if e == 'http_success' then
            local rText = stext.readAll()
            stext.close()
            return rText
        elseif e == 'http_failure' then
            req = false
            return {false, 'http_failure'}
        end
    end
end
function download_pastebin(pastebin_id)
    return download_file_http('http://pastebin.com/raw/'..pastebin_id)
end
function download_file(url)
    if string.sub(url, 1,7) == 'http://' then
        return download_file_http(url)
    elseif string.sub(url, 1,9) == 'pastebin:' then
        return download_pastebin(string.sub(url, 10, #url))
    end
end
function main(args)
    if #args ~= 2 then
        usage()
        return 0
    end
    local url, destination = args[1], args[2]
    local response = download_file(url)
    if type(response) == 'string' then
        print("wget: response ok")
    elseif type(response) == 'table' and response[1] == false then
        ferror("wget: response == table")
        ferror("wget: "..response[2])
        return 1
    else
        ferror("wget: ???")
        return 1
    end
    local p = os.cshell.resolve(destination)
    local h = fs.open(p, 'w')
    h.write(response)
    h.close()
    print("wget: saved as "..p)
end
main({...})
EndFile;
File;usr/manuals/wget.man
!cmfl!
.name
wget - download files through http
.cmd
wget <URL> <DESTFILE>
.listop URL
    URL could be a normal http url, like "http://lkmnds.github.io" (and it needs the http://, HTTP ONLY, not https)
    or URL could be a pastebin link, like "pastebin:pastebinid"
.e
.listop DESTFILE
    as normal operation, wget will rewrite DESTFILE when called, so don't mess things up
.e
EndFile;
File;bin/tty
#!/usr/bin/env lua
--/bin/tty: shows the current tty by reading /tmp/current_tty
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        --print("tty: recieved SIGKILL")
        return 0
    end
end
function main(args)
    k = fs.open("/tmp/current_tty", 'r')
    print(k.readAll())
    k.close()
end
main({...})
EndFile;
File;lib/device_manager
#!/usr/bin/env lua
--device manager
--task: create devices in /dev
--devices:
--  device.name = string
--  device.device = table
--  device.device.read = function
--  device.device.devwrite = function
function loadDevice(name, path)
    os.debug.debug_write("[devman] loading "..name)
    if os.loadAPI(path) then
        _G[name] = _G[fs.getName(path)]
        os.debug.debug_write("[devman] loaded "..name)
    else
        os.debug.kpanic("[devman] not loaded "..name)
    end
end
MAPDEVICES_BLOCK = {}
MAPDEVICES_BLOCK[7] = {
    [0]={key='dev_dummy', name='/dev/dummy', lib='dummy_device.lua'}
}
MAPDEVICES_CHAR = {}
MAPDEVICES_CHAR[1] = {
    [3]={key='dev_null', name='/dev/null', lib='null_device.lua'},
    [5]={key='dev_zero', name='/dev/zero', lib='zero_device.lua'},
    [7]={key='dev_full', name='/dev/full', lib='full_device.lua'},
    [8]={key='dev_random', name='/dev/random', lib='random_device.lua'},
    [9]={key='dev_urandom', name='/dev/urandom', lib='urandom_device.lua'},
}
MAPDEVICES_CHAR[10] = {
    [8]={key='dev_mouse', name='/dev/mouse', lib='mouse_device.lua'}
}
--create virtual disks(without loopback)
--fs-tools:
-- * copy from a fs to another fs
function lddev(path, type, major, minor)
    if type == 'b' then
        local d = MAPDEVICES_BLOCK[major][minor]
        if d == nil then
            ferror("lddev: device not found")
            return false
        end
        loadDevice(d.name, '/lib/devices/'..d.lib)
        os.internals._kernel.register_device(path, _G[d.name][d.key])
    elseif type == 'c' then
        local d = MAPDEVICES_CHAR[major][minor]
        if d == nil then
            ferror("lddev: device not found")
            return false
        end
        loadDevice(d.name, '/lib/devices/'..d.lib)
        os.internals._kernel.register_device(path, _G[d.name][d.key])
    end
end
function libroutine()
    --normal devices
    lddev('/dev/null', 'c', 1, 3)
    lddev('/dev/zero', 'c', 1, 5)
    lddev('/dev/full', 'c', 1, 7)
    lddev('/dev/random', 'c', 1, 8)
    lddev('/dev/urandom', 'c', 1, 9)
    --loopback devices
    lddev('/dev/loop0', 'b', 7, 0)
    lddev('/dev/loop1', 'b', 7, 0)
    lddev('/dev/loop2', 'b', 7, 0)
    lddev('/dev/loop3', 'b', 7, 0)
    lddev('/dev/loop4', 'b', 7, 0)
    --mouse
    lddev("/dev/mouse", 'c', 10, 8)
end
EndFile;
File;lib/devices/kbd.lua
local devname = ''
local devpath = ''
function mread(x)
    count = 0
    txt = ""
    repeat
        id,chr = os.pullEvent()
        if id == "char" then
            term.write(chr)
            txt = txt..chr
            count = count + 1
        end
        if id == "key" and chr == 28 then
            return txt
        end
    until count == x
    write('\n')
    return txt
end
function device_read(bytes)
    return mread(bytes)
end
function device_write(data)
end
function setup(name, path)
    devname = name
    devpath = path
    fs.open(path, 'w').close()
end
function libroutine()end
EndFile;
File;bin/sulogin
#!/usr/bin/env lua
--/bin/sulogin: logins to root
function main(args)
    os.runfile_proc("/sbin/login", {"root"})
end
main({...})
EndFile;
File;dev/tty0
EndFile;
File;sbin/reboot
#!/usr/bin/env lua
--/bin/reboot: wrapper to CC reboot
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        print("reboot: recieved SIGKILL")
        return 0
    end
end
function main(args)
    print("reboot: rebooting system.")
    os.reboot()
end
main({...})
EndFile;
File;var/yapi/cache/initramfs-tools.yap
Name;initramfs-tools
Version;0.0.2
Build;2
Author;Lukas Mendes
Email-Author;lkmnds@gmail.com
Description;tools to generate a initramfs for cubix
Dep;base
File;/usr/bin/generate-initramfs
#!/usr/bin/env lua
--generate-initramfs: generate initramfs for cubix
AUTHOR = "Lukas Mendes"
VERSION = '0.0.2'
function main(args)
    if not permission.grantAccess(fs.perms.SYS) then
        os.ferror("generate-initramfs: permission error")
        return 1
    end
    --/etc/initramfs.modules
    local h = fs.open("/etc/initramfs.modules", 'r')
    if h == nil then
        ferror("generate-initramfs: error opening initramfs.modules")
        return 0
    end
    local modules = h.readAll()
    h.close()
    print("generating initramfs in /boot/cubix-initramfs...")
    local initramfsfile = ''
    local mlines = os.strsplit(modules, '\n')
    for _,mod in ipairs(mlines) do
        if string.sub(mod, 1, 1) == '#' or mod == '' then else
            if mod == 'libcubix' then
                local h = fs.open("/boot/libcubix", 'r')
                if h == nil then
                    ferror("generate-initramfs: error opening libcubix")
                    ferror("Aborted.")
                    return 0
                end
                local modfile = h.readAll()
                h.close()
                initramfsfile = initramfsfile..modfile..'\n\n'
            else
                if fs.exists("/lib/modules/"..mod) then
                    local h = fs.open("/lib/modules/"..mod, 'r')
                    if h == nil then
                        ferror("generate-initramfs: error opening module "..mod)
                        ferror("Aborted.")
                        return 0
                    end
                    local modfile = h.readAll()
                    h.close()
                    initramfsfile = initramfsfile..modfile..'\n\n'
                else
                    ferror(mod..": module not found")
                    return 0
                end
            end
        end
    end
    local h = fs.open("/boot/cubix-initramfs", 'w')
    if h == nil then
        ferror("generate-initramfs: error opening cubix-initramfs for write")
        return 0
    end
    h.write(initramfsfile)
    h.close()
    print("generated cubix-initramfs with: ")
    for _,mod in ipairs(mlines) do
        if string.sub(mod, 1, 1) == '#' then else
            write(mod..' ')
        end
    end
    write('\n')
end
main({...})
EndFile;
EndFile;
File;etc/inittab
id:1:inittab
EndFile;
File;boot/libcubix
#!/usr/bin/env lua
--libcubix: compatibility for cubix
AUTHOR = 'Lukas Mendes'
VERSION = '0.2'
--[[
Libcubix serves as a library that contains all the functions
that do not use any "cubix" thing(like ferror for example)
Libcubix is used in installation stage to create a cubix initramfs,
this servers as the basic functions that are needed in systemboot and
after it(os.strsplit, os.tail, etc.)
As there can be other versions of initramfs created by the community,
this version serves as the "official" libcubix and initramfs generator
for cubix.
Libcubix was created to make programs writed in Pure Lua to use some of
the functions in Cubix, without making the programs to be run at Cubix enviroment
]]
os.viewTable = function (t)
    if t == nil then return 0 end
    print(t)
    for k,v in pairs(t) do
        print(k..","..tostring(v).." ("..type(v)..")")
    end
end
os.tail = function(t)
    if # t <= 1 then
        return nil
    end
    local newtable = {}
    for i, v in ipairs(t) do
        if i > 1 then
            table.insert(newtable, v)
        end
    end
    return newtable
end
os.strsplit = function (inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    if type(inputstr) ~= 'string' then
        term.set_term_color(colors.red)
        print("os.strsplit: type(inputstr) == "..type(inputstr))
        term.set_term_color(colors.white)
        return 1
    end
    if inputstr == nil then
        return ''
    end
    local t={} ; i=1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        t[i] = str
        i = i + 1
    end
    return t
end
function strcount(str, char)
    local c = 0
    for i=1, #str do
        local v = string.sub(str, i, i)
        if v == char then
            c = c + 1
        end
    end
    return c
end
_G['strcount'] = strcount
os.safestr = function (s)
    if string.byte(s) > 191 then
        return '@'..string.byte(s)
    end
    return s
end
os.generateSalt = function(l)
    if l < 1 then
        return nil
    end
    local res = ''
    for i = 1, l do
        res = res .. string.char(math.random(32, 126))
    end
    return res
end
function _prompt(message, yes, nope)
    write(message..'['..yes..'/'..nope..'] ')
    local result = read()
    if result == yes then
        return true
    else
        return false
    end
end
_G['prompt'] = _prompt
function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end
os.deepcopy = deepcopy
_G['deepcopy'] = deepcopy
function gethostname()
    local h = fs.open("/etc/hostname", 'r')
    if h == nil then
        return ''
    end
    local hstn = h.readAll()
    h.close()
    return hstn
end
_G['gethostname'] = gethostname
function class(base, init)
   local c = {}    -- a new class instance
   if not init and type(base) == 'function' then
      init = base
      base = nil
   elseif type(base) == 'table' then
    -- our new class is a shallow copy of the base class!
      for i,v in pairs(base) do
         c[i] = v
      end
      c._base = base
   end
   -- the class will be the metatable for all its objects,
   -- and they will look up their methods in it.
   c.__index = c
   -- expose a constructor which can be called by <classname>(<args>)
   local mt = {}
   mt.__call = function(class_tbl, ...)
   local obj = {}
   setmetatable(obj,c)
   if init then
      init(obj,...)
   else
      -- make sure that any stuff from the base class is initialized!
      if base and base.init then
      base.init(obj, ...)
      end
   end
   return obj
   end
   c.init = init
   c.is_a = function(self, klass)
      local m = getmetatable(self)
      while m do
         if m == klass then return true end
         m = m._base
      end
      return false
   end
   setmetatable(c, mt)
   return c
end
_G['class'] = class
function generate_lcubix(type, path)
    if type == 'all' then
        local h = fs.open("/boot/libcubix", 'r')
        local all_lcubix = h.readAll()
        h.close()
        local h2 = fs.open(path, 'w')
        h2.write(all_lcubix)
        h2.close()
    end
end
EndFile;
File;proc/3/exe
/bin/cshell_rewrite
EndFile;
File;etc/shadow.safecopy
cubix^8875ac1c6e6ab7b10ce9162cc3cc33c2330018df9664a58deb568b3cc1cb4fef^'d9M'W_}sD!6'Pv^cubix
root^63574847901e6d7f982c30ba96c4bc46a14e9503708085f2cc45295957c23462^,6@bQ+}k7@E7q45^root
EndFile;
File;etc/fstab
/dev/hda;/;cfs;;
/dev/loop1;/dev/shm;tmpfs;;
EndFile;
File;sbin/shutdown
#!/usr/bin/env lua
--/sbin/reboot: wrapper to CC shutdown
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        print("shutdown: recieved SIGKILL")
        return 0
    end
end
function main(args)
    os.shutdown()
end
main({...})
EndFile;
File;dev/tty7
EndFile;
File;bin/cp
#!/usr/bin/env lua
--/bin/cp: wrapper to CC cp (absolute paths)
_handler = {}
_handler.signal_handler = function(sig)
    if sig == 'kill' then
        --print("cp: SIGKILL")
        return 0
    end
end
function main(args)
    if #args == 0 then
        print("usage: cp <file> <destination>")
    end
    local from, to = args[1], args[2]
    if fs.exists(os.cshell.resolve(from)) then
        fs.copy(os.cshell.resolve(from), os.cshell.resolve(to))
    else
        os.ferror("cp: input file does not exist")
        return 1
    end
    return 0
end
main({...})
EndFile;
File;dev/stdout
EndFile;
File;etc/groups
#Group file for cubix
root:0:
disk:4:cubix
lx:5:cubix
network:6:cubix
power:7:
storage:8:cubix
video:9:cubix
EndFile;
File;bin/arch
#!/usr/bin/env lua
--/bin/arch: same as uname -m
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        --print("arch: recieved SIGKILL")
        return 0
    end
end
function main(args)
    os.runfile_proc("/bin/uname", {"-m"})
end
main({...})
EndFile;
File;bin/panic
#!/usr/bin/env lua
--/bin/panic: panics the kernel
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        --print("panic: recieved SIGKILL(?????)")
        return 0
    end
end
function main()
    os.debug.kpanic('panic')
end
main({...})
EndFile;
File;bin/pwd
#!/usr/bin/env lua
--/bin/pwd: print working directory
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        --print("pwd: recieved SIGKILL")
        return 0
    end
end
function main()
    print(os.cshell.getpwd())
end
main({...})
EndFile;
File;sbin/fsck
#!/usr/bin/env lua
--/sbin/fsck: file system check
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        --print("users: recieved SIGKILL")
        return 0
    end
end
VERSION = '0.0.1'
function main(args)
    print("cubix fsck v"..VERSION)
    if #args > 1 then
        local device = args[1]
        local fs = args[2]
        if fsdrivers[fs].check then
            fsdrivers[fs].check(device)
        else
            print("check function in "..fs.." not found")
        end
    else
        print("usage: fsck <device> <filesystem>")
    end
end
main({...})
EndFile;
File;bin/cksum
#!/usr/bin/env lua
--/bin/cksum
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        --print("cksum: recieved SIGKILL")
        return 0
    end
end
--local string = require("string")
--local bit = require("bit")
local tostring = tostring
--module('crc32')
local CRC32 = {
    0x00000000, 0x77073096, 0xee0e612c, 0x990951ba,
    0x076dc419, 0x706af48f, 0xe963a535, 0x9e6495a3,
    0x0edb8832, 0x79dcb8a4, 0xe0d5e91e, 0x97d2d988,
    0x09b64c2b, 0x7eb17cbd, 0xe7b82d07, 0x90bf1d91,
    0x1db71064, 0x6ab020f2, 0xf3b97148, 0x84be41de,
    0x1adad47d, 0x6ddde4eb, 0xf4d4b551, 0x83d385c7,
    0x136c9856, 0x646ba8c0, 0xfd62f97a, 0x8a65c9ec,
    0x14015c4f, 0x63066cd9, 0xfa0f3d63, 0x8d080df5,
    0x3b6e20c8, 0x4c69105e, 0xd56041e4, 0xa2677172,
    0x3c03e4d1, 0x4b04d447, 0xd20d85fd, 0xa50ab56b,
    0x35b5a8fa, 0x42b2986c, 0xdbbbc9d6, 0xacbcf940,
    0x32d86ce3, 0x45df5c75, 0xdcd60dcf, 0xabd13d59,
    0x26d930ac, 0x51de003a, 0xc8d75180, 0xbfd06116,
    0x21b4f4b5, 0x56b3c423, 0xcfba9599, 0xb8bda50f,
    0x2802b89e, 0x5f058808, 0xc60cd9b2, 0xb10be924,
    0x2f6f7c87, 0x58684c11, 0xc1611dab, 0xb6662d3d,
    0x76dc4190, 0x01db7106, 0x98d220bc, 0xefd5102a,
    0x71b18589, 0x06b6b51f, 0x9fbfe4a5, 0xe8b8d433,
    0x7807c9a2, 0x0f00f934, 0x9609a88e, 0xe10e9818,
    0x7f6a0dbb, 0x086d3d2d, 0x91646c97, 0xe6635c01,
    0x6b6b51f4, 0x1c6c6162, 0x856530d8, 0xf262004e,
    0x6c0695ed, 0x1b01a57b, 0x8208f4c1, 0xf50fc457,
    0x65b0d9c6, 0x12b7e950, 0x8bbeb8ea, 0xfcb9887c,
    0x62dd1ddf, 0x15da2d49, 0x8cd37cf3, 0xfbd44c65,
    0x4db26158, 0x3ab551ce, 0xa3bc0074, 0xd4bb30e2,
    0x4adfa541, 0x3dd895d7, 0xa4d1c46d, 0xd3d6f4fb,
    0x4369e96a, 0x346ed9fc, 0xad678846, 0xda60b8d0,
    0x44042d73, 0x33031de5, 0xaa0a4c5f, 0xdd0d7cc9,
    0x5005713c, 0x270241aa, 0xbe0b1010, 0xc90c2086,
    0x5768b525, 0x206f85b3, 0xb966d409, 0xce61e49f,
    0x5edef90e, 0x29d9c998, 0xb0d09822, 0xc7d7a8b4,
    0x59b33d17, 0x2eb40d81, 0xb7bd5c3b, 0xc0ba6cad,
    0xedb88320, 0x9abfb3b6, 0x03b6e20c, 0x74b1d29a,
    0xead54739, 0x9dd277af, 0x04db2615, 0x73dc1683,
    0xe3630b12, 0x94643b84, 0x0d6d6a3e, 0x7a6a5aa8,
    0xe40ecf0b, 0x9309ff9d, 0x0a00ae27, 0x7d079eb1,
    0xf00f9344, 0x8708a3d2, 0x1e01f268, 0x6906c2fe,
    0xf762575d, 0x806567cb, 0x196c3671, 0x6e6b06e7,
    0xfed41b76, 0x89d32be0, 0x10da7a5a, 0x67dd4acc,
    0xf9b9df6f, 0x8ebeeff9, 0x17b7be43, 0x60b08ed5,
    0xd6d6a3e8, 0xa1d1937e, 0x38d8c2c4, 0x4fdff252,
    0xd1bb67f1, 0xa6bc5767, 0x3fb506dd, 0x48b2364b,
    0xd80d2bda, 0xaf0a1b4c, 0x36034af6, 0x41047a60,
    0xdf60efc3, 0xa867df55, 0x316e8eef, 0x4669be79,
    0xcb61b38c, 0xbc66831a, 0x256fd2a0, 0x5268e236,
    0xcc0c7795, 0xbb0b4703, 0x220216b9, 0x5505262f,
    0xc5ba3bbe, 0xb2bd0b28, 0x2bb45a92, 0x5cb36a04,
    0xc2d7ffa7, 0xb5d0cf31, 0x2cd99e8b, 0x5bdeae1d,
    0x9b64c2b0, 0xec63f226, 0x756aa39c, 0x026d930a,
    0x9c0906a9, 0xeb0e363f, 0x72076785, 0x05005713,
    0x95bf4a82, 0xe2b87a14, 0x7bb12bae, 0x0cb61b38,
    0x92d28e9b, 0xe5d5be0d, 0x7cdcefb7, 0x0bdbdf21,
    0x86d3d2d4, 0xf1d4e242, 0x68ddb3f8, 0x1fda836e,
    0x81be16cd, 0xf6b9265b, 0x6fb077e1, 0x18b74777,
    0x88085ae6, 0xff0f6a70, 0x66063bca, 0x11010b5c,
    0x8f659eff, 0xf862ae69, 0x616bffd3, 0x166ccf45,
    0xa00ae278, 0xd70dd2ee, 0x4e048354, 0x3903b3c2,
    0xa7672661, 0xd06016f7, 0x4969474d, 0x3e6e77db,
    0xaed16a4a, 0xd9d65adc, 0x40df0b66, 0x37d83bf0,
    0xa9bcae53, 0xdebb9ec5, 0x47b2cf7f, 0x30b5ffe9,
    0xbdbdf21c, 0xcabac28a, 0x53b39330, 0x24b4a3a6,
    0xbad03605, 0xcdd70693, 0x54de5729, 0x23d967bf,
    0xb3667a2e, 0xc4614ab8, 0x5d681b02, 0x2a6f2b94,
    0xb40bbe37, 0xc30c8ea1, 0x5a05df1b, 0x2d02ef8d
}
local xor = bit.bxor
local lshift = bit.blshift
local rshift = bit.brshift
local band = bit.band
function hash(str)
    str = tostring(str)
    local count = string.len(str)
    local crc = 2 ^ 32 - 1
    local i = 1
    while count > 0 do
        local byte = string.byte(str, i)
        crc = xor(rshift(crc, 8), CRC32[xor(band(crc, 0xFF), byte) + 1])
        i = i + 1
        count = count - 1
    end
    crc = xor(crc, 0xFFFFFFFF)
    -- dirty hack for bitop return number < 0
    if crc < 0 then crc = crc + 2 ^ 32 end
    return crc
end
function work_pipe(pipe)
    local k = os.lib.pipe.Pipe.copyPipe(pipe)
    pipe:flush()
    local line = k:readAll()
    local cksum = hash(line)
    print(cksum)
end
function main(args, pipe)
    if pipe ~= nil then
        work_pipe(pipe)
        return 0
    else
        if #args == 0 then
            print("usage: cksum <file>")
            print("usage(pipe): cksum")
            return 0
        end
        local file = args[1]
        print("damn son")
    end
end
main({...})
EndFile;
File;usr/manuals/time-server.man
On the subject of Time Servers
Time servers in cubix have to follow a simple syntax, when made a GET request to them, without any arguments, they need to return this:
{day,month,year,hours,minutes,seconds,}
getTime_fmt unserialises the data and it will get the current time, applying timezone calculations as it does so.
strtime(timezone1, timezone2) is the default method to get hours, minutes and seconds, all in a string
EndFile;
File;var/yapi/db/extra
lx-base;http://lkmnds.github.io/yapi/extra/lx-base.yap
lx-server;http://lkmnds.github.io/yapi/extra/lx-server.yap
lx-client;http://lkmnds.github.io/yapi/extra/lx-client.yap
lx-window;http://lkmnds.github.io/yapi/extra/lx-window.yap
pkg-dev;http://lkmnds.github.io/yapi/extra/pkg-dev.yap
libcubix-dev;http://lkmnds.github.io/yapi/extra/libcubix-dev.yap
EndFile;
File;usr/manuals/procmngr.man
On the subject of the Process Manager
Primary task:
    Process Manager creates, kills and interfaces process with the userspace.
  Global variables:
    -os.processes [table] - shows the list of actual processes running at the system
    -os.pid_last [number] - the last PID of a process, used to create the PID of the next process
    -os.signals [table] - system signals(SIGKILL, SIGINT, SIGILL, SIGFPE...)
  Functions:
    -Process related:
      -os.call_handle(process, handler)
        -calls a process _handler, which calls a program _handler
      -os.send_signal(process, signal)
        -sends a signal to a process, depending of what signal
          -SIGKILL: kills the process and its children
      -os.terminate(process)
        -terminates a process, first it calls its _handle using os.call_handle
      -os.run_process(process, arguments)
        -runs a process with its arguments in a table
      -os.set_child(parent, child)
        -sets a relation between parent process and child process
      -os.set_parent(child, parent)
        -inverse of os.set_child
      -os.new_process(executable)
        -creates a process
      -os.runfile_proc(executable, arguments, parent)
        -creates a process, set its parent and runs it with specified arguments, after that, sends a SIGKILL to it
 * Secondary task:
    The concept of /proc is around Managed Files, they're files that the kernel can show information to the user.
     * /proc/cpuinfo
     * /proc/temperature
     * /proc/partitions
EndFile;
File;bin/dmesg
#!/usr/bin/env lua
--/bin/dmesg: debug messages
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        --print("dmesg: recieved SIGKILL")
        return 0
    end
end
function main(args)
    local debug_file = fs.open("/tmp/syslog", 'r')
    print(debug_file.readAll())
    debug_file.close()
end
main({...})
EndFile;
File;sbin/init
#!/usr/bin/env lua
--/sbin/init: manages (some part of) the user space
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        _G['CANT_HANDLE_THE_FORCE'] = true
        os.ferror("init: SIGKILL")
    end
end
local RUNLEVELFUNC = {}
function runlevel_0()
    if permission.grantAccess(fs.perms.ROOT) then
        os.shutdown()
    end
    permission.default()
end
function runlevel_1()
    --single-user
    for k,v in pairs(fs.list("/etc/rc1.d/")) do
        shell.run(fs.combine("/etc/rc1.d",v))
    end
    while true do
        os.runfile_proc("/sbin/login")
    end
end
function runlevel_2()
    --multiuser(all ttys running login) withtout network service
    loadmodule("multiuser", "/lib/multiuser/multiuser.lua")
end
function runlevel_3()
    --multiuser and network service
    os.internals.loadmodule("network", "/lib/net/network.lua")
    os.internals.loadmodule("multiuser", "/lib/multiuser/multiuser.lua")
end
function runlevel_5()
    --start LuaX, multiuser and network support
    os.internals.loadmodule("network", "/lib/net/network.lua")
    os.internals.loadmodule("multiuser", "/lib/multiuser/multiuser.lua")
    os.runfile_proc("/bin/lx", {'start'})
end
function runlevel_6()
    --reboot
    if permission.grantAccess(fs.perms.ROOT) then
        os.debug.debug_write("[init] rebooting with root permission")
        os.runfile_proc("/sbin/reboot")
    else
        --rebooting without permissions
        os.debug.debug_write("[init] rebooting withOUT root permission")
        os.reboot()
    end
    permission.default()
end
RUNLEVELFUNC[0] = runlevel_0
RUNLEVELFUNC[1] = runlevel_1
RUNLEVELFUNC[2] = runlevel_2
RUNLEVELFUNC[3] = runlevel_3
RUNLEVELFUNC[5] = runlevel_5
RUNLEVELFUNC[6] = runlevel_6
function main(args)
    if args[1] ~= nil then
        runlevel = tonumber(args[1])
    else
        if fs.exists("/etc/inittab") then
            local inittab = fs.open("/etc/inittab", 'r')
            local r = os.strsplit(inittab.readAll(), ':')[2]
            runlevel = tonumber(r)
            inittab.close()
        else
            os.debug.kpanic("[init] /etc/inittab not found")
            return 1
        end
    end
    os.lib.tty.current_tty("/dev/tty1")
    RUNLEVELFUNC[runlevel]()
    return 0
end
main({...})
EndFile;
File;proc/temperature
EndFile;
File;bin/who
#!/usr/bin/env lua
--/bin/whoami: who am i?
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        --print("who: recieved SIGKILL")
        return 0
    end
end
function main(args)
    local fsttime = fs.open("/proc/sttime", 'r')
    local ST_TIME = fsttime.readAll()
    fsttime.close()
    local cuser = fs.open("/tmp/current_user", 'r')
    local current_user = cuser.readAll()
    cuser.close()
    print(current_user .. '   :0  ' .. textutils.formatTime(tonumber(ST_TIME), false) .. '  (:0)')
end
main({...})
EndFile;
File;dev/tty9
EndFile;
File;usr/games/gameoflife
board = {}
tArgs = { ... }
generation = 0
sleeptime = 0.5
if(tArgs[1] == "left" or tArgs[1] == "right" or tArgs[1] == "top" or tArgs[1] == "bottom" or tArgs[1] == "front" or tArgs[1] == "back")then
	mon = peripheral.wrap(tArgs[1])
else
	mon = term
end
if(mon.isColor() or mon.isColor)then
	colored = true
else
	colored = false
end
w, h = mon.getSize()
for x = 1, w do
	board[x] = {}
	for y = 1, h do
		board[x][y] = 0
	end
end
function drawScreen()
	w, h = mon.getSize()
	for x = 1, w do
		for y = 1, h do
			nei = getNeighbours(x, y)
			if(board[x][y] == 1)then
				if colored then
					if(nei < 2 or nei > 3)then
						mon.setBackgroundColor(colors.red)
					else
						mon.setBackgroundColor(colors.green)
					end
				else
					mon.setBackgroundColor(colors.white)
				end
			else
				if colored then
					if(nei == 3)then
						mon.setBackgroundColor(colors.yellow)
					else
						mon.setBackgroundColor(colors.black)
					end
				else
					mon.setBackgroundColor(colors.black)
				end
			end
			mon.setCursorPos(x, y)
			mon.write(" ")
		end
	end
	mon.setCursorPos(1,1)
	if colored then
		mon.setTextColor(colors.blue)
	end
	mon.write(generation)
end
function getNeighbours(x, y)
	w, h = mon.getSize()
	total = 0
	if(x > 1 and y > 1)then if(board[x-1][y-1] == 1)then total = total + 1 end end
	if(y > 1)then if(board[x][y-1] == 1)then total = total + 1 end end
	if(x < w and y > 1)then if(board[x+1][y-1] == 1)then total = total + 1 end end
	if(x > 1)then if(board[x-1][y] == 1)then total = total + 1 end end
	if(x < w)then if(board[x+1][y] == 1)then total = total + 1 end end
	if(x > 1 and y < h)then if(board[x-1][y+1] == 1)then total = total + 1 end end
	if(y < h)then if(board[x][y+1] == 1)then total = total + 1 end end
	if(x < w and y < h)then if(board[x+1][y+1] == 1)then total = total + 1 end end
	return total
end
function compute()
	w, h = mon.getSize()
	while true do
		newBoard = {}
		for x = 1, w do
			newBoard[x] = {}
			for y = 1, h do
				nei = getNeighbours(x, y)
				if(board[x][y] == 1)then
					if(nei < 2)then
						newBoard[x][y] = 0
					elseif(nei > 3)then
						newBoard[x][y] = 0
					else
						newBoard[x][y] = 1
					end
				else
					if(nei == 3)then
						newBoard[x][y] = 1
					end
				end
			end
		end
		board = newBoard
		generation = generation + 1
		sleep(sleeptime)
	end
end
function loop()
	while true do
		event, variable, xPos, yPos = os.pullEvent()
		if event == "mouse_click" or event == "monitor_touch" or event == "mouse_drag" then
			if variable == 1 then
				board[xPos][yPos] = 1
			else
				board[xPos][yPos] = 0
			end
		end
		if event == "key" then
			if tostring(variable) == "28" then
				return true
			elseif tostring(variable) == "57" then
				if(mon.isColor() or mon.isColor)then
					colored = not colored
				end
			elseif tostring(variable) == "200" then
				if sleeptime > 0.1 then
					sleeptime = sleeptime - 0.1
				end
			elseif tostring(variable) == "208" then
				if sleeptime < 1 then
					sleeptime = sleeptime + 0.1
				end
			end
		end
		drawScreen()
	end
end
function intro()
	mon.setBackgroundColor(colors.black)
	mon.clear()
	mon.setCursorPos(1,1)
	mon.write("Conway's Game Of Life")
	mon.setCursorPos(1,2)
	mon.write("It is a game which represents life.")
	mon.setCursorPos(1,3)
	mon.write("The game runs by 4 basic rules:")
	mon.setCursorPos(1,4)
	mon.write("1. If a cell has less than 2 neighbours, it dies.")
	mon.setCursorPos(1,5)
	mon.write("2. If a cell has 2 or 3 neightbours, it lives.")
	mon.setCursorPos(1,6)
	mon.write("3. If a cell has more than 3 neighbours, it dies.")
	mon.setCursorPos(1,7)
	mon.write("4. If a cell has exactly 3 neighbours it is born.")
	mon.setCursorPos(1,9)
	mon.write("At the top left is the generation count.")
	mon.setCursorPos(1,10)
	mon.write("Press spacebar to switch between color modes")
	mon.setCursorPos(1,11)
	mon.write("Press enter to start  the game")
	mon.setCursorPos(1,13)
	mon.write("Colors:")
	mon.setCursorPos(1,14)
	mon.write("Red - Cell will die in next generation")
	mon.setCursorPos(1,15)
	mon.write("Green - Cell will live in next generation")
	mon.setCursorPos(1,16)
	mon.write("Yellow - Cell will be born in next generation")
	mon.setCursorPos(1,18)
	mon.write("Press any key to continue!")
	event, variable, xPos, yPos = os.pullEvent("key")
end
intro()
drawScreen()
while true do
	loop()
	parallel.waitForAny(loop, compute)
end
EndFile;
File;lib/luaX/lxWindow.lua
--/lib/luaX/lxWindow.lua
--luaX window library
--function: create, delete, buttons, etc
if not _G['LX_CLIENT_LOADED'] then
    os.ferror("lxWindow: lxClient not loaded")
    return 0
end
local window_data = {}
local windows = {}
function unload_all()
    windows = {}
end
function get_window_location()
    return {5 + #windows, 5 + #windows}
end
Window = {}
Window.__index = Window
function Window.new(path_lxw)
    local inst = {}
    setmetatable(inst, Window)
    inst.title = 'luaX Window'
    inst.focus = false
    inst.actions = {}
    inst.coords = {}
    inst.elements = {}
    inst.lxwFile = path_lxw
    return inst
end
function Window:add(element, x, y)
    local i = #self.elements + 1
    self.coords[i] = {x,y}
    self.elements[i] = element
end
function Window:call_handler(ev)
    if self.handler == nil then
        os.lib.lxServer.lxError("lxWindow: no handler set")
        return 0
    end
    print("call self.handler "..type(ev))
    self.handler(ev)
end
function Window:set_handler(f)
    self.handler = f
end
function Window:set_title(newtitle)
    self.title = newtitle
end
function write_window(window_location, lenX, lenY, window_title)
    local locX = window_location[1]
    local locY = window_location[2]
    --basic window borders
    os.lib.lxServer.write_rectangle(locX-1, locY-1, lenY+2, lenX+2, colors.black)
    os.lib.lxServer.write_solidRect(locX, locY, lenY, lenX, colors.white)
    --window title
    os.lib.lx.write_string(window_title, locX+3, locY-1, colors.white, colors.black)
end
function Window:show()
    tx = self.lxwdata['hw'][1]
    ty = self.lxwdata['hw'][2]
    sx = get_window_location()[1]
    sy = get_window_location()[2]
    write_window(get_window_location(), tx, ty, self.title)
    for i=1,#self.elements do
        element = self.elements[i]
        coordinates = self.coords[i]
        --print("show " .. coordinates[1] ..';'.. coordinates[2])
        element:_show(sx, sy)
    end
    while true do
        local e, p1, p2, p3, p4, p5 = os.pullEvent()
        local event = {e, p1, p2, p3, p4, p5}
        print(type(event))
        self:call_handler(event)
    end
end
function nil_handler(event)
    return nil
end
--[[
name:lxterm
hw:9,30
changeable:false
main:lxterm.lua
]]
function parse_lxw(path)
    local handler = fs.open(path, 'r')
    if handler == nil then
        lxError("lxWindow", "File not found")
        return false
    end
    local _data = handler.readAll()
    handler.close()
    local lxwdata = {}
    local data = os.strsplit(_data, '\n')
    for k,v in pairs(data) do
        if string.sub(v, 1, 1) ~= '#' then --comments
            --comparisons here
            local splitted_line = os.strsplit(v, ':')
            if splitted_line[1] == 'name' then
                lxwdata['name'] = splitted_line[2]
            elseif splitted_line[1] == 'hw' then
                lxwdata['hw'] = os.strsplit(splitted_line[2], ',')
            elseif splitted_line[1] == 'changeable' then
                lxwdata['changeable'] = splitted_line[2]
            elseif splitted_line[1] == 'main' then
                lxwdata['mainfile'] = splitted_line[2]
            end
        end
    end
    window_data[lxwdata['name']] = lxwdata
    return lxwdata
end
function main_run(file, window)
    --run a file with determined _ENV
    --it seems that i can not do this so i've put the window object into args
    os.run({}, file, {window})
end
function Window:load_itself()
    os.debug.debug_write("[lxWindow] load lxw: "..self.lxwFile, false)
    local lxwdata = parse_lxw(self.lxwFile)
    if lxwdata == false then
        lxError("lxWindow", "cannot load window")
        return 1
    else
        os.debug.debug_write("[lxWindow] load window: "..lxwdata['name'], false)
        self.lxwdata = lxwdata
        main_run(lxwdata['mainfile'], self)
    end
end
Object = class(function(self, xpos, ypos, x1pos, y2pos)
    self.posX = xpos
    self.posY = ypos
    self.finX = x1pos
    self.finY = y2pos
end)
Label = class(Object, function(self, label, x1, y1)
    local lenlabel = #label
    Object.init(self, x1, y1, x1, y1+lenlabel)
    self.ltext = label
end)
function Label:_show(location_x, location_y)
    os.lib.lx.write_string(self.ltext,
    location_x,
    location_y,
    os.lib.lx.random_color(), os.lib.lx.random_color()
    )
end
EventObject = class(Object, function(self, x, y, x1, y1)
    Object.init(self, x, y, x1, y1)
end)
function EventObject:_addListener(listener_func)
    self['listener'] = listener_func
end
--TextField class
TextField = class(EventObject, function(self, x, y, tfX, tfY)
    EventObject.init(self, x, y, tfX, tfY)
end)
tf1 = TextField(0, 0)
--create CommandBox
CommandBox = class(TextField, function(self, x, y, shellPath)
    TextField.init(self, x, y, x+20, y+20)
    self.spath = shellPath
    self.cmdbuffer = ''
    local cbox_listener = {} --default event listener
    function cbox_listener:evPerformed(event)
        print(type(event))
        if event[1] == 'key' then
            if event[2] == 98 then
                self.send_command(self.cmdbuffer)
                output = self.get_data()
                self.append_text(output)
            end
        end
    end
    self.event_handler = cbox_listener['evPerformed']
    self:addEventListener(cbox_listener)
end)
function CommandBox:_show(locX, locY)
    wd = window_data['lxterm']
    os.lib.lxServer.write_solidRect(locX, locY, wd['hw'][2], wd['hw'][1], colors.blue)
end
function CommandBox:addEventListener(listener_obj)
    self:_addListener(listener_obj['evPerformed'])
end
function libroutine()
end
EndFile;
File;proc/1/cmd
/sbin/init 
EndFile;
File;proc/3/cmd
/bin/cshell_rewrite 
EndFile;
File;bin/eject
#!/usr/bin/env lua
--/bin/eject: wrapper to CC "eject"
_handler = {}
_handler.signal_handler = function(sig)
    if sig == 'kill' then
        --print("eject: SIGKILL")
        return 0
    end
end
function main(args)
    if #args == 0 then print("usage: eject <side> ") return 0 end
    local side = args[1]
    disk.eject(side)
end
main({...})
EndFile;
File;g/lxterm/lxterm.lua
--/g/lxterm/lxterm.lua
--the lxterm.lxw will load lxterm.lua, which will configure the window and register the events as expected
local windowl = ...
function main()
    if not os.lib.lxWindow then
        os.ferror("lxterm: lxWindow not loaded")
        return 0
    end
    local Main = windowl[1]
    --local l1 = os.lib.lxWindow.Label('TestLabel', 0, 0)
    --Main:add(l1, 5, 5)
    --Main:set_handler(os.lib.lxWindow.nil_handler)
    --Main:show()
    Main:set_title("luaX Terminal")
    local cbox1 = os.lib.lxWindow.CommandBox(10, 10, '/sbin/login')
    Main:add(cbox1, 0, 0)
    Main:set_handler(cbox1.event_handler)
    --Main:show()
    while true do
        os.runfile_proc(cbox1.spath)
    end
end
main()
EndFile;
File;sbin/pm-suspend
#!/usr/bin/env lua
--/bin/pm-suspend: wrapper to ACPI suspend function
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        os.debug.debug_write("pm-suspend: recieved SIGKILL", false)
        return 0
    end
end
function main(args)
    os.suspend()
    return 0
end
main({...})
EndFile;
File;var/yapi/cache/bootsplash.yap
Name;bootsplash
Version;0.0.1
Build;3
Author;Lukas Mendes
Email-Author;lkmnds@gmail.com
Description;Boot Splash module for cubix
Dep;base
File;/lib/modules/bootsplash
--bootsplash module
bootsplash = {}
function bs_clear_screen()
    print("") --pog by jao
    term.clear()
    term.setCursorPos(1,1)
end
function textMode()
    while os.__boot_flag do
        term.clear()
        term.setCursorPos(19,9)
        write("C")
        if not os.__boot_flag then
            bs_clear_screen()
            return 0
        end
        sleep(.5)
        term.setCursorPos(20,9)
        write("u")
        if not os.__boot_flag then
            bs_clear_screen()
            return 0
        end
        sleep(.5)
        term.setCursorPos(21,9)
        write("b")
        if not os.__boot_flag then
            bs_clear_screen()
            return 0
        end
        sleep(.5)
        term.setCursorPos(22,9)
        write("i")
        if not os.__boot_flag then
            bs_clear_screen()
            return 0
        end
        sleep(.5)
        term.setCursorPos(23,9)
        write("x")
        if not os.__boot_flag then
            bs_clear_screen()
            return 0
        end
        sleep(.5)
    end
end
bootsplash.load_normal = function()
    print("loading load_normal...")
    local h = fs.open("/etc/bootsplash.default", 'r')
    if h == nil then
        os.debug.kpanic("bootsplash: error opening bootsplash.default")
    end
    local splash = h.readAll()
    h.close()
    if splash == 'text' then
        print("running text mode")
        parallel.waitForAll(textMode, cubix.boot_kernel)
    else
        os.debug.kpanic("bootsplash: invalid bootscreen")
    end
end
_G['bootsplash'] = bootsplash
EndFile;
File;/usr/bin/bootsplash
#!/usr/bin/env lua
--bootsplash
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        os.debug.debug_write("bootsplashd: SIGKILL'd!", false)
        return 0
    end
end
AUTHOR = "Lukas Mendes"
VERSION = '0.0.1'
function main(args)
    if args[1] == 'set-theme' then
        local theme = args[2]
        if theme == 'text' then
            local h = fs.open("/etc/bootsplash.default", 'w')
            h.write('text')
            h.close()
        elseif fs.exists("/usr/lib/bootsplash/"..theme..'.theme') then
            ferror("Still coming...")
        else
            ferror("theme not found")
            return 0
        end
    else
        print("usage: bootsplash <mode>")
    end
end
main({...})
EndFile;
EndFile;
File;dev/tty2
EndFile;
File;usr/manuals/acpi.man
ACPI Module
ACPI or Advanced Configuration and Power Interface is a interface for the OS to make power commands right away, without the direct interference on the hardware.
In CC, acpi works by making some cleanup tasks(deleting /tmp and /proc/<number>) and killing processes before the CC (shutdown/reboot) kicks in
Suspend(acpi_suspend or os.suspend): acpi just suspends the computer until a key is pressed
Hibernate(acpi_hibernate or os.hibernate): does not work now
EndFile;
File;lib/devices/random_device.lua
function rawread()
    while true do
        local sEvent, param = os.pullEvent("key")
        if sEvent == "key" then
            if param == 28 then
                break
            end
        end
    end
end
function print_rndchar()
    local cache = tostring(os.clock())
    local seed = 0
    for i=1,#cache do
        seed = seed + string.byte(string.sub(cache,i,i))
    end
    math.randomseed(tostring(seed))
    while true do
        s = string.char(math.random(0, 255))
        io.write(s)
    end
end
dev_random = {}
dev_random.device = {}
dev_random.name = '/dev/random'
dev_random.device.device_write = function (message)
    print("cannot write to /dev/random")
end
dev_random.device.device_read = function (bytes)
    local crand = {}
    if bytes == nil then
        crand = coroutine.create(print_rndchar)
        coroutine.resume(crand)
        while true do
            local event, key = os.pullEvent( "key" )
            if event and key then
                break
            end
        end
    else
        local cache = tostring(os.clock())
        local seed = 0
        for i=1,#cache do
            seed = seed + string.byte(string.sub(cache,i,i))
        end
        math.randomseed(tostring(seed))
        result = ''
        for i = 0, bytes do
            s = string.char(math.random(0, 255))
            result = result .. s
        end
        return result
    end
    return 0
end
return dev_random
EndFile;
