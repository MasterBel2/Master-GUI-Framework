local Internal = Internal
local ipairs = Include.ipairs
local pcall = Include.pcall
local pairs = Include.pairs
local Spring_Echo = Include.Spring.Echo

-- Finds the topmost element whose PrimaryFrame contains the given point.
function Internal.CheckElementUnderMouse(x, y)
	if not Internal.hasCheckedElementBelowMouse then
		for _, key in ipairs(Internal.elementOrder) do
			local element = Internal.elements[key]
			local primaryFrame = element.primaryFrame
			if primaryFrame ~= nil then -- Check for pre-initialised elements.
				local success, frameX, frameY, frameWidth, frameHeight = pcall(primaryFrame.Geometry, primaryFrame)
				if not success then
					-- frameX contains the error if this fails
					Error("CheckUnderMouse", "Element: " .. key, "PrimaryFrame:Geometry", frameX)
					break
				end
				if not (x and y and frameX and frameY and frameWidth and frameHeight) then
					Error("CheckUnderMouse", "Element: " .. key, "PrimaryFrame:Geometry is incomplete: " .. (frameX or "nil") .. ", " .. (frameY or "nil") .. ", " .. (frameWidth or "nil") .. ", " .. (frameHeight or "nil"))
					break
				end
				if PointIsInRect(x, y, frameX, frameY, frameWidth, frameHeight) then
					Internal.elementBelowMouse = element
					return true
				end
			end
		end
	end

	return Internal.elementBelowMouse ~= nil
end

-- Attempts to call an action on a responder, then recursively calls Event on the parent (if one exists) in the case of failure. 
local function Event(responder, ...)
	local success, result = pcall(responder.action, responder, ...)
	if not success then
		-- in case of failure, result stores the error message'
		Spring_Echo(responder.action)
		Spring_Echo("debugIdentifier", responder._debugIdentifier)
		Error("Event", "responder:action", result)
		return nil
	elseif result then
		return responder
	else
		local parent = responder.parent
		if parent ~= nil then
			return Event(parent, ...)
		end
	end
end
Internal.Event = Event

-- Calls an action on the top-most responder containing the specified point, failingover to its parent responder. Returns the responder that calls the action.
local function SearchDownResponderTree(responder, x, y, ...)
	if not (x and y) then
		Error("SearchDownResponderTree", "childResponder:Geometry", "x or y is nil: " .. (x or "nil") .. ", " .. (y or "nil"))
	end
	local childResponderCount = #responder.responders
	for i = 0, childResponderCount - 1 do
		local childResponder = responder.responders[childResponderCount - i]
		local success, responderX, responderY, responderWidth, responderHeight = pcall(childResponder.Geometry, childResponder)
		if not success then
			-- responderX contains the error if this fails
			Error("SearchDownResponderTree", "childResponder:Geometry", responderX)
			break
		end
		if not (responderX and responderY and responderWidth and responderHeight) then
			Error("SearchDownResponderTree", "childResponder:Geometry is incomplete: " .. (responderX or "nil") .. ", " .. (responderY or "nil") .. ", " .. (responderWidth or "nil") .. ", " .. (responderHeight or "nil"), responder._debugTypeIdentifier or "nil", (responder.rect and responder.rect._debugTypeIdentifier) or "nil", (responder._isDebugResponder and "true") or "false", (responder.noRect and "true") or "false")
			break
		end

		if PointIsInRect(x, y, responderX, responderY, responderWidth, responderHeight) then
			local favouredResponder = SearchDownResponderTree(childResponder, x, y, ...)
			if favouredResponder then
				return favouredResponder
			else
				return Event(childResponder, x, y, ...)
			end
		end
	end
	return Event(responder, x, y, ...)
end
Internal.SearchDownResponderTree = SearchDownResponderTree

-- Calls the base responder for a given event on the current element below mouse. 
function Internal.FindResponder(event, x, y, ...)
	return SearchDownResponderTree(Internal.elementBelowMouse.baseResponders[event], x, y, ...)
end
