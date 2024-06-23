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
function framework:Rasterizer(body)
	local rasterizer = framework:DrawingGroup(body)
	
	-- debug
	local framesCalculatedInARow = 0

	-- Caching
	local activeResponderCache = {}
	local drawList

	for _, event in pairs(events) do
		activeResponderCache[event] = { responders = {} }
	end
	
	local _LayoutChildren = rasterizer.LayoutChildren
	function rasterizer:LayoutChildren()
		return self
	end
	
	local layoutChildren
	local cachedNeedsLayout = true

	local _NeedsLayout = rasterizer.NeedsLayout
	function rasterizer:NeedsLayout()
		if (not layoutChildren) or _NeedsLayout(self) then
			cachedNeedsLayout = true
		else
			for i = 2, #layoutChildren do -- DrawingGroup has itself as its first layout child; we'll skip that, coz we handled that above.
				if layoutChildren[i]:NeedsLayout() then
					cachedNeedsLayout = true
					break
				end
			end
		end
		return cachedNeedsLayout
	end

	local cachedAvailableWidth
	local cachedAvailableHeight
	local cachedX, cachedY
	local cachedWidth, cachedHeight
	local needsPosition

	local _Layout = rasterizer.Layout
	function rasterizer:Layout(availableWidth, availableHeight)
		if cachedNeedsLayout or cachedAvailableWidth ~= availableWidth or cachedAvailableHeight ~= availableHeight then
			cachedNeedsLayout = false
			self.needsRedraw = true
			needsPosition = true

			cachedAvailableWidth = availableWidth
			cachedAvailableHeight = availableHeight

			layoutChildren = { _LayoutChildren(self) }
			Internal.DebugInfo[self._debugUniqueIdentifier .. ": " .. (self._debugTypeIdentifier or "\"unkown\"") .. " layout children"] = table.imap(layoutChildren, function(_, component) return (component._debugUniqueIdentifier or "\"unknown\"") .. ": " .. component._debugTypeIdentifier end)
			cachedWidth, cachedHeight = _Layout(self, availableWidth, availableHeight)
		end
		return cachedWidth, cachedHeight
	end

	local cachedX, cachedY
	local _Position = rasterizer.Position
	function rasterizer:Position(x, y)
		if needsPosition or cachedX ~= x or cachedY ~= y then
			needsPosition = false
			self.needsRedraw = true
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

			_Position(self, x, y)

			activeRasterizer = previousActiveRasterizer
			-- Reset  things
			Internal.activeResponders = previousResponders

			cachedX = x
			cachedY = y
			-- end
		else
			activeDrawingGroup.drawTargets[#activeDrawingGroup.drawTargets + 1] = self
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

	local _Draw = rasterizer.Draw
	function rasterizer:Draw()
		if Internal.debugMode.noRasterizer then
			_Draw(self)
			return
		elseif (not drawList) or self.needsRedraw then
			Log("Recalculating rasterizer (" .. os_clock() .. ")")
			recalculatingRasterizer = true
			if framesCalculatedInARow > 0 then
				Log("Recalculated " .. (self.name or "unnamed") .. " " .. framesCalculatedInARow .. " frame(s) in a row")
			end

			gl_DeleteList(drawList)
			drawList = gl_CreateList(_Draw, self)
			
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