function framework:ConstantOffsetAnchor(rectToAnchorTo, anchoredRect, xOffset, yOffset)
	local anchor = { rectToAnchorTo = rectToAnchorTo, anchoredRect = anchoredRect, xOffset = xOffset, yOffset = yOffset }

	local cachedAnchorTo
	local cachedAnchoredRect
	local cachedXOffset
	local cachedYOffset

	function anchor:LayoutChildren()
		return self, self.anchoredRect:LayoutChildren(), self.rectToAnchorTo:LayoutChildren()
	end

	function anchor:NeedsLayout()
		return cachedAnchorTo ~= self.rectToAnchorTo or cachedAnchoredRect ~= self.anchoredRect or cachedXOffset ~= self.xOffset or cachedYOffset ~= self.yOffset
	end

	function anchor:Layout(availableWidth, availableHeight)
		cachedAnchorTo = self.rectToAnchorTo
		cachedAnchoredRect = self.anchoredRect

		rectToAnchorToWidth, rectToAnchorToHeight = cachedAnchorTo:Layout(availableWidth, availableHeight)
		anchoredRectWidth, anchoredRectHeight = cachedAnchoredRect:Layout(availableWidth, availableHeight)
		return rectToAnchorToWidth, rectToAnchorToHeight
	end

	function anchor:Position(x, y)
		cachedXOffset = self.xOffset
		cachedYOffset = self.yOffset
        cachedAnchorTo:Position(x, y)
        cachedAnchoredRect:Position(x + cachedXOffset, y + cachedYOffset)
	end
	return anchor
end