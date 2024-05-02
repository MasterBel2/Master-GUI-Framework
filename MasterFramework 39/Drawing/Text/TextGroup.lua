local clear = Include.clear
local pairs = Include.pairs
local insert = Include.table.insert
local Internal = Internal

-- Allows group-drawing text objects. 
--
-- Text objects must be registered every frame they wish to be drawn by calling `activeTextGroup:AddElement(textObject)`. 
-- Text objects must implement the following interface:
-- - textObject._readOnly_font: a font object, generated by `framework:Font()`
-- - textObject:Draw(glFont): draws the text object, providing only the font object's glfont. The text object should use its own cached coordinates to draw.
function framework:TextGroup(body, name)
	local textGroup = { name = name or "default" }
	local elements = {}

	function textGroup:NeedsLayout()
		return body:NeedsLayout()
	end

	function textGroup:SetBody(newBody)
		body = newBody
	end

	function textGroup:AddElement(newElement)
		local fontKey = newElement._readOnly_font.key
		local fontGroup = elements[fontKey] or {}
		insert(fontGroup, newElement)
		elements[fontKey] = fontGroup
	end

	function textGroup:Layout(availableWidth, availableHeight)
		return body:Layout(availableWidth, availableHeight)
	end

	function textGroup:Position(...)
		for fontKey, textElements in pairs(elements) do
			if #textElements == 0 then
				elements[fontKey] = nil
			else
				clear(textElements)
			end
		end
		
		local previousTextGroup = Internal.activeTextGroup
		Internal.activeTextGroup = self
		body:Position(...)
		Internal.activeTextGroup = previousTextGroup
		
		insert(activeDrawingGroup.drawTargets, self)
	end

	function textGroup:Draw(...)
		for _, textElements in pairs(elements) do
			local textElement = textElements[1]
			if not textElement then break end

			local glFont = textElement._readOnly_font.glFont
			glFont:Begin()
			for index = 1, #textElements do
				textElements[index]:Draw(glFont)
			end
			glFont:End()
		end
	end

	return textGroup
end