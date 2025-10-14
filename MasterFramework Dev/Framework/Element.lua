local error = Include.error
local pairs = Include.pairs
local ipairs = Include.ipairs
local table = Include.table
local clear = Include.clear
local pcall = Include.pcall
local Internal = Internal
local type = Include.type
local Spring_Echo = Include.Spring.Echo

------------------------------------------------------------------------------------------------------------
-- Layers
------------------------------------------------------------------------------------------------------------

-- A set of functions used to generate a layerRequest. 
-- 
-- These requests are not a guarantee for the element's lifetime; they only guarantee the placement of 
-- the element.
-- Use `framework:MoveElement()` to update its placement. 
layerRequest = {
	-- The new element will be placed directly above the specified element, such that if they overlap, 
-- the new element will be obscured.
	-- Parameter target: the key (returned by `InsertElement()`) of the element.
	--
	-- Returns a valid layer request.
	directlyBelow = function(target) return { mode = "below", target = target } end,

	-- The new element will be placed directly above the specified element, such that if they overlap, 
	-- the new element will not be obscured.
	-- Parameter target: the key (returned by `InsertElement()`) of the element. 
	--
	-- Returns a valid layer request.
	directlyAbove = function(target) return { mode = "above", target = target } end,

	-- The element will be placed above all other elements, such that if it overlaps any other element, 
	-- it will not be obscured.
	--
	-- Returns a valid layer request.
	top = function() return { mode = "top" } end,

	-- The element will be placed below all other elements, such that if it overlaps any other element, 
	-- it will be obscured.
	--
	-- Returns a valid layer request.
	bottom = function() return { mode = "bottom" } end,

	-- The element will be placed just above the elements that are supposed to be below everything else. 
	--
	-- Returns a valid layer request.
	anywhere = function() return { mode = "anywhere" } end,
}

local elementOrder = {}
Internal.elementOrder = elementOrder
Internal.elements = {}

function framework:GetElement(key)
	return Internal.elements[key]
end

-- TODO: Conflicts Per Name!
local conflicts = {}

-- Returns the index of the layer that
local function WantedLayer(layerRequest)
	if layerRequest.mode == "top" then
		return 1
	elseif layerRequest.mode == "bottom" then
		return #elementOrder + 1
	elseif layerRequest.mode == "below" then
		for i, key in ipairs(elementOrder) do
			if key == layerRequest.target then
				return i + 1
			end
		end
		error("Could not find element \"" .. layerRequest.target .. "\" to place below!")
	elseif layerRequest.mode == "above" then
		for i, key in ipairs(elementOrder) do
			if key == layerRequest.target then
				return i
			end
		end
		error("Could not find element \"" .. layerRequest.target .. "\" to place above!")
	elseif layerRequest.mode == "anywhere" then -- If it doesn't matter, we'll just place just above the elements that are supposed to be below everything else.
		for i, key in ipairs(elementOrder) do
			if Internal.elements[key].layerRequest.mode == "bottom" then
				return i
			end
		end
		return #elementOrder + 1
	else
		error("Unrecognised layer mode \"" .. tostring(layerRequest.mode) .. "\"!")
	end
end

local function removeOrderForElement(key)
	for index, elementKey in ipairs(elementOrder) do
		if key == elementKey then
			table.remove(elementOrder, index)
			return
		end
	end
end

-- 
-- Parameters:
--  - key: The key (returned by `framework:InsertElement()`) of the element to be placed.
--  - layerRequest: see `framework.layerRequest`
function framework:MoveElement(key, layerRequest)
	removeOrderForElement(key)
	table.insert(elementOrder, WantedLayer(layerRequest))
	element.layerRequest = layerRequest
end

------------------------------------------------------------------------------------------------------------
-- Add/Remove Elements
------------------------------------------------------------------------------------------------------------

local function UniqueKey(preferredKey)
	if Internal.elements[preferredKey] == nil then
		Log("Creating element with preferred key: \"" .. preferredKey .. "\"")
		return preferredKey
	else
		conflicts[preferredKey] = (conflicts[preferredKey] or 0) + 1
		local key = UniqueKey(preferredKey .. "_" .. conflicts[preferredKey])
		Log("Key " .. preferredKey .. " has already been taken! Assigning key " .. key .. " instead.")
		return key
	end
end

local function nullFunctionTrue() return true end
local function nullFunctionFalse() return false end

