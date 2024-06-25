local pairs = Include.pairs
local insert = Include.table.insert
local clear = Include.clear
local Internal = Internal

local responderID = 0

function framework:Responder(rect, event, action)
	local responder = { action = action, responders = {}, id = responderID, _event = event }
	responderID = responderID + 1

	local width, height
	local cachedX, cachedY

	function responder:Size() return width, height end
	function responder:CachedPosition() return cachedX, cachedY end
	function responder:Geometry() return cachedX, cachedY, width, height end

	local laidOut
	function responder:Layout(...)
		laidOut = true
		width, height = rect:Layout(...)
		return width, height
	end

	function responder:Position(x, y)
		if not laidOut then
			Log("We havent laid out yet!")
			Log(self._debugTypeIdentifier)
			Log(self._debugUniqueIdentifier)
			if self._debug_mouseOverResponder then
				local path = self._debugTypeIdentifier
				local x = self._debug_mouseOverResponder.parent
				for i = 1, 1000 do
					if not x then break end
					path = (x._debugTypeIdentifier or "Unknown") .. "/" .. path
					x = x.parent
				end
				Log(path)
			end
		end
		if not rect then Log("We dont have a rect!") end

		-- Parent keeps track of the order of responders, and use that to decide who gets the interactions first
		local previousActiveResponder = Internal.activeResponders[event]
		insert(previousActiveResponder.responders, self)
		self.parent = previousActiveResponder

		Internal.activeResponders[event] = self
		clear(self.responders)
		rect:Position(x, y)
		Internal.activeResponders[event] = previousActiveResponder
		
		cachedX = x
		cachedY = y
	end

	
	return responder
end