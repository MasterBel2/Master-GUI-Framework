local table_insert = Include.table.insert

function framework:MarginAroundRect(rect, left, top, right, bottom)
	local margin = {}

	local width, height

	local cachedLeft
	local cachedBottom

	function margin:Layout(availableWidth, availableHeight)
		cachedLeft = left()
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