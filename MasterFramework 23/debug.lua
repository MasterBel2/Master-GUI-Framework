local Internal = Internal

local tostring = Include.tostring
local unpack = Include.unpack
local type = Include.type
local pairs = Include.pairs
local ipairs = Include.ipairs
local string = Include.string

local Spring_GetTimerMicros = Include.Spring.GetTimerMicros
local Spring_DiffTimers = Include.Spring.DiffTimers
local Spring_Echo = Include.Spring.Echo

Internal.drawCalls = {}
Internal.debugMode = {}
stats = {}

function Log(string)
	if Internal.debugMode.general then
		Spring_Echo("[MasterFramework " .. framework.compatabilityVersion .. "] " .. string)
	end
end


function LogDrawCall(caller)
	if Internal.debugMode.draw then
		Internal.drawCalls[caller] = (Internal.drawCalls[caller] or 0) + 1
		Log(caller)
	end
end

-- Logs a formatted error. Provide details as strings, they will be appeneded with the separator " - "
function Error(...)
	local errorString = "Error in MasterFramework " .. framework.compatabilityVersion

	for i,v in ipairs({...}) do
		errorString = errorString .. " - " .. v
	end

	Spring_Echo(errorString)
end

function debugDescriptionString(table, name, indentation)
	local description = ""
    indentation = indentation or 0
	description = "\255\100\100\100" .. string.rep("| ", indentation) .. "\255\001\255\001Table: " .. tostring(name)
    for key, value in pairs(table) do
        if type(value) == "table" then
            description = description .. "\n" .. debugDescriptionString(value, key, indentation + 1)
        else
            description = description .. "\n\255\100\100\100" .. string.rep("| ", indentation + 1) .. "\255\255\255\255" .. tostring(key) .. "\255\100\100\100:\255\255\255\255 " .. tostring(value)
        end
    end

	return description
end

function debugDescription(...)
	Spring.Echo(debugDescriptionString(...))
end

function startProfile(_profileName)
	profileName = _profileName
	startTimer = Spring_GetTimerMicros()
	-- startTimer = Spring_GetTimer()
end

function endProfile()
	-- local time = Spring_DiffTimers(Spring_GetTimer(), startTimer, nil)
	local time = Spring_DiffTimers(Spring_GetTimerMicros(), startTimer, nil, true)
	framework.stats[profileName] = time
	-- Log("Profiled " .. profileName .. ": " .. Spring_DiffTimers(Spring_GetTimer(), startTimer) * 1000 .. " microseconds")
end

function Internal.SetDebugMode(general, draw)
	if Internal.debugMode.initialised then return end
	Internal.debugMode.initialised = true

	general = general or draw
	Internal.debugMode = { general = general, draw = draw }

	if not general then return end

	for key, value in pairs(framework) do
		if type(value) == "function" then
			framework[key] = function(...)
				local temp = { value(...) }

				if temp[1] and type(temp[1]) == "table" then
					if draw then
						if temp[1].Draw then
							local cachedDraw = temp[1].Draw
							temp[1].Draw = function(...)
								LogDrawCall(key .. ":Draw (Begin)")
								cachedDraw(...)
								LogDrawCall(key .. ":Draw (End)")
							end
						end
						if temp[1].Layout then
							local cachedLayout = temp[1].Layout
							temp[1].Layout = function(...)
								LogDrawCall(key .. ":Layout (Begin)")
								local result = { cachedLayout(...) }
								LogDrawCall(key .. ":Layout (End)")
								return unpack(result)
							end
						end
					end

					if general then
						temp[1]._debugIdentifier = key
					end
				end

				return unpack(temp)
			end
		end
	end
end