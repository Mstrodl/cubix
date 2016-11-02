
-- configuration
local yapi_default_dir = '/var/yapi'

local yapi_cache_dir = '/var/cache/yapi'
local yapi_database_dir = fs.combine(yapi_default_dir, '/db')
local yapi_local_file = fs.combine(yapi_default_dir, '/local')

function yapi_mk_struct()
    fs.makeDir(yapi_default_dir)
    fs.makeDir(yapi_cache_dir)
    fs.makeDir(yapi_database_dir)
    fs.open(yapi_local_file, 'a').close()

    return true
end

function yapi_check_struct()
    if not fs.exists(yapi_default_dir) then return false end
    if not fs.exists(yapi_cache_dir) then return false end
    if not fs.exists(yapi_database_dir) then return false end
    if not fs.exists(yapi_local_file) then return false end

    return true
end

function yapi_mkstr(yapd)
    return rprintf("%s-%s", yapd['name'], yapd['version'])
end
