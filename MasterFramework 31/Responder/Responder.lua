local pairs = Include.pairs
local insert = Include.table.insert
local clear = Include.clear
local Internal = Internal

local responderID = 0

function framework:Responder(rect, event, action)
	local responder = { rect = rect, action = action, responders = {}, id = responderID }
	responderID = responderID + 1

	local width, height
	local cachedX, cachedY

	function responder:Size() return width, height end
	function responder:CachedPosition() return cachedX, cachedY end
	function responder:Geometry() return cachedX, cachedY, width, height end

	function responder:Layout(...)
		width, height = self.rect:Layout(...)
		return width, height
	end

	function responder:Draw(x, y)

		-- Parent keeps track of the order of responders, and use that to decide who gets the interactions first
		local previousActiveResponder = Internal.activeResponders[event]
		insert(previousActiveResponder.responders, self)
		self.parent = previousActiveResponder

		Internal.activeResponders[event] = self
		clear(self.responders)
		self.rect:Draw(x, y)
		Internal.activeResponders[event] = previousActiveResponder
		
		cachedX = x
		cachedY = y
	end

	
	return responder
end