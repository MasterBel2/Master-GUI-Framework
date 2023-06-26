-- An interface element that caches the size and position of its body, without impacting layout or drawing.
function framework:GeometryTarget(body)
    local geometryTarget = {}
    local width, height, cachedX, cachedY
    function geometryTarget:Layout(...)
        width, height = body:Layout(...)
        return width, height
    end
    function geometryTarget:Draw(x, y)
        cachedX = x
        cachedY = y
        body:Draw(x, y)
    end
    function geometryTarget:CachedPosition()
        return cachedX or 0, cachedY or 0
    end
    function geometryTarget:Size()
        if (not height) or (not width) then
            return self:Layout(0, 0) -- we need a value, so get one.
        end
        return width, height
    end
	function geometryTarget:Geometry()
		return self:Size(), self:CachedPosition()
	end

    return geometryTarget
end