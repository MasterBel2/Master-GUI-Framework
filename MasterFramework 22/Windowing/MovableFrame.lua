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

    if key then
        if ConfigData.framePositionCache[key] then
            xOffset = ConfigData.framePositionCache[key].xOffset or xOffset
            yOffset = ConfigData.framePositionCache[key].yOffset or yOffset
        else
            ConfigData.framePositionCache[key] = { xOffset = xOffset, yOffset = yOffset }
        end
    end

    local scale = framework:Dimension(1)

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
                ConfigData.framePositionCache[key].xOffset = xOffset
            end
        end
        if yOffset > availableHeight then
            yOffset = availableHeight
            if key then
                ConfigData.framePositionCache[key].yOffset = yOffset
            end
        end
            
        return width, height
    end

    local oldScale = scale() -- Maybe cache this?

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
        xOffset = math.max(x, 0)
        yOffset = math.max(y, 5)

        if key then
            ConfigData.framePositionCache[key].xOffset = x
            ConfigData.framePositionCache[key].yOffset = y
        end
    end

    function frame:Move(x, y)
        self:SetOffset(xOffset + x, yOffset + y)
    end

    return frame
end