local table_insert = table.insert

-- Returns an array with a set number of values, with a generation function that takes the array index of the value 
-- to generate and returns the value to be stored at that index.
function table.repeating(count, func)
    local newTable = {}
    for i = 1, 3 do
        table_insert(newTable, func(i))
    end
    return newTable
end

------------------------------------------------------------------------------------------------------------
-- Map
------------------------------------------------------------------------------------------------------------

-- Creates a new table composed of the results of calling a function on each key-value pair of the original table.
function table.map(_table, transform)
    local newTable = {}

    for key, value in pairs(_table) do
        local newKey, newValue = transform(key, value)
        newTable[newKey] = newValue
    end

    return newTable
end

function table.imap(array, transform)
    local newArray = {}

    for index, value in ipairs(array) do
        table_insert(newArray, transform(index, value))
    end

    return newArray
end

function table.mapToArray(_table, transform)
    local newArray = {}

    for key, value in pairs(_table) do
        local newValue = transform(key, value)
        if newValue then
            table_insert(newArray, newValue)
        end
    end

    return newArray
end
function table.imapToTable(array, transform)
    local newTable = {}

    for index, value in ipairs(array) do
        local newKey, newValue = transform(index, value)
        newTable[newKey] = newValue
    end

    return newTable
end

------------------------------------------------------------------------------------------------------------
-- ForEachh
------------------------------------------------------------------------------------------------------------

function table.forEach(_table, func)
    for key, value in pairs(_table) do
        func(key, value)
    end
end

function table.iforEach(array, func)
    for key, value in ipairs(array) do
        func(key, value)
    end
end

------------------------------------------------------------------------------------------------------------
-- Filter
------------------------------------------------------------------------------------------------------------

function table.filter(_table, shouldIncludeElement)
    local newTable = {}
    for key, value in pairs(_table) do
        if shouldIncludeElement(key, value) then
            newTable[key] = value
        end
    end
    return newTable
end

-- Returns a new array with all elements of a given array where the provided filter returns true. 
-- The filter is given the index and value for each entry in the array. Order is preserved.
function table.ifilter(array, shouldIncludeElement)
    local newArray = {}
    for index, value in ipairs(array) do
        if shouldIncludeElement(index, value) then
            table.insert(newArray, value)
        end
    end
    return newArray
end

function table.reduce(array, initialValue, operation)
    local value = initialValue
    for _, element in ipairs(array) do
        value = operation(value, element)
    end
    return value
end

------------------------------------------------------------------------------------------------------------
-- Join
------------------------------------------------------------------------------------------------------------

-- Assembles a string by concatenating all string in an array, inserting the provided separator in between.
function table.joinStrings(table, separator)
    if #table < 2 then if #table < 1 then return "" else return table[1] end end

    local string = ""

    for i=1, #table do
        string = string .. tostring(table[i])
        if i ~= #table then
            string = string .. separator
        end
    end
    
    return string
end

-- Returns an array containing all elements in the provided arrays, in the reverse order than provided.
function table.joinArrays(arrayArray)
    local newArray = {}

    for _, array in pairs(arrayArray) do
        for _, value in pairs(array) do
            table_insert(newArray, value)
        end
    end

    return newArray
end

------------------------------------------------------------------------------------------------------------
-- String
------------------------------------------------------------------------------------------------------------

-- Returns information about the lines (separated by "\n").
--
-- Return values:
-- - _lines:     an array of the string value of each line (not including its "\n" character)
-- - lineStarts: an array of the indices in the original string of the first character of each line
-- - lineEnds:   an array of the indices in the original string of the last character of each line
-- 
-- for example:
-- ```
-- local originalString = "testing123\ntesting456\ntesting789"
-- local lines, lineStarts, lineEnds = originalString:lines()
-- Spring.Echo(lines[2]) -- outputs "testing456"
-- Spring.Echo(originalString:sub(lineStarts[2], lineEnds[2])) -- outputs "testing456"
-- ```
--
-- "\r" is not treated as a special character, and will remain in the resulting string.
function string:lines()
    local searchIndex = 1
    local _lines = {}
    local lineStarts = {}
    local lineEnds = {}

    while searchIndex < self:len() do
        local lineBreakIndex, _ = self:find("\n", searchIndex)
        
        if not lineBreakIndex then
            lineBreakIndex = self:len() + 1
        end

        table.insert(_lines, self:sub(searchIndex, lineBreakIndex - 1))
        table.insert(lineStarts, searchIndex)
        table.insert(lineEnds, lineBreakIndex - 1)

        searchIndex = lineBreakIndex + 1
    end

    return _lines, lineStarts, lineEnds
end

-- Inserts a new string such that it starts at the given index.
function string:inserting(newString, index)
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
function string:unEscaped(showNewlines)
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
                unEscaped = unEscaped .. string.format("\\%03d", string.byte(self:sub(i + j - 1, i + j - 1)))
            end
            i = i + 3
        else
            unEscaped = unEscaped .. character
        end
        
        i = i + 1
    end

    return unEscaped
end