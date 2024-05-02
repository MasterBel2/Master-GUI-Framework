function framework:AbsoluteOffsetFromTopLeft(body, xOffset, yOffset)
	local absoluteOffset = { xOffset = xOffset, yOffset = yOffset }
	local width, height
	local _availableHeight

	local cachedXOffset
	local cachedYOffset
	function absoluteOffset:NeedsLayout()
		return body:NeedsLayout() or cachedXOffset ~= self.xOffset or cachedYOffset ~= self.yOffset
	end

	function absoluteOffset:Layout(availableWidth, availableHeight)
		_availableHeight = availableHeight
		cachedXOffset = self.xOffset
		cachedYOffset = self.yOffset
		width, height = body:Layout(availableWidth - cachedXOffset, availableHeight - cachedYOffset)
		return width + cachedXOffset, height + (availableHeight - cachedYOffset)
	end

	function absoluteOffset:Position(x, y)
		body:Position(x + cachedXOffset, y + _availableHeight - cachedYOffset - height)
	end

	return absoluteOffset
end