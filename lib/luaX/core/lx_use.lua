
function main()
    if os.lib.lx then
        local s = lx.current()
        --local s = lx.Screen(term.current(), 15, 5, 20, 10)
        s:write("Testing luaX")
        s:pixel(5, 5, colors.white)
    else
        ferror("lx not loaded")
    end
end

main()
