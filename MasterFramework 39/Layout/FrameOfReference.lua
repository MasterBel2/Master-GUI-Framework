local floor = Include.math.floor

function framework:FrameOfReference(xAnchor, yAnchor, body)
	local frame = { xAnchor = xAnchor, yAnchor = yAnchor, body = body, type = "FrameOfReference" }

	local width, height
	local rectWidth, rectHeight

	local cachedXAnchor
	local cachedYAnchor
	local cachedBody

	function frame:LayoutChildren()
		return self, self.body:LayoutChildren()
	end

	function frame:NeedsLayout()
		return cachedXAnchor ~= self.xAnchor or cachedYAnchor ~= self.yAnchor or cachedBody ~= self.body
	end

	function frame:Layout(availableWidth, availableHeight)
		cachedBody = self.body
		rectWidth, rectHeight = cachedBody:Layout(availableWidth, availableHeight)
		width = availableWidth
		height = availableHeight

		return availableWidth, availableHeight
	end

	function frame:Position(x, y)
		cachedXAnchor = self.xAnchor
		cachedYAnchor = self.yAnchor
		cachedBody:Position(x + floor((width - rectWidth) * cachedXAnchor), y + floor((height - rectHeight) * cachedYAnchor))
	end

	return frame
end