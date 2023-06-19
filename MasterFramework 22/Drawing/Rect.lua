-- A component of fixed size.
function framework:Rect(width, height, cornerRadius, decorations)
	local rect = { cornerRadius = cornerRadius or framework:Dimension(0), decorations = decorations or {} }

	function rect:SetSize(newWidth, newHeight)
		width = newWidth
		height = newHeight
	end

	function rect:Draw(x, y)
		LogDrawCall("Rect")
		local decorations = self.decorations
		for i = 1, #decorations do
			decorations[i]:Draw(self, x, y, width(), height())
		end
	end

	function rect:Layout() 
		return width(), height() 
	end

	return rect
end