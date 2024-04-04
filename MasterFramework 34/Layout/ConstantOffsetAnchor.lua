function framework:ConstantOffsetAnchor(rectToAnchorTo, anchoredRect, xOffset, yOffset)
	local anchor = { rectToAnchorTo = rectToAnchorTo, anchoredRect = anchoredRect, xOffset = xOffset, yOffset = yOffset }

	function anchor:Layout(availableWidth, availableHeight)
		rectToAnchorToWidth, rectToAnchorToHeight = self.rectToAnchorTo:Layout(availableWidth, availableHeight)
		anchoredRectWidth, anchoredRectHeight = self.anchoredRect:Layout(availableWidth, availableHeight)
		return rectToAnchorToWidth, rectToAnchorToHeight
	end

	function anchor:Position(x, y)
        self.rectToAnchorTo:Position(x, y)
        self.anchoredRect:Position(x + self.xOffset, y + self.yOffset)
	end
	return anchor
end