function framework:ConstantOffsetAnchor(rectToAnchorTo, anchoredRect, xOffset, yOffset)
	local anchor = Component(true, false)

	local xOffset
	local yOffset

	function anchor:SetOffsets(newXOffset, newYOffset)
		if newXOffset ~= xOffset or newYOffset ~= yOffset then
			xOffset = newXOffset
			yOffset = newYOffset
			self:NeedsPosition()
		end
	end
	
	function anchor:Layout(availableWidth, availableHeight)
		self:RegisterDrawingGroup()
		rectToAnchorToWidth, rectToAnchorToHeight = rectToAnchorTo:Layout(availableWidth, availableHeight)
		anchoredRectWidth, anchoredRectHeight = anchoredRect:Layout(availableWidth, availableHeight)
		
		return rectToAnchorToWidth, rectToAnchorToHeight
	end

	function anchor:Position(x, y)
        rectToAnchorTo:Position(x, y)
        anchoredRect:Position(x + xOffset, y + yOffset)
	end
	return anchor
end