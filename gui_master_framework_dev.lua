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
	events = { mousePress = "mousePress", mouseWheel = "mouseWheel", mouseOver = "mouseOver" }, -- mouseMove = "mouseMove", mouseRelease = "mouseRelease" (Handled differently to other events – see dragListeners)
}

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

	frameworkInternal.SetDebugMode(true, false, false)

    framework.Internal = nil
    framework.Include = nil

	WG["MasterFramework " .. framework.compatabilityVersion] = framework
end

function widget:DebugInfo()
	return frameworkInternal.DebugInfo
end

function widget:GetTooltip(x, y)
	-- IsAbove is called before GetTooltip, so we can use the element found by that.
	framework.startProfile(frameworkInternal.elementBelowMouse.key .. ":GetTooltip")
	local tooltip = framework.FindTooltip(x, y, frameworkInternal.elementBelowMouse.tooltips)
	framework.endProfile(frameworkInternal.elementBelowMouse.key .. ":GetTooltip")
	if not tooltip then return nil end

	return tooltip.description
end
function widget:TweakGetTooltip(x, y)
end

function widget:TextInput(utf8char)
    if not frameworkInternal.focusTarget then return end

	framework.startProfile(frameworkInternal.focusTargetElementKey .. ":TextInput()")
	local success, errorMessage = pcall(frameworkInternal.focusTarget.TextInput, frameworkInternal.focusTarget, utf8char)
	framework.endProfile(frameworkInternal.focusTargetElementKey .. ":TextInput()")
	if not success then 
		framework.Error("widget:TextInput", "focusTarget:TextInput", errorMessage)
	end

    return true
end

function widget:KeyPress(key, mods, isRepeat, label, utf32char, scanCode, actionList)
    if not frameworkInternal.focusTarget then return end

	framework.startProfile(frameworkInternal.focusTargetElementKey .. ":KeyPress()")
	local success, errorMessage = pcall(frameworkInternal.focusTarget.KeyPress, frameworkInternal.focusTarget, key, mods, isRepeat, label, utf32char, scanCode, actionList)
	if not success then 
		framework.Error("widget:KeyPress", "focusTarget:KeyPress", errorMessage)
	end
	framework.endProfile(frameworkInternal.focusTargetElementKey .. ":KeyPress()")

    return true
end

function widget:KeyRelease(key, mods, label, utf32char, scanCode, actionList)
	if not frameworkInternal.focusTarget then return end
	framework.startProfile(frameworkInternal.focusTargetElementKey .. ":KeyRelease()")
	local success, errorMessage = pcall(frameworkInternal.focusTarget.KeyRelease, frameworkInternal.focusTarget, key, mods, label, utf32char, scanCode, actionList)
	framework.endProfile(frameworkInternal.focusTargetElementKey .. ":KeyRelease()")
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
			framework.startProfile(key .. ":deselect()")
			local element = frameworkInternal.elements[key]
			local success, errorMessage = pcall(element.deselect)
			if not success then
				framework.Error("widget:MousePress", "Element: " .. key, "element.deslect", errorMessage)
			end
			framework.endProfile(key .. ":deselect()")
		end
		return false
	end
	framework.startProfile(frameworkInternal.elementBelowMouse.key .. ":MousePress()")
	local result = frameworkInternal.FindResponder(framework.events.mousePress, x, y, button)
	framework.endProfile(frameworkInternal.elementBelowMouse.key .. ":MousePress()")
	return result
end

function widget:MouseMove(x, y, dx, dy, button)
	local dragListener = frameworkInternal.dragListeners[button]
	if dragListener ~= nil then
		framework.startProfile(frameworkInternal.dragListenerElementKeys[button] .. ":MouseMove()")
		local success, errorMessage = pcall(dragListener.MouseMove, dragListener, x, y, dx, dy, button)
		framework.endProfile(frameworkInternal.dragListenerElementKeys[button] .. ":MouseMove()")
		if not success then
			framework.Error("widget:MouseMove", "dragListener:MouseMove", errorMessage)
		end
	end
end

function widget:MouseRelease(x, y, button)
	local dragListener = frameworkInternal.dragListeners[button]
	if dragListener then
		framework.startProfile(frameworkInternal.dragListenerElementKeys[button] .. ":MouseRelease()")
		local success, errorMessage = pcall(dragListener.MouseRelease, dragListener, x, y, button)
		framework.endProfile(frameworkInternal.dragListenerElementKeys[button] .. ":MouseRelease()")
		if not success then
			framework.Error("widget:MouseRelease", "dragListener:MouseRelease", errorMessage)
		end
		frameworkInternal.dragListeners[button] = nil
		frameworkInternal.dragListenerElementKeys[button] = nil
	end
	return false
