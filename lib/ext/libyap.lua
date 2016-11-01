
local kv_keys = { 'name', 'version', 'build', 'author', 'description',
    'email-author', 'url', 'packager', 'arch', 'license'}

local not_nil_entries = { 'name', 'version', 'build', 'author', 'description',
    'email-author' }

function check_nil_entries(tbl, entries)
    for _,entry in ipairs(entries) do
        if tbl[entry] == nil then
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

function check_yap(ydata)
    local nxt = check_nil_entries(ydata, not_nil_entries)
    while nxt do
        ferror(rprintf("check_yap: %s == nil", nxt))
        nxt = check_nil_entries(ydata, not_nil_entries)
    end

    return nxt
end

function test()
    local y = parse_yap(fs_readall("/var/yapi/test.yap"))
    print(check_yap(y))
end
