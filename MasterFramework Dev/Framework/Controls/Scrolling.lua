local gl = Include.gl
local table_insert = Include.table.insert
local math = Include.math
local error = Include.error

framework.OFFSETED_VIEWPORT_MODE_HORIZONTAL_VERTICAL = 0
framework.OFFSETED_VIEWPORT_MODE_HORIZONTAL = 1
framework.OFFSETED_VIEWPORT_MODE_VERTICAL = 2

--[[
    `OffsettedViewport` is an overriding extension of `DrawingGroup` that allows a large interface to be clipped and displayed within a smaller parent view. 
    Scrollbars are provided for navigation. 

    Overridden interface:
     - `viewport:Layout(availableWidth, availableHeight)`: A wrapper for `DrawingGroup`'s layout function that additionally lays out the viewport's scrollbars. 
                                                           `DrawingGroup`'s layout function will be provided with `math.huge` for scrollable axes, 
                                                            and `availableWidth`/`availableHeight` for non-scrollable axes.
     - `viewport:Position(x, y)`: A wrapper for `DrawingGroup`'s position function that additionally manages the offset of the `body` and positions the viewport's scrollbars.
     - `viewport:Draw()`: A wrapper for `DrawingGroup`'s draw function that clips all children to within the viewport's bounds (accounting for any scroll bars).
    
    Note: By default, the provided scrollbars do not react to mousewheel interaction; see `VerticalScrollContainer` and `HorizontalScrollContainer` for implementations
          of mousewheel scrolling 

    Arguments:
     - `body`: The parent component of the interface to be provided within the clipping viewport.
     - `mode`: Any of `framework.OFFSETED_VIEWPORT_MODE_HORIZONTAL_VERTICAL`, `framework.OFFSETED_VIEWPORT_MODE_HORIZONTAL`, or `framework.OFFSETED_VIEWPORT_MODE_VERTICAL = 2`, 
             that specifies on which axes scrolling will be enabled.

    Read-only properties:
     - `viewport.contentWidth`: The width of the the viewport's `body` returned from the last layout.
     - `viewport.contentHeight`: The height of the viewport's `body` returned from the last layout.

    Methods:
     - `viewport:GetOffsets()`: returns the offset used to position the `body` relative to the viewport.
     - `viewport:SetXOffset(_xOffset)`: sets a new x offset.
     - `viewport:SetYOffset(_yOffset)`: sets a new y offset.
]]
function framework:OffsettedViewport(body, mode)
    local viewport = self:DrawingGroup(body)
    viewport.contentWidth = 0
    viewport.contentHeight = 0

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
    local xOffset = 0
    local yOffset = 0

    function viewport:GetOffsets()
        return xOffset, yOffset
    end

    function viewport:SetXOffset(_xOffset)
        if xOffset ~= _xOffset then
            xOffset = _xOffset
            self.childNeedsPosition = true
        end
    end
    function viewport:SetYOffset(_yOffset)
        if yOffset ~= _yOffset then
            yOffset = _yOffset
            self.childNeedsPosition = true
        end
    end

    local draggingVertical = false
    local draggingHorizontal = false

    local scrollbarThickness = framework:AutoScalingDimension(2)
    local cachedScrollbarThickness
    
    local scrollStartMouse
    local scrollStartOffset

    local horizontalScrollbarRect = framework:Background(framework:Rect(function() return width * width / viewport.contentWidth end, scrollbarThickness), { framework.color.hoverColor }, nil)
    local horizontalScrollbar = framework:MouseOverResponder(
        framework:MousePressResponder(
            horizontalScrollbarRect,
            function(responder, x, y)
                horizontalScrollbarRect:SetDecorations({ framework.color.pressColor })
                draggingHorizontal = true
                scrollStartMouse = x
                scrollStartOffset = xOffset
                return true
            end,
            function(responder, x, y, dx, dy)
                viewport:SetXOffset(math.max(
                    math.min(
                        scrollStartOffset + (x - scrollStartMouse) * (viewport.contentWidth / width),
                        viewport.contentWidth - width -- Must not leave any unneccessary blank space at the bottom of the scroll box
                    ),
                    0  -- Must not leave any unneccessary blank space at the top of the scroll box
                ))
            end,
            function(responder, x, y)
                horizontalScrollbarRect:SetDecorations({ framework.color.hoverColor })
                draggingHorizontal = false
            end
        ),
        function(responder, x, y)
            if not draggingHorizontal then
                horizontalScrollbarRect:SetDecorations({ framework.color.selectedColor })
            end
        end,
        function(responder) end,
        function(responder)
            if not draggingHorizontal then 
                horizontalScrollbarRect:SetDecorations({ framework.color.hoverColor })
            end
        end
    )
    local verticalScrollbarRect = framework:Background(framework:Rect(scrollbarThickness, function() return height * height / viewport.contentHeight end), { framework.color.hoverColor }, nil)
    local verticalScrollbar = framework:MouseOverResponder(
        framework:MousePressResponder(
            verticalScrollbarRect,
            function(responder, x, y)
                draggingVertical = true
                verticalScrollbarRect:SetDecorations({ framework.color.pressColor })
                scrollStartMouse = y
                scrollStartOffset = yOffset
                return true
            end,
            function(responder, x, y, dx, dy)
                viewport:SetYOffset(math.max(
                    math.min(
                        scrollStartOffset - (y - scrollStartMouse) * (viewport.contentHeight / height),
                        viewport.contentHeight - height -- Must not leave any unneccessary blank space at the bottom of the scroll box
                    ),
                    0  -- Must not leave any unneccessary blank space at the top of the scroll box
                ))
            end,
            function(responder, x, y)
                verticalScrollbarRect:SetDecorations({ framework.color.hoverColor })
                draggingVertical = false
            end
        ),
        function(responder, x, y) end,
        function(responder)
            if not draggingVertical then
                verticalScrollbarRect:SetDecorations({ framework.color.selectedColor })
            end
        end,
        function(responder)
            if not draggingVertical then 
                verticalScrollbarRect:SetDecorations({ framework.color.hoverColor })
            end
        end
    )

    local _Layout = viewport.Layout
    function viewport:Layout(availableWidth, availableHeight)
        cachedScrollbarThickness = scrollbarThickness()
        local _width, _height = _Layout(self, allowHorizontalScrolling and math.huge or availableWidth, allowVerticalScrolling and math.huge or availableHeight)
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
    
    local _Position = viewport.Position
    function viewport:Position(x, y)
        _x = x
        _y = y

        _Position(self, x - xOffset, y + yOffset + height - self.contentHeight)

        self:SetYOffset(math.max(
            math.min(
                yOffset,
                viewport.contentHeight - height -- Must not leave any unneccessary blank space at the bottom of the scroll box
            ),
            0  -- Must not leave any unneccessary blank space at the top of the scroll box
        ))

        self:SetXOffset(math.max(
            math.min(
                xOffset,
                viewport.contentWidth - width -- Must not leave any unneccessary blank space at the bottom of the scroll box
            ),
            0  -- Must not leave any unneccessary blank space at the top of the scroll box
        ))

        _Position(self, x - xOffset, y + yOffset + height - self.contentHeight)


        if width < self.contentWidth then
            horizontalScrollbar:Position(x + width / viewport.contentWidth * xOffset, y)
        end
        if height < self.contentHeight then
            local relativeHeight = height / viewport.contentHeight
            verticalScrollbar:Position(x + width - cachedScrollbarThickness, y + height - relativeHeight * yOffset - height * relativeHeight)
        end
    end

    local _Draw = viewport.Draw
    function viewport:Draw()
        if height <= 0 or width <= 0 then
            return
        end

        local clipWidth = width
        local clipHeight = height

        local clipY = _y

        if height < self.contentHeight then
            clipWidth = clipWidth - cachedScrollbarThickness
        end
        if width < self.contentWidth then
            clipHeight = clipHeight - cachedScrollbarThickness
            clipY = clipY + cachedScrollbarThickness
        end
        
        gl.Scissor(_x, clipY, clipWidth, clipHeight)
        _Draw(self)
        gl.Scissor(false)
    end

    return viewport
