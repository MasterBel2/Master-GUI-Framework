local math = Include.math
local math_floor = Include.math.floor
local math_huge = Include.math.huge
local math_max = Include.math.max
local math_min = Include.math.min
local table = Include.table
local ipairs = Include.ipairs
local Internal = Internal

-- Automatically wrapping text. 
-- Set `maxLines = 1` to disable wrapping. (`framework:Text()` is an alias for `framework:WrappingText` that sets `maxLines = 1`.)
--
-- Note that raw/display index conversion updates only on layout, so between when the raw string is updated and layout occurs, index conversion to or from the display string will be invalid.
function framework:WrappingText(string, color, font, maxLines)
	maxLines = maxLines or math_huge
	font = font or framework.defaultFont
	color = color or framework.color.white
	local wrappingText = Component(true, false)

	wrappingText._readOnly_font = font
	wrappingText.type = "Wrapping Text"

	wrappingText.addedCharacters = {}
	wrappingText.removedSpaces = {}

	local coloredString
	local wrappedText, lineCount
	local cachedX, cachedY, cachedWidth, cachedHeight
	local cachedAvailableWidth, cachedAvailableHeight, cachedFontKey, cachedFontScaledSize, cachedFontScaledSize
	local addedCharacters = wrappingText.addedCharacters
	local removedSpaces = wrappingText.removedSpaces

	local stringChanged = true

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
		local xOffset = x - cachedX
		local yOffset = y - cachedY

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

	function wrappingText:LayoutChildren() end -- none; we update layout other ways

	function wrappingText:Layout(availableWidth, availableHeight, profile)
		self:RegisterDrawingGroup()
		availableWidth = math_min(availableWidth, 2147483647) -- if we allow math.huge, `glFont:WrapText()` will fail. 
		availableHeight = math_min(availableHeight, 2147483647)
		local fontScaledSize = font:ScaledSize()
		local glFont = font.glFont
		if availableWidth == cachedAvailableWidth and availableHeight == cachedAvailableHeight and not stringChanged and fontScaledSize == cachedFontScaledSize and font.key == cachedFontKey then
			return cachedWidth, cachedHeight
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
		cachedWidth = math_min(glFont:GetTextWidth(wrappedText) * cachedFontScaledSize, availableWidth)
		cachedHeight = math_min(maxHeight, lineCount * trueLineHeight)

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
		
		return cachedWidth, cachedHeight
	end
	
	function wrappingText:Position(x, y)
		cachedX = x
		cachedY = y

		Internal.activeTextGroup:AddElement(self)
	end

	-- Draws the text on-screen, using the cached coordinates from `wrappingText:Position(x, y)`.
	--
	-- Called by the `framework:TextGroup` that `wrappingText:Position(x, y)` registered us with.
	function wrappingText:Draw(glFont)
		glFont:SetTextColor(color:GetRawValues())
		color:RegisterDrawingGroup()

		-- height - 1 is because it appeared to be drawing 1 pixel too high - for the default font, at least. I haven't checked with any other font size yet.
		-- I don't know what to do about text that's supposed to be centred vertically in a cell, because this method of drawing means the descender pushes the text up a bunch.
		glFont:Print(wrappedText, cachedX, cachedY + cachedHeight - 1, font:ScaledSize(), "ao")
	end

	-- Returns the x,y coordinates provided in the last call of `wrappingText:Position(x, y)`
	function wrappingText:CachedPosition()
		return cachedX, cachedY
	end
	-- Returns the `wrappingText's` cached position and cached size.
	function wrappingText:Geometry()
		return cachedX, cachedY, cachedWidth, cachedHeight
	end
	-- Returns the width, height calculated in the last call of `wrappingText:Layout(availableWidth, availableHeight)`
	function wrappingText:Size()
		return cachedWidth, cachedHeight
	end

	return wrappingText
end