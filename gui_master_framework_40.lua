------------------------------------------------------------------------------------------------------------
-- Metadata
------------------------------------------------------------------------------------------------------------

-- https://github.com/MasterBel2/Master-GUI-Framework

local compatabilityVersion = 40

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

local isAboveThing

local function clear(array)
	for index = 1, #array do
		remove(array)
	end
end

if not WG.MasterFramework then WG.MasterFramework = {} end
WG.MasterFramework[framework.compatabilityVersion] = framework

function widget:SetConfigData(data)
	frameworkInternal.ConfigData = data or {}
end

function widget:GetConfigData()
	return frameworkInternal.ConfigData
end

function widget:Initialize()
    local DIR = LUAUI_DIRNAME .. "MasterFramework " .. compatabilityVersion

    local fileTree = FileTree(DIR)

    framework.Internal = frameworkInternal

    framework.Include = {
        error = error,
        pairs = pairs,
        ipairs = ipairs,
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
		os = os,

        widgetHandler = widgetHandler,

        debug = debug,

        error = error,
        Spring = Spring,
        VFS = VFS,
		WG = WG,

        GL = GL,
        gl = gl,

		-- custom
		clear = clear,
    }
    framework.framework = framework

    ForAllFiles(fileTree, function(filePath)
        if filePath:find(".+%.lua") then
            VFS.Include(filePath, framework)
        end
    end)

	-- I'd like these to move out somewhere... maybe

	framework.color = {
		white = framework:Color(1, 1, 1, 1),
		red = framework:Color(1, 0, 0, 1),
		green = framework:Color(0, 1, 0, 1),
		blue = framework:Color(0, 0, 1, 1),
		black = framework:Color(0, 0, 0, 1),
	
		baseBackgroundColor = framework:Color(0, 0, 0, 0.66),
	
		selectedColor = framework:Color(0.66, 1, 1, 0.66),
		pressColor    = framework:Color(0.66, 0.66, 1, 0.66),
		hoverColor    = framework:Color(1, 1, 1, 0.33) -- previously, this was 1, 1, 1, 0.66
	}
	
	framework.stroke = {
		defaultBorder = framework:Stroke(framework:Dimension(1), framework.color.hoverColor)
	}

	framework.dimension = {
        smallCornerRadius = framework:Dimension(2),
        defaultMargin = framework:Dimension(8),
        defaultCornerRadius = framework:Dimension(5),
        elementSpacing = framework:Dimension(1),
        groupSpacing = framework:Dimension(5)
	}

	framework.defaultFont = framework:Font("FreeSansBold.otf", 12)

    local viewSizeX, viewSizeY = Spring.GetViewGeometry()

	frameworkInternal.updateScreenEnvironment(viewSizeX, viewSizeY, framework.relativeScaleFactor)

	frameworkInternal.SetDebugMode(false, false, false)

    isAboveThing = frameworkInternal.IsAboveWatcher()

    framework.Internal = nil
    framework.Include = nil
end

function widget:DebugInfo()
	return frameworkInternal.DebugInfo
end

function widget:GetTooltip(x, y)
	-- IsAbove is called before GetTooltip, so we can use the element found by that.
	local tooltip = framework.FindTooltip(x, y, frameworkInternal.elementBelowMouse.tooltips)
	if not tooltip then return nil end

	return tooltip.description
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
	return frameworkInternal.FindResponder(framework.events.mousePress, x, y, button)
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
		return frameworkInternal.FindResponder(framework.events.mouseWheel, mouseX, mouseY, up, value)
	else
		return false
	end
end

local isAbove
local isAboveChecked = false
function widget:IsAbove(x, y)
	if isAboveChecked then return end

	if frameworkInternal.debugMode.draw then
		frameworkInternal.DebugInfo.elementBelowMouse = {}
		for _, element in pairs(frameworkInternal.elements) do
			frameworkInternal.SearchDownResponderTree(element.activeDebugResponder, x, y)
			
		end
	end

	-- startProfile("IsAbove")
	local isAbove
	-- for i=0,1000 do
		isAbove = frameworkInternal.CheckElementUnderMouse(x, y)
		if isAbove then
			isAboveThing:Search(frameworkInternal.elementBelowMouse.baseResponders[framework.events.mouseOver], x, y)
		else
			isAboveThing:Reset()
		end
	-- end
	-- endProfile()
	isAboveChecked = true
	return isAbove
end
function widget:Update()
	-- widget:IsAbove seems to be called multiple times a frame. To mitigate this, we'll call it once per function we *know* is called once per frame - in this case, Update().
	-- (It might be slightly more optimal (re performance) to call it in DrawScreen, but putting it in Update allows us to keep it right here where it's easy to read.)
	isAboveChecked = false
end

function widget:DrawScreen()
	-- startProfile("DrawScreen")
	frameworkInternal.hasCheckedElementBelowMouse = false
	frameworkInternal.elementBelowMouse = nil
	local index = #frameworkInternal.elementOrder
	while 0 < index do
		local key = frameworkInternal.elementOrder[index]
		index = index - 1
		local element = frameworkInternal.elements[key]

		if frameworkInternal.debugMode.draw then
			element.activeDebugResponder.responders = {}
			frameworkInternal._debug_currentElementKey = key
		end

		element:Draw()
	end
	framework.viewportDidChange = false
	if frameworkInternal.debugMode.draw then
		-- framework.Log("####")
		-- for caller, callCount in pairs(frameworkInternal.drawCalls) do
		-- 	framework.Log(caller .. ": " .. callCount)
		-- end
		frameworkInternal.drawCalls = {}
	end
	-- endProfile()
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
