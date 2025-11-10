------------------------------------------------------------------------------------------------------------
-- Metadata
------------------------------------------------------------------------------------------------------------

-- https://github.com/MasterBel2/Master-GUI-Framework

local compatabilityVersion = "Dev"

function widget:GetInfo()
	return {
		version = tostring(compatabilityVersion),
		name = "MasterBel2's GUI Framework (" .. compatabilityVersion .. ")",
		desc = "A GUI framework for the SpringRTS Engine",
		author = "MasterBel2",
		date = "October 2020",
		license = "GNU GPL, v2 or later",
		layer = -2,
		enabled = true,
	}
end

local function GetDebugModes()
	return false, false, false
end

local xpcall = xpcall
local pcall = pcall
if GetDebugModes() then
	-- This has a MASSIVE performance impact, 
	-- so we disable it unless debugging
	pcall = function(func, ...)
		local args = { ... }
		return xpcall(function()
			return func(unpack(args))
		end, debug.traceback)
	end
end

local remove = table.remove

local function ForAllFiles(fileTree, action, ...)
    for fileName, table in pairs(fileTree) do

        if not type(table) == "table" then break end -- Let people put functions in there - like this one!

        if table.type == "file" then
            action(fileName, ...)
        elseif table.type == "subDir" then
            ForAllFiles(table.fileTree, action, ...)
        end
    end
end
local function FileTree(directoryName)
    local files = {}

    for _, fileName in ipairs(VFS.DirList(directoryName), "*", VFS.RAW_FIRST) do
        files[fileName] = {
            type = "file"
        }
    end
    for _, subDir in ipairs(VFS.SubDirs(directoryName), "*", VFS.RAW_FIRST) do
        files[subDir] = {
            type = "subDir",
            fileTree = FileTree(subDir)
        }
    end

    return files
end

local frameworkInternal = {
	-- Persistent data loaded before `widget:Initialize()` and saved directly before `widget:Shutdown()`.
	-- 
	-- Please - each component should store their data under in a table keyed into `ConfigData` with their component name
	-- - e.g. `framework.Internal.ConfigData.MovableFrame`.
	ConfigData = {},
	DebugInfo = {}
}
local framework = {
    compatabilityVersion = compatabilityVersion,
	events = { mousePress = "mousePress", mouseWheel = "mouseWheel", mouseOver = "mouseOver", tooltip = "tooltip", _debug_mouseOver = "_debug_mouseOver" }, -- mouseMove = "mouseMove", mouseRelease = "mouseRelease" (Handled differently to other events – see dragListeners)
}
local isAbove
local isAboveChecked = false

function widget:SetConfigData(data)
	frameworkInternal.ConfigData = data or {}
end

function widget:GetConfigData()
	return frameworkInternal.ConfigData
end

function widget:Initialize()
    local DIR = LUAUI_DIRNAME .. "MasterFramework " .. compatabilityVersion .. "/"

	framework.DIR = DIR

    framework.Internal = frameworkInternal

    framework.Include = {
        error = error,
        pairs = pairs,
        ipairs = ipairs,
		next = next,
        type = type,
        string = string,
        math = math,
        table = table,
        tostring = tostring,
        tonumber = tonumber,
        pcall = pcall,
        unpack = unpack,
        loadstring = loadstring,
        setfenv = setfenv,
        setmetatable = setmetatable,
		os = os,

        widgetHandler = widgetHandler,

        debug = debug,

        error = error,
        Spring = Spring,
        VFS = VFS,
		WG = WG,

        GL = GL,
        gl = gl,
    }
    framework.framework = framework

	ForAllFiles(FileTree(DIR .. "Utils"), function(filePath)
        if filePath:find(".+%.lua") then
            VFS.Include(filePath, framework)
        end
    end)

    ForAllFiles(FileTree(DIR .. "Framework"), function(filePath)
        if filePath:find(".+%.lua") then
            VFS.Include(filePath, framework)
        end
    end)

	VFS.Include(DIR .. "Constants/constants.lua", framework)

    local viewSizeX, viewSizeY = Spring.GetViewGeometry()

	frameworkInternal.updateScreenEnvironment(viewSizeX, viewSizeY, framework.relativeScaleFactor)

	frameworkInternal.SetDebugMode(GetDebugModes())
	
	if frameworkInternal.debugMode.general then
	-- if true then
		local callInNames = { "GetTooltip", "TweakGetTooltip", "TextInput", "KeyPress", "KeyRelease", "MousePress", "MouseMove", "MouseRelease", "MouseWheel", "IsAbove", "Update", "DrawScreen", "ViewResize", "TweakMousePress", "TweakMouseMove", "TweakMouseRelease", "TweakMouseWheel", "TweakIsAbove" }
		for i = 1, #callInNames do
			local callIn = widget[callInNames[i]]
			widget[callInNames[i]] = function(...)
				if callInNames[i] == "IsAbove" and isAboveChecked then return callIn(...) end
				framework.startProfile(callInNames[i])
				local temp = { callIn(...) }
				framework.endProfile(callInNames[i])
				return unpack(temp)
			end
		end
	end

	if frameworkInternal.debugMode.draw then
		local _IsAbove = widget.IsAbove
		widget.IsAbove = function(self, x, y)
			if isAboveChecked then return isAbove end  
			if frameworkInternal.debugMode.draw then
				frameworkInternal.DebugInfo.elementBelowMouse = {}
				for _, element in pairs(frameworkInternal.elements) do
					frameworkInternal.SearchDownResponderTree(element.activeDebugResponder, x, y)
				end
			end
			return _IsAbove(self, x, y)
		end

		local _DrawScreen = widget.DrawScreen
		widget.DrawScreen = function(...)
			_DrawScreen(...)
			if frameworkInternal.debugMode.draw then
				-- framework.Log("####")
				-- for caller, callCount in pairs(frameworkInternal.drawCalls) do
				-- 	framework.Log(caller .. ": " .. callCount)
				-- end
				frameworkInternal.drawCalls = {}
			end
		end

	end

    framework.Internal = nil
    framework.Include = nil

	WG["MasterFramework " .. framework.compatabilityVersion] = framework
