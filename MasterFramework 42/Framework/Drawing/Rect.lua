-- A component of fixed size.
function framework:Rect(width, height, cornerRadius, decorations)
	return framework:Background(framework:LayoutRect(width, height), decorations, cornerRadius)
end

function framework:LayoutRect(width, height)
	local rect = {}
	local cachedWidth, cachedHeight

	function rect:SetSize(newWidth, newHeight)
		width = newWidth
		height = newHeight
	end

	function rect:LayoutChildren()
		return self
	end
	
	function rect:NeedsLayout()
		return cachedWidth ~= width() or cachedHeight ~= height()
	end

	function rect:Layout()
		cachedWidth = width()
		cachedHeight = height()
		return cachedWidth, cachedHeight
	end

	function rect:Position() --[[ noop ]] end

	return rect
end