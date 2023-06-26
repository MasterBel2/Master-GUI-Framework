local math = Include.math
local table = Include.table
local ipairs = Include.ipairs
local Internal = Internal

-- Automatically wrapping text. 
-- Set `maxLines = 1` to disable wrapping. (`framework:Text()` is an alias for `framework:WrappingText` that sets `maxLines = 1`.)
--
-- Note that raw/display index conversion updates only on layout, so between when the raw string is updated and layout occurs, index conversion to or from the display string will be invalid.
function framework:WrappingText(string, color, font, maxLines)
	maxLines = maxLines or math.huge
	font = font or framework.defaultFont
	local wrappingText = {
		color = color or framework.color.white,
		_readOnly_font = font,
		type = "Wrapping Text"
	}

	local wrappedText, lineCount
	local cachedX, cachedY, cachedWidth, cachedHeight
	local cachedAvailableWidth, cachedAvailableHeight, cachedFontKey, cachedFontScaledSize, cachedFontScaledSize
	local addedCharacters = {}

	local stringChanged = true

	-- Sets the raw string.
	-- 
	-- If a nil value is provided, an empty string will be set.
	function wrappingText:SetString(newString)
		if newString ~= string then
			string = newString or ""
			stringChanged = true
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
	function wrappingText:RawIndexToDisplayIndex(rawIndex)
		for breakNumber, breakIndex in ipairs(addedCharacters) do
			if breakIndex - breakNumber >= rawIndex then
				return rawIndex + (breakNumber - 1)
			end
		end
		return rawIndex + #addedCharacters
	end
	-- Returns the index of the matching character in the raw string. 
	-- 
	-- If the detected character was added, we'll just return the next character that wasn't added.
	-- If we provide the index of an added character, we'll return a second result - `true` - to indicate as such.
	-- Reminder, some characters might be changed (e.g. " " to "\n") and they won't be flagged.
	function wrappingText:DisplayIndexToRawIndex(displayIndex)
		for breakNumber, breakIndex in ipairs(addedCharacters) do
			if breakIndex == displayIndex then
				for i = 1, #addedCharacters - breakNumber do
					return breakIndex - breakNumber + 1, true
					-- Spring.Echo("Invalid index: adding " .. i)
					-- if addedCharacters[breakNumber + i] - i ~= displayIndex  then
					-- 	return breakIndex + i - breakNumber + i
					-- end
				end
			elseif breakIndex > displayIndex then
				return displayIndex - (breakNumber - 1)
			end
		end
		-- We hit this if the last character was not an added character
		return displayIndex - #addedCharacters, (#addedCharacters > 0)
	end

	-- Converts a screen coordinate to an index in the display string. 
	function wrappingText:CoordinateToCharacterDisplayIndex(x, y)
		local xOffset = x - cachedX
		local yOffset = y - cachedY

		local lines, lineStarts, lineEnds = wrappedText:lines()

		local lineIndex = math.min(#lines, math.max(1, #lines - math.floor(yOffset / (font.glFont.lineheight * font:ScaledSize()))))
		
		if lineIndex == 0 then return 1 end

		local line = lines[lineIndex]
		local lineStart = lineStarts[lineIndex]
		local lineEnd = lineEnds[lineIndex]

		local elapsedWidth = 0

		local i = 1
		while i <= line:len() do
			local character = line:sub(i, i)
			if character == "\255" then
				i = i + 4
			else
				local characterWidth = font.glFont:GetTextWidth(character) * font:ScaledSize()
				if elapsedWidth + characterWidth > xOffset then
					if xOffset - elapsedWidth > characterWidth / 2 then
						return lineStart + i
					else
						return lineStart + i - 1
					end
				end

				elapsedWidth = elapsedWidth + characterWidth
				i = i + 1
			end
		end

		return lineEnd + 1
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

	function wrappingText:Layout(availableWidth, availableHeight)
		availableWidth = math.min(availableWidth, 2147483647) -- if we allow math.huge, `glFont:WrapText()` will fail. 
		availableHeight = math.min(availableHeight, 2147483647)
		local fontScaledSize = font:ScaledSize()
		if availableWidth == cachedAvailableWidth and availableHeight == cachedAvailableHeight and not stringChanged and fontScaledSize == cachedFontScaledSize and font.key == cachedFontKey then
			return cachedWidth, cachedHeight
		end
		cachedFontScaledSize = fontScaledSize
		cachedFontKey = font.key
		stringChanged = false

		cachedAvailableWidth, cachedAvailableHeight = availableWidth, availableHeight
		local coloredText = self:ColoredString(string)

		local trueLineHeight = cachedFontScaledSize * font.glFont.lineheight
		local maxHeight = math.min(availableHeight, maxLines * trueLineHeight)

		-- `glFont:WrapText()` appears to consistently return a number (SLIGHTLY!) greater than availableWidth, probably due to floating-point math.
		-- Providing it an extra 0.1 width doesn't allow any extra characters through, but prevents the rounding error from messing us up.
		-- We won't report any this extra width to our parent, by clamping at availableWidth.
		wrappedText, lineCount = font.glFont:WrapText(coloredText, availableWidth + 0.1, maxHeight, cachedFontScaledSize) -- Apparently this adds an extra character ("\r") even when line breaks already
		cachedWidth = math.min(font.glFont:GetTextWidth(wrappedText) * cachedFontScaledSize, availableWidth)
		cachedHeight = math.min(maxHeight, lineCount * trueLineHeight)

		addedCharacters = {}
		for i = 1, wrappedText:len() do
			local displayCharacter = wrappedText:sub(i, i)
			local rawCharacter = string:sub(i - #addedCharacters, i - #addedCharacters)
			if displayCharacter ~= rawCharacter and not (displayCharacter == "\n" and rawCharacter == " ") then
				table.insert(addedCharacters, i)
			end
		end

		self.addedCharacters = addedCharacters
		
		return cachedWidth, cachedHeight
	end

	function wrappingText:Draw(x, y)
		cachedX = x
		cachedY = y

		Internal.activeTextGroup:AddElement(self)
	end

	-- Draws the text on-screen, using the cached coordinates from `wrappingText:Draw(x, y)`.
	--
	-- Called by the `framework:TextGroup` that `wrappingText:Draw(x, y)` registered us with.
	function wrappingText:DrawForReal(glFont)
		local color = self.color
		glFont:SetTextColor(color.r, color.g, color.b, color.a)

		-- height - 1 is because it appeared to be drawing 1 pixel too high - for the default font, at least. I haven't checked with any other font size yet.
		-- I don't know what to do about text that's supposed to be centred vertically in a cell, because this method of drawing means the descender pushes the text up a bunch.
		glFont:Print(wrappedText, cachedX, cachedY + cachedHeight - 1, font:ScaledSize(), "ao")
	end

	-- Returns the x,y coordinates provided in the last call of `wrappingText:Draw(x, y)`
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