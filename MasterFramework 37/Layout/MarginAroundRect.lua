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

	if shouldRasterize then
		rasterizableRect = framework:Rect(getWidth, getHeight, cornerRadius, decorations)
		rasterizer = framework:Rasterizer(rasterizableRect)

		function margin:Layout(availableWidth, availableHeight)
			if self.shouldInvalidateRasterizer or viewportDidChange or lastRasterizedWidth ~= width or lastRasterizedHeight ~= height then
				lastRasterizedWidth = width
				lastRasterizedHeight = height

				rasterizer.invalidated = true
			end

			local horizontal = left() + right() -- May be more performant to do left right top bottom – not sure though
			local vertical = top() + bottom()

			local rectWidth, rectHeight = self.rect:Layout(availableWidth - horizontal, availableHeight - vertical)
			width = rectWidth + horizontal
			height = rectHeight + vertical

			rasterizer:Layout(width, height)

			return width, height
		end

		function margin:Position(x, y)
			if self.shouldInvalidateRasterizer or lastRasterizedX ~= x or lastRasterizedY ~= y then
				rasterizableRect.cornerRadius = self.cornerRadius
				rasterizableRect.decorations = self.decorations
				lastRasterizedX = x
				lastRasterizedY = y
				rasterizer.invalidated = true
			end
			rasterizer:Position(x, y)
			self.shouldInvalidateRasterizer = false

			self.rect:Position(x + left(), y + bottom())
		end
	else
		function margin:Layout(availableWidth, availableHeight)
			local horizontal = left() + right() -- May be more performant to do left right top bottom – not sure though
			local vertical = top() + bottom()
	
			local rectWidth, rectHeight = self.rect:Layout(availableWidth - horizontal, availableHeight - vertical)
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
	
			self.rect:Position(cachedX + left(), cachedY + bottom())
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