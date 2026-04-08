-- In order to receive enter and actions, the responder must return true to hover actions.
function framework:MouseOverResponder(rect, hoverAction, enterAction, leaveAction)

	-- arguments for mouseOver: responder, x, y
	local responder = self:Responder(rect, events.mouseOver, hoverAction)

	responder.mouseIsOver = false

	function responder:MouseEnter()
		enterAction(self)
	end
	function responder:MouseLeave()
		leaveAction(self)
	end

	return responder
end