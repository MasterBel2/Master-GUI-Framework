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


function LogDrawCall(caller, isEnd)
	-- if Internal.debugMode.draw then
	-- 	local tag = caller .. (isEnd and "(End)" or "(Begin)")
	-- 	Internal.drawCalls[tag] = (Internal.drawCalls[tag] or 0) + 1
	-- end
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

function framework:GetDebugMode()
	return Internal.debugMode.general, Internal.debugMode.draw, Internal.debugMode.noRasterizer 
end

function Internal.SetDebugMode(general, draw, noRasterizer)
	if Internal.debugMode.initialised then return end
	Internal.debugMode.initialised = true

	general = general or draw
	Internal.debugMode = { general = general, draw = draw, noRasterizer = noRasterizer }

	if not general then return end

	local nextUniqueIdentifier = 1
	for key, value in pairs(framework) do
		if type(value) == "function" then
			framework[key] = function(...)
				local temp = { value(...) }

				if temp[1] and type(temp[1]) == "table" then
					if draw then
						if temp[1].Draw then
							local cachedDraw = temp[1].Draw
							-- local drawTag = key .. ":Draw"
							-- local _LogDrawCall = LogDrawCall
							temp[1].Draw = function(...)
								LogDrawCall(key .. ":Draw", false)
								cachedDraw(...)
								LogDrawCall(key .. ":Draw", true)
							end
						end
						if temp[1].Layout then
							local cachedLayout = temp[1].Layout
							-- local layoutTag = key .. ":Layout"
							-- local _LogDrawCall = LogDrawCall
							temp[1].Layout = function(...)
								LogDrawCall(key .. ":Layout", false)
								local result = { cachedLayout(...) }
								-- local width, height = cachedLayout(...)
								LogDrawCall(key .. ":Layout", true)
								-- return width, height
								return unpack(result)
							end
						end
					end

					if general then
						temp[1]._debugTypeIdentifier = key
						temp[1]._debugUniqueIdentifier = nextUniqueIdentifier
						nextUniqueIdentifier = nextUniqueIdentifier + 1
					end
				end

				return unpack(temp)
			end
		end
	end
end