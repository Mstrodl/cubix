Name;devscripts
Version;0.0.3
Build;7
Author;Lukas Mendes
Email-Author;lkmnds@gmail.com
Description;Developer Scripts for Cubix
Dep;base
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
if not IS_CUBIX then
    main()
end
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
EndFile;