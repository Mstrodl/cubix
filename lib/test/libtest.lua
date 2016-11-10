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
    for group, tests_group in pairs(tests) do
        printf("running tests for group %s", group)

        for _, test in ipairs(tests_group) do
            printf("Running: %s", test.desc)
            local ok, err = test.func()
            if not ok then
                ferror("ERROR[%s]: %s", group, err)
                return false
            end
        end
    end
    printf("all tests ended")
    return true
end
