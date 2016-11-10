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
                ferror("test_error[%s]: %s", group, err)
                return false
            end
        end
    end
    printf("libtest: all tests ended successfully")
    return true
end

function t_number_range(x, a, b)
    --[[
        t_number_range(
            x, a, b : int
        )
        Already check if (a <= x <= b)
    ]]
    local minrange = a <= x
    local maxrange = x <= b
    if minrange and maxrange then
        return true, ''
    else
        printf("val: %d", x)
        printf("minrange(%d): %s", a, tostring(minrange))
        printf("maxrange(%d): %s", b, tostring(maxrange))
        return false, ''
    end
end
