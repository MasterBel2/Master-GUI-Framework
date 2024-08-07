local GL_POLYGON = Include.GL.POLYGON

local gl_BeginEnd = Include.gl.BeginEnd
local gl_Color = Include.gl.Color
local gl_Rect = Include.gl.Rect
local gl_Vertex = Include.gl.Vertex
local pairs = Include.pairs
local error = Include.error

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

	if not r or not g or not b or not a then 
		error("Arguments to framework:Color are incomplete! r: " .. (r or "nil") .. ", g: " .. (g or "nil") .. ", b: " .. (b or "nil") .. ", a: " .. (a or "nil"))
	end

	function color:Set()
		self:RegisterDrawingGroup()
		gl_Color(r, g, b, a)
	end
	function color:SetRawValues(_r, _g, _b, _a)
		if not _r or not _g or not _b or not _a then 
			error("Arguments to color:SetRawValues(r, g, b, a) are incomplete! r: " .. (r or "nil") .. ", g: " .. (g or "nil") .. ", b: " .. (b or "nil") .. ", a: " .. (a or "nil")) 
		end
		self:NeedsRedraw()
		r = _r
		g = _g
		b = _b
		a = _a
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