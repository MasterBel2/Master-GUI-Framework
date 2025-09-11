local GL_POLYGON = Include.GL.POLYGON
local GL_QUADS = Include.GL.QUADS

local gl_BeginEnd = Include.gl.BeginEnd
local gl_Color = Include.gl.Color
local gl_Vertex = Include.gl.Vertex

local Internal = Internal

-- Colors counterclockwise from bottom left
function framework:Gradient(color1, color2, color3, color4)

	local DrawRoundedRect = Internal.DrawRoundedRect

	local gradient = Drawer()

	local color2r; local color2g; local color2b; local color2a
	local color3r; local color3g; local color3b; local color3a
	local color4r; local color4g; local color4b; local color4a
	local color1r; local color1g; local color1b; local color1a

	function gradient:SetColors(newColor1, newColor2, newColor3, newColor4)
		self:NeedsRedraw()
		color1r, color1g, color1b, color1a = newColor1:GetRawValues()
		color2r, color2g, color2b, color2a = newColor2:GetRawValues()
		color3r, color3g, color3b, color3a = newColor3:GetRawValues()
		color4r, color4g, color4b, color4a = newColor4:GetRawValues()
	end
	gradient:SetColors(color1, color2, color3, color4)

	local function DrawRectVertices(x, y, width, height)
		gl_Color(color1r, color1g, color1b, color1a)
		gl_Vertex(x, y)
		gl_Color(color2r, color2g, color2b, color2a)
		gl_Vertex(x + width, y)
		gl_Color(color3r, color3g, color3b, color3a)
		gl_Vertex(x + width, y + height)
		gl_Color(color4r, color4g, color4b, color4a)
		gl_Vertex(x, y + height)
	end

	local function drawRoundedRectVertex(xOffset, yOffset, x, y, width, height)
		local a = xOffset / width; local b = (width - xOffset) / width; local c = yOffset / height; local d = (height - yOffset) / height
		local mult1 = a * c
		local mult2 = b * c
		local mult3 = b * d
		local mult4 = a * d

		gl_Color(
			color1r * mult1 + color2r * mult2 + color3r * mult3 + color4r * mult4,
			color1g * mult1 + color2g * mult2 + color3g * mult3 + color4g * mult4,
			color1b * mult1 + color2b * mult2 + color3b * mult3 + color4b * mult4,
			color1a * mult1 + color2a * mult2 + color3a * mult3 + color4a * mult4
		)
		gl_Vertex(x + xOffset, y + yOffset)
	end

	function gradient:Draw(rect, x, y, width, height)
		self:RegisterDrawingGroup()
		local cornerRadius = rect.cornerRadius() or 0

		if cornerRadius > 0 then
			-- local beyondLeft = x <= 0
			-- local belowBottom = y <= 0
			-- local beyondRight = (x + width) >= viewportWidth
			-- local beyondTop = (y + height) >= viewportHeight

			gl_BeginEnd(GL_POLYGON, DrawRoundedRect, width, height, cornerRadius, drawRoundedRectVertex, belowBottom or beyondLeft, beyondRight or belowBottom, beyondRight or beyondTop, beyondLeft or beyondTop, x, y, width, height)
		else
			gl_BeginEnd(GL_QUADS, DrawRectVertices, x, y, width, height)
		end
	end
	return gradient
end

-- Colors from left to right
function framework:HorizontalGradient(color1, color2) return framework:Gradient(color1, color2, color2, color1) end
-- Colors from bottom to top
function framework:VerticalGradient(color1, color2) return framework:Gradient(color1, color1, color2, color2) end