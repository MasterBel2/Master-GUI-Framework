-- A component of fixed size.
function framework:Rect(width, height, cornerRadius, decorations)
	local rect = { cornerRadius = cornerRadius or framework:Dimension(0), decorations = decorations or {} }

	function rect:SetSize(newWidth, newHeight)
		width = newWidth
		height = newHeight
	end

	local cachedX
	local cachedY

	local cachedWidth, cachedHeight
	function rect:Draw()
		local decorations = self.decorations
		for i = 1, #decorations do
			decorations[i]:Draw(self, cachedX, cachedY, cachedWidth, cachedHeight)
		end
	end

	function rect:Position(x, y)
		cachedX = x
		cachedY = y
		activeDrawingGroup.drawTargets[#activeDrawingGroup.drawTargets + 1] = self
	end

	function rect:LayoutChildren()
		return self
	end
	
	function rect:NeedsLayout()
		return cachedWidth ~= width() or cachedHeight ~= height()
	end
	function rect:Layout()
		cachedWidth = width()
		cachedHeight = height()
		return cachedWidth, cachedHeight
	end

	return rect
end