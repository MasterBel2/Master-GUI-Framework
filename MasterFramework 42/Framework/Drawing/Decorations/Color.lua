local GL_POLYGON = Include.GL.POLYGON

local gl_BeginEnd = Include.gl.BeginEnd
local gl_Color = Include.gl.Color
local gl_Rect = Include.gl.Rect
local gl_Vertex = Include.gl.Vertex
local pairs = Include.pairs

local Internal = Internal

--[[
 	`Color` is a non-overriding extension of `Drawer` that draws a fill color in a rect.

	Methods:
	 - `color:Set()` Instructs GL to apply the color.
	 - `color:SetRawValues(r, g, b, a)`: Sets the RGBA values to be used.
	 - `color:GetRawValues()`: Returns `r, g, b, a`.
]]
function framework:Color(r, g, b, a)

	local DrawRoundedRect = Internal.DrawRoundedRect
	local DrawRect = Internal.DrawRect

	local color = Drawer()

	function color:Set()
		self:RegisterDrawingGroup()
		gl_Color(r, g, b, a)
	end
	function color:SetRawValues(...)
		self:NeedsRedraw()
		r, g, b, a = ...
	end
	function color:GetRawValues()
		return r, g, b, a
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