end

function widget:DebugInfo()
	return frameworkInternal.DebugInfo
end

function widget:GetTooltip(x, y)
	-- IsAbove is called before GetTooltip, so we can use the element found by that.

	if not frameworkInternal.elementBelowMouse then return nil end

	local tooltip = frameworkInternal.FindResponder(framework.events.tooltip, x, y)

	return tooltip and tooltip.description
end
function widget:TweakGetTooltip(x, y)
end

function widget:TextInput(utf8char)
    if not frameworkInternal.focusTarget then return end

	local success, errorMessage = pcall(frameworkInternal.focusTarget.TextInput, frameworkInternal.focusTarget, utf8char)
	if not success then 
		framework.Error("widget:TextInput", "focusTarget:TextInput", errorMessage)
	end

    return true
end

function widget:KeyPress(key, mods, isRepeat, label, utf32char, scanCode, actionList)
    if not frameworkInternal.focusTarget then return end
	
	local success, errorMessage = pcall(frameworkInternal.focusTarget.KeyPress, frameworkInternal.focusTarget, key, mods, isRepeat, label, utf32char, scanCode, actionList)
	if not success then 
		framework.Error("widget:KeyPress", "focusTarget:KeyPress", errorMessage)
	end
	
    return true
end

function widget:KeyRelease(key, mods, label, utf32char, scanCode, actionList)
	if not frameworkInternal.focusTarget then return end

	local success, errorMessage = pcall(frameworkInternal.focusTarget.KeyRelease, frameworkInternal.focusTarget, key, mods, label, utf32char, scanCode, actionList)
	if not success then 
		framework.Error("widget:KeyRelease", "focusTarget:KeyRelease", errorMessage)
	end
	
	return true
end

function widget:MousePress(x, y, button)
	if frameworkInternal.focusTarget then
		frameworkInternal.focusTarget:ReleaseFocus()
		frameworkInternal.focusTarget = nil
	end
	if not frameworkInternal.CheckElementUnderMouse(x, y) then
		for _, key in ipairs(frameworkInternal.elementOrder) do
			local element = frameworkInternal.elements[key]
			local success, errorMessage = pcall(element.deselect)
			if not success then
				framework.Error("widget:MousePress", "Element: " .. key, "element.deslect", errorMessage)
			end
		end
		return false
	end
	local result = frameworkInternal.FindResponder(framework.events.mousePress, x, y, button)
	return result
end

function widget:MouseMove(x, y, dx, dy, button)
	local dragListener = frameworkInternal.dragListeners[button]
	if dragListener ~= nil then
		local success, errorMessage = pcall(dragListener.MouseMove, dragListener, x, y, dx, dy, button)
		if not success then
			framework.Error("widget:MouseMove", "dragListener:MouseMove", errorMessage)
		end
	end
end

