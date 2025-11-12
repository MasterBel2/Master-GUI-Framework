function widget:GetInfo()
    return {
        name = "Lua File Editor",
        description = "",
        author = "MasterBel2",
        date = "April 2023",
        license = "GNU GPL, v2 or later",
        layer = math.huge,
        handler = true
    }
end

------------------------------------------------------------------------------------------------------------
-- MasterFramework
------------------------------------------------------------------------------------------------------------

local MasterFramework
local requiredFrameworkVersion = "Dev"
local key

------------------------------------------------------------------------------------------------------------
-- Imports
------------------------------------------------------------------------------------------------------------

local math_max = math.max
local math_min = math.min

------------------------------------------------------------------------------------------------------------
-- Interface
------------------------------------------------------------------------------------------------------------

local function TakeAvailableHeight(body)
    local cachedHeight
    local cachedAvailableHeight
    return {
        Layout = function(_, availableWidth, availableHeight)
            local width, height = body:Layout(availableWidth, availableHeight)
            cachedHeight = height
            cachedAvailableHeight = math_max(availableHeight, height)
            return width, cachedAvailableHeight
        end,
        Position = function(_, x, y) body:Position(x, y + cachedAvailableHeight - cachedHeight) end
    }
end
local function TakeAvailableWidth(body)
    return {
        Layout = function(_, availableWidth, availableHeight)
            local _, height = body:Layout(availableWidth, availableHeight)
            return availableWidth, height
        end,
        Position = function(_, x, y) body:Position(x, y) end
    }
end

------------------------------------------------------------------------------------------------------------
-- Lexing
------------------------------------------------------------------------------------------------------------

local keywords = {
    ["function"] = true,
    ["for"] = true,
    ["do"] = true,
    ["if"] = true,
    ["then"] = true,
    ["else"] = true,
    ["elseif"] = true,
    ["repeat"] = true,
    ["until"] = true,
    ["while"] = true,

    ["not"] = true,
    ["and"] = true,
    ["or"] = true,
    ["in"] = true,

    ["nil"] = true,
    ["true"] = true,
    ["false"] = true,

    ["break"] = true,
    ["end"] = true,
    ["return"] = true,

    ["goto"] = true,
    ["local"] = true
}
local twoCharacterOperators = {
    [".."] = true,
    ["~="] = true,
    ["=="] = true,
    -- ["<<"] = true,
    -- [">>"] = true,
    ["<="] = true,
    ["<="] = true,
	[">="] = true,
}
local singleCharacterOperators = {
    [">"] = true,
    ["<"] = true,
    ["="] = true,
    ["."] = true,
    ["-"] = true,
    ["/"] = true,
    ["*"] = true,
    ["%"] = true,
    ["#"] = true,
    ["#"] = true,
}

local punctuation = {
    [","] = true,
    [":"] = true,
    [";"] = true,
    ["("] = true,
    [")"] = true,
    ["["] = true,
    ["]"] = true,
    ["{"] = true,
    ["}"] = true,
}

local whitespace = {
    [" "] = true,
    ["\t"] = true,
    ["\r"] = true,
    ["\n"] = true,
}

local keywordOrAttributePrimaryCharacterSet = "[%a_]"
local keywordOrAttributeSecondaryCharacterSet = "[%a%d_]"
local numberLiteralPrimaryCharacterSet = "%d"
local numberLiteralSecondaryCharacterSet = "[%d_.]"
local numberLiteralTertiaryCharacterSet = "[%d_]"
local operatorCharacterSet = "[#=%+%-%*/%%%^&~|<>=%.]"

local TOKEN_TYPE_STRING_LITERAL = 1
local TOKEN_TYPE_UNCLOSED_STRING_LITERAL = 2
local TOKEN_TYPE_KEYWORD = 3
local TOKEN_TYPE_ATTRIBUTE = 4
local TOKEN_TYPE_NUMBER_LITERAL = 5
local TOKEN_TYPE_MULTILINE_COMMENT = 6
local TOKEN_TYPE_COMMENT = 7
local TOKEN_TYPE_OPERATOR = 8
local TOKEN_TYPE_INVALID_CHARACTER = 9
local TOKEN_TYPE_MULTILINE_STRING_LITERAL = 10
local TOKEN_TYPE_PUNCTUATION = 11
local TOKEN_TYPE_WHITESPACE = 12

local function lexStringLiteral(string, startIndex, terminator)
    local nextIndex = startIndex
    local escaped

    while nextIndex <= string:len() do
        local nextCharacter = string:sub(nextIndex, nextIndex)
        if escaped then
            escaped = false
        else
            if nextCharacter == terminator then
                return TOKEN_TYPE_STRING_LITERAL, startIndex - 1, nextIndex
            elseif nextCharacter == "\n" then
                return TOKEN_TYPE_UNCLOSED_STRING_LITERAL, startIndex - 1, nextIndex
            elseif nextCharacter == "\\" then
                escaped = true
            end
        end
        nextIndex = nextIndex + 1
    end

    return TOKEN_TYPE_UNCLOSED_STRING_LITERAL, startIndex - 1, string:len()
end

local function parseMultiLine(string, startIndex)
    if string:sub(startIndex, startIndex) ~= "[" then
        return nil
    end

    local layerCount = 0
    local nextIndex = startIndex + 1

    while nextIndex <= string:len() do
        if string:sub(nextIndex, nextIndex) == "=" then
            layerCount = layerCount + 1
            nextIndex = nextIndex + 1
        elseif string:sub(nextIndex, nextIndex) == "[" then
            nextIndex = nextIndex + 1
            break
        else 
            return nil
        end
    end

    local multilineClose = "%]"
    for i = 1, layerCount do
        multilineClose = multilineClose .. "="
    end
    multilineClose = multilineClose .. "%]"
    local commentCloseBegin, commentCloseEnd = string:find(multilineClose, nextIndex)
    
    if commentCloseBegin then
        return commentCloseEnd
    end
