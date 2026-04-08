local Internal = Internal
local error = Include.error

function Internal.TextChunk()
	local string
	local width = 0
	local height = 0
	local font = framework.defaultFont
	local color = framework.color.white

	local cachedX, cachedY = 0, 0

	local textChunk = Component(true, true)

	function textChunk:Layout(availableWidth, availableHeight)
		self:RegisterDrawingGroup()
		return width, height
	end
	function textChunk:Position(x, y)
		cachedX = x
		cachedY = y
		Internal.activeTextGroup:AddElement(self)
	end

	function textChunk:DrawText(glFont)
		self:RegisterDrawingGroup()
		color:RegisterDrawingGroup()
		glFont:SetTextColor(color:GetRawValues())

		glFont:Print(string, cachedX, cachedY + height - 1, font:ScaledSize(), "ao")
	end

	local drawingGroup = framework:DrawingGroup(textChunk)
	function drawingGroup:Update(newString, newFont, newColor)
		if newString and (string ~= newString)
		or newFont and (font ~= newFont) then
			string = newString or string
			font = newFont or font

			width = font.glFont:GetTextWidth(string) * font:ScaledSize()
			local displayLineCount = #string:lines_MasterFramework()
			height = displayLineCount * font:ScaledSize()

			textChunk._readOnly_font = font

			textChunk:NeedsLayout()
		end
		if newColor and (color ~= newColor) then
			color = newColor
			textChunk:NeedsRedraw()
		end

		drawingGroup:Layout(width, height)
	end
	return drawingGroup
end