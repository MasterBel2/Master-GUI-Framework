local math = Include.math
local Internal = Internal
local gl = Include.gl
local table_insert = Include.table.insert

-- Selection indices ranges from 1 (before the first character) to string:len() + 1 (after the last character)
-- Consider that to changing to 0 (before the first character) to string:len() (after the first character)
function framework:TextEntry(string, placeholderString, color, font, maxLines)
    color = color or framework.color.white
    local entry = {
        text = framework:WrappingText(string, color, font, maxLines),
        placeholder = framework:Text(placeholderString, framework:Color(color.r, color.g, color.b, 0.3), font, 1),
        selectionBegin = string:len() + 1, 
        selectionEnd = string:len() + 1, 
        canLoseFocus = false
    }

    local focused

    local selectFrom

    local selectedStroke = framework:Stroke(framework:Dimension(2), framework.color.hoverColor)
    local textStack = framework:StackInPlace({ entry.text, entry.placeholder }, 0, 0)
    local background = framework:MarginAroundRect(
        textStack,
        framework:Dimension(8),
        framework:Dimension(8),
        framework:Dimension(8),
        framework:Dimension(8),
        { framework:Color(0, 0, 0, 0.7) }
    )
    local selectionDetector = framework:MousePressResponder(
        background,
        function(responder, mouseX, mouseY, button)
            if button ~= 1 then return false end
            
            entry.selectionBegin = entry.text:CoordinateToCharacterRawIndex(mouseX, mouseY)
            entry.selectionEnd = entry.selectionBegin
            selectFrom = "begin" -- TODO: selection matching, click & drag text if you drag where already selected??
            
            entry:TakeFocus()

            selectedStroke.color = framework.color.pressColor
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
            
            -- if framework.PointIsInRect(mouseX, mouseY, responder:Geometry()) then
            --     selectedStroke.color = pressColor
            --     background.decorations[2] = selectedStroke
            -- elseif framework:FocusTarget() == entry then
            --     selectedStroke.color = selectedColor
            --     background.decorations[2] = selectedStroke
            -- else
            --     background.decorations[2] = nil
            -- end
        end,
        function(responder, mouseX, mouseY)
            selectedStroke.color = framework.color.selectedColor
            if self.selectionBegin == self.selectionEnd then
                selectFrom = nil
            end

            if framework.PointIsInRect(mouseX, mouseY, responder:Geometry()) and framework:FocusTarget() == entry then
                background.decorations[2] = selectedStroke
            else
                background.decorations[2] = nil
            end
        end
    )

    function entry:editBackspace(isCtrl)
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
    
    function entry:editDelete(isCtrl)
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

    function entry:editReturn(isCtrl)
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
            return true
        elseif key == 0x7F then 
            self:editDelete()
            return true
        elseif key == 0x1B then 
            self:editEscape()
            return true
        elseif key == 0x113 then
            self:editNext(mods.shift, mods.ctrl)
            return true
        elseif key == 0x114 then
            self:editPrevious(mods.shift, mods.ctrl)
            return true
        elseif key == 0x0D or key == 0x10F then
            self:editReturn(mods.ctrl)
            return true
        end
    end

    function entry:KeyRelease() end

    -- Attepts to own text editing focus.
    --
    -- We can take focus from another MasterFramework element, but not a different widget.
    -- Returns `true` on success, `nil` on failure.
    function entry:TakeFocus()
        if framework:TakeFocus(self) then
            focused = true
            selectedStroke.color = framework.color.selectedColor
            background.decorations[2] = selectedStroke
            return true
        end
    end

    -- Releases text editing focus, if we have it.
    function entry:ReleaseFocus()
        focused = false
        framework:ReleaseFocus(self)
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

    local x, y
    function entry:Position(_x, _y)
        x = _x
        y = _y
        selectionDetector:Position(x, y)
        table_insert(activeDrawingGroup.drawTargets, self)
    end

    function entry:Draw()
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

                    framework.color.hoverColor:Set()

                    if self.selectionBegin == self.selectionEnd then
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