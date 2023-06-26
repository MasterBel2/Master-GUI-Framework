function framework:AbsoluteOffsetFromTopLeft(body, xOffset, yOffset)
	local absoluteOffset = { xOffset = xOffset, yOffset = yOffset }
	local width, height
	local _availableHeight

	function absoluteOffset:Layout(availableWidth, availableHeight)
		_availableHeight = availableHeight
		width, height = body:Layout(availableWidth - self.xOffset, availableHeight - self.yOffset)
		return width + self.xOffset, height + (availableHeight - self.yOffset)
	end

	function absoluteOffset:Draw(x, y)
		body:Draw(x + self.xOffset, y + _availableHeight - self.yOffset - height)
	end

	return absoluteOffset
end