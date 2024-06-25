local pcall = Include.pcall
local pairs = Include.pairs
local Internal = Internal

local tooltipID = 0
function framework:Tooltip(rect, description)
	local tooltip = { description = description, tooltips = {} }
	local id = tooltipID -- like for responder, this is immutable so doesn't need to be stored in the table
	tooltipID = tooltipID + 1

	local width, height
	local cachedX, cachedY

	function tooltip:Size()
		return width, height
	end

	function tooltip:CachedPosition()
		return cachedX, cachedY
	end

	function tooltip:Geometry()
		return cachedX, cachedY, width, height
	end

	function tooltip:Layout(...)
		width, height = rect:Layout(...)
		return width, height
	end
	
	function tooltip:Position(x, y)
		local previousActiveTooltip = Internal.activeTooltip
		local parent = self.parent
		if previousActiveTooltip ~= parent then
			if parent then
				parent.tooltips[id] = nil
			end
			previousActiveTooltip.tooltips[id] = self
			self.parent = previousActiveTooltip
		end
		Internal.activeTooltip = self

		rect:Position(x, y)
		Internal.activeTooltip = previousActiveTooltip
		
		cachedX = x
		cachedY = y
	end
	return tooltip
end

function FindTooltip(x, y, tooltips)
	for key,tooltip in pairs(tooltips) do
		local success, tooltipX, tooltipY, tooltipWidth, tooltipHeight = pcall(tooltip.Geometry, tooltip)
		if not success then
			-- tooltipX stores the error message in case of failure
			Error("FindTooltip", "tooltip:Geometry", "Element: " .. key, tooltipX) 
			break
		end
		if not (x and y and tooltipX and tooltipY and tooltipWidth and tooltipHeight) then
			Error("FindTooltip", "Element: " .. key, "Tooltip:Geometry is incomplete: " .. (tooltipX or "nil") .. ", " .. (tooltipY or "nil") .. ", " .. (tooltipWidth or "nil") .. ", " .. (tooltipHeight or "nil"))
			break
		end

		if PointIsInRect(x, y, tooltipX, tooltipY, tooltipWidth, tooltipHeight) then
			local child = FindTooltip(x, y, tooltip.tooltips)
			return child or tooltip
		end
	end
	return nil
end