local floor = Include.math.floor

-- Positions a rect relative to another rect, with no impact on the layout of the original rect.
function framework:RectAnchor(rectToAnchorTo, anchoredRect, xAnchor, yAnchor)
	local rectAnchor = { xAnchor = xAnchor, yAnchor = yAnchor, type = "RectAnchor" }

	local rectToAnchorToWidth, rectToAnchorToHeight, anchoredRectWidth, anchoredRectHeight

	local cachedXAnchor
	local cachedYAnchor

	function achor:LayoutChildren()
		return self, rectToAnchorTo:LayoutChildren(), anchoredRect:LayoutChildren()
	end

	function anchor:NeedsLayout()
		return cachedXAnchor ~= self.xAnchor or cachedYAnchor ~= self.yAnchor
	end

	function rectAnchor:Layout(availableWidth, availableHeight)
		anchoredRectWidth, anchoredRectHeight = anchoredRect:Layout(availableWidth, availableHeight)
		rectToAnchorToWidth, rectToAnchorToHeight = rectToAnchorTo:Layout(availableWidth, availableHeight)
		return rectToAnchorToWidth, rectToAnchorToHeight
	end

	function rectAnchor:Position(x, y)
		cachedXAnchor = self.xAnchor
		cachedYAnchor = self.yAnchor
		rectToAnchorTo:Position(x, y)
		anchoredRect:Position(x + floor((rectToAnchorToWidth - anchoredRectWidth) * cachedXAnchor), y + floor((rectToAnchorToHeight - anchoredRectHeight) * cachedYAnchor))
	end
	
	return rectAnchor
end