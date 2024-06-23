local floor = Include.math.floor

function framework:FrameOfReference(xAnchor, yAnchor, body)
	local frame = Component(true, false)

	local width, height
	local rectWidth, rectHeight

	function frame:LayoutChildren()
		return body:LayoutChildren()
	end

	function frame:SetAnchors(newXAnchor, newYAnchor)
		if newXAnchor ~= xAnchor or newYAnchor ~= yAnchor then
			xAnchor = newXAnchor
			yAnchor = newYAnchor
			self:NeedsPosition()
		end
	end

	function frame:Layout(availableWidth, availableHeight)
		self:RegisterDrawingGroup()
		rectWidth, rectHeight = body:Layout(availableWidth, availableHeight)
		width = availableWidth
		height = availableHeight

		return availableWidth, availableHeight
	end

	function frame:Position(x, y)
		body:Position(x + floor((width - rectWidth) * xAnchor), y + floor((height - rectHeight) * yAnchor))
	end

	return frame
end