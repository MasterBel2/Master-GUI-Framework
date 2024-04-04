local Internal = Internal

local nextID = 0
function framework:PrimaryFrame(body)
	local primaryFrame = {}

	local cachedX, cachedY
	local width, height

	local _body

	function primaryFrame:SetBody()
		_body = framework:TextGroup(body)
	end

	primaryFrame:SetBody(body)

	function primaryFrame:Geometry()
		return cachedX, cachedY, width, height
	end

	function primaryFrame:CachedPosition()
		return cachedX, cachedY
	end

	function primaryFrame:Size()
		if (not width) or (not height) then
			return self:Layout(viewportWidth, viewportHeight)
		else
			return width, height
		end
	end

	function primaryFrame:Layout(availableWidth, availableHeight)
		width, height = _body:Layout(availableWidth, availableHeight)
		return width, height
	end

	function primaryFrame:Position(x, y)
		_body:Position(x, y)
		Internal.activeElement.primaryFrame = self
		cachedX = x
		cachedY = y
	end

	return primaryFrame
end