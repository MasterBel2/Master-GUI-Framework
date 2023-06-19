local ConfigData = Internal.ConfigData.ResizableMovableFrame or {
    frameSizeCache = {}
}
Internal.ConfigData.ResizableMovableFrame = ConfigData

local math = Include.math


-- As of now, primary frame MUST be inside ResizableMovableFrame, but ResizableMovableFrame must NOT have any padding on its margins,
-- as any padding will inset the primary frame from the visible size of ResizableMovableFrame.
function framework:ResizableMovableFrame(key, child, defaultX, defaultY, defaultWidth, defaultHeight, growToFitContents)
    local frame = {}

    local width = defaultWidth
    local height = defaultHeight

    local dragStartMouseDownX
    local dragStartMouseDownY
    local dragStartX
    local dragStartY
    local dragStartWidth
    local dragStartHeight

    if key then
        if ConfigData.frameSizeCache[key] then
            width = ConfigData.frameSizeCache[key].width or width
            height = ConfigData.frameSizeCache[key].height or width
        else
            ConfigData.frameSizeCache[key] = { width = width, height = height }
        end
    end

    local scale = framework:Dimension(1)
    local oldScale = scale()

    local movableFrame -- value set below responders

    local draggableDistance = framework:Dimension(20)
    local margin = framework:Dimension(0) -- Must be 0; see ResizableMovableFrame documentation. 

    local draggable = true

    local draggableColor = framework:Color(1, 1, 1, 1)
    local draggingColor = framework:Color(0.2, 1, 0.4, 1)
    local draggableDecoration = framework:Stroke(1, draggableColor, false)
    local marginDecorations = {}

    local highlightWhenDraggable = framework:MarginAroundRect(
        child,
        margin,
        margin,
        margin,
        margin,
        marginDecorations
    )

    frame.margin = highlightWhenDraggable

    local draggingLeft, draggingRight, draggingTop, draggingBottom = false

    local clickResponder = framework:MousePressResponder(
        highlightWhenDraggable,
        function(responder, x, y, button)
            if button ~= 1 or (not draggable) then return false end

            local scaledDraggableDistance = draggableDistance()

            local responderX, responderY, responderWidth, responderHeight = responder:Geometry()

            if x - responderX <= scaledDraggableDistance then
                draggingLeft = true
            elseif x - responderX - width >= -scaledDraggableDistance then
                draggingRight = true
            end
            if y - responderY <= scaledDraggableDistance then
                draggingBottom = true
            elseif y - responderY - height >= -scaledDraggableDistance then
                draggingTop = true
            end

            draggableDecoration.color = draggingColor

            dragStartMouseDownX = x
            dragStartMouseDownY = y

            dragStartX, dragStartY = movableFrame:CurrentOffset()

            dragStartWidth = width
            dragStartHeight = height

            return true
        end,
        function(responder, mouseX, mouseY, dx, dy, button)
            if not (draggingLeft or draggingRight or draggingBottom or draggingTop) then return false end
            local dMouseX = mouseX - dragStartMouseDownX
            local dMouseY = mouseY - dragStartMouseDownY

            local newProspectiveWidth = width
            local newProspectiveHeight = height
            if draggingLeft then
                newProspectiveWidth = dragStartWidth - dMouseX
            elseif draggingRight then
                newProspectiveWidth = dragStartWidth + dMouseX
            end
            if draggingBottom then
                newProspectiveHeight = dragStartHeight - dMouseY
            elseif draggingTop then
                newProspectiveHeight = dragStartHeight + dMouseY
            end
            
            local new_Width, new_Height = child:Layout(newProspectiveWidth, newProspectiveHeight)
            local newFinalWidth = math.min(new_Width, newProspectiveWidth) -- I tried commenting these out for some debugging thing and it appears
            local newFinalHeight = math.min(new_Height, newProspectiveHeight) -- clamping works even when we don't do this???

            -- local newFinalWidth = newProspectiveWidth
            -- local newFinalHeight = newProspectiveHeight

            local _dx = 0
            local _dy = 0

            if draggingLeft then
                width = newFinalWidth
                _dx = dragStartWidth - newFinalWidth
            elseif draggingRight then
                width = newFinalWidth
            end
            if draggingBottom then
                height = newFinalHeight
            elseif draggingTop then
                height = newFinalHeight
                _dy = newFinalHeight - dragStartHeight
            end

            movableFrame:SetOffset(dragStartX + _dx, dragStartY + _dy)

            if key then
                ConfigData.frameSizeCache[key].width = width
                ConfigData.frameSizeCache[key].height = height
            end
        end,
        function(responder, x, y)
            draggingLeft = false
            draggingRight = false
            draggingTop = false
            draggingBottom = false

            draggableDecoration.color = draggableColor
        end
    )

    local mouseOverResponder = framework:MouseOverResponder(
        clickResponder,
        function(responder, x, y)
            local responderX, responderY, responderWidth, responderHeight = responder:Geometry()
            local scaledDraggableDistance = draggableDistance()
            if x - responderX <= scaledDraggableDistance or 
                responderX + width - x <= scaledDraggableDistance or
                y - responderY <= scaledDraggableDistance or 
                responderY + height - y <= scaledDraggableDistance then
                draggable = true
                highlightWhenDraggable.decorations = { draggableDecoration }
                return true
            else
                draggable = false
                highlightWhenDraggable.decorations = {}
                return false
            end
        end,
        function() end,
        function()
            draggable = false
            highlightWhenDraggable.decorations = {}
        end
    )

    local function SizeControl(child)
        local control = {}
        function control:Layout(availableWidth, availableHeight)
            width, height = child:Layout(width, height)
            return child:Layout(width, height)
        end
        function control:Draw(...)
            return child:Draw(...)
        end
        return control
    end
    local sizeControl = SizeControl(mouseOverResponder)
    movableFrame = framework:MovableFrame(
        key, sizeControl,
        defaultX, defaultY
    )

    function frame:Layout(availableWidth, availableHeight)
        local currentScale = scale()
        if currentScale ~= oldScale then
            scaleTranslation = currentScale / oldScale
            width = width * scaleTranslation
            height = height * scaleTranslation
            oldScale = currentScale
        end

        movableFrame:Layout(availableWidth, availableHeight)

        -- if growToFitContents then
        --     width = math.max(childWidth, width)
        --     height = math.max(childHeight, height)
        -- end

        return availableWidth, availableHeight
    end

    function frame:Draw(x, y)
        movableFrame:Draw(x, y)
    end

    return frame
end
