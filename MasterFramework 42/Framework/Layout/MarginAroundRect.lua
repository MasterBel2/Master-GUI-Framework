local table_insert = Include.table.insert

function framework:MarginAroundRect(rect, left, top, right, bottom)
	local margin = {}

	local width, height

	local cachedLeft
	local cachedRight
	local cachedTop
	local cachedBottom

	function margin:LayoutChildren()
		return self, rect:LayoutChildren()
	end

	function margin:NeedsLayout()
		return cachedLeft ~= left() or cachedRight ~= right() or cachedTop ~= top() or cachedBottom ~= bottom()
	end

	function margin:Layout(availableWidth, availableHeight)
		cachedLeft = left()
		cachedTop = top()
		cachedRight = right()
		cachedBottom = bottom()

		local horizontal = cachedLeft + right()
		local vertical = top() + cachedBottom

		local rectWidth, rectHeight = rect:Layout(availableWidth - horizontal, availableHeight - vertical)
		width = rectWidth + horizontal
		height = rectHeight + vertical
		return width, height
	end

	function margin:Position(x, y)
		rect:Position(x + cachedLeft, y + cachedBottom)
	end

	return margin
end