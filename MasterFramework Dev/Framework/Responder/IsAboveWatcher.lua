local Internal = Internal
local pcall = Include.pcall

local watcherID = 0
-- Tracks which responders the mouse cursor is above along the entire responder chain, and notifies them
-- when the cursor enters and leaves their bounds.
Internal.IsAboveWatcher = function()
	local object = {}
	local lastResponderBelow

	local nestedWatcher

	-- Updates the last responder below, and the nested watcher.
	function object:Update(responderUnderMouse, x, y)

		if lastResponderBelow then
			if (not responderUnderMouse) or (responderUnderMouse ~= lastResponderBelow) then
				local success, errorMessage = pcall(lastResponderBelow.MouseLeave, lastResponderBelow)
				if not success then
					Error("IsAboveWatcher:Update", "lastResponderBelow:MouseLeave", errorMessage)
				end
				nestedWatcher:Reset()
				nestedWatcher = nil
			end
		end

		if responderUnderMouse then
			if (not lastResponderBelow) or (lastResponderBelow ~= responderUnderMouse) then
				local success, errorMessage = pcall(responderUnderMouse.MouseEnter, responderUnderMouse)
				if not success then
					Error("IsAboveWatcher:Update", "responderUnderMouse:MouseEnter", errorMessage)
				end
				nestedWatcher = Internal.IsAboveWatcher()
			end
			nestedWatcher:Bubble(responderUnderMouse, x, y)
		end

		lastResponderBelow = responderUnderMouse
	end

	-- Recursively searches for another responder that might handle the event, and triggers the events.
	function object:Bubble(responder, x, y)
		if responder and responder.parent then
			local responderUnderMouse = Internal.Event(responder.parent, x, y)
			self:Update(responderUnderMouse, x, y)
		else
			self:Reset()
		end
	end

	-- Locates the most deeply nested responder, and begins watching it.
	function object:Search(responder, x, y)
		self:Update(Internal.SearchDownResponderTree(responder, x, y), x, y)
	end

	-- Informs the watcher there is no responder to watch.
	function object:Reset()
		if lastResponderBelow then
			local success, errorMessage = pcall(lastResponderBelow.MouseLeave, lastResponderBelow)
			if not success then
				Error("IsAboveWatcher:Reset", "lastResponderBelow:MouseLeave", errorMessage)
			end
		end
		self:Update(nil, nil, nil)
	end

	return object
end