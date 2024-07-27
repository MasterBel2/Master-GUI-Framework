local Internal = Internal

local nextID = 0
function framework:PrimaryFrame(body)
	local primaryFrame = {}

	local cachedX, cachedY
	local width, height

	function primaryFrame:Geometry()
		return cachedX, cachedY, width, height
	end

	function primaryFrame:CachedPosition()
		return cachedX, cachedY
	end

	function primaryFrame:Size()
		return width, height
	end
	
	function primaryFrame:Layout(availableWidth, availableHeight)
		Internal.activeElement.primaryFrame = self
		width, height = body:Layout(availableWidth, availableHeight)
		return width, height
	end

	function primaryFrame:Position(x, y)
		body:Position(x, y)
		cachedX = x
		cachedY = y
	end

	return primaryFrame
end