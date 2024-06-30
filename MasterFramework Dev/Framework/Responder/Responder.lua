local pairs = Include.pairs
local insert = Include.table.insert
local clear = Include.clear
local Internal = Internal

Internal.activeResponders = {}

local responderID = 0

function framework:Responder(rect, event, action)
	local responder = { action = action, responders = {}, _event = event }

	local width, height
	local cachedX, cachedY

	function responder:Size() return width, height end
	function responder:CachedPosition() return cachedX, cachedY end
	function responder:Geometry() return cachedX, cachedY, width, height end

	function responder:Layout(...)
		width, height = rect:Layout(...)
		return width, height
	end

	function responder:Position(x, y)
		-- Parent keeps track of the order of responders, and use that to decide who gets the interactions first
		local previousActiveResponder = Internal.activeResponders[event]
		if previousActiveResponder then
			insert(previousActiveResponder.responders, self)
			self.parent = previousActiveResponder
		end

		Internal.activeResponders[event] = self
		clear(self.responders)
		rect:Position(x, y)
		Internal.activeResponders[event] = previousActiveResponder
		
		cachedX = x
		cachedY = y
	end

	
	return responder
end