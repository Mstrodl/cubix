
Test = lib.test.Test

test_rand_0 = Test('rand', 'range of rand()', function()
    local n = rand()
    local minrange = 0 <= n
    local maxrange = n <= math.pow(2, 32)-1
    if minrange and maxrange then
        return true, ''
    else
        print("minrange(0)", minrange)
        print("maxrange(2^32-1)", maxrange)
        return false, ''
    end
end)

test_rand_1 = Test('rand', 'range of randrange()', function()
    local min = rand()
    local max = rand()
    if min > max then
        local tmp = min
        min = max
        max = tmp
    end

    local r_num = randrange(min, max)
    local minrange = min <= r_num
    local maxrange = r_num <= max
    if minrange and maxrange then
        return true, ''
    else
        ferror("minrange(%d) = %s", min, tostring(minrange))
        ferror("maxrange(%d) = %s", max, tostring(maxrange))
        return false, 'error comparing range values'
    end
end)

lib.test.add_test(test_rand_0)
lib.test.add_test(test_rand_1)