function widget:MouseRelease(x, y, button)
	local dragListener = frameworkInternal.dragListeners[button]
	if dragListener then
		local success, errorMessage = pcall(dragListener.MouseRelease, dragListener, x, y, button)
		if not success then
			framework.Error("widget:MouseRelease", "dragListener:MouseRelease", errorMessage)
		end
		frameworkInternal.dragListeners[button] = nil
	end
	return false
end

function widget:MouseWheel(up, value)
	local mouseX, mouseY = Spring.GetMouseState()
	if frameworkInternal.CheckElementUnderMouse(mouseX, mouseY) then
		local result = frameworkInternal.FindResponder(framework.events.mouseWheel, mouseX, mouseY, up, value)
		return result
	else
		return false
	end
end

function widget:IsAbove(x, y)
	-- BAR's widget handler calls this a second time because we have a tooltip.
	-- That messes with profiling!
	if isAboveChecked then return frameworkInternal.elementBelowMouse ~= nil end

	local element, responder = framework.HighestResponderAtPoint(x, y, framework.events.mouseOver)
	frameworkInternal.elementBelowMouse = element

	frameworkInternal.DebugInfo.responderUnderMouse = responder and responder._debugUniqueIdentifier

	if responder ~= frameworkInternal.mouseOverResponder then
		local previousResponder = frameworkInternal.mouseOverResponder
		frameworkInternal.mouseOverResponder = responder
		local highestCommonResponder

		-- 
		local _responder = responder
		while _responder do
			if _responder.mouseIsOver then
				highestCommonResponder = _responder
				break
			else
				_responder.mouseIsOver = true
				if _responder.MouseEnter then
					local success, maybeError = pcall(_responder.MouseEnter, _responder)
					if not success then
						framework.Error("IsAbove", "responder:MouseEnter", maybeError, "Element Key: " .. element.key, _responder._debugTypeIdentifier, _responder._debugUniqueIdentifier)
						framework:RemoveElement(element.key)
						break
					end
				end
				_responder = responder.parent
			end
		end
		
		-- Remove isOver status from previous responders
		_responder = previousResponder
		while _responder and _responder ~= highestCommonResponder do
			_responder.mouseIsOver = false
			if _responder.MouseLeave then
				local success, maybeError = pcall(_responder.MouseLeave, _responder)
				if not success then
					framework.Error("IsAbove", "responder:MouseLeave", maybeError, "Element Key: " .. element.key, _responder._debugTypeIdentifier, _responder._debugUniqueIdentifier)
					framework:RemoveElement(element.key)
					break
				end
			end
			_responder = _responder.parent
		end
	end

	-- Call action on all responders under mouse
	local _responder = responder
	while _responder do
		local success, maybeError = pcall(_responder.action, _responder, x, y)
		if success then
			_responder = _responder.parent
		else
			framework.Error("IsAbove", maybeError, "Element Key: " .. element.key, _responder._debugTypeIdentifier, _responder._debugUniqueIdentifier)
			framework:RemoveElement(element.key)
			break
		end
	end

	isAboveChecked = true

	return element ~= nil
end
function widget:Update()
	-- widget:IsAbove seems to be called multiple times a frame. To mitigate this, we'll call it once per function we *know* is called once per frame - in this case, Update().
	-- (It might be slightly more optimal (re performance) to call it in DrawScreen, but putting it in Update allows us to keep it right here where it's easy to read.)
	isAboveChecked = false
end

function widget:DrawScreen()
	frameworkInternal.hasCheckedElementBelowMouse = false
	frameworkInternal.elementBelowMouse = nil
	local index = #frameworkInternal.elementOrder
	while 0 < index do
		local key = frameworkInternal.elementOrder[index]
		frameworkInternal.elements[key]:Draw()

		index = index - 1
	end
end

function widget:ViewResize(viewSizeX, viewSizeY)
	if framework.viewportWidth ~= viewSizeX or framework.viewportHeight ~= viewSizeY then
		frameworkInternal.updateScreenEnvironment(viewSizeX, viewSizeY, framework.relativeScaleFactor)
	end
end

-- Tweak mode 

function widget:TweakMousePress(x, y, button) end
function widget:TweakMouseMove(x, y, dx, dy, button) end
function widget:TweakMouseRelease(x, y, button) end
function widget:TweakMouseWheel(up, value) end
function widget:TweakIsAbove(x, y) return widget:IsAbove(x, y) end

------------------------------------------------------------------------------------------------------------
-- Joystick events
------------------------------------------------------------------------------------------------------------

-- function widget:JoyAxis(axis,value) end
-- function widget:JoyHat(hat, value) end
-- function widget:JoyButtonDown(button, state) end
-- function widget:JoyButtonUp(button, state) end
