local pairs = Include.pairs
local insert = Include.table.insert
local clear = Include.clear
local Internal = Internal

Internal.activeResponders = {}

function framework:Responder(rect, event, action)
	local responder = self:GeometryTarget(rect)
	responder.action = action
	responder.responders = {}
	responder._event = event

	local _Position = responder.Position

	function responder:Position(x, y)
		-- Parent keeps track of the order of responders, and use that to decide who gets the interactions first
		local previousActiveResponder = Internal.activeResponders[event]
		if previousActiveResponder then
			insert(previousActiveResponder.responders, self)
			self.parent = previousActiveResponder
		end

		Internal.activeResponders[event] = self
		clear(self.responders)
		_Position(self, x, y)
		Internal.activeResponders[event] = previousActiveResponder
	end
	
	return responder
end