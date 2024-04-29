local gl = Include.gl
local table_insert = Include.table.insert
local math = Include.math
local error = Include.error

framework.OFFSETED_VIEWPORT_MODE_HORIZONTAL_VERTICAL = 0
framework.OFFSETED_VIEWPORT_MODE_HORIZONTAL = 1
framework.OFFSETED_VIEWPORT_MODE_VERTICAL = 2

function framework:OffsettedViewport(body, mode)
    local viewport = { yOffset = 0, xOffset = 0, contentHeight = 0, contentWidth = 0 }

    if (not mode) or mode < 0 or mode > 2 then
        error("OffsettedViewport mode must be one of `framework.OFFSETED_VIEWPORT_MODE_HORIZONTAL_VERTICAL`, `framework.OFFSETED_VIEWPORT_MODE_HORIZONTAL`, and `framework.OFFSETED_VIEWPORT_MODE_VERTICAL`")
    end

    local allowVerticalScrolling
    local allowHorizontalScrolling

    if mode == 0 or mode == 1 then
        allowHorizontalScrolling = true
    end
    if mode == 0 or mode == 2 then
        allowVerticalScrolling = true
    end

    local width = 0
    local height = 0
    local _x = 0
    local _y = 0

    local draggingVertical = false
    local draggingHorizontal = false

    local scrollbarThickness = framework:Dimension(2)

    local scrollStartMouse
    local scrollStartOffset

    local horizontalScrollbarRect = framework:Rect(function() return width * width / viewport.contentWidth end, scrollbarThickness, nil, { framework.color.hoverColor })
    local horizontalScrollbar = framework:MouseOverResponder(
        framework:MousePressResponder(
            horizontalScrollbarRect,
            function(responder, x, y)
                horizontalScrollbarRect.decorations[1] = framework.color.pressColor
                draggingHorizontal = true
                scrollStartMouse = x
                scrollStartOffset = viewport.xOffset
                return true
            end,
            function(responder, x, y, dx, dy)
                viewport.xOffset = math.max(
                    math.min(
                        scrollStartOffset + (x - scrollStartMouse) * (viewport.contentWidth / width),
                        viewport.contentWidth - width -- Must not leave any unneccessary blank space at the bottom of the scroll box
                    ),
                    0  -- Must not leave any unneccessary blank space at the top of the scroll box
                )
            end,
            function(responder, x, y)
                horizontalScrollbarRect.decorations[1] = framework.color.hoverColor
                draggingHorizontal = false
            end
        ),
        function(responder, x, y)
            if not draggingHorizontal then
                horizontalScrollbarRect.decorations[1] = framework.color.selectedColor
            end
        end,
        function(responder) end,
        function(responder)
            if not draggingHorizontal then 
                horizontalScrollbarRect.decorations[1] = framework.color.hoverColor
            end
        end
    )
    local verticalScrollbarRect = framework:Rect(scrollbarThickness, function() return height * height / viewport.contentHeight end, nil, { framework.color.hoverColor })
    local verticalScrollbar = framework:MouseOverResponder(
        framework:MousePressResponder(
            verticalScrollbarRect,
            function(responder, x, y)
                draggingVertical = true
                verticalScrollbarRect.decorations[1] = framework.color.pressColor
                scrollStartMouse = y
                scrollStartOffset = viewport.yOffset
                return true
            end,
            function(responder, x, y, dx, dy)
                viewport.yOffset = math.max(
                    math.min(
                        scrollStartOffset - (y - scrollStartMouse) * (viewport.contentHeight / height),
                        viewport.contentHeight - height -- Must not leave any unneccessary blank space at the bottom of the scroll box
                    ),
                    0  -- Must not leave any unneccessary blank space at the top of the scroll box
                )
            end,
            function(responder, x, y)
                verticalScrollbarRect.decorations[1] = framework.color.hoverColor
                draggingVertical = false
            end
        ),
        function(responder, x, y) end,
        function(responder)
            if not draggingVertical then
                verticalScrollbarRect.decorations[1] = framework.color.selectedColor
            end
        end,
        function(responder)
            if not draggingVertical then 
                verticalScrollbarRect.decorations[1] = framework.color.hoverColor
            end
        end
    )
    
    local textGroup = framework:TextGroup(
        body,
        "Offsetted Viewport"
    )

    function viewport:Layout(availableWidth, availableHeight)
        local _width, _height = textGroup:Layout(allowHorizontalScrolling and math.huge or availableWidth, allowVerticalScrolling and math.huge or availableHeight)
        self.contentWidth = _width
        self.contentHeight = _height

        width = math.max(math.min(availableWidth, self.contentWidth), 0)
        height = math.max(math.min(availableHeight, self.contentHeight), 0)

        if width < self.contentWidth then
            horizontalScrollbar:Layout(0, 0) -- Responder and rect dont use the availableWidth/availableHeight arguments here
        end
        if height < self.contentHeight then
            verticalScrollbar:Layout(0, 0) -- Responder and rect dont use the availableWidth/availableHeight arguments here
        end

        return width, height
    end
    function viewport:Position(x, y)
        _x = x
        _y = y
        if height <= 0 or width <= 0 then return end

        table_insert(activeDrawingGroup.drawTargets, self)
        
        local previousDrawingGroup = activeDrawingGroup -- Capture drawing, so can happen within scissor
        self.drawTargets = {}
        activeDrawingGroup = self
        textGroup:Position(x - self.xOffset, y + self.yOffset + height - self.contentHeight)
        activeDrawingGroup = previousDrawingGroup


        if width < self.contentWidth then
            horizontalScrollbar:Position(x + width / viewport.contentWidth * viewport.xOffset, y)
        end
        if height < self.contentHeight then
            local relativeHeight = height / viewport.contentHeight
            verticalScrollbar:Position(x + width - scrollbarThickness(), y + height - relativeHeight * viewport.yOffset - height * relativeHeight)
        end
    end

    function viewport:Draw()
        if height <= 0 or width <= 0 then return end

        local clipWidth = width
        local clipHeight = height

        local clipY = _y

        if height < self.contentHeight then
            clipWidth = clipWidth - scrollbarThickness()
        end
        if width < self.contentWidth then
            clipHeight = clipHeight - scrollbarThickness()
            clipY = clipY + scrollbarThickness()
        end
        
        gl.Scissor(_x, clipY, clipWidth, clipHeight)
        local drawTargets = self.drawTargets
        for i = 1, #drawTargets do
            drawTargets[i]:Draw()
        end
        gl.Scissor(false)
    end

    return viewport
