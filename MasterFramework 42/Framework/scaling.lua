local Internal = Internal
local min = Include.math.min
local floor = Include.math.floor
local pairs = Include.pairs
local setmetatable = Include.setmetatable

relativeScaleFactor = 1

Internal.autoScalingDimensions = {}

function framework:Dimension(generator)
	local dimension = { registeredDrawGroups = {} }
	local cachedValue

	function dimension.ValueHasChanged()
		return floor(generator()) == cachedValue
	end

	function dimension.ComputedValue()
		if Internal.activeDrawingGroup then
			Internal.activeDrawingGroup.dimensions[dimension] = true
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
end

function framework:SetScale(newScale)
	updateScreenEnvironment(viewportWidth, viewportHeight, newScale)
end