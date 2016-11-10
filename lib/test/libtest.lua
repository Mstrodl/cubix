--[[
    libtest.lua - manage unit tests from various parts of the cubix kernel
]]

local tests = {}

Test = class(function(self, mod_to_test, desc_test, func)
    -- module to test, description, and a function to test the module
    self.module = mod_to_test
    self.desc = desc_test
    self.func = func
end)

function add_test(test)
    if not tests[test.module] then
        tests[test.module] = {}
    end
    table.insert(tests[test.module], test)
end

function run_tests()
    for module,tests_module in pairs(tests) do
        printf("running tests for module %s", module)
        for _,test in ipairs(tests_module) do
            printf("Running: %s", test.desc)
            if not test.func() then
                ferror("ERROR running test, aborting")
                return false
            end
        end
    end
    printf("all tests ended")
    return true
end
