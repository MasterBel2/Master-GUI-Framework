local string = Include.string

local string_byte = string.byte
local string_format = string.format

-- Returns information about the lines (separated by "\n").
--
-- Return values:
-- - lineStarts: an array of the indices in the original string of the first character of each line
-- - lineEnds:   an array of the indices in the original string of the last character of each line
-- - lines:      an optional array of the string value of each line (not including its "\n" character). Provide a `true` argument to `string:lines_MasterFramework` to gather the substrings.
-- 
-- for example:
-- ```
-- local originalString = "testing123\ntesting456\ntesting789"
-- local lineStarts, lineEnds, lines = originalString:lines_MasterFramework(true)
-- Spring.Echo(lines[2]) -- outputs "testing456"
-- Spring.Echo(originalString:sub(lineStarts[2], lineEnds[2])) -- outputs "testing456"
-- ```
--
-- "\r" is not treated as a special character, and will remain in the resulting string.
function string:lines_MasterFramework(shouldGatherLines)
    local searchIndex = 1
    local lineStarts = {}
    local lineEnds = {}
    local lines = shouldGatherLines and {}

    local lineCount = 0
    while searchIndex <= self:len() + 1 do
        local lineBreakIndex, _ = self:find("\n", searchIndex)
        
        if not lineBreakIndex then
            lineBreakIndex = self:len() + 1
        end

        lineCount = lineCount + 1
        lineStarts[lineCount] = searchIndex -- searchIndex == lineBreakIndex if we have two newlines in a row
        lineEnds[lineCount] = lineBreakIndex - 1
        if shouldGatherLines then
            lines[lineCount] = self:sub(searchIndex, lineBreakIndex - 1)
        end

        searchIndex = lineBreakIndex + 1
    end

    return lineStarts, lineEnds, lines
end

-- Inserts a new string such that it starts at the given index.
function string:inserting_MasterFramework(newString, index)
    index = index or #string + 1
    return self:sub(1, index - 1) .. newString .. self:sub(index, self:len())
end

-- Returns an array containing all elements in the provided arrays, in reverse of the order that was provided.

------------------------------------------------------------------------------------------------------------
-- Debug
------------------------------------------------------------------------------------------------------------

-- Converts non-visible characters to their escaped symbol, e.g. "\r" to "\\r"
--
-- This converts color strings (e.g. "\255\255\001\001" to "\\255\\255\\001\\001")
function string:unEscaped_MasterFramework(showNewlines)
    local unEscaped = ""

    local i = 1
    while i <= self:len() do
        local character = self:sub(i, i)
        if character == "\b" then
            unEscaped = unEscaped .. "\\b"
        elseif character == "\n" and showNewlines then
            unEscaped = unEscaped .. "\\n"
        elseif character == "\r" then
            unEscaped = unEscaped .. "\\r"
        elseif character == "\255" then
            local x = self:sub(i, i + 3)
            for j = 1, 4 do
                if i + j > self:len() then return unEscaped end
                unEscaped = unEscaped .. string_format("\\%03d", string_byte(self:sub(i + j - 1, i + j - 1)))
            end
            i = i + 3
        else
            unEscaped = unEscaped .. character
        end
        
        i = i + 1
    end

    return unEscaped
end