-- A component of fixed size.
function framework:Rect(width, height, cornerRadius, decorations)
	return framework:Background(framework:LayoutRect(width, height), decorations, cornerRadius)
end

function framework:LayoutRect(width, height)
	local rect = {}

	function rect:Layout()
		return width(), height()
	end

	function rect:Position() end

	return rect
end