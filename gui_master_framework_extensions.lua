function widget:GetInfo()
    return {
        name = "MasterFramework Extensions",
        description = "Provides higher-level interface elements such as buttons that may combine one or more MasterFramework core components together",
        layer = -math.huge -- Run Initialise after MasterFramework file has loaded, but before any widget uses it
    }
end

local requiredFrameworkVersion = 21

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

        -- Selection indices ranges from 1 (before the first character) to string:len() + 1 (after the last character)
        -- Consider that to changing to 0 (before the first character) to string:len() (after the first character)
        function MasterFramework:TextEntry(string, placeholderString, color, font, maxLines)
            color = color or MasterFramework.color.white
            local entry = {
                text = MasterFramework:WrappingText(string, color, font, maxLines),
                placeholder = MasterFramework:Text(placeholderString, MasterFramework:Color(color.r, color.g, color.b, 0.3), font, 1),
                selectionBegin = string:len() + 1, 
                selectionEnd = string:len() + 1, 
                canLoseFocus = false
            }

            local focused

            local selectFrom

            local selectedStroke = MasterFramework:Stroke(2, hoverColor)
            local textStack = MasterFramework:StackInPlace({ entry.text, entry.placeholder }, 0, 0)
            local background = MasterFramework:MarginAroundRect(
                textStack,
                MasterFramework:Dimension(8),
                MasterFramework:Dimension(8),
                MasterFramework:Dimension(8),
                MasterFramework:Dimension(8),
                { MasterFramework:Color(0, 0, 0, 0.7) }   
            )
            local selectionDetector = MasterFramework:MousePressResponder(
                background,
                function(responder, mouseX, mouseY, button)
                    if button ~= 1 then return false end
                    
                    entry.selectionBegin = entry.text:CoordinateToCharacterRawIndex(mouseX, mouseY)
                    entry.selectionEnd = entry.selectionBegin
                    selectFrom = "begin" -- TODO: selection matching, click & drag text if you drag where already selected??
                    
                    entry:TakeFocus()

                    selectedStroke.color = pressColor
                    background.decorations[2] = selectedStroke
                    
                    return true
                end,
                function(responder, mouseX, mouseY)
                    if selectFrom == "begin" then
                        entry.selectionBegin = entry.text:CoordinateToCharacterRawIndex(mouseX, mouseY)
                    else
                        entry.selectionEnd = entry.text:CoordinateToCharacterRawIndex(mouseX, mouseY)
                    end

                    if entry.selectionEnd < entry.selectionBegin then
                        local temp = entry.selectionEnd
                        entry.selectionEnd = entry.selectionBegin 
                        entry.selectionBegin = temp
                        if selectFrom == "begin" then
                            selectFrom = "end"
                        else
                            selectFrom = "begin"
                        end
                    end
                    
                    -- if MasterFramework.PointIsInRect(mouseX, mouseY, responder:Geometry()) then
                    --     selectedStroke.color = pressColor
                    --     background.decorations[2] = selectedStroke
                    -- elseif MasterFramework:FocusTarget() == entry then
                    --     selectedStroke.color = selectedColor
                    --     background.decorations[2] = selectedStroke
                    -- else
                    --     background.decorations[2] = nil
                    -- end
                end,
                function(responder, mouseX, mouseY)
                    selectedStroke.color = selectedColor
                    if self.selectionBegin == self.selectionEnd then
                        selectFrom = nil
                    end

                    if MasterFramework.PointIsInRect(mouseX, mouseY, responder:Geometry()) and MasterFramework:FocusTarget() == entry then
                        background.decorations[2] = selectedStroke
                    else
                        background.decorations[2] = nil
                    end
                end
            )

            function entry:editBackspace()
                local string = self.text:GetRawString()
                
                if self.selectionBegin == self.selectionEnd then -- Point select
                    if self.selectionBegin == 1 then return true end
                    string = string:sub(1, self.selectionBegin - 2)  .. string:sub(self.selectionEnd, string:len())
            
                    self.selectionBegin = self.selectionBegin - 1
                else -- Block select
                    string = string:sub(1, self.selectionBegin - 1) .. string:sub(self.selectionEnd, string:len())
                end
                
                self.selectionEnd = self.selectionBegin
            
                self.text:SetString(string)
            end
            
            function entry:editDelete()
                local string = self.text:GetRawString()
            
                if self.selectionBegin == self.selectionEnd then
                    string = string:sub(1, self.selectionBegin - 1) .. string:sub(self.selectionEnd + 1, string:len())
                else
                    string = string:sub(1, self.selectionBegin - 1) .. string:sub(self.selectionEnd, string:len())
                end

                self.selectionEnd = self.selectionBegin

                self.text:SetString(string)
            end
        
            function entry:editPrevious(isShift, isCtrl)

                if isShift and not selectFrom then
                    selectFrom = "begin"
                end

                if isCtrl then
                    local string = self.text:GetRawString()
                    local reversedStringEnd = string:len()
                    local stringEnd = reversedStringEnd + 1
                    local reversed = string:reverse()
                    local reversedSelectionBegin = stringEnd - self.selectionBegin -- TODO: Check!
                    local reversedSelectionEnd = stringEnd - self.selectionEnd

                    if selectFrom == "end" then
                        local newReversedPointerLocation = math.max(reversed:find("[%s]", reversedSelectionEnd) or reversedStringEnd, reversedStringEnd)
                        self.selectionEnd = stringEnd - newReversedPointerLocation
                    else
                        local newReversedPointerLocation = math.max(reversed:find("[%s]", reversedSelectionBegin) or reversedStringEnd, reversedStringEnd)
                        self.selectionBegin = stringEnd - newReversedPointerLocation
                    end
                elseif isShift or not selectFrom then
                    if selectFrom == "end" then
                        self.selectionEnd = math.max(self.selectionEnd - 1, 1)                        
                    else
                        self.selectionBegin = math.max(self.selectionBegin - 1, 1)
                    end
                end

                if self.selectionEnd < self.selectionBegin then
                    local temp = self.selectionEnd
                    self.selectionEnd = self.selectionBegin 
                    self.selectionBegin = temp
                    selectFrom = "begin"
                end

                if not isShift then
                    if selectFrom == "end" then
                        self.selectionBegin = self.selectionEnd
                    else
                        self.selectionEnd = self.selectionBegin
                    end
                    selectFrom = nil
                end

                return true
            end
            
            function entry:editNext(isShift, isCtrl)
                local string = self.text:GetRawString()
                local stringEnd = string:len() + 1

                if isShift and not selectFrom then
                    selectFrom = "end"
                end

                if isCtrl then
                    if selectFrom == "begin" then
                        self.selectionBegin = math.min(stringEnd, string:find("[%s]", self.selectionBegin) or stringEnd)
                    else
                        self.selectionEnd = math.min(stringEnd, string:find("[%s]", self.selectionEnd) or stringEnd)
                    end
                elseif isShift or not selectFrom then
                    if selectFrom == "begin" then
                        self.selectionBegin = math.min(stringEnd, self.selectionBegin + 1)
                    else
                        self.selectionEnd = math.min(stringEnd, self.selectionEnd + 1)
                    end
                end

                if self.selectionEnd < self.selectionBegin then
                    local temp = self.selectionEnd
                    self.selectionEnd = self.selectionBegin 
                    self.selectionBegin = temp
                    selectFrom = "end"
                end

                if not isShift then
                    if selectFrom == "begin" then
                        self.selectionEnd = self.selectionBegin
                    else
                        self.selectionBegin = self.selectionEnd
                    end
                    selectFrom = nil
                end
            end

            -- function entry:editPreviousWord() --[[Not implemented]] end
            -- function entry:editNextWord() --[[Not implemented]] end

            function entry:editReturn()
                local string = self.text:GetRawString()
                
                if self.selectionBegin == self.selectionEnd then -- Point select
                    if self.selectionBegin == 1 then return true end
                    string = string:sub(1, self.selectionBegin) .. "\n".. string:sub(self.selectionEnd + 1, string:len())
            
                    self.selectionBegin = self.selectionBegin + 1
                else -- Block select
                    string = string:sub(1, self.selectionBegin) .. "\n" .. string:sub(self.selectionEnd, string:len())
                end
                
                self.selectionEnd = self.selectionBegin
            
                self.text:SetString(string)
            end
            
            function entry:editEscape()
                self:ReleaseFocus()
            end

            function entry:TextInput(char)
                local string = self.text:GetRawString()

                string = string:sub(1, self.selectionBegin - 1) .. char .. string:sub(self.selectionEnd)
                self.text:SetString(string)

                self.selectionBegin = self.selectionBegin + char:len()
                self.selectionEnd = self.selectionBegin
            end

            function entry:KeyPress(key, mods, isRepeat)
                if key == 0x08 then
                    self:editBackspace()
                elseif key == 0x7F then 
                    self:editDelete()
                elseif key == 0x1B then 
                    self:editEscape()
                elseif key == 0x113 then
                    self:editNext(mods.shift, mods.ctrl)
                elseif key == 0x114 then
                    self:editPrevious(mods.shift, mods.ctrl)
                elseif key == 0x0D or key == 0x10F then
                    self:editReturn(mods.ctrl)
                end
            end

            function entry:KeyRelease() end

            -- Attepts to own text editing focus.
            --
            -- We can take focus from another MasterFramework element, but not a different widget.
            -- Returns `true` on success, `nil` on failure.
            function entry:TakeFocus()
                if MasterFramework:TakeFocus(self) then
                    focused = true
                    selectedStroke.color = selectedColor
                    background.decorations[2] = selectedStroke
                    return true
                end
            end

            -- Releases text editing focus, if we have it.
            function entry:ReleaseFocus()
                focused = false
                MasterFramework:ReleaseFocus(self)
                background.decorations[2] = nil
            end

            function entry:Layout(...)
                if self.text:GetRawString() == "" then
                    textStack.members[2] = self.placeholder
                else
                    textStack.members[2] = nil
                end
                return selectionDetector:Layout(...)
            end

            function entry:Draw(x, y)
                selectionDetector:Draw(x, y)

                if (focused or selectFrom) and not self.hideSelection then
                    -- this will be drawn after the background but before text, because we don't have our own TextGroup

                    local font = self.text._readOnly_font
                    local textX, textY, _, textHeight = self.text:Geometry()

                    local trueLineHeight = self.text._readOnly_font.glFont.lineheight * font:ScaledSize()

                    local displayString = self.text:GetDisplayString()
                    local lines, lineStarts, lineEnds = displayString:lines()

                    local translatedSelectionBegin = self.text:RawIndexToDisplayIndex(self.selectionBegin)
                    local translatedSelectionEnd = self.text:RawIndexToDisplayIndex(self.selectionEnd)
                    
                    for i = 1, #lines do
                        local line = lines[i]
                        local lineStart = lineStarts[i]
                        local lineEnd = lineEnds[i]

                        if translatedSelectionBegin <= lineEnd + 1 and translatedSelectionEnd >= lineStart then
                            local highlightYOffset = i * trueLineHeight
                            local highlightBeginIndex = math.max(translatedSelectionBegin + 1 - lineStart, 1)
                            local highlightEndIndex = math.min(translatedSelectionEnd + 1 - lineStart, lineEnd + 1)

                            local stringBeforeInsertion = line:sub(1, highlightBeginIndex - 1)

                            local highlightBeginXOffset = font.glFont:GetTextWidth(stringBeforeInsertion) * font:ScaledSize()

                            local lineY = textY + textHeight - highlightYOffset

                            if self.selectionBegin == self.selectionEnd then
                                hoverColor:Set()
                                gl.Rect(textX + highlightBeginXOffset - 0.5, lineY, textX + highlightBeginXOffset + 0.5, lineY + trueLineHeight)
                                return
                            else
                                local highlightedString = line:sub(highlightBeginIndex, highlightEndIndex - 1)
                                local highlightEndXOffset = font.glFont:GetTextWidth(highlightedString) * font:ScaledSize() + highlightBeginXOffset

                                gl.Rect(textX + highlightBeginXOffset, lineY, textX + highlightEndXOffset, lineY + trueLineHeight)
                            end
                        end
                    end
                end
            end

            return entry
        end

        function MasterFramework:OffsettedViewport(body, autoWidth, autoHeight)
            local viewport = { yOffset = 0, xOffset = 0, contentHeight = 0, contentWidth = 0 }
        
            local width = 0
            local height = 0
            local _x = 0
            local _y = 0

            local draggingVertical = false
            local draggingHorizontal = false

            local horizontalScrollbarColor = hoverColor
            local verticalScrollbarColor = hoverColor

            local scrollbarThickness = MasterFramework:Dimension(2)
            
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
                
            local textGroup = MasterFramework:TextGroup(
                MasterFramework:MouseOverResponder(
                    MasterFramework:MousePressResponder(
                        body,
                        function(responder, x, y)
                            local vx1, vy1, vx2, vy2 = verticalScrollbarRect()
                            local hx1, hy1, hx2, hy2 = horizontalScrollbarRect()
                            if MasterFramework.PointIsInRect(x, y, vx1, vy1, vx2 - vx1, vy2 - vy1) then
                                verticalScrollbarColor = pressColor
                                draggingVertical = true
                                return true
                            elseif MasterFramework.PointIsInRect(x, y, hx1, hy1, hx2 - hx1, hy2 - hy1) then
                                horizontalScrollbarColor = selectedColor
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
                            horizontalScrollbarColor = hoverColor
                            verticalScrollbarColor = hoverColor
                        end
                    ),
                    function(responder, x, y)
                        local vx1, vy1, vx2, vy2 = verticalScrollbarRect()
                        local hx1, hy1, hx2, hy2 = horizontalScrollbarRect()

                        if not draggingVertical then
                            if MasterFramework.PointIsInRect(x, y, vx1, vy1, vx2 - vx1, vy2 - vy1) then
                                verticalScrollbarColor = selectedColor
                                return true
                            else
                                verticalScrollbarColor = hoverColor
                            end
                        end
                        if not draggingHorizontal then
                            if MasterFramework.PointIsInRect(x, y, hx1, hy1, hx2 - hx1, hy2 - hy1) then
                                horizontalScrollbarColor = selectedColor
                                return true
                            else
                                horizontalScrollbarColor = hoverColor
                            end
                        end
                    end,
                    function(responder) end,
                    function(responder)
                        if not draggingHorizontal then 
                            horizontalScrollbarColor = hoverColor
                        end
                        if not draggingVertical then
                            verticalScrollbarColor = hoverColor
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

        function MasterFramework:ResponderScopeWrap(body)
            return MasterFramework:Responder(
                MasterFramework:Responder(
                    MasterFramework:Responder(
                        body,
                        MasterFramework.events.mousePress, 
                        function() end
                    ), 
                    MasterFramework.events.mouseOver, 
                    function() end
                ),
                MasterFramework.events.mouseWheel, 
                function() end
            )
        end

        function MasterFramework:VerticalScrollContainer(body)
            local viewport = self:OffsettedViewport(body, true, false)
            local container =  MasterFramework:Responder(MasterFramework:ResponderScopeWrap(viewport), MasterFramework.events.mouseWheel, function(responder, x, y, up, value)
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
        function MasterFramework:HorizontalScrollContainer(body)
            local viewport = self:OffsettedViewport(body, false, true)
        
            local container = MasterFramework:Responder(MasterFramework:ResponderScopeWrap(viewport), MasterFramework.events.mouseWheel, function(responder, x, y, up, value)
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