local Internal = Internal
local min = Include.math.min
local floor = Include.math.floor
local pairs = Include.pairs
local pcall = Include.pcall
local setmetatable = Include.setmetatable

relativeScaleFactor = 1

Internal.autoScalingDimensions = {}

function framework:Dimension(generator)
	local dimension = { registeredDrawGroups = {} }
	local cachedValue

	function dimension.ValueHasChanged()
		return floor(generator()) ~= cachedValue
	end

	function dimension.ComputedValue()
		if activeDrawingGroup then
			activeDrawingGroup.dimensions[dimension] = true
		end
		cachedValue = floor(generator())
		return cachedValue
	end

	setmetatable(dimension, {
		__call = dimension.ComputedValue
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
	
	viewportDidChange = 1

	for _, font in pairs(Internal.fonts) do
		font:Scale(combinedScaleFactor)
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