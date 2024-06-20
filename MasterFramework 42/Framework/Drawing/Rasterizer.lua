local insert = Include.table.insert
local pairs = Include.pairs
local clear = Include.clear
local gl_DeleteList = Include.gl.DeleteList
local gl_CreateList = Include.gl.CreateList
local gl_CallList = Include.gl.CallList
local os_clock = Include.os.clock
local unpack = Include.unpack

local Internal = Internal


-- NOTE: Translation is NOT COMPATIBLE WITH RESPONDERS
local emptyTable = {}
local recalculatingRasterizer = false

-- Wraps the body in a draw list, to avoid both layout recalculation and redrawing.
-- Set `rasterizer.invalidated = true` to re-layout and re-draw.
-- Call `rasterizer:SetBody()` to change the contents of the rasterizer. This automatically invalidates the rasterizer.
--
-- Currently, nested rasterizers have no performance benefit, as draw lists cannot be nested.
--
-- Additional notes: 
--  - When drawDebug is enabled, rasterization is disabled.
--  - When scaling or screen size changes, all rasterizers will automatically invalidate themselves.
function framework:Rasterizer(providedBody)
	local rasterizer = { invalidated = true, type = "Rasterizer" }

	local drawingGroup = framework:DrawingGroup(providedBody)
	
	-- debug
	local framesCalculatedInARow = 0

	-- Caching
	local activeResponderCache = {}
	local drawList
	local width, height

	for _, event in pairs(events) do
		activeResponderCache[event] = { responders = {} }
	end

	function rasterizer:SetBody(newBody)
		drawingGroup:SetBody(newBody)
		invalidated = true
	end
	
	function rasterizer:LayoutChildren()
		return self
	end
	
	local layoutChildren
	local cachedNeedsLayout
	function rasterizer:NeedsLayout()
		if not layoutChildren then return true end
		Internal.DebugInfo["Rasterizer layoutChildren count"] = #layoutChildren
		for i = 1, #layoutChildren do
			if layoutChildren[i]:NeedsLayout() then
				cachedNeedsLayout = true
				return true
			end
		end
		cachedNeedsLayout = false
		return false
	end

	local cachedAvailableWidth, cachedAvailableHeight
	function rasterizer:Layout(availableWidth, availableHeight)
		layoutChildren = { drawingGroup:LayoutChildren() }
		self.invalidated = self.invalidated or cachedNeedsLayout or viewportDidChange or availableWidth ~= cachedAvailableWidth or availableHeight ~= availableHeight
		cachedNeedsLayout = false
		if self.invalidated then
			width, height = drawingGroup:Layout(availableWidth, availableHeight)
			cachedAvailableWidth = availableWidth 
			cachedAvailableHeight = availableHeight
		end
		return width, height 
	end

	local cachedX, cachedY
	function rasterizer:Position(x, y)
		self.invalidated = self.invalidated or cachedX ~= x or cachedY ~= y
		if self.invalidated then
			-- Cache responders that won't be drawn
			for _, event in pairs(events) do
				-- activeResponderCache[event].responders = {}
				clear(activeResponderCache[event].responders)
			end

			local previousResponders = Internal.activeResponders
			Internal.activeResponders = activeResponderCache

			-- Display lists cannot be nested, so well record child rasterizers and draw them on top of ourselves
			local previousActiveRasterizer = activeRasterizer
			activeRasterizer = self
			self.childRasterizers = {}

			drawingGroup:Position(x, y)

			activeRasterizer = previousActiveRasterizer
			-- Reset  things
			Internal.activeResponders = previousResponders

			if activeRasterizer then
				activeRasterizer.childRasterizers[#activeRasterizer.childRasterizers] = self
			else
				activeDrawingGroup.drawTargets[#activeDrawingGroup.drawTargets] = self
			end

			cachedX = x
			cachedY = y
		end

		for _, event in pairs(events) do
			local parentResponder = Internal.activeResponders[event]
			local childrenOfParentResponder = parentResponder.responders
			
			local cachedResponders = activeResponderCache[event].responders

			for index = 1, #cachedResponders do
				local cachedResponder = cachedResponders[index]
				insert(childrenOfParentResponder, cachedResponder)
				cachedResponder.parent = parentResponder
			end
		end
	end

	function rasterizer:Draw()
		if Internal.debugMode.noRasterizer then
			drawingGroup:Draw()
			return
		elseif self.invalidated --[[or drawingGroup:NeedsRedraw()]] then
			Log("Recalculating rasterizer (" .. os_clock() .. ")")
			recalculatingRasterizer = true
			if framesCalculatedInARow > 0 then
				Log("Recalculated " .. (self.name or "unnamed") .. " " .. framesCalculatedInARow .. " frame(s) in a row")
			end

			gl_DeleteList(drawList)
			drawList = gl_CreateList(drawingGroup.Draw, drawingGroup)
			
			self.invalidated = false
			framesCalculatedInARow = framesCalculatedInARow + 1
		else
			framesCalculatedInARow = 0
		end

		gl_CallList(drawList)

		for i = 1, #self.childRasterizers do
			self.childRasterizers[i]:Draw()
		end
	end

	return rasterizer
end