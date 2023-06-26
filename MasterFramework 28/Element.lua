local pairs = Include.pairs
local ipairs = Include.ipairs
local table = Include.table
local clear = Include.clear
local pcall = Include.pcall
local Internal = Internal

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

local function nullFunction() end

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
function framework:InsertElement(body, preferredKey, layerRequest, deselectAction)
	-- Create element

	preferredKey = preferredKey or "Unknown"

	if not body then
		error("[framework:InsertElement] No body provided for element \"" .. preferredKey .. "\"")
	end

	local element = { 
		body = body,
		primaryFrame = nil, 
		tooltips = {}, 
		baseResponders = {},
		deselect = deselectAction or function() end
	}

	function element:Draw()
		Internal.activeElement = element
		Internal.activeTooltip = element
		Internal.activeResponders = element.baseResponders
		for _, responder in pairs(Internal.activeResponders) do
			clear(responder.responders)
		end

		startProfile(self.key .. ":Layout()")
		local success, _error = pcall(body.Layout, body, viewportWidth, viewportHeight)
		if not success then
			Error("widget:DrawScreen", "Element: " .. self.key, "elementBody:Layout", _error)
			framework:RemoveElement(self.key)
		end
		endProfile()

		startProfile(self.key .. ":Draw()")
		local success, _error = pcall(body.Draw, body, 0, 0)
		if not success then
			Error("widget:DrawScreen", "Element: " .. self.key, "elementBody:Draw", _error)
			framework:RemoveElement(self.key)
		end
		endProfile()
	end

	for _, event in pairs(events) do
		element.baseResponders[event] = { responders = {}, action = nullFunction }
	end

	-- Create key

	local key = UniqueKey(preferredKey)

	element.key = key 
	Internal.elements[key] = element

	local wantedLayer = WantedLayer(layerRequest or self.layerRequest.anywhere())
	table.insert(elementOrder, wantedLayer, key)
	element.layerRequest = layerRequest

	return key
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