end

local function lex(string)
    local tokenCount = 0
    local tokenTypes = {}
    local tokenStartIndices = {}
    local tokenEndIndices = {}

    local function addToken(type, startIndex, endIndex)
        tokenCount = tokenCount + 1
        tokenTypes[tokenCount] = type
        tokenStartIndices[tokenCount] = startIndex
        tokenEndIndices[tokenCount] = endIndex
    end

    local nextIndex = 1
    
    while nextIndex <= string:len() do
        local shouldContinue

        local currentIndex = nextIndex
        nextIndex = nextIndex + 1

        local character = string:sub(currentIndex, currentIndex)

        if character:find(keywordOrAttributePrimaryCharacterSet) then
            local startIndex = currentIndex
            while currentIndex <= string:len() do
                local character = string:sub(nextIndex, nextIndex)
                if not character or not character:find(keywordOrAttributeSecondaryCharacterSet) then
                    local keywordOrAttribute = string:sub(startIndex, currentIndex)
                    local tokenType
                    if keywords[keywordOrAttribute] then
                        tokenType = TOKEN_TYPE_KEYWORD
                    else
                        tokenType = TOKEN_TYPE_ATTRIBUTE
                    end

                    addToken(tokenType, startIndex, currentIndex)

                    nextIndex = currentIndex + 1
                    break
                end

                currentIndex = nextIndex
                nextIndex = nextIndex + 1
            end

        elseif character:find(numberLiteralPrimaryCharacterSet) then
            local numberBegin, numberEnd = string:find("[%d_]*[%.x]?[%d_]*", nextIndex) -- TODO: more fine-grained parsing, what if the decimal point is there, and nothing after it?
            if numberBegin == nextIndex then
                addToken(TOKEN_TYPE_NUMBER_LITERAL, currentIndex, numberEnd)
                nextIndex = numberEnd + 1
            else
                addToken(TOKEN_TYPE_NUMBER_LITERAL, currentIndex, currentIndex)
            end
        elseif character == "-" and string:sub(nextIndex, nextIndex) == "-" then -- comment
            local multilineCommentEndIndex = parseMultiLine(string, nextIndex + 1)
            if multilineCommentEndIndex then
                addToken(TOKEN_TYPE_MULTILINE_COMMENT, currentIndex, multilineCommentEndIndex)
                nextIndex = multilineCommentEndIndex + 1
            else
                local commentEnd = string:find("\n", nextIndex + 1) or string:len()
                addToken(TOKEN_TYPE_COMMENT, currentIndex, commentEnd)
                nextIndex = commentEnd + 1
            end
        elseif character:find(operatorCharacterSet) then
            if twoCharacterOperators[string:sub(currentIndex, nextIndex)] then
                addToken(TOKEN_TYPE_OPERATOR, currentIndex, nextIndex)
                nextIndex = nextIndex + 1
            elseif singleCharacterOperators[string:sub(currentIndex, currentIndex)] then
                addToken(TOKEN_TYPE_OPERATOR, currentIndex, currentIndex)
            else
                addToken(TOKEN_TYPE_INVALID_CHARACTER, currentIndex, currentIndex)
            end
        elseif character == "\'" then
            addToken(lexStringLiteral(string, nextIndex, "\'"))
            nextIndex = tokenEndIndices[tokenCount] + 1
        elseif character == "\"" then
            addToken(lexStringLiteral(string, nextIndex, "\""))
            nextIndex = tokenEndIndices[tokenCount] + 1
        elseif character == "[" then -- multi-line string literal
            local multilineStringEndIndex = parseMultiLine(string, currentIndex)
            if multilineStringEndIndex then
                addToken(TOKEN_TYPE_MULTILINE_STRING_LITERAL, currentIndex, multilineStringEndIndex)
                nextIndex = multilineStringEndIndex + 1
            else
                addToken(TOKEN_TYPE_PUNCTUATION, currentIndex, currentIndex)
            end
        elseif punctuation[character] then
            addToken(TOKEN_TYPE_PUNCTUATION, currentIndex, currentIndex)
        elseif whitespace[character] then
            addToken(TOKEN_TYPE_WHITESPACE, currentIndex, currentIndex)
        else
            addToken(TOKEN_TYPE_INVALID_CHARACTER, currentIndex, currentIndex)
        end
    end

    return tokenCount, tokenTypes, tokenStartIndices, tokenEndIndices
end

------------------------------------------------------------------------------------------------------------
-- Widget Internals
------------------------------------------------------------------------------------------------------------

local fileName
local filePath
local showFullFilePath

local tabBar
local searchEntry

local textEntry
local codeScrollContainer
local fileBrowserStackContents

local editedFileColor
local savedFileColor

local errorHighlightColor
local searchHighlightColor
local selectedSearchHighlightColor

local fileNameText
local saveButton
local revertButton

local lastSelectedSearchResult
local searchResults = {}

local editedFiles = {}

local folderMenus = {}
local fileButtons = {}

local errors = {}
local errorDisplays = {}
local errorHighlightID

local fileNamePattern = "([%w%s%._&-]+)/?$"

local verticalSplitDividerXCache = {}

