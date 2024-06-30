local ConfigData = Internal.ConfigData.ResizableMovableFrame or {
    frameSizeCache = {}
}
Internal.ConfigData.ResizableMovableFrame = ConfigData

local math = Include.math


-- As of now, primary frame MUST be inside ResizableMovableFrame, but ResizableMovableFrame must NOT have any padding on its margins,
-- as any padding will inset the primary frame from the visible size of ResizableMovableFrame.
function framework:ResizableMovableFrame(key, child, defaultX, defaultY, defaultWidth, defaultHeight, growToFitContents)
    local frame = Component(true, false)

    local width = defaultWidth
    local height = defaultHeight

    local dragStartMouseDownX
    local dragStartMouseDownY
    local dragStartX
    local dragStartY
    local dragStartWidth
    local dragStartHeight

    local scale = framework:AutoScalingDimension(1)
    local cachedScale = scale.RawValue()

    if key then
        if not ConfigData.frameSizeCache then ConfigData.frameSizeCache = {} end
        if ConfigData.frameSizeCache[key] then
            local cachedWidth = ConfigData.frameSizeCache[key].width
            local cachedHeight = ConfigData.frameSizeCache[key].height
            width = (cachedWidth and (cachedWidth * cachedScale)) or width
            height = (cachedHeight and (cachedHeight * cachedScale)) or height
        else
            ConfigData.frameSizeCache[key] = { width = width / cachedScale, height = height / cachedScale }
        end
    end

    local movableFrame -- value set below responders

    local draggableDistance = framework:AutoScalingDimension(20)
    local margin = framework:AutoScalingDimension(0) -- Must be 0; see ResizableMovableFrame documentation. 

    local draggable = true

    local draggableColor = framework:Color(1, 1, 1, 1)
    local draggingColor = framework:Color(0.2, 1, 0.4, 1)
    local draggableDecoration = framework:Stroke(framework:AutoScalingDimension(1), draggableColor, false)
    local draggingDecoration = framework:Stroke(framework:AutoScalingDimension(1), draggingColor)

    local highlightWhenDraggable = framework:Background(
        framework:MarginAroundRect(
            child,
            margin,
            margin,
            margin,
            margin
        ),
    {})

    frame.background = highlightWhenDraggable

    function frame:DebugInfo()
        return {
            width = width,
            height = height,
            movableFrameDebugInfo = movableFrame:DebugInfo()
        }
    end

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

            highlightWhenDraggable:SetDecorations({ draggingDecoration })

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

            local _dx = 0
            local _dy = 0

            local newProspectiveWidth = width
            local newProspectiveHeight = height
            if draggingLeft then
                width = dragStartWidth - dMouseX
                _dx = dragStartWidth - width
            elseif draggingRight then
                width = dragStartWidth + dMouseX
            end
            if draggingBottom then
                height = dragStartHeight - dMouseY
            elseif draggingTop then
                height = dragStartHeight + dMouseY
                _dy = height - dragStartHeight
            end

            frame:NeedsLayout()

            movableFrame:SetOffset(dragStartX + _dx, dragStartY + _dy)

            if key then
                ConfigData.frameSizeCache[key].width = width / cachedScale
                ConfigData.frameSizeCache[key].height = height / cachedScale
            end
        end,
        function(responder, x, y)
            draggingLeft = false
            draggingRight = false
            draggingTop = false
            draggingBottom = false

            highlightWhenDraggable:SetDecorations({})
        end
    )

    local mouseOverResponder = framework:MouseOverResponder(
        clickResponder,
        function(responder, x, y)
            if draggingLeft or draggingRight or draggingTop or draggingBottom then return end

            local responderX, responderY, responderWidth, responderHeight = responder:Geometry()
            local scaledDraggableDistance = draggableDistance()
            if x - responderX <= scaledDraggableDistance or 
                responderX + width - x <= scaledDraggableDistance or
                y - responderY <= scaledDraggableDistance or 
                responderY + height - y <= scaledDraggableDistance then
                draggable = true
                highlightWhenDraggable:SetDecorations({ draggableDecoration })
                return true
            else
                draggable = false
                highlightWhenDraggable:SetDecorations({})
                return false
            end
        end,
        function() end,
        function()
            draggable = false
            if draggingLeft or draggingRight or draggingTop or draggingBottom then return end
            highlightWhenDraggable:SetDecorations({})
        end
    )

    local function SizeControl(child)
        local control = {}

        function control:Layout(availableWidth, availableHeight)
            if width ~= width then width = defaultWidth end
            if height ~= height then height = defaultHeight end
            width, height = child:Layout(math.min(width, availableWidth), math.min(height, availableHeight))
            if key then
                ConfigData.frameSizeCache[key].width = width / cachedScale
                ConfigData.frameSizeCache[key].height = height / cachedScale
            end
            return width, height
        end
        function control:Position(...)
            return child:Position(...)
        end
        return control
    end
    local sizeControl = SizeControl(mouseOverResponder)
    movableFrame = framework:MovableFrame(
        key, sizeControl,
        defaultX, defaultY
    )

    function frame:Layout(availableWidth, availableHeight)
        self:RegisterDrawingGroup()
        local currentScale = scale.RawValue()
        if currentScale ~= cachedScale then
            Log("Updating scale!")
            scaleTranslation = currentScale / cachedScale
            width = width * scaleTranslation
            height = height * scaleTranslation
            cachedScale = currentScale
        end

        movableFrame:Layout(availableWidth, availableHeight)

        -- if growToFitContents then
        --     width = math.max(childWidth, width)
        --     height = math.max(childHeight, height)
        -- end

        return availableWidth, availableHeight
    end

    function frame:Position(x, y)
        movableFrame:Position(x, y)
    end

    return frame
end
