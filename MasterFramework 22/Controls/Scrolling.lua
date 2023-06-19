local gl = Include.gl
local math = Include.math

function framework:OffsettedViewport(body, autoWidth, autoHeight)
    local viewport = { yOffset = 0, xOffset = 0, contentHeight = 0, contentWidth = 0 }

    local width = 0
    local height = 0
    local _x = 0
    local _y = 0

    local draggingVertical = false
    local draggingHorizontal = false

    local horizontalScrollbarColor = framework.color.hoverColor
    local verticalScrollbarColor = framework.color.hoverColor

    local scrollbarThickness = framework:Dimension(2)
    
    local function verticalScrollbarRect()
        local relativeHeight = height / viewport.contentHeight
        local x2 = _x + width
        local x1 = x2 - scrollbarThickness()
        local y2 = _y + height - relativeHeight * viewport.yOffset
        local y1 = y2 - height * relativeHeight
        return x1, y1, x2, y2
    end
    local function horizontalScrollbarRect()
        local relativeWidth = width / viewport.contentWidth
        local y1 = _y
        local y2 = y1 + scrollbarThickness()
        local x1 = _x + relativeWidth * viewport.xOffset
        local x2 = x1 + width * relativeWidth
        return x1, y1, x2, y2
    end
        
    local textGroup = framework:TextGroup(
        framework:MouseOverResponder(
            framework:MousePressResponder(
                body,
                function(responder, x, y)
                    local vx1, vy1, vx2, vy2 = verticalScrollbarRect()
                    local hx1, hy1, hx2, hy2 = horizontalScrollbarRect()
                    if framework.PointIsInRect(x, y, vx1, vy1, vx2 - vx1, vy2 - vy1) then
                        verticalScrollbarColor = framework.color.pressColor
                        draggingVertical = true
                        return true
                    elseif framework.PointIsInRect(x, y, hx1, hy1, hx2 - hx1, hy2 - hy1) then
                        horizontalScrollbarColor = framework.color.selectedColor
                        draggingHorizontal = true
                        return true
                    end
                end,
                function(responder, x, y, dx, dy)
                    if draggingVertical then
                        viewport.yOffset = math.max(
                            math.min(
                                viewport.yOffset - dy * (viewport.contentHeight / height),
                                viewport.contentHeight - height -- Must not leave any unneccessary blank space at the bottom of the scroll box
                            ),
                            0  -- Must not leave any unneccessary blank space at the top of the scroll box
                        )
                    elseif draggingHorizontal then
                        viewport.xOffset = math.max(
                            math.min(
                                viewport.xOffset + dx * (viewport.contentWidth / width),
                                viewport.contentWidth - width -- Must not leave any unneccessary blank space at the bottom of the scroll box
                            ),
                            0  -- Must not leave any unneccessary blank space at the top of the scroll box
                        )
                    end
                end,
                function(responder, x, y)
                    draggingHorizontal = false
                    draggingVertical = false
                    horizontalScrollbarColor = framework.color.hoverColor
                    verticalScrollbarColor = framework.color.hoverColor
                end
            ),
            function(responder, x, y)
                local vx1, vy1, vx2, vy2 = verticalScrollbarRect()
                local hx1, hy1, hx2, hy2 = horizontalScrollbarRect()

                if not draggingVertical then
                    if framework.PointIsInRect(x, y, vx1, vy1, vx2 - vx1, vy2 - vy1) then
                        verticalScrollbarColor = framework.color.selectedColor
                        return true
                    else
                        verticalScrollbarColor = framework.color.hoverColor
                    end
                end
                if not draggingHorizontal then
                    if framework.PointIsInRect(x, y, hx1, hy1, hx2 - hx1, hy2 - hy1) then
                        horizontalScrollbarColor = framework.color.selectedColor
                        return true
                    else
                        horizontalScrollbarColor = framework.color.hoverColor
                    end
                end
            end,
            function(responder) end,
            function(responder)
                if not draggingHorizontal then 
                    horizontalScrollbarColor = framework.color.hoverColor
                end
                if not draggingVertical then
                    verticalScrollbarColor = framework.color.hoverColor
                end
            end
        ),
        "Offsetted Viewport"
    )

    function viewport:Layout(availableWidth, availableHeight)
        local _width, _height = textGroup:Layout(availableWidth, availableHeight)
        self.contentWidth = _width
        self.contentHeight = _height

        if autoWidth then
            width = self.contentWidth
        else
            width = math.max(math.min(availableWidth, self.contentWidth), 0)
        end

        if autoHeight then
            height = self.contentHeight
        else
            height = math.max(math.min(availableHeight, self.contentHeight), 0)
        end

        return width, height
    end
    function viewport:Draw(x, y)
        _x = x
        _y = y
        if height <= 0 or width <= 0 then return end
        gl.Scissor(x, y, width, height)
        textGroup:Draw(x - self.xOffset, y + self.yOffset + height - self.contentHeight)
        gl.Scissor(false)

        if height < self.contentHeight then
            verticalScrollbarColor:Set()
            gl.Rect(verticalScrollbarRect())
        end
        if width < self.contentWidth then
            horizontalScrollbarColor:Set()
            gl.Rect(horizontalScrollbarRect())
        end
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
    local viewport = self:OffsettedViewport(body, true, false)
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
    local viewport = self:OffsettedViewport(body, false, true)

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