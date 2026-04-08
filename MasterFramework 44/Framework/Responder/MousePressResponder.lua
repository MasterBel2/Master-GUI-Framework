local Internal = Internal

Internal.dragListeners = {}

function framework:MousePressResponder(rect, downAction, moveAction, releaseAction)
	local responder = framework:Responder(rect, events.mousePress, nil)

	responder.downAction = downAction
	responder.moveAction = moveAction
	responder.releaseAction = releaseAction

	function responder:action(x, y, button)
		responder.button = button
		Internal.dragListeners[button] = responder
		return responder:downAction(x, y, button)
	end

	function responder:MouseMove(x, y, dx, dy, button)
		self:moveAction(x, y, dx, dy, button)
	end
	
	function responder:MouseRelease(x, y, button)
		-- The call site will remove as a drag listener
		self:releaseAction(x, y, button)
	end

	return responder
end