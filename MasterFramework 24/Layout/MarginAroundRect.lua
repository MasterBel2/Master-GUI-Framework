function framework:MarginAroundRect(rect, left, top, right, bottom, decorations, cornerRadius, shouldRasterize)
	local margin = { rect = rect, decorations = decorations or {}, cornerRadius = cornerRadius or framework:Dimension(0), 
		shouldInvalidateRasterizer = true, type = "MarginAroundRect"
	}

	local rasterizableRect
	local rasterizer

	local width, height

	local function getWidth() return width end
	local function getHeight() return height end

	if shouldRasterize then
		rasterizableRect = framework:Rect(getWidth, getHeight, cornerRadius, decorations)
		rasterizer = framework:Rasterizer(rasterizableRect)

		function margin:Draw(x, y)
			if self.shouldInvalidateRasterizer or viewportDidChange then
				rasterizableRect.cornerRadius = self.cornerRadius
				rasterizableRect.decorations = self.decorations
				rasterizer.invalidated = self.shouldInvalidateRasterizer
				self.shouldInvalidateRasterizer = false
			end
			rasterizer:Draw(x, y)

			self.rect:Draw(x + left(), y + bottom())
		end
	else
		function margin:Draw(x, y)
			local decorations = self.decorations
			for i = 1, #decorations do
				decorations[i]:Draw(self, x, y, width, height)
			end
	
			self.rect:Draw(x + left(), y + bottom())
		end
	end
	
	function margin:Layout(availableWidth, availableHeight)
		local horizontal = left() + right() -- May be more performant to do left right top bottom – not sure though
		local vertical = top() + bottom()

		local rectWidth, rectHeight = self.rect:Layout(availableWidth - horizontal, availableHeight - vertical)
		width = rectWidth + horizontal
		height = rectHeight + vertical
		return width, height
	end

	return margin
end