local function ConfigureErrorHighlight()
    if errors[filePath] then
        local lineStarts, lineEnds = textEntry.text:GetRawString():lines_MasterFramework()
        local line = errors[filePath].line

        if errorHighlightID then
            textEntry.text:UpdateHighlight(errorHighlightID, errorHighlightColor, lineStarts[line], lineEnds[line] + 1)
        else
            errorHighlightID = textEntry.text:HighlightRange(errorHighlightColor, lineStarts[line], lineEnds[line] + 1)
        end
    elseif errorHighlightID then
        textEntry.text:RemoveHighlight(errorHighlightID)
    end
end

local function SelectFile(path, _fileName, targetCharacterIndex)
    textEntry.placeholder:SetString("")
    if VFS.FileExists(path, VFS.RAW) then
        fileName = _fileName or path:match(fileNamePattern)
        filePath = path
        textEntry.text:SetString(editedFiles[path] or VFS.LoadFile(path))
        if textEntry.text.availableWidth and textEntry.text.availableHeight then
            textEntry.text:Layout(textEntry.text.availableWidth, textEntry.text.availableHeight)
            if targetCharacterIndex then
                local lineCount = #textEntry.text:GetDisplayString():sub(1, textEntry.text:RawIndexToDisplayIndex(targetCharacterIndex)):lines_MasterFramework()
                local offset = (lineCount - 10) * textEntry.text._readOnly_font:ScaledSize()
                codeScrollContainer.viewport:SetYOffset(math.max(0, offset))
            end
            fileNameDisplay.visual:SetString(showFullFilePath and path or fileName)
            ConfigureErrorHighlight()
        end
    end
end


local function RevealPath(path)
    if path == nil or path == "" then return true end
    if not RevealPath(path:match("(.+/)[%w%s%._&-]+/?$")) then
        return false
    end
    if fileButtons[path] then
        SelectFile(path)
        return true
    elseif folderMenus[path] then
        folderMenus[path]:ShowChildren()
        return true
    else
        return false
    end
end

local function MarkFileEdited(path, isEdited)
    if not path or (editedFiles[path] and isEdited) or ((not editedFiles[path]) and (not isEdited)) then
        return
    end
    local pattern = "(.+/)[%w%s%._&-]+/?$"
    
    fileButtons[path].visual:SetBaseColor(isEdited and editedFileColor or savedFileColor)

    local change = isEdited and 1 or -1

    local trimmedPath = path:match(pattern)
    while trimmedPath and trimmedPath ~= "" do
        local menu = folderMenus[trimmedPath]
        menu.editedSubfileCount = menu.editedSubfileCount + change
        if isEdited then 
            menu.title:SetBaseColor(editedFileColor)
        elseif menu.editedSubfileCount == 0 then
            menu.title:SetBaseColor(savedFileColor)
        end 
        trimmedPath = trimmedPath:match(pattern)
    end
end

local function Save()
    if not filePath then return end
    local fh = io.open(filePath, "w")
    fh:write(textEntry.text:GetRawString())
    fh:close()
    
    MarkFileEdited(filePath, false)
    editedFiles[filePath] = nil
end

function widget:GetConfigData()
    return {
        editedFiles = editedFiles,
        filePath = filePath,
        verticalSplitDividerXCache = verticalSplitDividerXCache
    }
end
function widget:SetConfigData(data)
    editedFiles = data.editedFiles
    filePath = data.filePath
    verticalSplitDividerXCache = data.verticalSplitDividerXCache or {}
    for path, _ in pairs(editedFiles) do
        MarkFileEdited(path, true)
    end
end

local tokenTypeColors = {
    [TOKEN_TYPE_STRING_LITERAL] = "\255\001\170\085",
    [TOKEN_TYPE_MULTILINE_STRING_LITERAL] = "\255\001\170\085",
    [TOKEN_TYPE_COMMENT] = "\255\085\085\085",
    [TOKEN_TYPE_MULTILINE_COMMENT] = "\255\085\085\085",
    [TOKEN_TYPE_NUMBER_LITERAL] = "\255\001\085\170",
    [TOKEN_TYPE_KEYWORD] = "\255\170\001\085",
    [TOKEN_TYPE_ATTRIBUTE] = "\255\255\170\085",
}

local function UIFileButton(path)
    local _fileName = path:match(fileNamePattern)
    local button = MasterFramework:Button(MasterFramework:Text(_fileName, editedFiles[path] and editedFileColor or savedFileColor), function()
        SelectFile(path, _fileName)
    end)

    fileButtons[path] = button

    function button:Deregister()
        fileButtons[path] = nil
    end

    return button