-- Adds an element to be drawn.
--
-- Parameters:
--  - body: A component as specified in the "Basic Components" section of this file. This component must 
--          either be or contain a `framework:PrimaryFrame`.
--  - preferredKey: A string that will be used to generate an identifying string for this element. 
--                  To avoid collisions, the key may be modified. The key actually used will be returned 
--                  by this function. 
--  - layerRequest: allows arrangement of various interface elements. See `framework.layerRequest` for more 
--                  detail.
--  - deselctAction: Nil, or a function to be called when a click is performed outside the bounds of a 
--                   selected element. (WARNING: THIS IS LIKELY BROKEN)
--
-- Returns a key (derived from preferredKey) that can be used to remove the element from the interface. 
-- The element will NOT be automatically removed. See `framework:RemoveElement()` for more detail.
function framework:InsertElement(body, preferredKey, layerRequest, deselectAction, allowInteractionBehind)
	-- Create element

	preferredKey = preferredKey or "Unknown"

	if not body then
		error("[framework:InsertElement] No body provided for element \"" .. preferredKey .. "\"")
	end

	local element = {
		body = body,
		primaryFrame = nil,
		tooltips = {},
		deselect = deselectAction or nullFunctionTrue,

		groupsNeedingLayout = {},
		groupsNeedingPosition = {}
	}
	local drawingGroup = framework:DrawingGroup(body)
	element.drawingGroup = drawingGroup

	function element:Draw()
		Internal.activeElement = self
		activeDrawingGroup = nil

		startProfile(self.key .. ":UpdateLayout()")
		local groupsNeedingLayout = self.groupsNeedingLayout
		self.groupsNeedingLayout = {}
		for drawingGroup, _ in pairs(groupsNeedingLayout) do
			local success, _error = pcall(drawingGroup.UpdateLayout, drawingGroup)
			if not success then
				Error("widget:DrawScreen", "Element: " .. self.key, "drawingGroup:UpdateLayout", _error)
				framework:RemoveElement(self.key)
			end
		end
		endProfile(self.key .. ":UpdateLayout()")

		startProfile(self.key .. ":UpdatePosition()")
		local groupsNeedingPosition = self.groupsNeedingPosition
		self.groupsNeedingPosition = {}
		for drawingGroup, _ in pairs(groupsNeedingPosition) do
			local success, _error = pcall(drawingGroup.UpdatePosition, drawingGroup)
			if not success then
				Error("widget:DrawScreen", "Element: " .. self.key, "drawingGroup:UpdatePosition", _error)
				framework:RemoveElement(self.key)
			end
		end
		endProfile(self.key .. ":UpdatePosition()")

		local success, _error = pcall(drawingGroup.Draw, drawingGroup, 0, 0)
		if not success then
			Error("widget:DrawScreen", "Element: " .. self.key, "drawingGroup:Draw", _error)
			framework:RemoveElement(self.key)
		end
	end

	local nullFunction = allowInteractionBehind and nullFunctionFalse or nullFunctionTrue

	for _, event in pairs(events) do
		element.drawingGroup.responderCache[event].action = nullFunction
		element.drawingGroup.responderCache[event]._debugIdentifier = "Base responder for " .. event
	end
	element.drawingGroup.responderCache[events.mousePress].MouseMove = nullFunction
	element.drawingGroup.responderCache[events.mouseOver].MouseEnter = nullFunction
	element.drawingGroup.responderCache[events.mouseOver].MouseLeave = nullFunction

	-- Create key

	local key = UniqueKey(preferredKey)

	if Internal.debugMode.draw then
		element.activeDebugResponder = {
			_debugTypeIdentifier = "Base Debug Responder",
			responders = {},
			-- FIXME
			ContainsAbsolutePoint = function(_, x, y) 
				return PointIsInRect(x, y, 0, 0, viewportWidth, viewportHeight)
			end,
			action = function(self)
				Internal.DebugInfo.elementBelowMouse[key] = {
					type = "Base",
					cachedX = 0,
					cachedY = 0,
					cachedWidth = viewportWidth,
					cachedHeight = viewportHeight,
					_debugTypeIdentifier = "Base Debug Responder for \"" .. key .. "\""  
				}
			end
		}
	end

	element.key = key
	Internal.elements[key] = element

	local wantedLayer = WantedLayer(layerRequest or self.layerRequest.anywhere())
	table.insert(elementOrder, wantedLayer, key)
	element.layerRequest = layerRequest

	Internal.activeElement = element
	activeDrawingGroup = nil
	local success, _error = pcall(element.drawingGroup.Layout, element.drawingGroup, viewportWidth, viewportHeight)
	if not success then
		Error("Element: " .. element.key, "drawingGroup:Layout(viewportWidth, viewportHeight)", _error)
		framework:RemoveElement(element.key)
	end

	if not element.primaryFrame then
		Error("Element: " .. element.key, "No `PrimaryFrame` in view hierarchy!")
		framework:RemoveElement(element.key)
	end

	local success, _error = pcall(element.drawingGroup.Position, element.drawingGroup, 0, 0)
	if not success then
		Error("Element: " .. element.key, "drawingGroup:Position(0, 0)", _error)
		framework:RemoveElement(element.key)
	end
	Internal.activeElement = nil

	return key, element
end

-- Removes an element from the display.
--
-- Parameters:
--  - key: the key returned from `framework:InsertElement()` when the element was inserted.
function framework:RemoveElement(key)
	if key ~= nil then
		Log("Removed " .. key)
		Internal.elements[key] = nil
		removeOrderForElement(key)
	else
		Log("Could not remove element: Key is nill!")
	end
end
