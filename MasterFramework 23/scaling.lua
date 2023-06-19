local Internal = Internal
local min = Include.math.min
local floor = Include.math.floor
local pairs = Include.pairs

relativeScaleFactor = 1

function framework:Dimension(unscaled)
	return function()
		return floor(unscaled * combinedScaleFactor)
	end
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