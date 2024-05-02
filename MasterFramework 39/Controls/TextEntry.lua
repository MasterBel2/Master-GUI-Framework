local math = Include.math
local Internal = Internal
local gl = Include.gl
local table_insert = Include.table.insert
local os_clock = Include.os.clock

local gl_Rect = gl.Rect

local math_max = math.max
local math_min = math.min
local math_floor = math.floor

local forwardCtrlSkipPattern = "[%s\n]*[^%s\n]+[%s\n]"
local reverseCtrlSkipPattern = "[%s\n][^%s\n]+[%s\n]*$"

local Spring_GetClipboard = Include.Spring.GetClipboard
local Spring_SetClipboard = Include.Spring.SetClipboard
-- Selection indices ranges from 1 (before the first character) to string:len() + 1 (after the last character)
-- Consider that to changing to 0 (before the first character) to string:len() (after the first character)
function framework:TextEntry(string, placeholderString, color, font, maxLines)
    color = color or framework.color.white
    local entry = {
        text = framework:WrappingText(string, color, font, maxLines),
        placeholder = framework:Text(placeholderString, framework:Color(color.r, color.g, color.b, 0.3), font, 1),
        selectionBegin = string:len() + 1, -- index of character after selection begin
        selectionEnd = string:len() + 1, -- index of character after selection end
        canLoseFocus = false,

        undoSingleCharAppendable = false,

    }

    local undoLog = {}
    local redoLog = {}

    local undoOffset = 0
    local redoOffset = -1

    local focused

    local selectFrom
    local selectionChangedClock = os_clock()

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

            selectionChangedClock = os_clock()
            
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

            selectionChangedClock = os_clock()
            
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

        local selectionBegin = self.selectionBegin
        local selectionEnd = self.selectionEnd

        local deletedText
        if selectionBegin == selectionEnd then
            if selectionBegin == 1 then return true end
            if isCtrl then
                local begin = self.text:GetRawString():sub(1, self.selectionBegin - 1):find(reverseCtrlSkipPattern)
                deletedText = string:sub(begin + 1, selectionBegin - 1)
            else
                deletedText = string:sub(selectionBegin - 1, selectionBegin - 1)
            end
        else
            deletedText = string:sub(selectionBegin, selectionEnd - 1)
        end

        local function redoAction()
            local string = entry.text:GetRawString()

            if selectionBegin == selectionEnd then
                string = string:sub(1, selectionBegin - 1 - deletedText:len()) .. string:sub(selectionBegin)
                self.selectionBegin = selectionBegin - deletedText:len()
            else
                string = string:sub(1, selectionBegin - 1) .. string:sub(selectionEnd)
                self.selectionBegin = selectionBegin
            end
    
            self.selectionEnd = self.selectionBegin

            entry.text:SetString(string)
        end

        self:InsertUndoAction(function()
            local string = entry.text:GetRawString()
            if selectionBegin == selectionEnd then
                entry.text:SetString(string:sub(1, selectionBegin - 1 - deletedText:len()) .. deletedText .. string:sub(selectionBegin - deletedText:len()))
                entry.selectionBegin = selectionBegin
            else
                entry.text:SetString(string:sub(1, selectionBegin - 1) .. deletedText .. string:sub(selectionBegin))
                entry.selectionBegin = selectionBegin + deletedText:len()
            end

            
            entry.selectionEnd = entry.selectionBegin
        end, redoAction)

        redoAction()
    end
    
    function entry:editDelete(isCtrl)
        local string = entry.text:GetRawString()

        local selectionBegin = self.selectionBegin
        local selectionEnd = self.selectionEnd

        local deletedText
        if selectionBegin == selectionEnd then
            if isCtrl then
                local _, blockEnd = string:find(forwardCtrlSkipPattern, selectionBegin)
                deletedText = string:sub(selectionBegin, (blockEnd and (blockEnd - 1) or entry.text:GetRawString():len()))
            else
                deletedText = string:sub(selectionBegin, selectionBegin)
            end
        else
            deletedText = string:sub(selectionBegin, selectionEnd - 1)
        end

        local function redoAction()
            local string = entry.text:GetRawString()

            if selectionBegin == selectionEnd then
                string = string:sub(1, selectionBegin - 1) .. string:sub(selectionEnd + deletedText:len())
            else
                string = string:sub(1, selectionBegin - 1) .. string:sub(selectionEnd)
            end
    
            self.selectionBegin = selectionBegin
            self.selectionEnd = self.selectionBegin

            entry.text:SetString(string)
        end

        self:InsertUndoAction(function()
            local string = entry.text:GetRawString()

            entry.text:SetString(string:sub(1, selectionBegin - 1) .. deletedText .. string:sub(selectionBegin))

            entry.selectionBegin = selectionBegin
            entry.selectionEnd = entry.selectionBegin
        end, redoAction)

        redoAction()
    end

    function entry:editPrevious(isShift, isCtrl)

        if isShift and not selectFrom then
            selectFrom = "begin"
        end

        if isCtrl then
            if selectFrom == "end" then
                local begin = self.text:GetRawString():sub(1, self.selectionEnd - 1):find(reverseCtrlSkipPattern)
                self.selectionEnd = (begin or 0) + 1
            else
                local begin = self.text:GetRawString():sub(1, self.selectionBegin - 1):find(reverseCtrlSkipPattern)
                self.selectionBegin = (begin or 0) + 1
            end
        elseif isShift or not selectFrom then
            if selectFrom == "end" then
                self.selectionEnd = math_max(self.selectionEnd - 1, 1)                        
            else
                self.selectionBegin = math_max(self.selectionBegin - 1, 1)
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
                local _, matchEnd = string:find(forwardCtrlSkipPattern, self.selectionBegin)
                self.selectionBegin = matchEnd or stringEnd
            else
                local _, matchEnd = string:find(forwardCtrlSkipPattern, self.selectionEnd)
                self.selectionEnd = matchEnd or stringEnd
            end
        elseif isShift or not selectFrom then
            if selectFrom == "begin" then
                self.selectionBegin = math_min(stringEnd, self.selectionBegin + 1)
            else
                self.selectionEnd = math_min(stringEnd, self.selectionEnd + 1)
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
        self:InsertText("\n")
    end
    
    function entry:editEscape()
        self:ReleaseFocus()
    end

    function entry:InsertUndoAction(undoAction, redoAction)
        local undoLogLength = #undoLog
        for i = 1, undoOffset do
            undoLog[#undoLog - undoOffset + i] = nil
            redoLog[#redoLog - undoOffset + i] = nil
        end
        
        undoOffset = 0

        undoLog[#undoLog + 1] = undoAction
        redoLog[#redoLog + 1] = redoAction
    end

    function entry:InsertText(newText)
        local selectionBegin = self.selectionBegin
        local selectionEnd = self.selectionEnd

        local string = self.text:GetRawString()
        
        local replacedText = string:sub(selectionBegin, selectionEnd - 1)

        local function redoAction()
            local string = entry.text:GetRawString()
            entry.text:SetString(string:sub(1, selectionBegin - 1) .. newText .. string:sub(selectionEnd))

            entry.selectionBegin = selectionBegin + newText:len()
            entry.selectionEnd = entry.selectionBegin
        end

        self:InsertUndoAction(function()
            local string = entry.text:GetRawString()
            entry.text:SetString(string:sub(1, selectionBegin - 1) .. replacedText .. string:sub(selectionBegin + newText:len()))
            
            entry.selectionBegin = selectionBegin + replacedText:len()
            entry.selectionEnd = entry.selectionBegin
        end, redoAction)
        
        redoAction()
    end

    function entry:TextInput(char)
        entry:InsertText(char)
    end

    function entry:KeyPress(key, mods, isRepeat)
        selectionChangedClock = os_clock()

        if key == 0x08 then
            self:editBackspace(mods.ctrl)
            return true
        elseif key == 0x7F then 
            self:editDelete(mods.ctrl)
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
        elseif key == 0x63 and mods.ctrl then 
            self:editCopy()
            return true
        elseif key == 0x78 and mods.ctrl then
            self:editCut()
            return true
        elseif key == 0x76 and mods.ctrl then
            self:editPaste()
            return true
        elseif key == 0x7A and mods.ctrl and not mods.shift then
            self:editUndo()
            return true
        elseif key == 0x7A and mods.ctrl and mods.shift then
            self:editRedo()
            return true
        end
    end

    function entry:editCopy()
        if self.selectionBegin ~= self.selectionEnd then
            Spring_SetClipboard(self.text:GetRawString():sub(self.selectionBegin, self.selectionEnd - 1))
        end
    end
    function entry:editPaste()
        self:InsertText(Spring_GetClipboard())
    end
    function entry:editCut()
        if self.selectionBegin ~= self.selectionEnd then
            Spring_SetClipboard(self.text:GetRawString():sub(self.selectionBegin, self.selectionEnd - 1))
            self:InsertText("")
        end
    end
    function entry:editUndo()
        local currentUndo = undoLog[#undoLog - undoOffset]
        if currentUndo then
            currentUndo()
            undoOffset = undoOffset + 1
        end
    end
    function entry:editRedo()
        local currentRedo = redoLog[#redoLog - (undoOffset - 1)]
        if currentRedo then
            currentRedo()
            undoOffset = undoOffset - 1
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

    function entry:NeedsLayout()
        return selectionDetector:NeedsLayout() or self.text:NeedsLayout()
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
            local textX, textY, textWidth, textHeight = self.text:Geometry()

            local trueLineHeight = font.glFont.lineheight * font:ScaledSize()

            local displayString = self.text:GetDisplayString()
            local lineStarts, lineEnds = displayString:lines_MasterFramework()
            
            local displayIndexOfCharacterAfterSelectionBegin, addedCharactersIndex, removedSpacesIndex, computedOffset, _ = self.text:RawIndexToDisplayIndex(self.selectionBegin)
            local displayIndexOfCharacterAfterSelectionEnd = self.text:RawIndexToDisplayIndex(self.selectionEnd, addedCharactersIndex, removedSpacesIndex, computedOffset)
            
            local fontScaledSize = font:ScaledSize()

            for i = 1, #lineStarts do
                local lineStart = lineStarts[i]
                local lineEnd = lineEnds[i]

                if displayIndexOfCharacterAfterSelectionBegin <= lineEnd + 1 and displayIndexOfCharacterAfterSelectionEnd >= lineStart then
                    local highlightYOffset = i * trueLineHeight
                    -- clamp selection to line
                    local highlightBeginIndex = math_max(displayIndexOfCharacterAfterSelectionBegin, lineStart)
                    -- Allow an index that specifies the first character of the next line; 
                    -- Selection end indices give the index of the first character excluded from the selection,
                    -- So this correctly includes the newline in the drawn selection, without incorrectly measuring
                    -- any characters from the next line.
                    --
                    -- highlightEndIndex is used for generating the substring, so we subtract one to specify the 
                    -- character within the selection, rather than the character without the selection.
                    local highlightEndIndex = math_min(displayIndexOfCharacterAfterSelectionEnd, lineEnd + 2) - 1

                    local stringBeforeInsertion = displayString:sub(lineStart, highlightBeginIndex - 1)

                    local highlightBeginXOffset = font.glFont:GetTextWidth(stringBeforeInsertion) * fontScaledSize

                    local lineY = textY + textHeight - highlightYOffset

                    framework.color.hoverColor:Set()

                    if self.selectionBegin == self.selectionEnd then
                        if math_floor(os_clock() - selectionChangedClock) % 2 == 0 then
                            gl_Rect(textX + highlightBeginXOffset - 0.5, lineY, textX + highlightBeginXOffset + 0.5, lineY + trueLineHeight)
                        end
                        return
                    else
                        local highlightEndXOffset
                        if highlightEndIndex == lineEnd + 1 then
                            highlightEndXOffset = textWidth
                        else
                            local highlightedString = displayString:sub(highlightBeginIndex, highlightEndIndex)
                            highlightEndXOffset = font.glFont:GetTextWidth(highlightedString) * fontScaledSize + highlightBeginXOffset
                        end

                        gl_Rect(textX + highlightBeginXOffset, lineY, textX + highlightEndXOffset, lineY + trueLineHeight)
                    end
                elseif displayIndexOfCharacterAfterSelectionEnd <= lineStart then
                    break
                end
            end
        end
    end

    return entry
end