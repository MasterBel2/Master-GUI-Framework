local Internal = Internal

local math = Include.math
local table_insert = Include.table.insert
local os_clock = Include.os.clock

local Spring_GetModKeyState = Include.Spring.GetModKeyState

local math_max = math.max
local math_min = math.min
local math_floor = math.floor

local forwardCtrlSkipPattern = "[%s\n]*[^%s\n]+[%s\n]"
local reverseCtrlSkipPattern = "[%s\n][^%s\n]+[%s\n]*$"

local nextNewlinePattern = ".[^\n]*[\n]"
local previousNewlinePattern = "[\n][^\n]*$"

local Spring_GetClipboard = Include.Spring.GetClipboard
local Spring_SetClipboard = Include.Spring.SetClipboard
-- Selection indices ranges from 1 (before the first character) to string:len() + 1 (after the last character)
-- Consider that to changing to 0 (before the first character) to string:len() (after the first character)
function framework:TextEntry(string, placeholderString, color, font, maxLines)
    color = color or framework.color.white
    local entry = Drawer()

    entry.text = framework:WrappingText(string, color, font, maxLines)
    local placeholderR, placeholderG, placeholderB = color:GetRawValues()
    entry.placeholder = framework:Text(placeholderString, framework:Color(placeholderR, placeholderG, placeholderB, 0.3), font, 1)
    entry.selectionBegin = string:len() + 1 -- index of character after selection begin
    entry.selectionEnd = string:len() + 1 -- index of character after selection end
    entry.canLoseFocus = false
    entry.undoSingleCharAppendable = false

    -- Reserve the ID, but we'll drop it until we need it later
    local selectionHighlightID = entry.text:HighlightRange(
        framework.color.hoverColor,
        entry.selectionBegin,
        entry.selectionEnd
    )
    entry.text:RemoveHighlight(selectionHighlightID)

    local undoLog = {}
    local redoLog = {}

    local undoOffset = 0
    local redoOffset = -1

    local focused

    local selectFrom
    local selectionChangedClock = os_clock()

    function entry:CurrentCursorIndex()
        if selectFrom == "begin" then
            return self.selectionBegin 
        else 
            return self.selectionEnd
        end
    end

    function entry:MoveCursor(destinationIndex, isShift)
        self:NeedsRedraw()
        selectionChangedClock = os_clock()
        if not isShift then
            self.selectionBegin = destinationIndex
            self.selectionEnd = destinationIndex
            selectFrom = nil
        else
            if not selectFrom then
                if destinationIndex < self.selectionBegin then
                    selectFrom = "begin"
                else
                    selectFrom = "end"
                end
            end

            if selectFrom == "begin" then
                self.selectionBegin = destinationIndex

                if self.selectionEnd < self.selectionBegin then
                    local temp = self.selectionEnd
                    self.selectionEnd = self.selectionBegin 
                    self.selectionBegin = temp
                    selectFrom = "end"
                end
            elseif selectFrom == "end" then
                self.selectionEnd = destinationIndex

                if self.selectionEnd < self.selectionBegin then
                    local temp = self.selectionEnd
                    self.selectionEnd = self.selectionBegin 
                    self.selectionBegin = temp
                    selectFrom = "begin"
                end
            end
            
            if self.selectionBegin == self.selectionEnd then
                selectFrom = nil
            end
        end
        self.text:UpdateHighlight(selectionHighlightID, framework.color.hoverColor, self.selectionBegin, self.selectionEnd)
    end

    local textStack = framework:StackInPlace({ entry.text, entry.placeholder }, 0, 0)
    local background = framework:Background(
        framework:MarginAroundRect(
            textStack,
            framework:AutoScalingDimension(8),
            framework:AutoScalingDimension(8),
            framework:AutoScalingDimension(8),
            framework:AutoScalingDimension(8)
        ), 
        textEntryStyles.defaultBackgroundDecorations
    )
    local selectionDetector = framework:MousePressResponder(
        background,
        function(responder, mouseX, mouseY, button)
            if button ~= 1 then return false end
            
            -- TODO: selection matching, click & drag text if you drag where already selected??
            local _, _, _, shift = Spring_GetModKeyState()

            entry:MoveCursor(entry.text:CoordinateToCharacterRawIndex(mouseX, mouseY), shift)
            
            entry:TakeFocus()

            background:SetDecorations(textEntryStyles.pressedBackgroundDecorations)

            selectionChangedClock = os_clock()
            
            return true
        end,
        function(responder, mouseX, mouseY)
            entry:MoveCursor(entry.text:CoordinateToCharacterRawIndex(mouseX, mouseY), true)
            
            -- if responder:ContainsAbsolutePoint(mouseX, mouseY) then
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
            if responder:ContainsAbsolutePoint(mouseX, mouseY) and framework:FocusTarget() == entry then
                background:SetDecorations(textEntryStyles.selectedBackgroundDecorations)
            else
                background:SetDecorations(textEntryStyles.defaultBackgroundDecorations)
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
                local begin = self.text:GetRawString():sub(1, self.selectionBegin - 1):find(reverseCtrlSkipPattern) or 0
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
                entry:MoveCursor(selectionBegin - deletedText:len())
            else
                string = string:sub(1, selectionBegin - 1) .. string:sub(selectionEnd)
                entry:MoveCursor(selectionBegin)
            end

            entry.text:SetString(string)
        end

        self:InsertUndoAction(function()
            local string = entry.text:GetRawString()
            if selectionBegin == selectionEnd then
                entry.text:SetString(string:sub(1, selectionBegin - 1 - deletedText:len()) .. deletedText .. string:sub(selectionBegin - deletedText:len()))
                entry:MoveCursor(selectionBegin)
            else
                entry.text:SetString(string:sub(1, selectionBegin - 1) .. deletedText .. string:sub(selectionBegin))
                entry:MoveCursor(selectionBegin + deletedText:len())
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
    
            entry:MoveCursor(selectionBegin)

            entry.text:SetString(string)
        end

        self:InsertUndoAction(function()
            local string = entry.text:GetRawString()

            entry.text:SetString(string:sub(1, selectionBegin - 1) .. deletedText .. string:sub(selectionBegin))

            entry:MoveCursor(selectionBegin)
        end, redoAction)

        redoAction()
    end

    function entry:editPrevious(isShift, isCtrl)
        local destinationIndex

        if selectFrom and not isShift then 
            destinationIndex = self.selectionBegin
        else
            if isCtrl then
                destinationIndex = (self.text.GetRawString():sub(1, self:CurrentCursorIndex() - 1):find(reverseCtrlSkipPattern) or 0) + 1
            else
                destinationIndex = math_max(self:CurrentCursorIndex() - 1, 1)
            end
        end
        
        self:MoveCursor(destinationIndex, isShift)
    end
    
    function entry:editNext(isShift, isCtrl)
        local destinationIndex

        if selectFrom and not isShift then
            destinationIndex = self.selectionEnd
        else
            local string = self.text.GetRawString()
            local stringEnd = string:len() + 1
            if isCtrl then
                local _, matchEnd = string:find(forwardCtrlSkipPattern, self:CurrentCursorIndex())
                destinationIndex = matchEnd or stringEnd
            else
                destinationIndex = math_min(self:CurrentCursorIndex() + 1, stringEnd)
            end
        end

        self:MoveCursor(destinationIndex, isShift)
    end

    function entry:IndexAtXOffsetBetweenDisplayNewlineIndices(rangeBeginDisplayIndex, rangeEndDisplayIndex, xOffset)
        local font = self.text._readOnly_font
        xOffset = math_floor(xOffset)
        
        local rawString = self.text:GetRawString()

        local accumulatedWidth = 0

        local rangeBeginRawIndex = self.text:DisplayIndexToRawIndex(rangeBeginDisplayIndex) + 1
        local rangeEndRawIndex = self.text:DisplayIndexToRawIndex(rangeEndDisplayIndex) - 1

        for i = rangeBeginRawIndex, rangeEndRawIndex do
            if xOffset <= accumulatedWidth then
                return i
            else
                accumulatedWidth = accumulatedWidth + math_floor(font.glFont:GetTextWidth(rawString:sub(i, i)) * font:ScaledSize())
            end
        end
        
        return rangeEndRawIndex + 1
    end

    function entry:editAbove(isShift, isCtrl)
        local destinationIndex

        if selectFrom and not isShift then 
            destinationIndex = self.selectionBegin
        else
            if isCtrl then
                local clippedString = self.text:GetRawString():sub(1, self:CurrentCursorIndex() - 1)
                destinationIndex = (clippedString:find(previousNewlinePattern) or 0) + 1
            else
                local displayString = self.text:GetDisplayString()
                local displayIndex = self.text:RawIndexToDisplayIndex(self:CurrentCursorIndex())
                local substring = displayString:sub(1, displayIndex - 1)
                
                local previousNewlineIndex = substring:find(previousNewlinePattern)
                
                if previousNewlineIndex then
                    local previousLineStart = (substring:sub(1, previousNewlineIndex - 1):find(previousNewlinePattern) or 0)
                    if previousLineStart then
                        local targetWidth = self.text._readOnly_font.glFont:GetTextWidth(substring:sub(previousNewlineIndex + 1, displayIndex - 1)) * self.text._readOnly_font:ScaledSize()
                        destinationIndex = self:IndexAtXOffsetBetweenDisplayNewlineIndices(previousLineStart, previousNewlineIndex, targetWidth)
                    else
                        destinationIndex = 1
                    end
                else
                    destinationIndex = 1
                end
            end
        end
        self:MoveCursor(destinationIndex, isShift)
    end

    function entry:editBelow(isShift, isCtrl)
        local destinationIndex

        if selectFrom and not isShift then 
            destinationIndex = self.selectionEnd
        else
            if isCtrl then
                destinationIndex = (self.text:GetRawString():find("\n", self:CurrentCursorIndex() + 1) or self.text:GetRawString():len() + 1)
            else
                local displayString = self.text:GetDisplayString()
                local displayIndex = self.text:RawIndexToDisplayIndex(self:CurrentCursorIndex())
                local _, nextNewlineIndex = displayString:find("\n", displayIndex)
                if nextNewlineIndex then
                    local _, endOfNextLine = displayString:find(nextNewlinePattern, nextNewlineIndex)
                    endOfNextLine = endOfNextLine or displayString:len() + 1
                    local currentLineStart = (displayString:sub(1, displayIndex):find(previousNewlinePattern) or 0) + 1

                    local targetWidth = self.text._readOnly_font.glFont:GetTextWidth(displayString:sub(currentLineStart, displayIndex - 1)) * self.text._readOnly_font:ScaledSize()
                    destinationIndex = self:IndexAtXOffsetBetweenDisplayNewlineIndices(nextNewlineIndex, endOfNextLine, targetWidth)
                else
                    destinationIndex = self.text:GetRawString():len() + 1
                end
            end
            
        end

        self:MoveCursor(destinationIndex, isShift)
    end

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
            
            entry:MoveCursor(selectionBegin + newText:len())
        end

        self:InsertUndoAction(function()
            local string = entry.text:GetRawString()
            entry.text:SetString(string:sub(1, selectionBegin - 1) .. replacedText .. string:sub(selectionBegin + newText:len()))
            
            entry:MoveCursor(selectionBegin + replacedText:len())
        end, redoAction)
        
        redoAction()
    end

    function entry:TextInput(char)
        entry:InsertText(char)
    end

    function entry:KeyPress(key, mods, isRepeat)
        if key == 0x08 then
            self:editBackspace(mods.ctrl)
            return true
        elseif key == 0x7F then 
            self:editDelete(mods.ctrl)
            return true
        elseif key == 0x1B then 
            self:editEscape()
            return true
        elseif key == 0x111 then
            self:editAbove(mods.shift, mods.ctrl)
            return true
        elseif key == 0x112 then
            self:editBelow(mods.shift, mods.ctrl)
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
            self.text:UpdateHighlight(selectionHighlightID, framework.color.hoverColor, self.selectionBegin, self.selectionEnd)
            background:SetDecorations(textEntryStyles.selectedBackgroundDecorations)
            return true
        end
    end

    -- Releases text editing focus, if we have it.
    function entry:ReleaseFocus()
        if self.selectionBegin == self.selectionEnd then
            self.text:RemoveHighlight(selectionHighlightID)
        end
        focused = false
        framework:ReleaseFocus(self)
        background:SetDecorations(textEntryStyles.defaultBackgroundDecorations)
    end

    function entry:Layout(...)
        if self.text:GetRawString() == "" then
            textStack:SetMembers({ self.text , self.placeholder })
        else
            textStack:SetMembers({ self.text })
        end
        return selectionDetector:Layout(...)
    end

    function entry:Position(x, y)
        selectionDetector:Position(x, y)
    end

    return entry
end