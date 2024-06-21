local floor = Include.math.floor

function framework:FrameOfReference(xAnchor, yAnchor, body)
	local frame = { xAnchor = xAnchor, yAnchor = yAnchor, type = "FrameOfReference" }

	local width, height
	local rectWidth, rectHeight

	local cachedXAnchor
	local cachedYAnchor

	function frame:LayoutChildren()
		return self, body:LayoutChildren()
	end

	function frame:NeedsLayout()
		return cachedXAnchor ~= self.xAnchor or cachedYAnchor ~= self.yAnchor
	end

	function frame:Layout(availableWidth, availableHeight)
		rectWidth, rectHeight = body:Layout(availableWidth, availableHeight)
		width = availableWidth
		height = availableHeight

		return availableWidth, availableHeight
	end

	function frame:Position(x, y)
		cachedXAnchor = self.xAnchor
		cachedYAnchor = self.yAnchor
		body:Position(x + floor((width - rectWidth) * cachedXAnchor), y + floor((height - rectHeight) * cachedYAnchor))
	end

	return frame
end