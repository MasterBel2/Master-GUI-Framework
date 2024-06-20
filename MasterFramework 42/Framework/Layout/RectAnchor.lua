local floor = Include.math.floor

-- Positions a rect relative to another rect, with no impact on the layout of the original rect.
function framework:RectAnchor(rectToAnchorTo, anchoredRect, xAnchor, yAnchor)
	local rectAnchor = { rectToAnchorTo = rectToAnchorTo, anchoredRect = anchoredRect, xAnchor = xAnchor, yAnchor = yAnchor, type = "RectAnchor" }

	local rectToAnchorToWidth,rectToAnchorToHeight,anchoredRectWidth,anchoredRectHeight

	local cachedAnchorTo
	local cachedAnchoredRect
	local cachedXAnchor
	local cachedYAnchor

	function achor:LayoutChildren()
		return self, self.rectToAnchorTo:LayoutChildren(), self.cachedAnchoredRect:LayoutChildren()
	end

	function anchor:NeedsLayout()
		return cachedAnchorTo ~= self.rectToAnchorTo or cachedAnchoredRect ~= self.anchoredRect or cachedXAnchor ~= self.xAnchor or cachedYAnchor ~= self.yAnchor
	end

	function rectAnchor:Layout(availableWidth, availableHeight)
		anchoredRectWidth, anchoredRectHeight = self.anchoredRect:Layout(availableWidth, availableHeight)
		rectToAnchorToWidth, rectToAnchorToHeight = self.rectToAnchorTo:Layout(availableWidth, availableHeight)
		return rectToAnchorToWidth, rectToAnchorToHeight
	end

	function rectAnchor:Position(x, y)
		local rectToAnchorTo = self.rectToAnchorTo
		local anchoredRect = self.anchoredRect
		cachedXAnchor = self.xAnchor
		cachedYAnchor = self.yAnchor
		rectToAnchorTo:Position(x, y)
		anchoredRect:Position(x + floor((rectToAnchorToWidth - anchoredRectWidth) * cachedXAnchor), y + floor((rectToAnchorToHeight - anchoredRectHeight) * cachedYAnchor))
	end
	return rectAnchor
end