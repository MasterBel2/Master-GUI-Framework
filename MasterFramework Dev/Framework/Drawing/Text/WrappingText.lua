local math = Include.math
local math_floor = Include.math.floor
local math_huge = Include.math.huge
local math_max = Include.math.max
local math_min = Include.math.min

local gl_Rect = Include.gl.Rect
local gl_Translate = Include.gl.Translate

local pairs = Include.pairs

local table = Include.table
local Internal = Internal

-- Automatically wrapping text. 
-- Set `maxLines = 1` to disable wrapping. (`framework:Text()` is an alias for `framework:WrappingText` that sets `maxLines = 1`.)
--
-- Note that raw/display index conversion updates only on layout, so between when the raw string is updated and layout occurs, index conversion to or from the display string will be invalid.
function framework:WrappingText(string, baseColor, font, maxLines)
	maxLines = maxLines or math_huge
	font = font or framework.defaultFont
	baseColor = baseColor or framework.color.white
	local textChunks = {}
	local wrappingText = table.mergeInPlace(Component(true, true), framework:GeometryTarget({ Layout = function(_, ...) return ... end, Position = function() end }))

	wrappingText._readOnly_font = font
	wrappingText.type = "Wrapping Text"

	wrappingText.addedCharacters = {}
	wrappingText.removedSpaces = {}

	local coloredString
	local wrappedText, lineCount
	local cachedAvailableWidth, cachedAvailableHeight, cachedFontKey, cachedFontScaledSize, cachedFontScaledSize
	local addedCharacters = wrappingText.addedCharacters
	local removedSpaces = wrappingText.removedSpaces

	local stringChanged = true

	local nextHighlightID = 0
    local highlights = {}
	local cachedAddedCharactersIndex, cachedRemovedSpacesIndex, cachedComputedOffset

	function wrappingText:SetBaseColor(newBaseColor)
		if baseColor ~= newBaseColor then
			baseColor = newBaseColor
			for i = 1, #textChunks do
				textChunks[i]:Update(nil, nil, nil, nil, newBaseColor)
			end
			self:NeedsRedraw()
		end
	end
	function wrappingText:GetBaseColor()
		return baseColor
	end

	-- Sets the raw string.
	-- 
	-- If a nil value is provided, an empty string will be set.
	function wrappingText:SetString(newString)
		if newString ~= string then
			string = newString or ""
			stringChanged = true
			self:NeedsLayout()
		end
	end
	-- Returns the string that was provided to `WrappingText`, unmodified. 
	-- 
	-- Use`wrappingText:RawIndexToDisplayIndex` and to find the equivalent location of a character in the display string.
	function wrappingText:GetRawString()
		return string
	end

	-- Returns the string that will be drawn on-screen. This may have newlines and color codes inserted.
	-- Use `wrappingText:DisplayIndexToRawIndex` to find the equivalent location of a character in the raw string.
	function wrappingText:GetDisplayString()
		return wrappedText
	end

	-- Returns the index of the matching character in the display string.
	-- If we were provided the index of a removed space, we'll return a second result - `true` - to indicate as such.
	-- Reminder, some characters might be changed (e.g. " " to "\n") and they won't be flagged.
	function wrappingText:RawIndexToDisplayIndex(rawIndex, addedCharactersIndex, removedSpacesIndex, computedOffset)
		local addedCharactersIndex = addedCharactersIndex or 1
		local removedSpacesIndex = removedSpacesIndex or 1

		local computedOffset = computedOffset or 0

		while (addedCharacters[addedCharactersIndex] <= rawIndex + computedOffset) or (removedSpaces[removedSpacesIndex] <= rawIndex) do
			if addedCharacters[addedCharactersIndex] - computedOffset < removedSpaces[removedSpacesIndex] then
				computedOffset = computedOffset + 1
				addedCharactersIndex = addedCharactersIndex + 1
			elseif addedCharacters[addedCharactersIndex] - computedOffset == removedSpaces[removedSpacesIndex] then
				-- count them as swapped, no change to offset
				addedCharactersIndex = addedCharactersIndex + 1
				removedSpacesIndex = removedSpacesIndex + 1
			elseif addedCharacters[addedCharactersIndex] - computedOffset > removedSpaces[removedSpacesIndex] then
				computedOffset = computedOffset - 1
				removedSpacesIndex = removedSpacesIndex + 1
			end
		end

		return rawIndex + computedOffset, addedCharactersIndex, removedSpacesIndex, computedOffset, rawIndex == removedSpaces[removedSpacesIndex - 1]
	end

	-- Returns the index of the matching character in the raw string. 
	-- 
	-- If the detected character was added, we'll just return the next character that wasn't added.
	-- If we were provided provide the index of an added character, we'll return a second result - `true` - to indicate as such.
	-- Reminder, some characters might be changed (e.g. " " to "\n") and they won't be flagged.
	function wrappingText:DisplayIndexToRawIndex(displayIndex)
		local addedCharactersIndex = 1
		local removedSpacesIndex = 1

		local computedOffset = 0

		while math_min(addedCharacters[addedCharactersIndex], removedSpaces[removedSpacesIndex] - computedOffset) <= displayIndex do
			if addedCharacters[addedCharactersIndex] < removedSpaces[removedSpacesIndex] - computedOffset then
				computedOffset = computedOffset - 1
				addedCharactersIndex = addedCharactersIndex + 1
			elseif addedCharacters[addedCharactersIndex] == removedSpaces[removedSpacesIndex] - computedOffset then
				-- count them as swapped, no change to offset
				addedCharactersIndex = addedCharactersIndex + 1
				removedSpacesIndex = removedSpacesIndex + 1
			elseif addedCharacters[addedCharactersIndex] > removedSpaces[removedSpacesIndex] - computedOffset then
				computedOffset = computedOffset + 1
				removedSpacesIndex = removedSpacesIndex + 1
			end
		end

		return displayIndex + computedOffset, addedCharacters[addedCharactersIndex - 1] == displayIndex
	end

	-- Converts a screen coordinate to an index in the display string. 
	function wrappingText:CoordinateToCharacterDisplayIndex(x, y)
		local absoluteX, absoluteY = self:CachedPositionTranslatedToGlobalContext()
		local xOffset = x - absoluteX
		local yOffset = y - absoluteY

		local glFont = font.glFont
		local scaledFontSize = font:ScaledSize()

		local lineStarts, lineEnds = wrappedText:lines_MasterFramework()

		local lineIndex = math_min(#lineStarts, math_max(1, #lineStarts - math_floor(yOffset / (glFont.lineheight * scaledFontSize))))
		
		if lineIndex == 0 then return 1 end

		local lineStart = lineStarts[lineIndex]
		local lineEnd = lineEnds[lineIndex]

		local elapsedWidth = 0

		local i = 0
		while i <= (lineEnd - lineStart) do
			local character = wrappedText:sub(lineStart + i, lineStart + i)
			if character == "\255" then
				i = i + 4
			else
				local characterWidth = glFont:GetTextWidth(character) * scaledFontSize
				if (characterWidth > 0) and (elapsedWidth + characterWidth / 2 > xOffset) then
					return lineStart + i
				end

				elapsedWidth = elapsedWidth + characterWidth
				i = i + 1
			end
		end

		return lineEnd + 1 -- index before line break; see string:lines_MasterFramework for more details on how the indices are generated
	end

	-- Converts a screen coordinate to an index in the raw string.
	function wrappingText:CoordinateToCharacterRawIndex(x, y)
		return self:DisplayIndexToRawIndex(self:CoordinateToCharacterDisplayIndex(x, y))
	end

	-- An overridable function that may provide various annotations (color, or more) to the raw string, before wrapping occurs.
	--
	-- The result of `wrappingText:ColoredString` is used to generate an intermediate value between the raw string and the display string. No index conversion is provided.
	function wrappingText:ColoredString(rawString)
		return rawString
	end

	local _Layout = wrappingText.Layout
	function wrappingText:Layout(availableWidth, availableHeight, profile)
		self:RegisterDrawingGroup()
		availableWidth = math_min(availableWidth, 2147483647) -- if we allow math.huge, `glFont:WrapText()` will fail. 
		availableHeight = math_min(availableHeight, 2147483647)
		local fontScaledSize = font:ScaledSize()
		local glFont = font.glFont
		if availableWidth == cachedAvailableWidth and availableHeight == cachedAvailableHeight and not stringChanged and fontScaledSize == cachedFontScaledSize and font.key == cachedFontKey then
			for i = 1, #textChunks do
				textChunks[i]:Layout(textChunks[i]:CachedSize())
			end
			
			return _Layout(self, self:Size())
		end

		if stringChanged then
			coloredString = self:ColoredString(string)
		end

		cachedFontScaledSize = fontScaledSize
		cachedFontKey = font.key
		stringChanged = false

		cachedAvailableWidth, cachedAvailableHeight = availableWidth, availableHeight

		local trueLineHeight = cachedFontScaledSize * glFont.lineheight
		local maxHeight = math_min(availableHeight, maxLines * trueLineHeight)

		wrappedText, lineCount = glFont:WrapText(coloredString, availableWidth + 0.1, maxHeight, cachedFontScaledSize) -- Apparently this adds an extra character ("\r") even when line breaks already
		local width = math_min(glFont:GetTextWidth(wrappedText) * cachedFontScaledSize, availableWidth)
		local height = math_min(maxHeight, lineCount * trueLineHeight)

		local addedCharacterCount = 0
		local removedSpacesCount = 0

		local i = 1
		local j = 1
		local string_sub = string.sub
		local rawCharacter = string_sub(string, i, i)
		local displayCharacter = string_sub(wrappedText, j, j)
		local rawLength = string:len()
		local displayLength = wrappedText:len()
		while i <= rawLength and j <= displayLength do
			if rawCharacter ~= displayCharacter then
				if rawCharacter == " " then
					removedSpacesCount = removedSpacesCount + 1
					removedSpaces[removedSpacesCount] = i
					i = i + 1
					rawCharacter = string_sub(string, i, i)
				else
					addedCharacterCount = addedCharacterCount + 1
					addedCharacters[addedCharacterCount] = j
					j = j + 1
					displayCharacter = string_sub(wrappedText, j, j)
				end
			else
				i = i + 1
				rawCharacter = string_sub(string, i, i)
				j = j + 1
				displayCharacter = string_sub(wrappedText, j, j)
			end
		end

		addedCharacters[addedCharacterCount + 1] = math_huge -- for iteration purposes
		removedSpaces[removedSpacesCount + 1] = math_huge -- for iteration purposes

		for i = addedCharacterCount + 2, #addedCharacters do
			addedCharacters[i] = nil
		end
		for i = removedSpacesCount + 2, #removedSpaces do
			removedSpaces[i] = nil
		end


		local lineStarts, lineEnds = string:lines_MasterFramework()
		-- Seems to be the sweet spot through experimental testing
		-- I imagine this could change depending on the nature of the text
		local linesPerChunk = 10
		local desiredChunkCount = math.ceil(#lineStarts / linesPerChunk)
		do
			local addedCharactersIndex, removedSpacesIndex, computedOffset
			for i = #textChunks + 1, desiredChunkCount do
				local displayStartIndex, displayEndIndex
				displayStartIndex, addedCharactersIndex, removedSpacesIndex, computedOffset = self:RawIndexToDisplayIndex(lineStarts[(i - 1) * linesPerChunk + 1] - 1, addedCharactersIndex, removedSpacesIndex, computedOffset)
				displayEndIndex, addedCharactersIndex, removedSpacesIndex, computedOffset = self:RawIndexToDisplayIndex(lineEnds[i * linesPerChunk] and (lineEnds[i * linesPerChunk] + 1) or string:len(), addedCharactersIndex, removedSpacesIndex, computedOffset)
				
				local displayString = wrappedText:sub(displayStartIndex + 1, displayEndIndex - 1)

				-- Current implementation assumes that any coloredString will work regardless where a split occurs.
				-- This is not the case!
				-- The following code also doesn't work but could serve as a starting point.

				-- if textChunks[i - 1] then
				-- 	local previousDisplayString = wrappedText:sub(1, displayStartIndex - 1)
				-- 	local colorCodeIndex, _, colorCode = previousDisplayString:find("(\255...).-$")
				-- 	local colorCancelIndex = previousDisplayString:find("\b")
				-- 	if colorCodeIndex then
				-- 		if colorCancelIndex then
				-- 			if colorCancelIndex < colorCodeIndex then
				-- 				displayString = colorCode .. displayString
				-- 			end
				-- 		end
				-- 		displayString = colorCode .. displayString
				-- 	end
				-- end

				textChunks[i] = Internal.TextChunk()
				textChunks[i]:Update(displayString, font, baseColor)
			end
		end
		for i = desiredChunkCount + 1, #textChunks do
			textChunks[i] = nil
		end
		local addedCharactersIndex, removedSpacesIndex, computedOffset
		for i = 1, desiredChunkCount do
			local displayStartIndex, displayEndIndex
			displayStartIndex, addedCharactersIndex, removedSpacesIndex, computedOffset = self:RawIndexToDisplayIndex(lineStarts[(i - 1) * linesPerChunk + 1] - 1, addedCharactersIndex, removedSpacesIndex, computedOffset)
			displayEndIndex, addedCharactersIndex, removedSpacesIndex, computedOffset = self:RawIndexToDisplayIndex(lineEnds[i * linesPerChunk] and (lineEnds[i * linesPerChunk] + 1) or string:len() + 1, addedCharactersIndex, removedSpacesIndex, computedOffset)
		
			local displayString = wrappedText:sub(displayStartIndex + 1, displayEndIndex - 1)

			-- Current implementation assumes that any coloredString will work regardless where a split occurs.
			-- This is not the case!
			-- The following code also doesn't work but could serve as a starting point.

			-- if textChunks[i - 1] then
			-- 	local previousDisplayString = wrappedText:sub(1, displayStartIndex - 1)
			-- 	local colorCodeIndex, _, colorCode = previousDisplayString:find("(\255...).-$")
			-- 	local colorCancelIndex = previousDisplayString:find("\b")
			-- 	if colorCodeIndex then
			-- 		if colorCancelIndex then
			-- 			if colorCancelIndex < colorCodeIndex then
			-- 				displayString = colorCode .. displayString
			-- 			end
			-- 		end
			-- 		displayString = colorCode .. displayString
			-- 	end
			-- end

			textChunks[i]:Update(displayString, font, baseColor)
		end

		-- We don't return here since we're only using this to coerce the `GeometryTarget` into caching width, height for us
		_Layout(self, width, height)

		local lastEndIndex = math_huge
		for _, highlight in pairs(highlights) do
			local displayStartIndex, displayEndIndex
			local reuseLast = highlight.startIndex > lastEndIndex
			lastEndIndex = highlight.endIndex
			displayStartIndex, cachedAddedCharactersIndex, cachedRemovedSpacesIndex, cachedComputedOffset = self:RawIndexToDisplayIndex(highlight.startIndex, reuseLast and cachedAddedCharactersIndex, reuseLast and cachedRemovedSpacesIndex, reuseLast and cachedComputedOffset)
			displayEndIndex, cachedAddedCharactersIndex, cachedRemovedSpacesIndex, cachedComputedOffset = self:RawIndexToDisplayIndex(highlight.endIndex, cachedAddedCharactersIndex, cachedRemovedSpacesIndex, cachedComputedOffset)	
			highlight.displayStartIndex = displayStartIndex
			highlight.displayEndIndex = displayEndIndex
		end
		
		return width, height
	end

	local _Position = wrappingText.Position
	function wrappingText:Position(x, y)
		_Position(self, x, y)
		local chunkYOffset = 0
		for i = 1, #textChunks do
			local _, height = self:Size()
			local _, chunkHeight = textChunks[i]:CachedSize()
			chunkYOffset = chunkYOffset + chunkHeight
			textChunks[i]:Position(x, y + height - chunkYOffset)
		end

		activeDrawingGroup.drawTargets[#activeDrawingGroup.drawTargets + 1] = self
	end

	function wrappingText:Draw()
		self:RegisterDrawingGroup()
		local glFont = self._readOnly_font.glFont
		local displayString = self:GetDisplayString()
        local lineStarts, lineEnds = displayString:lines_MasterFramework()
		local scaledSize = self._readOnly_font:ScaledSize()
        local lineHeight = scaledSize * glFont.lineheight
		local textWidth, textHeight = self:Size()

		local x, y = self:CachedPositionRemainingInLocalContext()
		gl_Translate(x, y, 0)

		for _, highlight in pairs(highlights) do
			highlight.color:Set()
			for i = 1, #lineStarts do
				local lineStart = lineStarts[i]
				local lineEnd = lineEnds[i]

				if highlight.displayStartIndex <= lineEnd + 1 and highlight.displayEndIndex >= lineStart then
					local xStart = glFont:GetTextWidth(displayString:sub(lineStart, highlight.displayStartIndex - 1)) * scaledSize
					if highlight.displayStartIndex == highlight.displayEndIndex then
						gl_Rect(
							xStart - 0.5,
							textHeight - i * lineHeight,
							xStart + 0.5,
							textHeight - (i - 1) * lineHeight
						)
					else
						local selectedText = displayString:sub(math_max(lineStart, highlight.displayStartIndex), math_min(highlight.displayEndIndex - 1, lineEnd))
						gl_Rect(
							xStart,
							textHeight - i * lineHeight,
							xStart + glFont:GetTextWidth(selectedText) * scaledSize,
							textHeight - (i - 1) * lineHeight
						)
					end
				end
			end
		end

		gl_Translate(-x, -y, 0)
	end

	------------------
	-- Highlighting --
	------------------

	--[[
		Will under-lay a rect with the specified colour over the specified range.
		Save the returned ID for updating and removing the highlight.

		If argument `reuseLast` is true, it will begin its search from .
		Use this iff you know that the new highlight ends after the previous highlight begins.
	]]
    function wrappingText:HighlightRange(color, startIndex, endIndex, reuseLast)
		nextHighlightID = nextHighlightID + 1
		self:NeedsRedraw()

		local displayStartIndex, displayEndIndex
		if coloredString then
			displayStartIndex, cachedAddedCharactersIndex, cachedRemovedSpacesIndex, cachedComputedOffset = self:RawIndexToDisplayIndex(startIndex, reuseLast and cachedAddedCharactersIndex, reuseLast and cachedRemovedSpacesIndex, reuseLast and cachedComputedOffset)
			displayEndIndex, cachedAddedCharactersIndex, cachedRemovedSpacesIndex, cachedComputedOffset = self:RawIndexToDisplayIndex(endIndex, cachedAddedCharactersIndex, cachedRemovedSpacesIndex, cachedComputedOffset)
		end
        highlights[nextHighlightID] = { 
			color = color, 
			startIndex = startIndex, 
			endIndex = endIndex, 
			displayStartIndex = displayStartIndex, 
			displayEndIndex = displayEndIndex
		}

		return nextHighlightID
    end
	--[[
		Overwrites the data for a pre-existing highlight.
		
		This can be used to re-create a previously removed highlight, or simply change its appearance. 
	]]
	function wrappingText:UpdateHighlight(id, color, startIndex, endIndex, reuseLast)
		local temp = nextHighlightID
		nextHighlightID = id - 1
		self:HighlightRange(color, startIndex, endIndex, reuseLast)
		nextHighlightID = temp
	end
	--[[
		Removes a highlight.
		The id will not be recycled.
	]]
    function wrappingText:RemoveHighlight(id)
		self:NeedsRedraw()
		highlights[id] = nil
    end

	return wrappingText
end