local floor = Include.math.floor

function framework:FrameOfReference(xAnchor, yAnchor, body)
	local frame = { xAnchor = xAnchor, yAnchor = yAnchor, body = body, type = "FrameOfReference" }

	local width, height
	local rectWidth, rectHeight

	function frame:Layout(availableWidth, availableHeight)
		rectWidth, rectHeight = self.body:Layout(availableWidth, availableHeight)
		width = availableWidth
		height = availableHeight

		return availableWidth, availableHeight
	end

	function frame:Draw(x, y)
        LogDrawCall("FrameOfReference")
		self.body:Draw(x + floor((width - rectWidth) * self.xAnchor), y + floor((height - rectHeight) * self.yAnchor))
	end

	return frame
end