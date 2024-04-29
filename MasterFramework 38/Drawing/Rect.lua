local table_insert = Include.table.insert

-- A component of fixed size.
function framework:Rect(width, height, cornerRadius, decorations)
	local rect = { cornerRadius = cornerRadius or framework:Dimension(0), decorations = decorations or {} }

	function rect:SetSize(newWidth, newHeight)
		width = newWidth
		height = newHeight
	end

	local cachedX
	local cachedY

	function rect:Draw()
		local decorations = self.decorations
		for i = 1, #decorations do
			decorations[i]:Draw(self, cachedX, cachedY, width(), height())
		end
	end

	function rect:Position(x, y)
		cachedX = x
		cachedY = y
		table_insert(activeDrawingGroup.drawTargets, self)
	end

	function rect:Layout() 
		return width(), height() 
	end

	return rect
end