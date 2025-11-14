local math = Include.math
local math_floor = Include.math.floor
local math_ceil = Include.math.ceil
local math_huge = Include.math.huge
local math_max = Include.math.max
local math_min = Include.math.min

local next = Include.next

local gl_Rect = Include.gl.Rect
local gl_Translate = Include.gl.Translate

local pairs = Include.pairs

local table = Include.table
local Internal = Internal

-- 13/11/2025
-- There are multiple perf cliffs here, when testing with Tests/Framework/test_WrappingTest:test_displayIndexToRawIndex
--       Interval: ditri
--   (iterations):    10k
--           8192: 3.2  s
--     256 - 4096: 0.29 s
--            128: 0.15 s
--             64: 0.088s
--             32: 0.092s
--             16: 0.075s 
--              8: 0.072s
--              4: 0.064s
--              2: 0.059s
--              1: Crash
-- This was tested with code, I imagine we could use larger intervals when fewer insertions have been made.
-- I noticed no appreciable perf impact to Layout().
local indexConversionCacheInterval = 4

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

	local rawLineStarts, rawLineEnds, rawLineCount; function wrappingText:GetRawLines() return rawLineStarts, rawLineEnds, rawLineCount end
	local coloredString
	local wrappedText, lineCount, wrappedLineStarts, wrappedLineEnds; function wrappingText:GetDisplayLines() return wrappedLineStarts, wrappedLineEnds, lineCount end
	local width, height
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
				textChunks[i]:Update(nil, nil, newBaseColor)
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

	local rawIndexAddedCharactersIndex = { 1 }
	local rawIndexRemovedSpacesIndex = { 1 }
	local function CachedRawIndexToDisplayIndexSearchProgress(rawIndex)
		local index = math_ceil(rawIndex / indexConversionCacheInterval)
		local addedCharactersIndex = rawIndexAddedCharactersIndex[index]
		local removedSpacesIndex = rawIndexRemovedSpacesIndex[index]
		return addedCharactersIndex, removedSpacesIndex, addedCharactersIndex - removedSpacesIndex
	end

	-- Returns the index of the matching character in the display string.
	-- If we were provided the index of a removed space, we'll return an extra result - `true` - to indicate as such.
	-- Reminder, some characters might be changed (e.g. " " to "\n") and they won't be flagged.
	function wrappingText:RawIndexToDisplayIndex(rawIndex, addedCharactersIndex, removedSpacesIndex, computedOffset)
		if rawIndex > string:len() then return wrappedText:len(), #addedCharacters, #removedSpaces, #addedCharacters - #removedSpaces end
		if not addedCharactersIndex then
			addedCharactersIndex, removedSpacesIndex, computedOffset = CachedRawIndexToDisplayIndexSearchProgress(rawIndex)
		end

		local addedCharacter = addedCharacters[addedCharactersIndex]
		local addedCharacterRawIndex = addedCharacter - computedOffset
		local removedSpace = removedSpaces[removedSpacesIndex]

		while addedCharacterRawIndex <= rawIndex or removedSpace <= rawIndex do
			if addedCharacterRawIndex < removedSpace then
				computedOffset = computedOffset + 1
				addedCharactersIndex = addedCharactersIndex + 1
				addedCharacter = addedCharacters[addedCharactersIndex]
				addedCharacterRawIndex = addedCharacter - computedOffset
			elseif addedCharacterRawIndex == removedSpace then
				-- count them as swapped, no change to offset
				addedCharactersIndex = addedCharactersIndex + 1
				addedCharacter = addedCharacters[addedCharactersIndex]
				addedCharacterRawIndex = addedCharacter - computedOffset
				removedSpacesIndex = removedSpacesIndex + 1
				removedSpace = removedSpaces[removedSpacesIndex]
			elseif addedCharacterRawIndex > removedSpace then
				computedOffset = computedOffset - 1
				addedCharacterRawIndex = addedCharacter - computedOffset
				removedSpacesIndex = removedSpacesIndex + 1
				removedSpace = removedSpaces[removedSpacesIndex]
			end
		end

		return rawIndex + computedOffset, addedCharactersIndex, removedSpacesIndex, computedOffset, rawIndex == removedSpaces[removedSpacesIndex - 1]
	end

	local displayIndexAddedCharactersIndex = { 1 }
	local displayIndexRemovedSpacesIndex = { 1 }
	local function CachedDisplayIndexToRawIndexSearchProgress(displayIndex)
		local index = math_ceil(displayIndex / indexConversionCacheInterval)
		local addedCharactersIndex = displayIndexAddedCharactersIndex[index]
		local removedSpacesIndex = displayIndexRemovedSpacesIndex[index]
		return addedCharactersIndex, removedSpacesIndex, removedSpacesIndex - addedCharactersIndex
	end

	-- Returns the index of the matching character in the raw string. 
	-- 
	-- If the detected character was added, we'll just return the next character that wasn't added.
	-- If we were provided provide the index of an added character, we'll return a second result - `true` - to indicate as such.
	-- Reminder, some characters might be changed (e.g. " " to "\n") and they won't be flagged.
	function wrappingText:DisplayIndexToRawIndex(displayIndex, addedCharactersIndex, removedSpacesIndex, computedOffset)
		if displayIndex > wrappedText:len() then return string:len(), #addedCharacters, #removedSpaces, #removedSpaces - #addedCharacters end
		if not addedCharactersIndex then
			addedCharactersIndex, removedSpacesIndex, computedOffset = CachedDisplayIndexToRawIndexSearchProgress(displayIndex)
		end

		local addedCharacter = addedCharacters[addedCharactersIndex]
		local removedSpace = removedSpaces[removedSpacesIndex]
		-- while addedCharacters stores display indices, removedSpaces stores raw indices. 
		-- So, we need to convert between them.
		local removedSpaceDisplayIndex = removedSpace - computedOffset

		-- Interesting to note, checking spaces is consistently (marginally) faster
		while removedSpaceDisplayIndex <= displayIndex or addedCharacter <= displayIndex do
			if addedCharacter < removedSpace then
				computedOffset = computedOffset - 1
				addedCharactersIndex = addedCharactersIndex + 1

				addedCharacter = addedCharacters[addedCharactersIndex]
				removedSpaceDisplayIndex = removedSpace - computedOffset
			elseif addedCharacter == removedSpace then
				-- count them as swapped, no change to offset
				addedCharactersIndex = addedCharactersIndex + 1
				removedSpacesIndex = removedSpacesIndex + 1

				addedCharacter = addedCharacters[addedCharactersIndex]
				removedSpace = removedSpaces[removedSpacesIndex]
				removedSpaceDisplayIndex = removedSpace - computedOffset
			elseif addedCharacter > removedSpace then
				computedOffset = computedOffset + 1
				removedSpacesIndex = removedSpacesIndex + 1

				removedSpace = removedSpaces[removedSpacesIndex]
				removedSpaceDisplayIndex = removedSpace - computedOffset
			end
		end

		return displayIndex + computedOffset, addedCharactersIndex, removedSpacesIndex, computedOffset, addedCharacters[addedCharactersIndex - 1] == displayIndex
	end

	-- Converts a screen coordinate to an index in the display string. 
	function wrappingText:CoordinateToCharacterDisplayIndex(x, y)
		local absoluteX, absoluteY = self:CachedPositionTranslatedToGlobalContext()
		local xOffset = x - absoluteX
		local yOffset = y - absoluteY

		local glFont = font.glFont
		local scaledFontSize = font:ScaledSize()

		local lineIndex = math_min(lineCount, math_max(1, lineCount - math_floor(yOffset / (glFont.lineheight * scaledFontSize))))
		
		if lineIndex == 0 then return 1 end

		local lineStart = wrappedLineStarts[lineIndex]
		local lineEnd = wrappedLineEnds[lineIndex]

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
		wrappedLineStarts, wrappedLineEnds = wrappedText:lines_MasterFramework()
		width = math_min(glFont:GetTextWidth(wrappedText) * cachedFontScaledSize, availableWidth)
		height = math_min(maxHeight, lineCount * trueLineHeight)


		local i = 1
		local j = 1
		local string_byte = string.byte
		local rawCharacter = string_byte(string, i)
		local displayCharacter = string_byte(wrappedText, j)
		local rawLength = string:len()
		local displayLength = wrappedText:len()
		
		local addedCharacterCount = 0
		local removedSpacesCount = 0

		local displayCacheEntries = 1
		local rawCacheEntries = 1

		while i <= rawLength and j <= displayLength do
			if j >= displayCacheEntries * indexConversionCacheInterval then
				-- even though this won't line up perfectly with the raw index we're associating it with,
				-- it's good enough for its current purpose of conversion to raw index, as extra added characters
				-- will be adjusted for.
				displayCacheEntries = displayCacheEntries + 1
				displayIndexAddedCharactersIndex[displayCacheEntries] = addedCharacterCount + 1
				displayIndexRemovedSpacesIndex[displayCacheEntries] = removedSpacesCount + 1
			end
			if i >= rawCacheEntries * indexConversionCacheInterval then
				-- even though this won't line up perfectly with the display index we're associating it with,
				-- it's good enough for its current purpose of conversion to display index, as extra added characters
				-- will be adjusted for.
				rawCacheEntries = rawCacheEntries + 1
				rawIndexAddedCharactersIndex[rawCacheEntries] = addedCharacterCount + 1
				rawIndexRemovedSpacesIndex[rawCacheEntries] = removedSpacesCount + 1
			end

			if rawCharacter ~= displayCharacter then
				if rawCharacter == 32 then
					removedSpacesCount = removedSpacesCount + 1
					removedSpaces[removedSpacesCount] = i
					i = i + 1
					rawCharacter = string_byte(string, i)
				 elseif displayCharacter == 255 then
					addedCharacterCount = addedCharacterCount + 4
					addedCharacters[addedCharacterCount - 3] = j
					addedCharacters[addedCharacterCount - 2] = j + 1
					addedCharacters[addedCharacterCount - 1] = j + 2
					addedCharacters[addedCharacterCount    ] = j + 3
					j = j + 4
				 	displayCharacter = string_byte(wrappedText, j)
				else
					addedCharacterCount = addedCharacterCount + 1
					addedCharacters[addedCharacterCount] = j
					j = j + 1
					displayCharacter = string_byte(wrappedText, j)
				end
			else
				i = i + 1
				rawCharacter = string_byte(string, i)
				j = j + 1
				displayCharacter = string_byte(wrappedText, j)
			end
		end

		for i = displayCacheEntries + 1, math_ceil(displayLength / indexConversionCacheInterval) do
			displayIndexAddedCharactersIndex[i] = nil
			displayIndexRemovedSpacesIndex[i] = nil
		end
		for i = rawCacheEntries + 1, math_ceil(rawLength / indexConversionCacheInterval) do
			rawIndexAddedCharactersIndex[i] = nil
			rawIndexRemovedSpacesIndex[i] = nil
		end

		addedCharacters[addedCharacterCount + 1] = math_huge -- for iteration purposes
		removedSpaces[removedSpacesCount + 1] = math_huge -- for iteration purposes

		for i = addedCharacterCount + 2, #addedCharacters do
			addedCharacters[i] = nil
		end
		for i = removedSpacesCount + 2, #removedSpaces do
			removedSpaces[i] = nil
		end


		rawLineStarts, rawLineEnds = string:lines_MasterFramework()
		rawLineCount = #rawLineStarts
		-- Seems to be the sweet spot through experimental testing
		-- I imagine this could change depending on the nature of the text
		local linesPerChunk = 10
		local desiredChunkCount = math.ceil(rawLineCount / linesPerChunk)

		local addedCharactersIndex, removedSpacesIndex, computedOffset
		for i = 1, #textChunks do
			local displayStartIndex, displayEndIndex
			local rawStartIndex = rawLineStarts[(i - 1) * linesPerChunk + 1] - 1
			rawStartIndex = (rawStartIndex == 0) and 1 or rawStartIndex
			displayStartIndex, addedCharactersIndex, removedSpacesIndex, computedOffset = self:RawIndexToDisplayIndex(rawStartIndex, addedCharactersIndex, removedSpacesIndex, computedOffset)
			displayEndIndex, addedCharactersIndex, removedSpacesIndex, computedOffset = self:RawIndexToDisplayIndex(rawLineEnds[i * linesPerChunk] and (rawLineEnds[i * linesPerChunk] + 1) or string:len() + 1, addedCharactersIndex, removedSpacesIndex, computedOffset)
		
			local displayString = wrappedText:sub(rawStartIndex == 1 and 1 or displayStartIndex + 1, displayEndIndex - 1)

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
		for i = #textChunks + 1, desiredChunkCount do
			local displayStartIndex, displayEndIndex
			local rawStartIndex = rawLineStarts[(i - 1) * linesPerChunk + 1] - 1
			rawStartIndex = (rawStartIndex == 0) and 1 or rawStartIndex
			displayStartIndex, addedCharactersIndex, removedSpacesIndex, computedOffset = self:RawIndexToDisplayIndex(rawStartIndex, addedCharactersIndex, removedSpacesIndex, computedOffset)
			displayEndIndex, addedCharactersIndex, removedSpacesIndex, computedOffset = self:RawIndexToDisplayIndex(rawLineEnds[i * linesPerChunk] and (rawLineEnds[i * linesPerChunk] + 1) or string:len() + 1, addedCharactersIndex, removedSpacesIndex, computedOffset)
			
			local displayString = wrappedText:sub(rawStartIndex == 1 and 1 or displayStartIndex + 1, displayEndIndex - 1)

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
		for i = desiredChunkCount + 1, #textChunks do
			textChunks[i] = nil
		end

		-- We don't return here since we're only using this to coerce the `GeometryTarget` into caching width, height for us
		_Layout(self, width, height)

		local lastEndIndex = math_huge
		for id, highlight in pairs(highlights) do
			local reuseLast = highlight.startIndex > lastEndIndex
			lastEndIndex = highlight.endIndex

			self:UpdateHighlight(id, highlight.color, highlight.startIndex, highlight.endIndex, reuseLast)
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
		if not next(highlights) then return end

		local glFont = self._readOnly_font.glFont
		local scaledSize = self._readOnly_font:ScaledSize()
        local lineHeight = scaledSize * glFont.lineheight
		local textWidth, textHeight = self:Size()

		local x, y = self:CachedPositionRemainingInLocalContext()
		gl_Translate(x, y, 0)

		for _, highlight in pairs(highlights) do
			highlight.color:Set()
			for lineOffset, line in pairs(highlight.lines) do
				gl_Rect(
					line.xEnd and line.xStart or line.xStart - 0.5,
					textHeight - lineOffset * lineHeight,
					line.xEnd and line.xEnd or line.xStart + 0.5,
					textHeight - (lineOffset - 1) * lineHeight
				)
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
		if wrappedText then
			displayStartIndex, cachedAddedCharactersIndex, cachedRemovedSpacesIndex, cachedComputedOffset = self:RawIndexToDisplayIndex(startIndex, reuseLast and cachedAddedCharactersIndex, reuseLast and cachedRemovedSpacesIndex, reuseLast and cachedComputedOffset)
			displayEndIndex, cachedAddedCharactersIndex, cachedRemovedSpacesIndex, cachedComputedOffset = self:RawIndexToDisplayIndex(endIndex, cachedAddedCharactersIndex, cachedRemovedSpacesIndex, cachedComputedOffset)
			if not displayStartIndex then error("oh no") end
		end

		local highlight = highlights[nextHighlightID]
		if highlight then
			highlight.color = color; highlight.startIndex = startIndex; highlight.endIndex = endIndex; highlight.displayStartIndex = displayStartIndex; highlight.endIndex = endIndex 
		else
			highlight = {
				color = color, 
				startIndex = startIndex, 
				endIndex = endIndex, 
				displayStartIndex = displayStartIndex, 
				displayEndIndex = displayEndIndex,
				lines = {}
			}
		end

		local highlightedLines = highlight.lines

		if wrappedText then
			for i = 1, lineCount do
				local lineStart = wrappedLineStarts[i]
				local lineEnd = wrappedLineEnds[i]

				if displayStartIndex <= lineEnd + 1 and displayEndIndex >= lineStart then
					local highlightedLine = highlightedLines[i] or {}

					local lineHighlightStartIndex = math_max(lineStart, displayStartIndex)
					if displayStartIndex > lineStart then
						highlightedLine.xStart = (lineHighlightStartIndex == highlightedLine.startIndex) and highlightedLine.xStart or font.glFont:GetTextWidth(wrappedText:sub(lineStart, displayStartIndex - 1)) * font:ScaledSize()
					else
						highlightedLine.xStart = 0
					end
					highlightedLine.startIndex = lineHighlightStartIndex
					if displayStartIndex ~= displayEndIndex then
						local lineHighlightEndIndex = math_min(displayEndIndex - 1, lineEnd)
						highlightedLine.xEnd = (lineHighlightEndIndex == highlightedLine.endIndex) and highlightedLine.xEnd or font.glFont:GetTextWidth(wrappedText:sub(lineStart, lineHighlightEndIndex)) * font:ScaledSize()
					else
						highlightedLine.xEnd = nil
					end
					highlightedLines[i] = highlightedLine
				else
					highlightedLines[i] = nil
				end
			end
		end

		highlights[nextHighlightID] = highlight

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