end

function framework:ResponderScopeWrap(body)
    return framework:Responder(
        framework:Responder(
            framework:Responder(
                body,
                framework.events.mousePress, 
                function() end
            ), 
            framework.events.mouseOver, 
            function() end
        ),
        framework.events.mouseWheel, 
        function() end
    )
end

function framework:VerticalScrollContainer(body)
    local viewport = self:OffsettedViewport(body, framework.OFFSETED_VIEWPORT_MODE_VERTICAL)
    local container =  framework:Responder(framework:ResponderScopeWrap(viewport), framework.events.mouseWheel, function(responder, x, y, up, value)
        local _, responderHeight = responder:Size()
        viewport.yOffset = math.max(
            math.min(
                viewport.yOffset - value * 20,
                viewport.contentHeight - responderHeight -- Must not leave any unneccessary blank space at the bottom of the scroll box
            ),
            0  -- Must not leave any unneccessary blank space at the top of the scroll box
        )
        return true
    end)

    return container
end
function framework:HorizontalScrollContainer(body)
    local viewport = self:OffsettedViewport(body, framework.OFFSETED_VIEWPORT_MODE_HORIZONTAL)

    local container = framework:Responder(framework:ResponderScopeWrap(viewport), framework.events.mouseWheel, function(responder, x, y, up, value)
        local responderWidth, _ = responder:Size()
        viewport.xOffset = math.max(
            math.min(
                viewport.xOffset - value * 20,
                viewport.contentWidth - responderWidth -- Must not leave any unneccessary blank space at the bottom of the scroll box
            ),
            0  -- Must not leave any unneccessary blank space at the top of the scroll box
        )
        return true
    end)

    container.viewport = viewport

    return container
end