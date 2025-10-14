local Internal = Internal
local ipairs = Include.ipairs
local pcall = Include.pcall
local pairs = Include.pairs
local Spring_Echo = Include.Spring.Echo

function HighestResponderAtPoint(x, y, event)
	for j = 1, #Internal.elementOrder do
		local element = Internal.elements[Internal.elementOrder[j]]
		local responders = element.drawingGroup.responderCache[event].responders
		
		local currentMatchingResponder
		
		local i = 0
		while i <= #responders - 1 do
			local responder = responders[#responders - i]
			local success, pointIsContained = pcall(responder.ContainsAbsolutePoint, responder, x, y)
			if success then
				if pointIsContained then
					currentMatchingResponder = responder
					responders = responder.responders
					i = 0
				else
					i = i + 1
				end
			else
				Error("HighestReceiverAtPoint", "Element: " .. element.key, "Responder:ContainsPoint", x, y, event, pointIsContained, responder._debugTypeIdentifier, responder._debugUniqueIdentifier)
				framework:RemoveElement(element.key)
				currentMatchingResponder = nil
				break
			end
		end

		if currentMatchingResponder then
			return element, currentMatchingResponder
		end
	end
end

-- Finds the topmost element whose PrimaryFrame contains the given point.
function Internal.CheckElementUnderMouse(x, y)
	if not Internal.hasCheckedElementBelowMouse then
		startProfile("MasterFramework:CheckUnderMouse")
		for index = 1, #Internal.elementOrder do
			local element = Internal.elements[Internal.elementOrder[index]]
			local primaryFrame = element.primaryFrame
			if primaryFrame ~= nil then -- Check for pre-initialised elements.
				local success, containsPoint = pcall(primaryFrame.ContainsAbsolutePoint, primaryFrame, x, y)
				if success then
					if containsPoint then
						Internal.elementBelowMouse = element
						return true
					end
				else
					Error("CheckUnderMouse", "Element: " .. key, "PrimaryFrame:ContainsAbsolutePoint", containsPoint)
					framework:RemoveElement(key)
					break
				end
			end
		end
		endProfile("MasterFramework:CheckUnderMouse")
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
		local success, containsPoint = pcall(childResponder.ContainsAbsolutePoint, childResponder, x, y)
		if not success then
			Error("SearchDownResponderTree", "childResponder:ContainsAbsolutePoint", containsPoint)
			break
		end

		if containsPoint then
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
	return SearchDownResponderTree(Internal.elementBelowMouse.drawingGroup.responderCache[event], x, y, ...)
end
