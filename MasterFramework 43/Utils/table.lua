local ipairs = Include.ipairs
local pairs = Include.pairs

local function table_shallowCopy(table)
	local newTable = {}
	for key, value in pairs(table) do
		newTable[key] = value
	end
	return newTable
end

Include.table = table_shallowCopy(Include.table)
table = Include.table
table.shallowCopy = table_shallowCopy

local table_insert = table.insert
local table_remove = table.remove

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
            table_insert(newArray, value)
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
-- Clear
------------------------------------------------------------------------------------------------------------

function Include.clear(array)
	for index = 1, #array do
		table_remove(array)
	end
end