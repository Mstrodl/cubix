-- ISAAC Implementation in Lua for Cubix
-- Based mostly on the C and Python versions in Rosetta Code

local INT_MASK = 2^32 -1

-- external results
local randrsl = {}
local randcnt = 0

local isaac_seeded_entpool = false
local isaac_seeded = false

-- internal state
local mm = {}
local aa = 0
local bb = 0
local cc = 0

local function isaac()
    local i, x, y
    cc = cc + 1
    bb = bb + cc

    os.debug.debug_write("isaac: loop cache", false)
    for i=0,255 do

        x = mm[i]
        local switch = i % 4

        if switch == 0 then aa = bit.bxor(aa, bit.blshift(aa, 13))
        elseif switch == 1 then aa = bit.bxor(aa, bit.brshift(aa, 6))
        elseif switch == 2 then aa = bit.bxor(aa, bit.blshift(aa, 2))
        elseif switch == 3 then aa = bit.bxor(aa, bit.brshift(aa, 16))
        end

        aa = mm[(i+128) % 256] + aa
        aa = aa % (INT_MASK)

        local cache = mm[bit.brshift(x, 2) % 256] + aa + bb
        y = cache % (INT_MASK)
        mm[i] = y

        local cache = mm[bit.brshift(y, 10) % 256] + x
        bb = cache % (INT_MASK)
        randrsl[i] = bb
    end

    os.debug.debug_write("isaac: reset", false)
    randcnt = 0
end

function mix(a,b,c,d,e,f,g,h)
    a = a % (INT_MASK)
    b = b % (INT_MASK)
    c = c % (INT_MASK)
    d = d % (INT_MASK)
    e = e % (INT_MASK)
    f = f % (INT_MASK)
    g = g % (INT_MASK)
    h = h % (INT_MASK)

    a = bit.bxor(a, bit.blshift(b, 11))
    d = d + a
    d = d % (INT_MASK)

    b = b + c
    b = b % (INT_MASK)

    b = bit.bxor(b, bit.brshift(c, 2))
    e = e + b
    e = e % (INT_MASK)

    c = c + d
    c = c % (INT_MASK)

    c = bit.bxor(c, bit.blshift(d, 8))
    f = f + c
    f = f % (INT_MASK)
    d = d + e
    d = d % (INT_MASK)

    d = bit.bxor(d, bit.brshift(e, 16))
    g = g + d
    g = g % (INT_MASK)

    e = e + f
    e = e % (INT_MASK)

    e = bit.bxor(e, bit.brshift(f, 10))
    h = h + e
    h = h % (INT_MASK)

    f = f + g
    f = f % (INT_MASK)

    f = bit.bxor(f, bit.brshift(g, 4))
    a = a + f
    a = a % (INT_MASK)

    g = g + h
    g = g % (INT_MASK)

    g = bit.bxor(g, bit.brshift(h, 8))
    b = b + g
    b = b % (INT_MASK)

    h = h + a
    h = h % (INT_MASK)

    h = bit.bxor(h, bit.brshift(a, 9))
    c = c + h
    c = c % (INT_MASK)

    a = a + b
    a = a % (INT_MASK)

    return a,b,c,d,e,f,g,h
end

