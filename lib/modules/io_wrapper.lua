--wrappers for I/O functions
function wrapped_write(caller, str)
    local w,h = term.getSize()
    local x,y = term.getCursorPos()

    local nLinesPrinted = 0
    local function newLine()
        if y + 1 <= h then
            term.setCursorPos(1, y + 1)
        else
            term.setCursorPos(1, h)
            term.scroll(1)
        end
        x, y = term.getCursorPos()
        nLinesPrinted = nLinesPrinted + 1
    end

    -- Print the line with proper word wrapping
    while string.len(sText) > 0 do
        local whitespace = string.match( sText, "^[ \t]+" )
        if whitespace then
            -- Print whitespace
            caller( whitespace )
            x,y = term.getCursorPos()
            sText = string.sub( sText, string.len(whitespace) + 1 )
        end

        local newline = string.match( sText, "^\n" )
        if newline then
            -- Print newlines
            newLine()
            sText = string.sub( sText, 2 )
        end

        local text = string.match( sText, "^[^ \t\n]+" )
        if text then
            sText = string.sub( sText, string.len(text) + 1 )
            if string.len(text) > w then
                -- Print a multiline word
                while string.len( text ) > 0 do
                    if x > w then
                        newLine()
                    end
                    caller( text )
                    text = string.sub( text, (w-x) + 2 )
                    x,y = term.getCursorPos()
                end
            else
                -- Print a word normally
                if x + string.len(text) - 1 > w then
                    newLine()
                end
                caller( text )
                x,y = term.getCursorPos()
            end
        end
    end

    return nLinesPrinted
end

function print_wrapped(callback, ...)
    local nLinesPrinted = 0
    local nLimit = select("#", ... )
    for n = 1, nLimit do
        local s = tostring( select( n, ... ) )
        if n < nLimit then
            s = s .. "\t"
        end
        nLinesPrinted = nLinesPrinted + callback(s)
    end
    nLinesPrinted = nLinesPrinted + callback("\n")
    return nLinesPrinted
end
