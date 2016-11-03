
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

local total_jobs = 0
local done_jobs = 0

function yapi_job_set(jobs)
    total_jobs = jobs
end

function yapi_job_next()
    done_jobs = done_jobs + 1
end

function yapi_job_message(...)
    write(rprintf("(%d/%d) ", done_jobs, total_jobs))
    printf(...)
end

function yapi_download_file(url)
    url = 'http://' .. url
    local splitted = string.split(url, '/')
    local requesting = true

    http.request(url)

    while requesting do
        local ev, url, httphandler = os.pullEvent()
        if ev == 'http_success' then
            local str_result = httphandler.readAll()
            httphandler.close()
            return str_result

        elseif ev == 'http_failure' then
            requesting = false
            return {false, httphandler}
        end
    end
end

function yapi_mkstr(yapd)
    return rprintf("%s-%s", yapd['name'], yapd['version'])
end

function yapi_upd_one_repo(repo)
    --write("updating "..repo['name']..' ')
    local server_path = rprintf("%s%s", repo['server'], repo['name'])

    local k = yapi_download_file(server_path)
    if type(k) == 'table' then
        printf("error updating %s: %s", repo['name'], k[2])
        return false
    end

    -- write to repofile
    local repofile_handler = fs.open(rprintf("%s/%s", yapi_database_dir, repo['name']), 'w')
    if not repofile_handler then return false end
    repofile_handler.write(k)
    repofile_handler.close()

    return true
end

function yapi_get_sources()
    -- get sources file
    local sources_data = fs_readall("/var/yapi/sources")
    if not sources_data then
        return false
    end

    local current = {}
    local repos = {
        [1] = {},
        [2] = {},
        [3] = {},
        [4] = {}
    }

    for _,line in ipairs(string.splitlines(sources_data)) do
        local tokens = string.split(line, ' ')
        if tokens[1] == 'repo' then
            current['name'] = tokens[2]
        elseif tokens[1] == 'end' then
            -- insert into repos
            table.insert(repos[current['type']], current)
            current = {}
        elseif tokens[1] == 'server' then
            current['server'] = tokens[2]
        elseif tokens[1] == 'type' then
            --[[
            Types:
            type 1 repository: Core repository, the first to download
            type 2 repository: Local repositories, maintained on disk
            type 3 repository: Extra repositories, downloaded after core
            type 4 repository: Community repos, if any error happens, they won't not be downloaded
            ]]
            current['type'] = tonumber(tokens[2])
        end
    end

    return repos
end

function yapi_update_repos()
    local repos = yapi_get_sources()
    local total_repos = 0
    local jobs = 0

    for _,repo_type in pairs(repos) do
        for _,repo in ipairs(repo_type) do
            total_repos = total_repos + 1
        end
    end

    yapi_job_set(total_repos)

    for _,repo_type in pairs(repos) do
        for _,repo in ipairs(repo_type) do
            yapi_job_next()
            yapi_job_message('updating %s', repo['name'])
            if not yapi_upd_one_repo(repo) then return false end
        end
    end

    --TODO: management for local repositories

    return true
end

-- database model and calls

Yapidb = class(function(self)
    self.db = {}
    self.installed = {}
    self.localdb = {}
end)

function Yapidb:usual_check()
    --TODO: add conflict checking
    printf("checking conflicts...")
    return true
    --return self:check_conflicts()
end

function Yapidb:_load_local()
    local local_file = fs_readall(yapi_local_file)
    local res
    if not local_file then return false end
    res = textutils.unserialize(local_file)
    if not res then return false end
    self.localdb = res
    return true
end

function Yapidb:load_local()
    if not self:_load_local() then
        ferror("[ydb:load_local] error loading local file")
        return false
    end
    return true
end

function Yapidb:_save_local()
    local new_local_file = textutils.serialize(self.localdb)
    if not new_local_file then return false end
    return fs_writedata(yapi_local_file, new_local_file)
end
