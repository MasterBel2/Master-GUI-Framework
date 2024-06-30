local ConfigData = Internal.ConfigData.MovableFrame or {
    framePositionCache = {}
}
Internal.ConfigData.MovableFrame = ConfigData
local math = Include.math

-- If key is set, MovableFrame will automatically cache its position
-- DO NOT have multiple concurrent MovableFrame instances with the same key!
function framework:MovableFrame(key, child, defaultX, defaultY)
    local frame = Component(true, false)

    local handleDimension = framework:AutoScalingDimension(20)
    
    -- offsets are to top left corner
    local xOffset = defaultX
    local yOffset = defaultY

    local scale = framework:AutoScalingDimension(1)
    local cachedScale = scale.RawValue()

    if key then
        if ConfigData.framePositionCache[key] then
            local cachedXOffset = ConfigData.framePositionCache[key].xOffset
            local cachedYOffset = ConfigData.framePositionCache[key].yOffset
            xOffset = (cachedXOffset and (cachedXOffset * scale.RawValue())) or xOffset
            yOffset = (cachedYOffset and (cachedYOffset * scale.RawValue())) or yOffset
        end
    end

    local handleDecorations = { unhighlightedColor }

    local handle = framework:Background(framework:Rect(handleDimension, handleDimension), handleDecorations)

    local selected = false

    local handleHoverDetector = framework:MouseOverChangeResponder(
        handle,
        function(isOver)
            if not selected then
                handleDecorations[1] = (isOver and framework.color.hoverColor) or nil
                handle:SetDecorations(handleDecorations)
            end
        end
    )
    local handlePressDetector = framework:MousePressResponder(
        handleHoverDetector,
        function()
            handleDecorations[1] = framework.color.pressColor
            handle:SetDecorations(handleDecorations)
            selected = true
            return true
        end,
        function(responder, x, y, dx, dy)
            frame:Move(dx, dy)
        end,
        function()
            handleDecorations[1] = framework.color.hoverColor
            handle:SetDecorations(handleDecorations)
            selected = false
        end
    )

    local zStack = framework:StackInPlace({ child, handlePressDetector }, 0, 1)

    local width, height

    function frame:DebugInfo()
        return {
            xOffset = xOffset,
            yOffset = yOffset,
            width = width,
            height = height,
        }
    end
    
    local cachedAvailableWidth, cachedAvailableHeight
    function frame:Layout(availableWidth, availableHeight)
        self:RegisterDrawingGroup()
        width, height = zStack:Layout(availableWidth, availableHeight)
        cachedAvailableWidth = availableWidth
        cachedAvailableHeight = availableHeight
            
        return availableWidth, availableHeight
    end

    function frame:Position(x, y)
        local newScale = scale.RawValue()
        if newScale ~= cachedScale then
            scaleTranslation = newScale / cachedScale
            xOffset = xOffset * scaleTranslation
            self:SetOffset(xOffset * scaleTranslation, yOffset * scaleTranslation, true)
            cachedScale = newScale
        else
            self:SetOffset(xOffset, yOffset)
        end

        zStack:Position(x + xOffset, y + yOffset - height)
    end

    function frame:CurrentOffset()
        return xOffset, yOffset
    end

    function frame:SetOffset(x, y, skipNeedsPosition)
        local newXOffset = math.min(math.max(x, 0), cachedAvailableWidth - 5)
        local newYOffset = math.min(math.max(y, 5), cachedAvailableHeight)
        if newXOffset ~= newXOffset then -- nan
            newXOffset = 0
        end
        if newYOffset ~= newYOffset then --nan
            newYOffset = 5
        end

        if not skipNeedsPosition and (newXOffset ~= xOffset or newYOffset ~= yOffset) then
            self:NeedsPosition()
        end
        xOffset = newXOffset
        yOffset = newYOffset

        if key then
            ConfigData.framePositionCache[key].xOffset = xOffset / scale.RawValue()
            ConfigData.framePositionCache[key].yOffset = yOffset / scale.RawValue()

            -- Log("cachedAvailableWidth:" .. cachedAvailableWidth)
            -- Log("cachedAvailableHeight:" .. cachedAvailableHeight)
            -- Log("xOffset:" .. ConfigData.framePositionCache[key].xOffset)
            -- Log("yOffset:" .. ConfigData.framePositionCache[key].yOffset)
            -- Log("newXOffset:" .. newXOffset)
            -- Log("newYOffset:" .. newYOffset)
            -- Log("x:" .. x)
            -- Log("y:" .. y)
            -- Log("scale.RawValue():" .. scale.RawValue())
        end
    end

    function frame:Move(x, y)
        self:SetOffset(xOffset + x, yOffset + y)
    end

    return frame
end