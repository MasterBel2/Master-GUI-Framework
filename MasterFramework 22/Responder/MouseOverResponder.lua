-- In order to receive enter and actions, the responder must return true to hover actions.
function framework:MouseOverResponder(rect, hoverAction, enterAction, leaveAction)

	-- arguments for mouseOver: responder, x, y
	local responder = self:Responder(rect, events.mouseOver, hoverAction)

	local mouseIsOver = false

	function responder:MouseEnter()
		mouseIsOver = true
		enterAction(self)
	end
	function responder:MouseLeave()
		mouseIsOver = false
		leaveAction(self)
	end
	function responder:MouseIsOver()
		return mouseIsOver
	end

	return responder
end