local function randinit(flag)
    local i
    local a,b,c,d,e,f,g,h

    aa = 0
    bb = 0
    cc = 0

    a,b,c,d,e,f,g,h = 0x9e3779b9, 0x9e3779b9,
    0x9e3779b9, 0x9e3779b9, 0x9e3779b9,
    0x9e3779b9, 0x9e3779b9, 0x9e3779b9 -- golden ratio

    os.debug.debug_write("randinit: scramble", false)
    for i=0,3 do -- scramble it
        a,b,c,d,e,f,g,h = mix(a,b,c,d,e,f,g,h)
    end

    os.debug.debug_write("randinit: filling", false)
    for i=0,255,8 do -- fill in mm with messy stuff
        if flag then -- use all the information in the seed
            a = a + randrsl[i  ];
            b = b + randrsl[i+1];
            c = c + randrsl[i+2];
            d = d + randrsl[i+3];
            e = e + randrsl[i+4];
            f = f + randrsl[i+5];
            g = g + randrsl[i+6];
            h = h + randrsl[i+7];

            a = a % (INT_MASK)
            b = b % (INT_MASK)
            c = c % (INT_MASK)
            d = d % (INT_MASK)
            e = e % (INT_MASK)
            f = f % (INT_MASK)
            g = g % (INT_MASK)
            h = h % (INT_MASK)
        end
        a,b,c,d,e,f,g,h = mix(a,b,c,d,e,f,g,h);
        mm[i  ] = a;
        mm[i+1] = b;
        mm[i+2] = c;
        mm[i+3] = d;
        mm[i+4] = e;
        mm[i+5] = f;
        mm[i+6] = g;
        mm[i+7] = h;
    end

    if flag then
        for i=0,255,8 do
            a = a + mm[i  ];
            b = b + mm[i+1];
            c = c + mm[i+2];
            d = d + mm[i+3];
            e = e + mm[i+4];
            f = f + mm[i+5];
            g = g + mm[i+6];
            h = h + mm[i+7];

            a = a % (INT_MASK)
            b = b % (INT_MASK)
            c = c % (INT_MASK)
            d = d % (INT_MASK)
            e = e % (INT_MASK)
            f = f % (INT_MASK)
            g = g % (INT_MASK)
            h = h % (INT_MASK)

            a,b,c,d,e,f,g,h = mix(a,b,c,d,e,f,g,h);

            mm[i  ]=a;
            mm[i+1]=b;
            mm[i+2]=c;
            mm[i+3]=d;
            mm[i+4]=e;
            mm[i+5]=f;
            mm[i+6]=g;
            mm[i+7]=h;
        end
    end

    os.debug.debug_write("randinit: reset", false)

    isaac()
    randcnt=0
end

function isaac_seed(seed, flag)
    print("isaac_seed "..tostring(seed))
    sleep(.5)
    if isaac_seeded or (not isaac_seeded_entpool) then
        if (not permission.grantAccess(fs.perms.SYS)) then
            ferror("isaac_seed: not enough permission")
            return false
        end
    end

    isaac_seeded = true

    local i,m
    for i=0,255 do
        mm[i]=0
    end
    m = #seed

    for i=0,255 do
        if i > m then
            randrsl[i]=0;
        else
            randrsl[i] = seed[i];
        end
    end

    os.debug.debug_write("isaac_seed: initializing", false)

    randinit(flag)
    isaac()
    isaac()

    os.debug.debug_write("isaac_seed: seeded", false)
end

function isaac_seed_mt()
    os.debug.debug_write("isaac_seed: seeding from MT19937(os.random)")
    for i=0,255 do
        randrsl[i] = os.random.extract_num(os.random)
    end
end

function isaac_seed_entpool()
    os.debug.debug_write("isaac_seed: seeding from entropyman", false)
    for i=0,255 do
        randrsl[i] = entropyman.pool_seed()
    end
    sleep(.3)
    isaac_seed_entpool = true
end

function isaac_rand()
    -- get random number from the state
    r = randrsl[randcnt]
    randcnt = randcnt + 1
    if randcnt > 255 then
        isaac()
        randcnt = 0
    end
    return r
end

function isaac_export_seed()
    r = ''
    for i=0,255 do
        r = r .. randrsl[i]
    end
    return r
end

function libroutine()
    isaac_seed(os.generateSalt(64))

    _G['rand'] = function() -- overwrite Mersenne Twister syscalls
        return isaac_rand()
    end

    _G['randrange'] = function(a, b)
        --generate from a to b inclusive
        local v = rand()
        return (v % (b+1)) + a
    end

    _G['getrandombyte'] = function(flag)
        local val = randrange(0, 256 - 1)
        if flag then
            return tonumber(tostring(val))
        else
            return val
        end
    end
end
