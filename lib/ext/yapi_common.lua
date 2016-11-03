
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
        elseif tokens[1] == '}' then
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

    for _,repo_type in ipairs(repos) do
        for _,repo in ipairs(repo_type) do
            total_repos = total_repos + 1
        end
    end

    yapi_job_set(total_repos)

    for _,repo_type in ipairs(repos) do
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

function Yapidb:_load_db(repo)
    local splitted_spaces, tokens, current_package, package_name

    local path = fs.combine(yapi_database_dir..'/', repo['name'])
    local repo_data = fs_readall(path)
    if not repo_data then return false end

    --[[
    Formatting for packages in repofiles:

    p package-name {
        dep dep1,dep2,dep3,...,depN
        build Number
        url url_to_yapfile
    }
    ]]

    local db_repo = {}

    -- read through repo_data and add package entries to self.db
    for _,line in ipairs(string.splitlines(repo_data)) do
        tokens = string.split(line, ' ')

        if string.sub(line, 1, 1) == 'p' then
            -- check if the last token is {
            if tokens[3] ~= '{' then
                ferror("[ydb:_load_db] t[3] ~= '{'")
                return false
            end

            -- get package name
            package_name = tokens[2]

            db_repo[package_name] = {}
            current_package = package_name

        elseif tokens[1] == 'build' then
            local pkgbuild = tokens[2]
            db_repo[current_package]['build'] = tonumber(pkgbuild)

        elseif tokens[1] == 'dep' then
            local str_pkg_dep = tokens[2]
            local pkg_dep = string.split(str_pkg_dep, ',')
            db_repo[current_package]['depends'] = pkg_dep

        elseif tokens[1] == 'url' then
            local url = tokens[2]
            local yapurl = ''
            if url == 'default' then
                local build = db_repo[current_package]['build']
                yapurl = rprintf("http://%s/%s/%s-%d.yap", yapi_server_url, repo['name'],
                    current_package, build)
            else
                yapurl = url
            end
            db_repo[current_package]['url'] = yapurl

        elseif line == '}' then
            current_package = nil
        end
    end

    self.db[repo['name']] = db_repo

    return true
end

function Yapidb:pkg_get_data(pkgname)
    for _,repodb in pairs(self.db) do
        for pkg_name,pkg_data in pairs(repodb) do
            if pkg_name == pkgname then
                return pkg_data
            end
        end
    end
    return false
end

function Yapidb:_load_repos()
    local repos = yapi_get_sources()

    for _,repo_type in ipairs(repos) do
        for _,repo in ipairs(repo_type) do
            if not self:_load_db(repo) then
                return false
            end
        end
    end

    return true
end

function Yapidb:load_repos()
    if not self:_load_repos() then
        ferror("[ydb:load_repos] error loading repofiles")
        return false
    end
    return true
end

function Yapidb:package_find(pkgwanted)
    if pkgwanted == nil or pkgwanted == '' then return false end
    for _,repodb in pairs(self.db) do
        for pkgname,_ in pairs(repodb) do
            if pkgname == pkgwanted then return true end
        end
    end
    return false
end

function Yapidb:make_deps(listpkgs)
    local new_list = {}
    for _,pkgname in ipairs(listpkgs) do
        local pkg_data = self:pkg_get_data(pkgname)
        if pkg_data['depends'] then
            for _,dep in ipairs(pkg_data['depends']) do
                if dep ~= '' then
                    local deps_of_dep = self:make_deps({dep})
                    for _,dep_of_dep in pairs(deps_of_dep) do
                        table.insert(new_list, dep_of_dep)
                    end
                end
            end
        end
        table.insert(new_list, pkgname)
    end

    return new_list
end
