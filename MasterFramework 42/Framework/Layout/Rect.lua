function framework:Rect(width, height)
	local rect = {}

	function rect:Layout()
		return width(), height()
	end

	function rect:Position() end

	return rect
end