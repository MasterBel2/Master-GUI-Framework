local sin = Include.math.sin

------------------------------------------------------------------------------------------------------------
-- Drawing
------------------------------------------------------------------------------------------------------------

local sinThetaCache = {}
local halfPi = Include.math.pi / 2
local function newSinTheta(cornerRadius)
	local radians = halfPi/cornerRadius
	local sinTheta = {}
	for i = 0, cornerRadius do
		sinTheta[i] = sin(radians * i) * cornerRadius
	end
	sinThetaCache[cornerRadius] = sinTheta
	return sinTheta
end

function Internal.DrawRoundedRect(width, height, cornerRadius, drawFunction, shouldSquareBottomLeft, shouldSquareBottomRight, shouldSquareTopRight, shouldSquareTopLeft, ...)
	LogDrawCall("DrawRoundedRect")

	local centerTopY = height - cornerRadius
	local centerRightX = width - cornerRadius
	
	local sinTheta = sinThetaCache[cornerRadius] or newSinTheta(cornerRadius)
	
	local pastEnd = cornerRadius

	-- Bottom left
	if shouldSquareBottomLeft then
		drawFunction(0, 0, ...)
	else
		for i = 0, cornerRadius do
			drawFunction(cornerRadius - sinTheta[pastEnd-i], cornerRadius - sinTheta[i], ...)
		end
	end

	-- Bottom right
	if shouldSquareBottomRight then
		drawFunction(width, 0, ...)
	else
		for i = 0, cornerRadius do
			drawFunction(centerRightX + sinTheta[i], cornerRadius - sinTheta[pastEnd-i], ...)
		end
	end

	-- Top right
	if shouldSquareTopRight then
		drawFunction(width, height, ...)
	else
		for i = 0, cornerRadius do
			drawFunction(centerRightX + sinTheta[pastEnd-i], centerTopY + sinTheta[i], ...)
		end
	end

	-- Top left
	if shouldSquareTopLeft then
		drawFunction(0, height, ...)
	else
		for i = 0, cornerRadius do
			drawFunction(cornerRadius - sinTheta[i], centerTopY + sinTheta[pastEnd-i], ...)
		end
	end
end

function Internal.DrawRectVertices(width, height, drawFunction)
	LogDrawCall("DrawRectVertices")
	drawFunction(0, 0)
	drawFunction(width, 0)
	drawFunction(width, height)
	drawFunction(0, height)
end


function Internal.DrawRect(drawFunction, x, y, width, height)
	LogDrawCall("DrawRect")
	drawFunction(x, y, x + width, y + height)
end