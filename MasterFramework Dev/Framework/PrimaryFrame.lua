local Internal = Internal

local nextID = 0
function framework:PrimaryFrame(body)
	local primaryFrame = self:GeometryTarget(body)

	local _Layout = self.Layout
	function primaryFrame:Layout(availableWidth, availableHeight)
		if not Internal.activeElement.primaryFrame then
			Internal.activeElement.primaryFrame = self
		end
		return _Layout(self, availableWidth, availableHeight)
	end

	return primaryFrame
end