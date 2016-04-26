
os.internals.loadmodule("bbshub", "/lib/random/generator/blumblumshub.lua")
gen = nil

function initrand()
    local s = entropyman.export_seed()
end

function getrand()
    return os.bbshub.next_num(os.bbshub)
end

function libroutine()
    _G['getrandom'] = getrand
end
