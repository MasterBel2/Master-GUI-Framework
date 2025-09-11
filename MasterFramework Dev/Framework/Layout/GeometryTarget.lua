-- An interface element that caches the size and position of its body, without impacting layout or drawing.
function framework:GeometryTarget(body)
    local geometryTarget = {}
    local width, height, cachedX, cachedY
    local drawingGroup

    function geometryTarget:Layout(...)
        drawingGroup = activeDrawingGroup
        width, height = body:Layout(...)
        return width, height
    end
    function geometryTarget:Position(x, y)
        cachedX = x
        cachedY = y
        body:Position(x, y)
    end

    --[[ 
        Returns the x,y coordinates provided in the last call of 
        `geometryTarget:Position(x, y)`. These are only valid within 
        the local context of this GeometryTarget's parent `DrawingGroup`,
        since `DrawingGroup`s hide absolute locations from their 
        children to reduce redraws due to movement.

        Use this only for drawing.
    ]] 
    function geometryTarget:CachedPositionRemainingInLocalContext()
        return cachedX, cachedY
    end

    --[[
        Returns a value computed from a combination of:
        - the x,y coordinates provided in the last call of `geometryTarget:Position(x, y)`
        - the x,y offsets used by the `DrawingGroup` within which this `GeometryTarget`
          is nested
        These are only valid within the global context - i.e. the top-level `DrawingGroup`
        or when dealing with the coordinates passed through the responder chain.
    ]]
    function geometryTarget:CachedPositionTranslatedToGlobalContext()
        local localXOffset, localYOffset = drawingGroup:AbsolutePosition()

        return (cachedX or 0) + localXOffset, (cachedY or 0) + localYOffset
    end

    --[[
        Returns a value computed from a combination of:
        - the x,y coordinates provided in the last call of `geometryTarget:Position(x, y)`.
        - the x,y offsets used by the `DrawingGroup` within which this `GeometryTarget`
          is nested.
        - the x,y offsets used by the `DrawingGroup` within which the coordinates will 
          be used by the caller.

        Drawing should use coordinates localised to the `DrawingGroup` that requests the draw,
        since that `DrawingGroup` will apply a gl.Translate before drawing occurs. 
    ]]
    function geometryTarget:CachedPositionTranslatedToContext(callerDrawingGroup)
        local globalXOffset, globalYOffset = self:CachedPositionTranslatedToGlobalContext()
        local callerXOffset, callerYOffset = callerDrawingGroup:AbsolutePosition()

        return globalXOffset - callerXOffset, globalYOffset - callerYOffset
    end

    function geometryTarget:Size()
        if (not height) or (not width) then
            return self:Layout(0, 0) -- we need a value, so get one.
        end
        return width, height
    end

    --[[
        Returns whether the absolute point is contained within the geometry target.
        
        An absolute point is a point in the global context - that is, the context of
        the top-level drawing group, or provided by the game itself (e.g. mouse interaction).

        Use this when handling coordinates by responders, or e.g. when providing coordinates 
        to `AbsoluteOffsetFromTopLeft` to position an element's `PrimaryFrame` within 
        the global context.
    ]]
    function geometryTarget:ContainsAbsolutePoint(x, y)
        local localXOffset, localYOffset = drawingGroup:AbsolutePosition()
		return PointIsInRect(x, y, cachedX + localXOffset, cachedY + localYOffset, width, height)
    end
    
    --[[
        Returns whether a point in another drawing group's context is contained within
        the geometry target.
        
        Each `DrawingGroup` creates its own locally-valid coordinates to preserve information
        when a portion of an element is translated with no other renderable changes.

        Supply a reference to the `DrawingGroup` that provided the context the coordinates
        were obtained within. If the coordinates were obtained from outside MasterFramework,
        use `geometryTarget:ContainsAbsolutePoint`.
    ]]
    function geometryTarget:ContainsPoint(x, y, callerDrawingGroup)
        local callerXOffset, callerYOffset = callerDrawingGroup:AbsolutePosition()
		return geometryTarget:ContainsAbsolutePoint(x + callerXOffset, y + callerXOffset)
	end

    return geometryTarget
end