end
local function UIFolderMenu(path)
    local folderMenu
    local contentsVisible = false
    local spacing = MasterFramework:AutoScalingDimension(2)

    local checkBox = MasterFramework:CheckBox(12, function(_, checked)
        if checked then
            folderMenu:ShowChildren()
        else
            folderMenu:HideChildren()
        end
    end)
    local title = MasterFramework:Text(path:match("([%w%s%._&-]+)/?$") or "error")

    local registeredChildren

    local function deregisterChildren()
        if registeredChildren then
            for _, child in ipairs(registeredChildren) do
                child:Deregister()
            end
        end

        registeredChildren = nil
    end

    local folderRow = MasterFramework:HorizontalStack({ checkBox, title }, MasterFramework:AutoScalingDimension(8), 0.5)

    folderMenu = MasterFramework:VerticalStack({ folderRow }, spacing, 0)

    function folderMenu:Deregister()
        deregisterChildren()
        folderMenus[path] = nil
    end

    function folderMenu:ShowChildren()
        if not folderMenu:GetMembers()[2] then
            registeredChildren = table.joinArrays({ table.imap(VFS.SubDirs(path, "*", VFS.RAW), function(_, subDir) return UIFolderMenu(subDir) end), table.imap(VFS.DirList(path, "*", VFS.RAW), function(_, filePath) return UIFileButton(filePath) end) })
            folderMenu:SetMembers({ folderRow, MasterFramework:MarginAroundRect(
                MasterFramework:VerticalStack(registeredChildren, spacing, 0),
                MasterFramework:AutoScalingDimension(20),
                MasterFramework:AutoScalingDimension(0),
                MasterFramework:AutoScalingDimension(0),
                MasterFramework:AutoScalingDimension(0)
            ) })
        end
        checkBox:SetChecked(true)
    end
    function folderMenu:HideChildren()
        if self:GetMembers()[2] then
            folderMenu:SetMembers({ folderRow })
            deregisterChildren()
        end
        checkBox:SetChecked(false)
    end

    folderMenu.editedSubfileCount = 0

    local escapedPath = path:gsub("([%-%.])", "%%%1")

    for editedFilePath, _ in pairs(editedFiles) do
        if editedFilePath:find("^" .. path) then
            folderMenu.editedSubfileCount = folderMenu.editedSubfileCount + 1
        end
    end

    if folderMenu.editedSubfileCount == 0 then
        title:SetBaseColor(savedFileColor)
    else
        title:SetBaseColor(editedFileColor)
    end

    folderMenu.title = title

    folderMenus[path] = folderMenu

    return folderMenu
end

local function VerticalSplit(left, right, yAnchor, key)
    local split = MasterFramework:Component(true, false)
    local isDragging

    local minWidth = MasterFramework:AutoScalingDimension(40)

    local dividerWidth = MasterFramework:AutoScalingDimension(2)
    local width, height
    local dividerRect = MasterFramework:Background(MasterFramework:Rect(dividerWidth, function() return height end), { MasterFramework.color.hoverColor }, nil)

    local previousScale = MasterFramework.combinedScaleFactor

    local dragStartX
    local dividerStartX
    local dividerX = (verticalSplitDividerXCache[key] or 100) * previousScale

    local hoverColor = MasterFramework.color.hoverColor

    local divider = MasterFramework:MouseOverChangeResponder(
        MasterFramework:MousePressResponder(
            dividerRect,
            function(_, x)
                dividerRect:SetDecorations({ MasterFramework.color.pressColor })
                isDragging = true
                dragStartX = x
                dividerStartX = dividerX
                return true
            end,
            function(_, x)
                local dx = x - dragStartX
                dividerX = dividerStartX + dx
                -- dividerX = math_max(math.min((minWidth() - dividerWidth()) / 2, dragStartX + dx), width - math.min((minWidth() - dividerWidth()) / 2))
                verticalSplitDividerXCache[key] = dividerX / previousScale
                split:NeedsLayout()
            end,
            function()
                dividerRect:SetDecorations({ hoverColor })
                isDragging = false
            end
        ),
        function(isOver)
            hoverColor = isOver and MasterFramework.color.selectedColor or MasterFramework.color.hoverColor
            if not isDragging then
                dividerRect:SetDecorations({ hoverColor })
            end
        end
    )

    function split:Layout(availableWidth, availableHeight)
        self:RegisterDrawingGroup()
        if previousScale ~= MasterFramework.combinedScaleFactor then
            dividerX = dividerX / previousScale * MasterFramework.combinedScaleFactor
            previousScale = MasterFramework.combinedScaleFactor
        end

        dividerX = math.min(math_max((minWidth() - dividerWidth()) / 2, dividerX), availableWidth - (minWidth() - dividerWidth()) / 2)

        if availableWidth < minWidth() then
            availableWidth = minWidth()
            dividerX = math.floor((availableWidth - dividerWidth()) / 2)
        end

        local leftWidth, leftHeight = left:Layout(dividerX, availableHeight)
        local rightWidth, rightHeight = right:Layout(availableWidth - (leftWidth + dividerWidth()), availableHeight)

        
        left._split_cachedHeight = leftHeight
        
        right._split_xOffset = leftWidth + dividerWidth()
        right._split_cachedHeight = rightHeight
        
        width = leftWidth + dividerWidth() + rightWidth
        height = math_max(leftHeight, rightHeight)
        
        divider:Layout(dividerWidth(), height)

        return width, height
    end
    function split:Position(x, y)
        left:Position(x, y + (height - left._split_cachedHeight) * yAnchor)
        right:Position(x + right._split_xOffset, y + (height - right._split_cachedHeight) * yAnchor)
        divider:Position(x + dividerX, y)
    end

    return split
end

