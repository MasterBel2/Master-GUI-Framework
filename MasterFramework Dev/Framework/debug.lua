local Internal = Internal

local tostring = Include.tostring
local unpack = Include.unpack
local type = Include.type
local pairs = Include.pairs
local ipairs = Include.ipairs
local string = Include.string
local error = Include.error
local table_insert = Include.table.insert

local Spring_GetTimer
if Include.Spring.GetTimerMicros then
	Spring_GetTimer = Include.Spring.GetTimerMicros
else
	Spring_GetTimer = Include.Spring.GetTimer
end
local Spring_DiffTimers = Include.Spring.DiffTimers
local Spring_Echo = Include.Spring.Echo

Internal.drawCalls = {}
Internal.debugMode = {}
stats = {}

function Log(string)
	if not string then return end
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

--[[
	Generates a string detailing the contents of a table - recursively. Calling this, 

	Parameters:
	- `table`: the table whose contents are to be displayed
	- `name`: an optional string describing the table provided - e.g. the key used to access this table from its parent table
	- `indentation`: an optional integer indicating how nested this table is. Usually, you will provide `0` or `nil`; this is primarily for the sake of recursion.
	- `describedTables`: a table keyed by tables whose descriptions have been generated. This table is used to avoid infinite recursion in the case of recursive table references.

	Note: Call this as framework.debugDescription, NOT framework:debugDescription!
]]
function debugDescriptionString(table, name, indentation, describedTables)
	describedTables = describedTables or {}
	local description = ""
	indentation = indentation or 0
	description = "\255\100\100\100" .. string.rep("| ", indentation) .. "\255\001\255\001Table: " .. tostring(name)
	if describedTables[table] then
		description = description .. "\255\255\001\001(Previously described)"
	else
		describedTables[table] = true
		for key, value in pairs(table) do
			if type(value) == "table" then
				description = description .. "\n" .. debugDescriptionString(value, key, indentation + 1, describedTables)
			else
				description = description .. "\n\255\100\100\100" .. string.rep("| ", indentation + 1) .. "\255\255\255\255" .. tostring(key) .. "\255\100\100\100:\255\255\255\255 " .. tostring(value)
			end
		end
	end

	return description
end

function debugDescription(...)
	Spring_Echo(debugDescriptionString(...))
end

local profileTimers = {}
function startProfile(profileName)
	if Internal.debugMode.general then
		profileTimers[profileName] = Spring_GetTimer()
	end
	-- startTimer = Spring_GetTimer()
end

function endProfile(profileName, recordMax)
	-- local time = Spring_DiffTimers(Spring_GetTimer(), startTimer, nil)
	if Internal.debugMode.general and profileTimers[profileName] then
		local time = Spring_DiffTimers(Spring_GetTimer(), profileTimers[profileName], nil, true)
		if not recordMax or ((framework.stats[profileName] or 0) < time) then
			framework.stats[profileName] = time
		end
	end
	-- Log("Profiled " .. profileName .. ": " .. Spring_DiffTimers(Spring_GetTimer(), startTimer) * 1000 .. " microseconds")
end

function framework:GetDebugMode()
	return Internal.debugMode.general, Internal.debugMode.draw, Internal.debugMode.disableDrawList 
end

-- A unique identifier used by `EnableDebugMode`. Always increment this after assigning the value to something, and do not reset it.
local nextUniqueIdentifier = 1

