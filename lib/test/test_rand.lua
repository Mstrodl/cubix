
Test = lib.test.Test

test_rand_0 = Test('rand', 'range of rand()', function()
    local n = rand()
    return lib.test.t_number_range(n, 0, math.pow(2, 32)-1)
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
    return lib.test.t_number_range(r_num, min, max)
end)

test_rand_2 = Test('rand', 'getrandombyte()', function()
    local rnd_byte = getrandombyte()
    return lib.test.t_number_range(rnd_byte, 0, 255)
end)

lib.test.add_test(test_rand_0)
lib.test.add_test(test_rand_1)
lib.test.add_test(test_rand_2)