local function TabBar(options)
    local box = MasterFramework:Box(MasterFramework:Rect(MasterFramework:AutoScalingDimension(0), MasterFramework:AutoScalingDimension(0)))
    local body = MasterFramework:MarginAroundRect(
        box,
        MasterFramework:AutoScalingDimension(0),
        MasterFramework:AutoScalingDimension(20),
        MasterFramework:AutoScalingDimension(0),
        MasterFramework:AutoScalingDimension(20)
    )

    local buttons = table.imap(options, function(index, tab)
        local titleText = MasterFramework:Text(tab.title)
        local button = MasterFramework:Button(
            titleText,
            function()
                tabBar:Select(index)
            end
        )

        button.titleText = titleText
        return button
    end)

    local tabBar
    tabBar = MasterFramework:VerticalHungryStack(
        MasterFramework:HorizontalStack(buttons, MasterFramework:AutoScalingDimension(8), 1),
        TakeAvailableWidth(body),
        MasterFramework:Rect(MasterFramework:AutoScalingDimension(0), MasterFramework:AutoScalingDimension(0)),
        0.5
    )

    local lastSelectedButton
    function tabBar:Select(index)
        if not buttons[index] then return end
        if lastSelectedButton then
            lastSelectedButton.titleText:SetBaseColor(MasterFramework:Color(1, 1, 1, 1))
        end
        lastSelectedButton = buttons[index]
        buttons[index].titleText:SetBaseColor(MasterFramework:Color(0.3, 0.6, 1, 1))
        box:SetChild(options[index].display)
    end

    tabBar:Select(1)

    return tabBar
end

local widgetPathToWidgetName = {}
local widgetNameToFileName = {}
local fileNameToWidgetName = {}
local runningWidgets = {}
local messages = {}

function ErrorDisplay()
    local text = MasterFramework:WrappingText("", MasterFramework.color.red)
    local errorDisplay
    errorDisplay = MasterFramework:Button(text, function()
        if errorDisplay.path then
            shownError = false
            local lineStarts, lineEnds = textEntry.text:GetDisplayString():lines_MasterFramework()
            SelectFile(errorDisplay.path, nil, lineStarts[errors[errorDisplay.path].line])
            RevealPath(errorDisplay.path)
        end
    end)
    errorDisplay.descriptionText = text

    return errorDisplay
end

local failedToLoad = {}

local consoleStrings = {
    ["^Loading:  (.*)"] = function(fullMessage, widgetPath)
        runningWidgets[widgetPath] = { enabled = true }
        errorDisplays[widgetPath] = nil
        errors[widgetPath] = nil
        if widgetPath == filePath then
            ConfigureErrorHighlight()
        end
    end,
    ["^Loading widget from user:  (.+[^%s])%s+<([^%s]+)> ...$"] = function(fullMessage, widgetName, fileName)
        -- If we get this, we dont get an "Added" message when the widget is successfully loaded
        failedToLoad["LuaUI/Widgets/" .. fileName] = nil
        
        widgetNameToFileName[widgetName] = fileName
        fileNameToWidgetName[fileName] = widgetName
        widgetPathToWidgetName["LuaUI/Widgets/" .. fileName] = widgetName
        runningWidgets["LuaUI/Widgets/" .. fileName] = { enabled = true }
        errorDisplays["LuaUI/Widgets/" .. fileName] = nil
        errors["LuaUI/Widgets/" .. fileName] = nil

        if path == filePath then
            ConfigureErrorHighlight()
        end
    end,
    ["^Added:  (.*)"] = function(fullMessage, widgetPath) 
        -- We only get this if the widget was manually enabled by the user, not when the widget is loaded by the game. 
        runningWidgets[widgetPath] = { enabled = true }
        errorDisplays[widgetPath] = nil
        errors[widgetPath] = nil
        if widgetPath == filePath then
            ConfigureErrorHighlight()
        end
    end,
    ["^Removed:  (.*)"] = function(fullMessage, widgetPath) -- disabled by user
        runningWidgets[widgetPath] = nil

        if widgetPath == filePath then
            ConfigureErrorHighlight()
        end
    end,
    ["^Failed to load: (.+[^%s])  %((.*)%)"] = function(fullMessage, fileName, description) -- widget crash
        -- failedToLoad[fileName] = 
        failedToLoad[fileName] = description
        local path, line, errorMessage = description:match("%[string \"([^\"]+)\"%]:(%d+): (.*)")
        -- local path = "LuaUI/Widgets/" .. fileName
        if path then
            errors[path] = { message = errorMessage, line = tonumber(line) }
            errorDisplays[path] = errorDisplays[path] or ErrorDisplay()
            errorDisplays[path].descriptionText:SetString(widgetPathToWidgetName[path] or path .. ":" .. errorMessage)
            errorDisplays[path].path = path
        end
    end,
    ["^Error in ([^%s\n]+)%(%): %[string \"([^\"]+)\"%]:(%d+): (.*)"] = function(fullMessage, func, path, line, errorMessage)
        errors[path] = { message = errorMessage, line = tonumber(line), func = func }
        errorDisplays[path] = errorDisplays[path] or ErrorDisplay()
        errorDisplays[path].descriptionText:SetString(widgetPathToWidgetName[path] or path .. ":" .. errorMessage)
        errorDisplays[path].path = path

        if path == filePath then
            ConfigureErrorHighlight()
        end
    end,
    ["^Removed widget: (.*)"] = function(fullMessage, widgetName) -- widget crash
        -- runningWidgets["LuaUI/Widgets/" .. widgetNameToFileName[widgetName]].enabled = false
    end
}

function widget:AddConsoleLine(msg)
    for pattern, func in pairs(consoleStrings) do
        local returnValues = { msg:match(pattern) }
        if #returnValues > 0 then
            -- if pattern == "Error in ([^%s\n]+)%(%): %[string \"([^\"]+)\"%]:(%d+): (.*)" then
            --     returnValues.msg = msg
            --     table.insert(messages, returnValues)
            -- end
            func(msg, unpack(returnValues))
        end
    end
    return true
end

------------------------------------------------------------------------------------------------------------
-- Code Editor Text Entry
------------------------------------------------------------------------------------------------------------

