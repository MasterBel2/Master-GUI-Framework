local GL_SRC_ALPHA = Include.GL.SRC_ALPHA
local GL_ONE_MINUS_SRC_ALPHA = Include.GL.ONE_MINUS_SRC_ALPHA

local gl_BeginEnd = Include.gl.BeginEnd
local gl_Blending = Include.gl.Blending

function framework:Blending(srcMode, dstMode, decorations)
	local blending = {}

	function blending:Draw(...)
		gl_Blending(srcMode, dstMode)
		for i=1, #decorations do
			decorations[i]:Draw(...)
		end
		gl_Blending(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
	end

	return blending
end