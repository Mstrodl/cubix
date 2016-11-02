
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

function yapi_get_sources()
    -- get sources file
    local sources_data = fs_readall("/var/yapi/sources")
    if not sources_data then
        return false
    end

    local current = {}
    local repos = {
        [0] = {},
        [1] = {},
        [2] = {},
        [3] = {}
    }

    for _,line in ipairs(string.splitlines(sources_data)) do
        local tokens = string.split(line, ' ')
        if tokens[1] == 'repo' then
            current['name'] = tokens[2]
        elseif tokens[1] == 'end' then
            -- insert into repos
            table.insert(repos[current['type']], current)
        elseif tokens[1] == 'server' then
            current['server'] = tokens[2]
        elseif tokens[1] == 'type' then
            --[[
            Types:
            type 0 repository: Core repository, the first to download
            type 1 repository: Local repositories, maintained on disk
            type 2 repository: Extra repositories, downloaded after core
            type 3 repository: Community repos, if any error happens, they won't not be downloaded
            ]]
            current['type'] = tonumber(tokens[2])
        end
    end

    return repos
end

function yapi_update_repos()
    local repos = yapi_get_sources()

    for _,repo in ipairs(repos[0]) do
        yapi_upd_one_repo(repo)
    end

    --TODO: management for local repositories

    for _,repo in ipairs(repos[2]) do
        yapi_upd_one_repo(repo)
    end

    for _,repo in ipairs(repos[3]) do
        yapi_upd_one_repo(repo)
    end
end

-- database model and calls

Yapidb = class(function(self)
    self.db = {}
    self.installed = {}
end)

function Yapidb:update_one_repo(repo)
    -- get repo from database file, and get the file accordingly
end