function WG.LuaTextEntry(framework, content, placeholderText, saveFunc)
    local monospaceFont = framework:Font("fonts/monospaced/SourceCodePro-Medium.otf", 12)
    local textEntry = framework:TextEntry(content, placeholderText, nil, monospaceFont)
    textEntry.saveFunc = saveFunc

    function textEntry:SetPostEditEffect(postEditEffect)
        local function ReplaceEditFunction(name)
            local cachedFunction = textEntry[name]
            textEntry[name] = function(...)
                cachedFunction(...)
                postEditEffect()
            end
        end
        ReplaceEditFunction("InsertText")
        ReplaceEditFunction("editUndo")
        ReplaceEditFunction("editRedo")
        ReplaceEditFunction("editBackspace")
        ReplaceEditFunction("editDelete")
    end

    local textEntry_KeyPress = textEntry.KeyPress
    function textEntry:KeyPress(key, mods, isRepeat)
        if key == 0x73 and mods.ctrl then 
            saveFunc()
        elseif key == 0x09 then
            self:editTab()
        end

        return textEntry_KeyPress(self, key, mods, isRepeat)
    end

    function textEntry:editTab()
        local rawString = textEntry.text:GetRawString()
        local _, _, spaces = rawString:find("\n([ \t]+)[^\n^ ^\t]")
        self:InsertText(spaces or "    ")
    end

    function textEntry:editReturn(isCtrl)
        if isCtrl then
            self:InsertText("\n")
            return
        end

        local rawString = textEntry.text:GetRawString()
        local clipped = rawString:sub(1, self.selectionBegin)
        while true do
            local lineStart, _, spaces, text = clipped:find("\n(%s*)([^\n]*)$")
            
            if not lineStart then
                local spaces, text = clipped:match("^(%s*)([^\n]*)$")
                self:InsertText("\n" .. spaces)
                return
            end

            if text:len() > 0 then
                self:InsertText("\n" .. spaces)
                return
            else
                clipped = rawString:sub(1, lineStart - 1)
            end
        end 
    end

    local text_Layout = textEntry.text.Layout
    local text_Position = textEntry.text.Position

    local textHeight
    local codeNumbersWidth
    local spacing = framework:AutoScalingDimension(2)
    local codeNumbersColor = framework:Color(0.2, 0.2, 0.2, 1)

    local textEntryWidth = 0
    
    local displayString

    local lineTitles = {}
    local lineOffsets = {}
    textEntry.lineOffsets = lineOffsets
    local lineStarts, lineEnds
    local lineCount

    local lineHeight
    local oldLineHeight

    function textEntry.text:Layout(availableWidth, availableHeight)
        -- framework.startProfile("wrappingText:Layout() - custom layout: update line title widths")
        lineStarts, lineEnds = self:GetRawString():lines_MasterFramework()
        lineHeight = monospaceFont:ScaledSize()

        self.availableWidth = availableWidth
        self.availableHeight = availableHeight

        local oldLineCount
        lineCount = #lineStarts
        
        codeNumbersWidth = 0

        -- if lineCount ~= oldLineCount or oldLineHeight ~= lineHeight then
        --     oldLineHeight = lineHeight
        --     for i = 1, lineCount do
        --         local lineTitleWidth
        --         local lineTitle = lineTitles[i]
        --         if not lineTitles[i] then
        --             lineTitle = framework:Text(tostring(i), codeNumbersColor, monospaceFont)
        --             lineTitles[i] = lineTitle
        --         end
        --         lineTitleWidth, _ = lineTitle:Layout(math.huge, math.huge)

        --         codeNumbersWidth = math_max(lineTitleWidth, codeNumbersWidth)
        --     end

        --     for i = lineCount + 1, #lineTitles do
        --         lineTitles[i] = nil
        --     end
        -- else
        --     for i = 1, #lineTitles do
        --         lineTitle:Layout(math.huge, math.huge)
        --     end
        -- end


        -- framework.endProfile("wrappingText:Layout() - custom layout: update line title widths") -- negligible apart from first run

        local width, height = text_Layout(self, availableWidth - codeNumbersWidth - spacing(), availableHeight)

        -- framework.startProfile("wrappingText:Layout() - custom layout: record added newlines")

        textHeight = height
        textEntryWidth = width + codeNumbersWidth

        displayString = self:GetDisplayString()

        local insertedNewlineCount = 0
        local addedCharactersIndex = 1
        local removedSpacesIndex = 1
        local computedOffset = 0

        local addedCharacters = self.addedCharacters
        local string_sub = displayString.sub
        for i = 1, lineCount do
            local lineStartDisplayIndex, _addedCharactersIndex, _removedSpacesIndex, _computedOffset = self:RawIndexToDisplayIndex(lineStarts[i], addedCharactersIndex, removedSpacesIndex, computedOffset)
            for i = addedCharactersIndex, _addedCharactersIndex do
                local index = addedCharacters[i]
                if string_sub(displayString, index, index) == "\n" then
                    insertedNewlineCount = insertedNewlineCount + 1
                end
            end
            addedCharactersIndex = _addedCharactersIndex
            removedSpacesIndex = _removedSpacesIndex
            computedOffset = _computedOffset

            lineOffsets[i] = i + insertedNewlineCount
            -- lineTitles[i]._insertedNewlineCount = insertedNewlineCount
        end

        -- framework.endProfile("wrappingText:Layout() - custom layout: record added newlines")

        return textEntryWidth, height
    end
    local placeholder_Layout = textEntry.placeholder.Layout
    function textEntry.placeholder:Layout(availableWidth, availableHeight)
        local width, height = placeholder_Layout(self, availableWidth - codeNumbersWidth - spacing(), availableHeight)
        return width + codeNumbersWidth + spacing(), height
    end
    local placeholder_Position = textEntry.placeholder.Position
    function textEntry.placeholder:Position(x, y)
        placeholder_Position(self, x + codeNumbersWidth + spacing(), y)
    end
    function textEntry.text:Position(x, y)
        -- framework.startProfile("wrappingText:Position() - line numbers")
        local rightX = x + codeNumbersWidth
        local topY = y + textHeight
        -- for i = 1, lineCount do
        --     local lineTitle = lineTitles[i]
        --     local width, _ = lineTitle:Size()
        --     lineTitle:Position(rightX - width, topY - lineOffsets[i] * lineHeight)
        -- end
        -- framework.endProfile("wrappingText:Position() - line numbers")
        -- framework.startProfile("wrappingText:Position()")
        text_Position(self, rightX + spacing(), y)
        -- framework.endProfile("wrappingText:Position()")
    end
    
    function textEntry.text:ColoredString(string)

        local tokenCount, tokenTypes, tokenStartIndices, tokenEndIndices = lex(string)

        local stringComponents = {}
        local componentIndex = 1
        local characterIndex = 1
        local lastWasColored = false
        for tokenIndex = 1, tokenCount do
            -- local tokenIndex = tokenCount - (i - 1)
            local tokenType = tokenTypes[tokenIndex]
            local color = tokenTypeColors[tokenType]
            if color then
                lastWasColored = true
                stringComponents[componentIndex] = color
                componentIndex = componentIndex + 1
                stringComponents[componentIndex] = string:sub(characterIndex, tokenEndIndices[tokenIndex])
                componentIndex = componentIndex + 1
            else
                if lastWasColored and (not (tokenType == TOKEN_TYPE_WHITESPACE)) then
                    stringComponents[componentIndex] = "\b"
                    componentIndex = componentIndex + 1
                    lastWasColored = false
                end
                stringComponents[componentIndex] = string:sub(characterIndex, tokenEndIndices[tokenIndex])
                componentIndex = componentIndex + 1
            end

            characterIndex = tokenEndIndices[tokenIndex] + 1
        end

        Spring.CreateDir("LuaUI/MasterFramework Dev/Tests/TestResources/")
        local file = io.open("LuaUI/MasterFramework Dev/Tests/TestResources/code_example.lua", "w")
        file:write(string)
        file:close()

        local coloredString = table.concat(stringComponents)

        file = io.open("LuaUI/MasterFramework Dev/Tests/TestResources/code_example_colored.lua", "w")
        file:write(coloredString)
        file:close()


        return coloredString
    end

    return textEntry
