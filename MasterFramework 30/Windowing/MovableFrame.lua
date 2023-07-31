local ConfigData = Internal.ConfigData.MovableFrame or {
    framePositionCache = {}
}
Internal.ConfigData.MovableFrame = ConfigData
local math = Include.math

-- If key is set, MovableFrame will automatically cache its position
-- DO NOT have multiple concurrent MovableFrame instances with the same key!
function framework:MovableFrame(key, child, defaultX, defaultY)
    local frame = {}

    local handleDimension = framework:Dimension(20)
    local xOffset = defaultX -- offsets are to top left corner
    local yOffset = defaultY

    local scale = framework:Dimension(1)
    local oldScale = scale() -- Maybe cache this?

    local handleDecorations = { unhighlightedColor }

    local handle = framework:Rect(handleDimension, handleDimension, nil, handleDecorations)

    local selected = false

    local handleHoverDetector = framework:MouseOverChangeResponder(
        handle,
        function(isOver)
            if not selected then
                handleDecorations[1] = (isOver and framework.color.hoverColor) or nil
            end
        end
    )
    local handlePressDetector = framework:MousePressResponder(
        handleHoverDetector,
        function()
            handleDecorations[1] = framework.color.pressColor
            selected = true
            return true
        end,
        function(responder, x, y, dx, dy)
            frame:Move(dx, dy)
        end,
        function()
            handleDecorations[1] = framework.color.hoverColor
            selected = false
        end
    )

    local zStack = framework:StackInPlace({ child, handlePressDetector }, 0, 1)

    local width, height
    function frame:Layout(availableWidth, availableHeight)
        width, height = zStack:Layout(availableWidth, availableHeight)
        if xOffset > availableWidth - 5 then
            xOffset = availableWidth - 5
            if key then
                ConfigData.framePositionCache[key].xOffset = xOffset / oldScale
            end
        end
        if yOffset > availableHeight then
            yOffset = availableHeight
            if key then
                ConfigData.framePositionCache[key].yOffset = yOffset / oldScale
            end
        end
            
        return width, height
    end

    function frame:Draw(x, y)
        local currentScale = scale()
        if currentScale ~= oldScale then
            scaleTranslation = currentScale / oldScale
            xOffset = xOffset * scaleTranslation
            yOffset = yOffset * scaleTranslation
            oldScale = currentScale
        end

        zStack:Draw(x + xOffset, y + yOffset - height)
    end

    function frame:CurrentOffset()
        return xOffset, yOffset
    end

    function frame:SetOffset(x, y)
        xOffset = math.min(math.max(x, 0), framework.viewportWidth - 5)
        yOffset = math.min(math.max(y, 5), framework.viewportHeight)

        if key then
            ConfigData.framePositionCache[key].xOffset = x / oldScale
            ConfigData.framePositionCache[key].yOffset = y / oldScale
        end
    end

    if key then
        if ConfigData.framePositionCache[key] then
            frame:SetOffset(
                (ConfigData.framePositionCache[key].xOffset * oldScale) or xOffset, 
                (ConfigData.framePositionCache[key].yOffset * oldScale) or yOffset
            )
        else
            ConfigData.framePositionCache[key] = { xOffset = xOffset / oldScale, yOffset = yOffset / oldScale }
        end
    end

    function frame:Move(x, y)
        self:SetOffset(xOffset + x, yOffset + y)
    end

    return frame
end