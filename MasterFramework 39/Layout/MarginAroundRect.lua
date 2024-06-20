local table_insert = Include.table.insert

function framework:MarginAroundRect(rect, left, top, right, bottom, decorations, cornerRadius, shouldRasterize)
	local margin = { rect = rect, decorations = decorations or {}, cornerRadius = cornerRadius or framework:Dimension(0), 
		shouldInvalidateRasterizer = true, type = "MarginAroundRect"
	}

	local rasterizableRect
	local rasterizer

	local width, height
	local lastRasterizedWidth
	local lastRasterizedHeight
	local lastRasterizedX
	local lastRasterizedY

	local function getWidth() return width end
	local function getHeight() return height end

	local cachedLeft
	local cachedRight
	local cachedTop
	local cachedBottom
	local cachedRect

	function margin:LayoutChildren()
		return self, self.rect:LayoutChildren()
	end

	function margin:NeedsLayout()
		return cachedLeft ~= left() or cachedRight ~= right() or cachedTop ~= top() or cachedBottom ~= bottom() or cachedRect ~= self.rect
	end

	if shouldRasterize then
		rasterizableRect = framework:Rect(getWidth, getHeight, cornerRadius, decorations)
		rasterizer = framework:Rasterizer(rasterizableRect)

		function margin:Layout(availableWidth, availableHeight)
			if self.shouldInvalidateRasterizer then
				rasterizer.invalidated = true
			end

			cachedLeft = left()
			cachedRight = right()
			cachedTop = top()
			cachedBottom = bottom()
			cachedRect = self.rect

			local horizontal = cachedLeft + cachedRight
			local vertical = cachedTop + cachedBottom

			local rectWidth, rectHeight = cachedRect:Layout(availableWidth - horizontal, availableHeight - vertical)
			width = rectWidth + horizontal
			height = rectHeight + vertical

			rasterizer:Layout(width, height)

			return width, height
		end

		function margin:Position(x, y)
			if self.shouldInvalidateRasterizer then
				rasterizableRect.cornerRadius = self.cornerRadius
				rasterizableRect.decorations = self.decorations

				rasterizer.invalidated = true
			end
			rasterizer:Position(x, y)
			self.shouldInvalidateRasterizer = false

			cachedRect:Position(x + cachedLeft, y + cachedBottom)
		end
	else
		function margin:Layout(availableWidth, availableHeight)
			cachedLeft = left()
			cachedRight = right()
			cachedTop = top()
			cachedBottom = bottom()
			cachedRect = self.rect

			local horizontal = cachedLeft + cachedRight
			local vertical = cachedTop + cachedBottom
	
			local rectWidth, rectHeight = cachedRect:Layout(availableWidth - horizontal, availableHeight - vertical)
			width = rectWidth + horizontal
			height = rectHeight + vertical
			return width, height
		end

		local cachedX
		local cachedY

		function margin:Position(x, y)
			table_insert(activeDrawingGroup.drawTargets, self)

			cachedX = x
			cachedY = y
	
			cachedRect:Position(cachedX + cachedLeft, cachedY + cachedBottom)
		end

		function margin:Draw()
			local decorations = self.decorations
			for i = 1, #decorations do
				decorations[i]:Draw(self, cachedX, cachedY, width, height)
			end
		end
	end

	return margin
end