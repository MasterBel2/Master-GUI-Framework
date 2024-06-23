local floor = Include.math.floor

-- Positions a rect relative to another rect, with no impact on the layout of the original rect.
function framework:RectAnchor(rectToAnchorTo, anchoredRect, xAnchor, yAnchor)
	local rectAnchor = Component(true, false)

	local rectToAnchorToWidth, rectToAnchorToHeight, anchoredRectWidth, anchoredRectHeight

	function anchor:SetAnchors(newXAnchor, yAnchor)
		if xAnchor ~= newXAnchor or yAnchor ~= newYAnchor then
			xAnchor = newXAnchor
			yAnchor = newYAnchor
			self:NeedsPosition()
		end
	end

	function achor:LayoutChildren()
		return rectToAnchorTo:LayoutChildren(), anchoredRect:LayoutChildren()
	end

	function rectAnchor:Layout(availableWidth, availableHeight)
		anchoredRectWidth, anchoredRectHeight = anchoredRect:Layout(availableWidth, availableHeight)
		rectToAnchorToWidth, rectToAnchorToHeight = rectToAnchorTo:Layout(availableWidth, availableHeight)
		return rectToAnchorToWidth, rectToAnchorToHeight
	end

	function rectAnchor:Position(x, y)
		rectToAnchorTo:Position(x, y)
		anchoredRect:Position(x + floor((rectToAnchorToWidth - anchoredRectWidth) * xAnchor), y + floor((rectToAnchorToHeight - anchoredRectHeight) * yAnchor))
	end
	
	return rectAnchor
end