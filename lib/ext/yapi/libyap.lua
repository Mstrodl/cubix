--[[
    libyap.lua - Library for the YAP package format.
]]

-- import libcompress
libcompress = cubix.load_file("/lib/ext/compression.lua")

-- initialize LZW Instance
local yap_lzw = libcompress.LZW()

local kv_keys = { 'name', 'version', 'build', 'author', 'description',
    'email-author', 'url', 'packager', 'arch', 'license'}

local not_nil_entries = { 'name', 'version', 'build', 'author', 'description',
    'email-author' }

function check_nil_entries(tbl, entries)
    for _,entry in ipairs(entries) do
        if tbl[entry] == nil or tbl[entry] == '' then
            return entry
        end
    end
    return false
end

function parse_yap(data)
    local result = {}
    result['depends'] = {}
    result['optdepend'] = {}
    result['folders'] = {}
    for _,line in ipairs(string.splitlines(data)) do
        local d = string.split(line, '=')
        local decl = string.split(line, ';')
        local key = d[1]

        if table.exists(key, kv_keys) then
            result[key] = d[2]
        elseif key == 'depend' then
            result['dep_str'] = p[2]
            table.insert(result['dep'], string.split(p[2], ':'))
        elseif key == 'optdepend' then
            result['optdep_str'] = p[2]
            table.insert(result['optdepend'], string.split(p[2], ':'))
        elseif decl[1] == 'folder' then
            table.insert(result['folders'], f[2])
        else
            ferror(rprintf("unrecognized key: %s", key))
            return nil
        end
    end
    return result
end

function yap_check(ydata)
    if type(ydata) ~= "table" then return true end

    local nxt = check_nil_entries(ydata, not_nil_entries)
    while nxt do
        ferror("check_yap: %s == nil", nxt)
        if nxt then return true end
        nxt = check_nil_entries(ydata, not_nil_entries)
    end

    return nxt
end

function yap_decompress_files(ydata)
    local res = {}
    for k, compressed_data in pairs(ydata['files']) do
        local decompressed = yap_lzw:decompress(compressed_data)
        if not decompressed then
            return nil
        end
        res[k] = decompressed
    end
end

function yap_install(ydata)
    for _, folder in ipairs(ydata['folders']) do
        if not fs.makeDir(folder) then
            return false
        end
    end

    local decompressed_files = yap_decompress_files(ydata)

    -- if any error happened decompressing, raise error
    if not decompressed_files then
        return false
    end

    for path, data in pairs(decompressed_files) do
        fs_writedata(path, data)
    end

    return true
end

function test()
    local y = parse_yap(fs_readall("/var/yapi/test.yap"))
    yap_check(y)
end
