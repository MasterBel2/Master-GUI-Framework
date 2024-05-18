local GL_LINE_LOOP = Include.GL.LINE_LOOP

local gl_BeginEnd = Include.gl.BeginEnd
local gl_LineWidth = Include.gl.LineWidth
local gl_Vertex = Include.gl.Vertex
local tostring = Include.tostring

local Internal = Internal

-- Draws a border around an object. NOTE: DOES NOT CURRENTLY WORK PROPERLY
function framework:Stroke(width, color, inside)

	local DrawRoundedRect = Internal.DrawRoundedRect
	local DrawRectVertices = Internal.DrawRectVertices

	local stroke = { width = width, color = color, inside = inside or false }

	-- Only used for the draw function, so we don't need to worry about this being used by multiple strokes.
	local cachedX 
	local cachedY
	local cachedWidth
	local cachedHeight
	local cachedCornerRadius

	local function strokePixel(xOffset, yOffset)
		gl_Vertex(cachedX + xOffset, cachedY + yOffset)
	end

	function stroke:Draw(rect, x, y, width, height)
		local strokeWidth = self.width()
		if strokeWidth <= 0 then
			return 
		end

		self.color:Set()
		gl_LineWidth(strokeWidth)

		-- Ceil and floor here prevent half-pixels
		local halfStroke = strokeWidth / 2
		-- if inside then
		-- 	cachedX = floor(x + halfStroke)
		-- 	cachedY = floor(y + halfStroke)
		-- 	cachedWidth = ceil(width - strokeWidth)
		-- 	cachedHeight = ceil(height - strokeWidth)
		-- 	cachedCornerRadius = ceil(max(0, (rect.cornerRadius() or 0) - halfStroke))
		-- else
			cachedX = x + halfStroke
			cachedY = y + halfStroke
			cachedWidth = width - strokeWidth
			cachedHeight = height - strokeWidth
			cachedCornerRadius = rect.cornerRadius()
		-- end

		if cachedCornerRadius > 0 then
			gl_BeginEnd(GL_LINE_LOOP, DrawRoundedRect, cachedWidth, cachedHeight, cachedCornerRadius, strokePixel, 
				x <= 0 or y <= 0, x + cachedWidth >= viewportWidth or y <= 0, x + cachedWidth >= viewportWidth or y + cachedHeight >= viewportHeight, x == 0 or y + cachedHeight >= viewportHeight)
		else
			gl_BeginEnd(GL_LINE_LOOP, DrawRectVertices, cachedWidth, cachedHeight, strokePixel)
		end
	end

	return stroke
end
