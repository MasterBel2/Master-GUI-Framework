local Internal = Internal
local widgetHandler = Include.widgetHandler
local Spring_SDLStartTextInput = Include.Spring.SDLStartTextInput

function framework:TakeFocus(newFocusTarget)
	if Internal.focusTarget then
		Internal.focusTarget:ReleaseFocus()
	end
	if widgetHandler:OwnText() then
		Spring_SDLStartTextInput()
		Internal.focusTarget = newFocusTarget
		Internal.focusTargetElementKey = Internal.activeElement.key
		return true
	end
end

-- NOTE: this is to be called by focusTarget, not by anything else! We don't tell focusTarget that we took
-- focus away from them, 
function framework:ReleaseFocus(requestingFocusTarget)
	if requestingFocusTarget == Internal.focusTarget then
		Internal.focusTarget = nil
		Internal.focusTargetElementKey = nil
		return widgetHandler:DisownText()
	end
end

function framework:FocusTarget()
	return Internal.focusTarget
end