end

------------------------------------------------------------------------------------------------------------
-- Setup/Update/Teardown
------------------------------------------------------------------------------------------------------------

function widget:Update()
    local errors = table.mapToArray(errorDisplays, function(name, display) return { name = name, display = display } end)
    table.sort(errors, function(a, b)
        return a.name > b.name
    end)
    errorStack:SetMembers(table.imap(errors, function(_, x) return x.display end))
end

function widget:Initialize()
    MasterFramework = WG["MasterFramework " .. requiredFrameworkVersion]
    if not MasterFramework then
        error("[Lua File Editor] MasterFramework " .. requiredFrameworkVersion .. " not found!")
    end

    errorHighlightColor = MasterFramework:Color(1, 0.2, 0.1, 0.5)
    searchHighlightColor = MasterFramework:Color(0.3, 0.6, 1, 0.3)
    selectedSearchHighlightColor = MasterFramework:Color(1, 1, 0.0, 0.3)

    table = MasterFramework.table

    textEntry = WG.LuaTextEntry(MasterFramework, "", "Select File To Edit", Save)
    local textEntry_KeyPress = textEntry.KeyPress
    function textEntry:KeyPress(key, mods, isRepeat)
        if key == 0x66 and mods.ctrl then
            tabBar:Select(2)
            searchEntry:TakeFocus()
        elseif key == 0x72 and mods.ctrl then -- Ctrl+R
            self.saveFunc()
            local widgetName = widgetPathToWidgetName[filePath]
            if mods.shift then
                Spring.SendCommands("luaui reload")
            elseif widgetName then
                widgetHandler:DisableWidget(widgetName)
                widgetHandler:EnableWidget(widgetName)
            end
        else
            textEntry_KeyPress(self, key, mods, isRepeat)
        end
    end
    

    local monospaceFont = MasterFramework:Font("fonts/monospaced/SourceCodePro-Medium.otf", 12)
    searchEntry = MasterFramework:TextEntry("", "Search", nil, monospaceFont)
    local searchStack = MasterFramework:VerticalStack({}, MasterFramework:AutoScalingDimension(2), 0)

    function searchEntry:SetPostEditEffect(postEditEffect)
        local function ReplaceEditFunction(name)
            local cachedFunction = searchEntry[name]
            searchEntry[name] = function(...)
                cachedFunction(...)
                postEditEffect()
            end
        end
        ReplaceEditFunction("InsertText")
        ReplaceEditFunction("editUndo")
        ReplaceEditFunction("editRedo")
        ReplaceEditFunction("editBackspace")
        ReplaceEditFunction("editDelete")
    end

    local function Search()
        local searchTerm = searchEntry.text:GetRawString()

        for _, result in ipairs(searchResults) do
            _ = result.highlightID and textEntry.text:RemoveHighlight(result.highlightID)
        end

        if searchTerm:len() < 3 then
            searchStack:SetMembers({})
            return
        end

        local searchBegin = 1
        searchResults = {}
        lastSelectedSearchResult = nil
        local searchee = textEntry.text:GetRawString()
        while searchBegin < searchee:len() do
            local start, _end = searchee:find(searchTerm, searchBegin)
            if start and _end then
                table.insert(searchResults, { 
                    filePath = filePath, 
                    start = start, 
                    _end = _end, 
                    highlightID = textEntry.text:HighlightRange(searchHighlightColor, start, _end + 1)
                })
                searchBegin = _end + 1
            else
                break
            end
        end

        searchStack:SetMembers(table.imap(searchResults, function(_, result)
            return MasterFramework:Button(
                MasterFramework:WrappingText(
                    "\255\122\122\122" .. (searchee:sub(1, result.start - 1):match("[^\n]*[\n][^\n]*$") or "") .. 
                    "\255\255\255\255" .. searchee:sub(result.start, result._end) ..
                    "\255\122\122\122" .. (searchee:match("([^\n]*[\n][^\n]*)", result._end + 1) or "")
                ),
                function()
                    _ = lastSelectedSearchResult and textEntry.text:UpdateHighlight(lastSelectedSearchResult.highlightID, searchHighlightColor, lastSelectedSearchResult.start, lastSelectedSearchResult._end + 1)
                    textEntry.text:UpdateHighlight(result.highlightID, selectedSearchHighlightColor, result.start, result._end + 1)
                    lastSelectedSearchResult = result
                    SelectFile(result.filePath, nil, result.start)
                end
            )
        end))
        textEntry.text:NeedsRedraw()
    end

    textEntry:SetPostEditEffect(function()
        if filePath then 
            MarkFileEdited(filePath, true)
            editedFiles[filePath] = textEntry.text:GetRawString() -- Would be nice to cache the `no file` case also?
        end

        saveButton.visual:SetString("Save")
        revertButton.visual:SetString("Revert")

        Search()
    end)

    searchEntry:SetPostEditEffect(Search)

    editedFileColor = MasterFramework:Color(1, 0.6, 0.3, 1)
    savedFileColor = MasterFramework:Color(1, 1, 1, 1)

    fileNameDisplay = MasterFramework:Button(MasterFramework:Text("<no file>", MasterFramework:Color(0.3, 0.3, 0.3, 1)), function()
        showFullFilePath = not showFullFilePath
        fileNameDisplay.visual:SetString(showFullFilePath and filePath or fileName or "<no file>")
    end)
    saveButton = MasterFramework:Button(MasterFramework:Text("Save", MasterFramework:Color(0.3, 0.3, 0.6, 1)), function(button)
        Save()
    end)
    revertButton = MasterFramework:Button(MasterFramework:Text("Revert", MasterFramework:Color(0.6, 0.3, 0.3, 1)), function(button)
        if not filePath then return end
        textEntry.text:SetString(VFS.LoadFile(filePath))
        MarkFileEdited(filePath, false)
        editedFiles[filePath] = nil
    end)

    errorStack = MasterFramework:VerticalStack({}, MasterFramework:AutoScalingDimension(2), 0)

    tabBar = TabBar({
        { title = "Files", display = MasterFramework:VerticalScrollContainer(UIFolderMenu(LUAUI_DIRNAME)) },
        { title = "Search", display = MasterFramework:VerticalHungryStack(searchEntry, MasterFramework:VerticalScrollContainer(searchStack), MasterFramework:Rect(MasterFramework:AutoScalingDimension(0), MasterFramework:AutoScalingDimension(0)), 0) },
        { title = "Errors", display = errorStack }
    })

    codeScrollContainer = MasterFramework:VerticalScrollContainer(textEntry)

    local resizableFrame = MasterFramework:ResizableMovableFrame(
        "Lua File Editor",
        MasterFramework:PrimaryFrame(
                MasterFramework:Background(
                    MasterFramework:MarginAroundRect(
                    VerticalSplit(
                        tabBar,
                        MasterFramework:VerticalHungryStack(
                            MasterFramework:HorizontalStack({
                                    fileNameDisplay,
                                    saveButton,
                                    revertButton
                                }, 
                                MasterFramework:AutoScalingDimension(8), 0.5
                            ),
                            TakeAvailableWidth(TakeAvailableHeight(codeScrollContainer)),
                            MasterFramework:Rect(MasterFramework:AutoScalingDimension(0), MasterFramework:AutoScalingDimension(0)), 
                            0
                        ),
                        1,
                        "Lua File Editor Split: Side Bar & Editor 1"
                    ),
                    MasterFramework:AutoScalingDimension(20),
                    MasterFramework:AutoScalingDimension(20),
                    MasterFramework:AutoScalingDimension(20),
                    MasterFramework:AutoScalingDimension(20)
                ),
                { MasterFramework.FlowUIExtensions:Element() },
                MasterFramework:AutoScalingDimension(5)
            )
        ),
        MasterFramework.viewportWidth * 0.1, MasterFramework.viewportHeight * 0.1, 
        MasterFramework.viewportWidth * 0.8, MasterFramework.viewportHeight * 0.8,
        false
    )

    key = MasterFramework:InsertElement(resizableFrame, "Lua File Editor", MasterFramework.layerRequest.anywhere())

    if filePath then
        SelectFile(filePath)
        RevealPath(filePath)
    end

    local buffer = Spring.GetConsoleBuffer()
    for _, line in ipairs(buffer) do
        widget:AddConsoleLine(line.text)
    end
end

function widget:Shutdown() 
    MasterFramework:RemoveElement(key)
    WG.MasterStats = nil
end