function framework:AbsoluteOffsetFromTopLeft(body, xOffset, yOffset)
	local absoluteOffset = Component(true, false)
	local width, height
	local _availableHeight

	function absoluteOffset:SetOffsets(newXOffset, newYOffset)
		if newXOffset ~= xOffset or newYOffset ~= yOffset then
			xOffset = newXOffset
			yOffset = newYOffset
			self:NeedsLayout()
		end
	end

	function absoluteOffset:Layout(availableWidth, availableHeight)
		_availableHeight = availableHeight
		width, height = body:Layout(availableWidth - xOffset, availableHeight - yOffset)
		return width + xOffset, height + (availableHeight - yOffset)
	end

	function absoluteOffset:Position(x, y)
		body:Position(x + xOffset, y + _availableHeight - yOffset - height)
	end

	return absoluteOffset
end