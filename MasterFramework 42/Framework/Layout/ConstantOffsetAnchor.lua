function framework:ConstantOffsetAnchor(rectToAnchorTo, anchoredRect, xOffset, yOffset)
	local anchor = { xOffset = xOffset, yOffset = yOffset }

	local cachedXOffset
	local cachedYOffset

	function anchor:LayoutChildren()
		return self, anchoredRect:LayoutChildren(), rectToAnchorTo:LayoutChildren()
	end

	function anchor:NeedsLayout()
		return cachedXOffset ~= self.xOffset or cachedYOffset ~= self.yOffset
	end

	function anchor:Layout(availableWidth, availableHeight)
		rectToAnchorToWidth, rectToAnchorToHeight = rectToAnchorTo:Layout(availableWidth, availableHeight)
		anchoredRectWidth, anchoredRectHeight = anchoredRect:Layout(availableWidth, availableHeight)
		
		return rectToAnchorToWidth, rectToAnchorToHeight
	end

	function anchor:Position(x, y)
		cachedXOffset = self.xOffset
		cachedYOffset = self.yOffset
        rectToAnchorTo:Position(x, y)
        anchoredRect:Position(x + cachedXOffset, y + cachedYOffset)
	end
	return anchor
end