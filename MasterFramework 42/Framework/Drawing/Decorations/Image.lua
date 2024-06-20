local GL_POLYGON = Include.GL.POLYGON

local gl_TexCoord = Include.gl.TexCoord
local gl_Texture = Include.gl.Texture
local gl_TexRect = Include.gl.TexRect
local gl_BeginEnd = Include.gl.BeginEnd
local gl_Vertex = Include.gl.Vertex

local Internal = Internal

-- Draws an image in a rect. The image is immutable, that is you cannot change the file.
function framework:Image(fileName, tintColor)
    
    local DrawRoundedRect = Internal.DrawRoundedRect
    local DrawRect = Internal.DrawRect

	local image = { fileName = fileName, tintColor = tintColor or framework.color.white }

	local function drawRoundedRectVertex(xOffset, yOffset, x, y, width, height)
		gl_TexCoord(xOffset / width, 1 - (yOffset / height))
		gl_Vertex(x + xOffset, y + yOffset)
	end

	function image:NeedsRedrawForDrawer(drawer)
		return self.tintColor:NeedsRedrawForDrawer(drawer)
	end

	function image:Draw(rect, x, y, width, height)
		self.tintColor:Set()
		gl_Texture(self.fileName)
		
		if rect.cornerRadius() > 0 then
			gl_BeginEnd(GL_POLYGON, DrawRoundedRect, width, height, rect.cornerRadius(), drawRoundedRectVertex, false, false, false, false, x, y, width, height)
		else
			DrawRect(gl_TexRect, x, y, width, height)
		end
		gl_Texture(false)
	end

	return image
end