end

--[[
    `ResponderScopeWrap` wraps its child (`body`) in no-op responders, to 'clip' interaction to its bounds. 
    Use this when clipping a child view to a parent's bounds, e.g. with `OffsettedViewport`.
]]
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

--[[
    A wrapper for `OffsettedViewport` that implements mousewheel interaction for vertical scrolling.
    `VerticalScrollContainer` is an extension of `Responder`.

    Since `DrawingGroup`'s default responder wrapping wraps the `OffsettedViewport`'s child - 
    which we can expect to be larger than the `OffsettedViewport` itself -
    we'll wrap it again outside to clip interaction to the bounds of `OffsettedViewport`.

    Read-only properties:
     - `container.viewport`: the wrapped `OffsettedViewport`.
]]
function framework:VerticalScrollContainer(body)
    local viewport = self:OffsettedViewport(body, framework.OFFSETED_VIEWPORT_MODE_VERTICAL)
    local container =  framework:Responder(framework:ResponderScopeWrap(viewport), framework.events.mouseWheel, function(responder, x, y, up, value)
        local _, responderHeight = responder:Size()
        local _, yOffset = viewport:GetOffsets()
        viewport:SetYOffset(math.max(
            math.min(
                yOffset - value * 20,
                viewport.contentHeight - responderHeight -- Must not leave any unneccessary blank space at the bottom of the scroll box
            ),
            0  -- Must not leave any unneccessary blank space at the top of the scroll box
        ))
        return true
    end)

    container.viewport = viewport

    return container
end

--[[
    A wrapper for `OffsettedViewport` that implements mousewheel interaction for horizontal scrolling.
    `HorizontalScrollContainer` is an extension of `Responder`.

    Since `DrawingGroup`'s default responder wrapping wraps the `OffsettedViewport`'s child - 
    which we can expect to be larger than the `OffsettedViewport` itself -
    we'll wrap it again outside to clip interaction to the bounds of `OffsettedViewport`.

    Read-only properties:
     - `container.viewport`: the wrapped `OffsettedViewport`.
]]
function framework:HorizontalScrollContainer(body)
    local viewport = self:OffsettedViewport(body, framework.OFFSETED_VIEWPORT_MODE_HORIZONTAL)

    local container = framework:Responder(framework:ResponderScopeWrap(viewport), framework.events.mouseWheel, function(responder, x, y, up, value)
        local responderWidth, _ = responder:Size()
        local xOffset, _ = viewport:GetOffsets()
        viewport:SetXOffset(math.max(
            math.min(
                xOffset - value * 20,
                viewport.contentWidth - responderWidth -- Must not leave any unneccessary blank space at the bottom of the scroll box
            ),
            0  -- Must not leave any unneccessary blank space at the top of the scroll box
        ))
        return true
    end)

    container.viewport = viewport

    return container
end