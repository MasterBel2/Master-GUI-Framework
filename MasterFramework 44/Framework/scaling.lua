local Internal = Internal
local min = Include.math.min
local floor = Include.math.floor
local ceil = Include.math.ceil
local pairs = Include.pairs
local pcall = Include.pcall
local setmetatable = Include.setmetatable

relativeScaleFactor = 1
combinedScaleFactor = 1

Internal.autoScalingDimensions = {}

function framework:Dimension(generator, ...)
	local dimension = { registeredDrawGroups = {} }
	local cachedRawValue
	local cachedCeilValue
	local cachedFloorValue
	local cacheRoundValue

	function dimension.Update(...)
		local newRawValue = generator(...)
		if newRawValue ~= cachedRawValue then
			cachedRawValue = newRawValue
			cachedCeilValue = ceil(cachedRawValue)
			cachedFloorValue = floor(cachedRawValue)
			cachedRoundValue = floor(cachedRawValue + 0.5)

			for drawingGroup, pass in pairs(dimension.registeredDrawGroups) do
				if pass == DRAWING_GROUP_PASS.LAYOUT then
					drawingGroup:LayoutUpdated(dimension)
				elseif pass == DRAWING_GROUP_PASS.POSITION then
					drawingGroup:PositionsUpdated(dimension)
				elseif pass == DRAWING_GROUP_PASS.DRAW then
					drawingGroup:DrawerUpdated(dimension)
				end
			end
		end
	end

	dimension.Update(...)

	local function Register()
		if activeDrawingGroup then
			-- Each pass triggers every pass after it, so we only have to record the first.
			dimension.registeredDrawGroups[activeDrawingGroup] = dimension.registeredDrawGroups[activeDrawingGroup] or activeDrawingGroup.pass
			if activeDrawingGroup.pass == DRAWING_GROUP_PASS.DRAW then
				activeDrawingGroup.drawers[dimension] = true
			else
				activeDrawingGroup.layoutComponents[dimension] = true
			end
		end
	end

	function dimension.FloorValue()
		Register()
		return cachedFloorValue
	end
	function dimension.CeilValue()
		Register()
		return cachedCeilValue
	end
	function dimension.RoundValue()
		Register()
		return cachedRoundValue
	end
	function dimension.RawValue()
		Register()
		return cachedRawValue
	end

	setmetatable(dimension, {
		__call = dimension.FloorValue
	})

	return dimension
end

function framework:AutoScalingDimension(unscaled)
	local dimension = Internal.autoScalingDimensions[unscaled]

	if not dimension then
		dimension = self:Dimension(function() return unscaled * combinedScaleFactor end)
		Internal.autoScalingDimensions[unscaled] = dimension
	end

	return dimension
end

function Internal.updateScreenEnvironment(newWidth, newHeight, newScale)
	viewportWidth = newWidth
	viewportHeight = newHeight

	relativeScaleFactor = newScale
	combinedScaleFactor = min(viewportWidth / 1920, viewportHeight / 1080) * relativeScaleFactor
	
	for _, font in pairs(Internal.fonts) do
		font:Scale(combinedScaleFactor)
	end

	for _, dimension in pairs(Internal.autoScalingDimensions) do
		dimension.Update()
	end

	for _, element in pairs(Internal.elements) do
		Internal.activeElement = element
		local success, _error = pcall(element.drawingGroup.Layout, element.drawingGroup, viewportWidth, viewportHeight)
		if not success then
			Error("Element: " .. element.key, "drawingGroup:Layout(viewportWidth, viewportHeight)", _error)
			framework:RemoveElement(element.key)
		end
	end

	Internal.activeElement = nil
end

function framework:SetScale(newScale)
	updateScreenEnvironment(viewportWidth, viewportHeight, newScale)
end