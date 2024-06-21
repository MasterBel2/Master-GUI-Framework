local table_insert = Include.table.insert

function framework:MarginAroundRect(rect, left, top, right, bottom)
	local margin = { rect = rect }

	local width, height

	local cachedLeft
	local cachedRight
	local cachedTop
	local cachedBottom
	local cachedRect

	function margin:LayoutChildren()
		return self, self.rect:LayoutChildren()
	end

	function margin:NeedsLayout()
		return cachedLeft ~= left() or cachedRight ~= right() or cachedTop ~= top() or cachedBottom ~= bottom() or cachedRect ~= self.rect
	end

	function margin:Layout(availableWidth, availableHeight)
		cachedLeft = left()
		cachedBottom = bottom()
		cachedRect = self.rect

		local horizontal = cachedLeft + right()
		local vertical = top() + cachedBottom

		local rectWidth, rectHeight = cachedRect:Layout(availableWidth - horizontal, availableHeight - vertical)
		width = rectWidth + horizontal
		height = rectHeight + vertical
		return width, height
	end

	function margin:Position(x, y)
		cachedRect:Position(x + cachedLeft, y + cachedBottom)
	end

	return margin
end