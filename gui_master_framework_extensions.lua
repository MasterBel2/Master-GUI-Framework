function widget:GetInfo()
    return {
        name = "MasterFramework Extensions",
        description = "Provides higher-level interface elements such as buttons that may combine one or more MasterFramework core components together",
        layer = -math.huge -- Run Initialise after MasterFramework file has loaded, but before any widget uses it
    }
end

local requiredFrameworkVersion = 14

local framePositionCache = {}
local frameSizeCache = {}

function widget:Initialize()

    local MasterFramework = WG.MasterFramework[requiredFrameworkVersion]
    if MasterFramework then
        MasterFramework.areComplexElementsAvailable = true

        local semiTransparent = 0.66

        local hoverColor    = MasterFramework:Color(1, 1, 1, 0.33)
        local pressColor    = MasterFramework:Color(0.66, 0.66, 1, 0.66)
        local selectedColor = MasterFramework:Color(0.66, 1, 1, 0.66)

        local baseBackgroundColor = MasterFramework:Color(0, 0, 0, 0.66)
        
        local textColor = MasterFramework:Color(1, 1, 1, 1)

        local smallCornerRadius = MasterFramework:Dimension(2)

        local defaultMargin = MasterFramework:Dimension(8)
        local defaultCornerRadius = MasterFramework:Dimension(5)

        -- Dimensions
        local elementSpacing = MasterFramework:Dimension(1)
        local groupSpacing = MasterFramework:Dimension(5)

        -- function MasterFramework:ButtonWithHoverEffect()
        --     local hover = MasterFramework:MouseOverChangeResponder(
        --         margin,
        --         function(isOver)
        --             if isOver then
        --                 margin.decorations = { [1] = highlightColor }
        --             else
        --                 margin.decorations = {}
        --             end
        --         end
        --     )

        --     return 
        -- end

        ------------------------------------------------
        function MasterFramework:CheckBox(scale, action)
            local checkbox = {}
            local dimension = MasterFramework:Dimension(scale)
            local radius = MasterFramework:Dimension(scale / 2)
            
            local checked = false
        
            local highlightColor = hoverColor
            local unhighlightedColor = defaultBorder
        
            local rect = MasterFramework:Rect(dimension, dimension, radius, { unhihlightedColor })
            
            local body = MasterFramework:MouseOverChangeResponder(
                MasterFramework:MousePressResponder(
                    rect,
                    function(self, x, y, button)
                        highlightColor = pressColor
                        rect.decorations[1] = highlightColor
                        return true
                    end,
                    function(self, x, y, dx, dy)
                    end,
                    function(self, x, y)
                        highlightColor = hoverColor
                        if MasterFramework.PointIsInRect(x, y, self:Geometry()) then
                            checkbox:SetChecked(not checked)
                            action(checkbox, checked)
                        end
                    end
                ),
                function(isInside)
                    rect.decorations[1] = (isInside and highlightColor) or unhighlightedColor
                end
            )
             
            function checkbox:Draw(...)
                body:Draw(...)
            end
            function checkbox:Layout(...)
                return body:Layout(...)
            end
        
            function checkbox:SetChecked(newChecked)
                checked = newChecked
                unhighlightedColor = (checked and selectedColor) or defaultBorder
                rect.decorations[1] = (isInside and highlightColor) or unhighlightedColor
            end
        
            checkbox:SetChecked(checked)
            return checkbox
        end

        -----------------------------------------------
        function MasterFramework:Button(visual, action)
            local button = { visual = visual }
            local margin = MasterFramework:MarginAroundRect(visual, defaultMargin, defaultMargin, defaultMargin, defaultMargin, {}, marginDimension, false)

            local highlightColor = hoverColor
            button.action = action

            local responder = MasterFramework:MouseOverChangeResponder(
                MasterFramework:MousePressResponder(
                    margin,
                    function(self, x, y, button)
                        if button ~= 1 then return false end
                        if MasterFramework.PointIsInRect(x, y, self:Geometry()) then
                            margin.decorations = { [1] = pressColor }
                        else
                            margin.decorations = {}
                        end
                        return true
                    end,
                    function(self, x, y, dx, dy)
                        if MasterFramework.PointIsInRect(x, y, self:Geometry()) then
                            margin.decorations = { [1] = pressColor }
                        else
                            margin.decorations = {}
                        end
                    end, 
                    function(self, x, y)
                        if MasterFramework.PointIsInRect(x, y, self:Geometry()) then
                            margin.decorations = {}
                            button.action(button)
                        end
                    end
                ),
                function(isInside)
                    margin.decorations[1] = (isInside and highlightColor) or unhighlightedColor
                end
            )

            function button:Layout(...)
                return responder:Layout(...)
            end
            function button:Draw(...)
                responder:Draw(...)
            end

            button.margin = margin

            return button
        end

        -- If key is set, MovableFrame will automatically cache its position
        -- DO NOT have multiple concurrent MovableFrame instances with the same key!
        function MasterFramework:MovableFrame(key, child, defaultX, defaultY)
            local frame = {}

            local handleDimension = MasterFramework:Dimension(20)
            local xOffset = defaultX -- offsets are to top left corner
            local yOffset = defaultY

            if key then
                if framePositionCache[key] then
                    xOffset = framePositionCache[key].xOffset or xOffset
                    yOffset = framePositionCache[key].yOffset or yOffset
                else
                    framePositionCache[key] = { xOffset = xOffset, yOffset = yOffset }
                end
            end

            local scale = MasterFramework:Dimension(1)

            local handleDecorations = { unhighlightedColor }

            local handle = MasterFramework:Rect(handleDimension, handleDimension, nil, handleDecorations)

            local selected = false

            local handleHoverDetector = MasterFramework:MouseOverChangeResponder(
                handle,
                function(isOver)
                    if not selected then
                        handleDecorations[1] = (isOver and hoverColor) or nil
                    end
                end
            )
            local handlePressDetector = MasterFramework:MousePressResponder(
                handleHoverDetector,
                function()
                    handleDecorations[1] = pressColor
                    selected = true
                    return true
                end,
                function(responder, x, y, dx, dy)
                    frame:Move(dx, dy)
                end,
                function()
                    handleDecorations[1] = hoverColor
                    selected = false
                end
            )

            local zStack = MasterFramework:StackInPlace({ child, handlePressDetector }, 0, 1)

            local width, height
            function frame:Layout(availableWidth, availableHeight)
                width, height = zStack:Layout(availableWidth, availableHeight)
                if xOffset > availableWidth - 5 then
                    xOffset = availableWidth - 5
                    if key then
                        framePositionCache[key].xOffset = xOffset
                    end
                end
                if yOffset > availableHeight then
                    yOffset = availableHeight
                    if key then
                        framePositionCache[key].yOffset = yOffset
                    end
                end
                    
                return width, height
            end

            local oldScale = scale()

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
                    framePositionCache[key].xOffset = x
                    framePositionCache[key].yOffset = y
                end
            end

            function frame:Move(x, y)
                self:SetOffset(xOffset + x, yOffset + y)
            end

            return frame
        end

        -- As of now, primary frame MUST be inside ResizableMovableFrame, but ResizableMovableFrame must NOT have any padding on its margins,
        -- as any padding will inset the primary frame from the visible size of ResizableMovableFrame.
        function MasterFramework:ResizableMovableFrame(key, child, defaultX, defaultY, defaultWidth, defaultHeight, growToFitContents)
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
                if frameSizeCache[key] then
                    width = frameSizeCache[key].width or width
                    height = frameSizeCache[key].height or width
                else
                    frameSizeCache[key] = { width = width, height = height }
                end
            end

            local scale = MasterFramework:Dimension(1)
            local oldScale = scale()

            local movableFrame -- value set below responders

            local draggableDistance = MasterFramework:Dimension(20)
            local margin = MasterFramework:Dimension(0) -- Must be 0; see ResizableMovableFrame documentation. 

            local draggable = true

            local draggableColor = MasterFramework:Color(1, 1, 1, 1)
            local draggingColor = MasterFramework:Color(0.2, 1, 0.4, 1)
            local draggableDecoration = MasterFramework:Stroke(1, draggableColor, false)
            local marginDecorations = {}

            local highlightWhenDraggable = MasterFramework:MarginAroundRect(
                child,
                margin,
                margin,
                margin,
                margin,
                marginDecorations
            )

            frame.margin = highlightWhenDraggable

            local draggingLeft, draggingRight, draggingTop, draggingBottom = false

            local clickResponder = MasterFramework:MousePressResponder(
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
                        frameSizeCache[key].width = width
                        frameSizeCache[key].height = height
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

            local mouseOverResponder = MasterFramework:MouseOverResponder(
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
            movableFrame = MasterFramework:MovableFrame(
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
    end
end

function widget:GetConfigData()
    return {
        framePositionCache = framePositionCache,
        frameSizeCache = frameSizeCache,
    }
end

function widget:SetConfigData(data)
    framePositionCache = data.framePositionCache
    frameSizeCache = data.frameSizeCache
end