local pairs = Include.pairs
local clear = Include.clear
local gl_DeleteList = Include.gl.DeleteList
local gl_CreateList = Include.gl.CreateList
local gl_CallList = Include.gl.CallList

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

	local textGroup = framework:TextGroup(providedBody)
	
	-- debug
	local framesCalculatedInARow = 0

	-- Caching
	local activeResponderCache = {}
	local drawList
	local _body = textGroup
	local width, height

	for _, event in pairs(events) do
		activeResponderCache[event] = { responders = {} }
	end

	function rasterizer:SetBody(newBody)
		textGroup:SetBody(newBody)
		invalidated = true
	end

	function rasterizer:Layout(availableWidth, availableHeight)
		if self.invalidated or not drawList or viewportDidChange then
			width, height = _body:Layout(availableWidth, availableHeight)
		end
		return width, height 
	end

	local function draw(body, ...)
		body:Draw(...)
	end

	function rasterizer:Draw(x, y)
		LogDrawCall("Rasterizer")
		if recalculatingRasterizer or Internal.drawDebug then
			-- Display lists cannot be nested, so we'll skip using one while we're creating one.
			_body:Draw(x, y)
			return
		elseif self.invalidated or not drawList or viewportDidChange then
			-- Log("Recalculating rasterizer " .. self._readOnly_elementID)
			recalculatingRasterizer = true
			if framesCalculatedInARow > 0 then
				Log("Recalculated " .. (self.name or "unnamed") .. " " .. framesCalculatedInARow .. " frame(s) in a row")
			end
			LogDrawCall("Rasterizer (Recompile)")

			-- Cache responders that won't be drawn
			for _, event in pairs(events) do
				-- activeResponderCache[event].responders = {}
				clear(activeResponderCache[event].responders)
			end

			local previousResponders = Internal.activeResponders
			Internal.activeResponders = activeResponderCache

			gl_DeleteList(drawList)
			drawList = gl_CreateList(draw, _body, x, y)

			-- Reset  things
			Internal.activeResponders = previousResponders
			
			self.invalidated = false
			recalculatingRasterizer = false
			framesCalculatedInARow = framesCalculatedInARow + 1
		else
			framesCalculatedInARow = 0
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

		gl_CallList(drawList)
	end

	return rasterizer
end