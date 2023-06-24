local GL_POLYGON = Include.GL.POLYGON

local gl_BeginEnd = Include.gl.BeginEnd
local gl_Color = Include.gl.Color
local gl_Rect = Include.gl.Rect
local gl_Vertex = Include.gl.Vertex

local Internal = Internal

-- Draws a color in a rect.
function framework:Color(r, g, b, a)

	local DrawRoundedRect = Internal.DrawRoundedRect
	local DrawRect = Internal.DrawRect

	local color = { r = r, g = g, b = b, a = a }

	function color:Set()
		gl_Color(self.r, self.g, self.b, self.a)
	end

	local function drawRoundedRectVertex(xOffset, yOffset, x, y)
		gl_Vertex(x + xOffset, y + yOffset)
	end
	
	function color:Draw(rect, x, y, width, height)
		self:Set()
		local cornerRadius = rect.cornerRadius() or 0

		if cornerRadius > 0 then
			local beyondLeft = x <= 0
			local belowBottom = y <= 0
			local beyondRight = (x + width) >= viewportWidth
			local beyondTop = (y + height) >= viewportHeight

			gl_BeginEnd(GL_POLYGON, DrawRoundedRect, width, height, cornerRadius, drawRoundedRectVertex, 
				belowBottom or beyondLeft, beyondRight or belowBottom, beyondRight or beyondTop, beyondLeft or beyondTop, x, y)
		else
			DrawRect(gl_Rect, x, y, width, height)
		end
	end

	return color
end