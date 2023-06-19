function framework:ConstantOffsetAnchor(rectToAnchorTo, anchoredRect, xOffset, yOffset)
	local anchor = { rectToAnchorTo = rectToAnchorTo, anchoredRect = anchoredRect, xOffset = xOffset, yOffset = yOffset }

	function anchor:Layout(availableWidth, availableHeight)
		rectToAnchorToWidth, rectToAnchorToHeight = self.rectToAnchorTo:Layout(availableWidth, availableHeight)
		anchoredRectWidth, anchoredRectHeight = self.anchoredRect:Layout(availableWidth, availableHeight)
		return rectToAnchorToWidth, rectToAnchorToHeight
	end

	function anchor:Draw(x, y)
		LogDrawCall("ConstantOffsetAnchor")
        self.rectToAnchorTo:Draw(x, y)
        self.anchoredRect:Draw(x + self.xOffset, y + self.yOffset)
	end
	return anchor
end