end

function widget:MouseWheel(up, value)
	local mouseX, mouseY = Spring.GetMouseState()
	if frameworkInternal.CheckElementUnderMouse(mouseX, mouseY) then
		framework.startProfile(frameworkInternal.elementBelowMouse.key .. ":MouseWheel()")
		local result = frameworkInternal.FindResponder(framework.events.mouseWheel, mouseX, mouseY, up, value)
		framework.endProfile(frameworkInternal.elementBelowMouse.key  .. ":MouseWheel()")
		return result
	else
		return false
	end
end

local isAbove
local isAboveChecked = false

function widget:IsAbove(x, y)
	if isAboveChecked then return frameworkInternal.elementBelowMouse ~= nil end

	if frameworkInternal.debugMode.draw then
		frameworkInternal.DebugInfo.elementBelowMouse = {}
		for _, element in pairs(frameworkInternal.elements) do
			frameworkInternal.SearchDownResponderTree(element.activeDebugResponder, x, y)
		end
	end

	framework.startProfile("IsAbove")

	local element, responder = framework.HighestResponderAtPoint(x, y, framework.events.mouseOver)
	frameworkInternal.elementBelowMouse = element

	frameworkInternal.DebugInfo.responderUnderMouse = responder and responder._debugUniqueIdentifier

	if responder ~= frameworkInternal.mouseOverResponder then
		local previousResponder = frameworkInternal.mouseOverResponder
		frameworkInternal.mouseOverResponder = responder
		local highestCommonResponder
		do
			local _responder = responder
			while _responder do
				if _responder.mouseIsOver then
					highestCommonResponder = _responder
					break
				else
					_responder.mouseIsOver = true
					_responder = responder.parent
				end
			end
		end
		do
			local _responder = previousResponder
			while _responder and _responder ~= highestCommonResponder do
				_responder.mouseIsOver = false
				_responder = _responder.parent
			end
		end
		do
			local _responder = previousResponder
			while _responder and _responder ~= highestCommonResponder do
					if _responder.MouseLeave then
						local success, maybeError = pcall(_responder.MouseLeave, _responder)
						if not success then
							framework.Error("IsAbove", "responder:MouseLeave", maybeError, "Element Key: " .. element.key, _responder._debugTypeIdentifier, _responder._debugUniqueIdentifier)
							framework:RemoveElement(element.key)
							break
						end
					end
				-- end
				_responder = _responder.parent
			end
		end
		do
			local _responder = responder
			while _responder and _responder ~= highestCommonResponder do
				if _responder.MouseEnter then
					local success, maybeError = pcall(_responder.MouseEnter, _responder)
					if not success then
						framework.Error("IsAbove", "responder:MouseEnter", maybeError, "Element Key: " .. element.key, _responder._debugTypeIdentifier, _responder._debugUniqueIdentifier)
						framework:RemoveElement(element.key)
						break
					end
				end
				_responder = _responder.parent
			end
		end
	end

	do
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
	end

	isAboveChecked = true

	framework.endProfile("IsAbove")

	return element ~= nil
end
function widget:Update()
	-- widget:IsAbove seems to be called multiple times a frame. To mitigate this, we'll call it once per function we *know* is called once per frame - in this case, Update().
	-- (It might be slightly more optimal (re performance) to call it in DrawScreen, but putting it in Update allows us to keep it right here where it's easy to read.)
	isAboveChecked = false
end

function widget:DrawScreen()
	framework.startProfile("DrawScreen")

	frameworkInternal.hasCheckedElementBelowMouse = false
	frameworkInternal.elementBelowMouse = nil
	local index = #frameworkInternal.elementOrder
	while 0 < index do
		local key = frameworkInternal.elementOrder[index]
		frameworkInternal.elements[key]:Draw()

		index = index - 1
	end
	framework.viewportDidChange = false
	if frameworkInternal.debugMode.draw then
		-- framework.Log("####")
		-- for caller, callCount in pairs(frameworkInternal.drawCalls) do
		-- 	framework.Log(caller .. ": " .. callCount)
		-- end
		frameworkInternal.drawCalls = {}
	end
	framework.endProfile("DrawScreen")
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
