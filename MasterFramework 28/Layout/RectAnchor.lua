-- Positions a rect relative to another rect, with no impact on the layout of the original rect.
function framework:RectAnchor(rectToAnchorTo, anchoredRect, xAnchor, yAnchor)
	local rectAnchor = { rectToAnchorTo = rectToAnchorTo, anchoredRect = anchoredRect, xAnchor = xAnchor, yAnchor = yAnchor, type = "RectAnchor" }

	local rectToAnchorToWidth,rectToAnchorToHeight,anchoredRectWidth,anchoredRectHeight

	function rectAnchor:Layout(availableWidth, availableHeight)
		anchoredRectWidth, anchoredRectHeight = self.anchoredRect:Layout(availableWidth, availableHeight)
		rectToAnchorToWidth, rectToAnchorToHeight = self.rectToAnchorTo:Layout(availableWidth, availableHeight)
		return rectToAnchorToWidth, rectToAnchorToHeight
	end

	function rectAnchor:Draw(x, y)
		local rectToAnchorTo = self.rectToAnchorTo
		local anchoredRect = self.anchoredRect
		rectToAnchorTo:Draw(x, y)
		anchoredRect:Draw(x + floor((rectToAnchorToWidth - anchoredRectWidth) * self.xAnchor), y + floor((rectToAnchorToHeight - anchoredRectHeight) * self.yAnchor))
	end
	return rectAnchor
end