-- Wraps draw & layout functions with debug helpers, depending what debug modes the framework has enabled.
-- 
-- This includes: 
-- - for draw debug, a utility that adds to DebugInfo data about the component currently under cursor, and draws a border of every component.
-- - for general debug, a unique & type id for each instance (see `nextUniqueIdentifier`)
-- 
-- All functions included in `target` will be replaced by a wrapper function that conditionally adds these features.
-- If neither general nor draw debug are enabled for the framework, no wrapper function will be added, to preserve performance.
function EnableDebugMode(target)
	if target._masterframework_debugModeEnabled then return end
	target._masterframework_debugModeEnabled = true

	local general, draw, disableDrawList = Internal.debugMode.general, Internal.debugMode.draw,  Internal.debugMode.disableDrawList

	if not general then return end

	local dummyRect
	if draw then
		dummyRect = { cornerRadius = function() return 0 end }
	end

	for key, value in pairs(target) do
		if type(value) == "function" then
			target[key] = function(...)
				local temp = { value(...) }

				if temp[1] and type(temp[1]) == "table" then

					temp[1]._debugTypeIdentifier = key
					temp[1]._debugUniqueIdentifier = nextUniqueIdentifier
					nextUniqueIdentifier = nextUniqueIdentifier + 1

					if draw then
						local activeDrawingGroup
						local cachedX, cachedY, cachedWidth, cachedHeight, needsLayout
						local elementKey

						if temp[1].Position and temp[1].Layout then
							temp[1]._debug_mouseOverResponder = {
								responders = {},
	
								-- FIXME: wait, this can never be nil???
								noRect = temp[1] == nil,
	
								_isDebugResponder = true,
								_debugTypeIdentifier = temp[1]._debugTypeIdentifier,
								_debugUniqueIdentifier = temp[1]._debugUniqueIdentifier,
	
								ContainsAbsolutePoint = function(_, x, y)
									local drawingGroupOffsetX, drawingGroupOffsetY = activeDrawingGroup:AbsolutePosition()
									return PointIsInRect(x, y, cachedX + drawingGroupOffsetX, cachedY + drawingGroupOffsetY, cachedWidth, cachedHeight)
								end,

								MouseEnter = function() end,
								MouseLeave = function() end,
								action = function(_, x, y)
									local drawingGroupOffsetX, drawingGroupOffsetY = activeDrawingGroup:AbsolutePosition()
									Internal.DebugInfo.elementBelowMouse[elementKey] = {
										type = key,
										path = key,
										cachedX = cachedX + drawingGroupOffsetX,
										cachedY = cachedY + drawingGroupOffsetY,
										cachedWidth = cachedWidth,
										cachedHeight = cachedHeight,
										x = x,
										y = y,

										needsLayout = needsLayout,
	
										_debugTypeIdentifier = temp[1]._debugTypeIdentifier,
										_debugUniqueIdentifier = temp[1]._debugUniqueIdentifier
									}
									local x = temp[1]._debug_mouseOverResponder.parent
									for i = 1, 1000 do
										if not x or x == x.parent  then break end
										Internal.DebugInfo.elementBelowMouse[elementKey].path = (x._debugTypeIdentifier or "Unknown") .. "/" .. Internal.DebugInfo.elementBelowMouse[elementKey].path
										x = x.parent
									end
	
									return true
								end,
							}
						end

						if temp[1].Position then
							local _Position = temp[1].Position
							temp[1].Position = function(self, x, y)
								if type(self) ~= "table" then
									Log(temp[1]._debugTypeIdentifier .. ":Position", "Unique Identifier: " .. temp[1]._debugUniqueIdentifier)
									error("erroneous argument: missing self!")
								end
								if not x then
									Log(temp[1]._debugTypeIdentifier .. ":Position", "Unique Identifier: " .. temp[1]._debugUniqueIdentifier)
									error("erroneous argument: x is nil!")
								end
								if not y then
									Log(temp[1]._debugTypeIdentifier .. ":Position", "Unique Identifier: " .. temp[1]._debugUniqueIdentifier)
									error("erroneous argument: y is nil!")
								end

								if not temp[1].laidOut then
									-- local x = temp[1]._debug_mouseOverResponder.parent
									-- local path = temp[1]._debugTypeIdentifier
									-- for i = 1, 1000 do
									-- 	if not x then break end
									-- 	path = (x._debugTypeIdentifier or "Unknown") .. "/" .. path
									-- 	x = x.parent
									-- end
									Log("Position called before Layout for " .. temp[1]._debugTypeIdentifier .. " " .. temp[1]._debugUniqueIdentifier)
								end
								LogDrawCall(key .. ":Position", false)
								elementKey = Internal.activeElement.key

								local previousActiveDebugResponder
								if Internal.activeElement then
									previousActiveDebugResponder = Internal.activeElement.activeDebugResponder
									if temp[1]._debug_mouseOverResponder then
										temp[1]._debug_mouseOverResponder.parent = previousActiveDebugResponder
										table_insert(previousActiveDebugResponder.responders, temp[1]._debug_mouseOverResponder)
										temp[1]._debug_mouseOverResponder.responders = {}
										Internal.activeElement.activeDebugResponder = temp[1]._debug_mouseOverResponder
									end
								end

								_Position(self, x, y)

								Internal.activeElement.activeDebugResponder = previousActiveDebugResponder

								cachedX, cachedY = x, y
								table_insert(activeDrawingGroup.drawTargets, { Draw = function()
									local drawingGroupOffsetX, drawingGroupOffsetY = activeDrawingGroup:AbsolutePosition()
									framework.stroke.defaultBorder:Draw(dummyRect, cachedX + drawingGroupOffsetX, cachedY + drawingGroupOffsetY, cachedWidth, cachedHeight)
								end })
								LogDrawCall(key .. ":Position", true)
							end
						end
						if temp[1].NeedsLayout then
							local _NeedsLayout = temp[1].NeedsLayout
							temp[1].NeedsLayout = function(...)
								needsLayout = _NeedsLayout(...) or false
								temp[1]._debug_needsLayout = needsLayout
								return needsLayout
							end
						end
						
						if temp[1].Layout then
							temp[1].laidOut = true
							local _Layout = temp[1].Layout
							temp[1].Layout = function(self, availableWidth, availableHeight)
								if type(self) ~= "table" then
									Log(temp[1]._debugTypeIdentifier .. ":Layout", "Unique Identifier: " .. temp[1]._debugUniqueIdentifier)
									error("erroneous argument: missing self!")
								end
								if not availableWidth then
									Log(temp[1]._debugTypeIdentifier .. ":Layout", "Unique Identifier: " .. temp[1]._debugUniqueIdentifier)
									error("erroneous argument: availableWidth is nil!")
								end
								if not availableHeight then
									Log(temp[1]._debugTypeIdentifier .. ":Layout", "Unique Identifier: " .. temp[1]._debugUniqueIdentifier)
									error("erroneous argument: availableHeight is nil!")
								end
								activeDrawingGroup = framework.activeDrawingGroup or temp[1]
								LogDrawCall(key .. ":Layout", false)
								cachedWidth, cachedHeight = _Layout(self, availableWidth, availableHeight)
								if not cachedWidth then
									Log(temp[1]._debugTypeIdentifier .. ":Layout", "Unique Identifier: " .. temp[1]._debugUniqueIdentifier)
									error("Erroneous return value: width is nil!")
								end
								if not cachedHeight then
									Log(temp[1]._debugTypeIdentifier .. ":Layout", "Unique Identifier: " .. temp[1]._debugUniqueIdentifier)
									error("Erroneous return value: height is nil!")
								end
								LogDrawCall(key .. ":Layout", true)
								return cachedWidth, cachedHeight
							end
						end
					end
				end

				return unpack(temp)
			end
		end
	end
end

function Internal.SetDebugMode(general, draw, disableDrawList)
	if Internal.debugMode.initialised then return end
	Internal.debugMode.initialised = true

	general = general or draw
	Internal.debugMode = { general = general, draw = draw, disableDrawList = disableDrawList }

	EnableDebugMode(framework)
	Log("Debug mode enabled!", general, draw, disableDrawList)
end