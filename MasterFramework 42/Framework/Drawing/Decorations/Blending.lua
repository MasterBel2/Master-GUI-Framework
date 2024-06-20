local GL_SRC_ALPHA = Include.GL.SRC_ALPHA
local GL_ONE_MINUS_SRC_ALPHA = Include.GL.ONE_MINUS_SRC_ALPHA

local gl_BeginEnd = Include.gl.BeginEnd
local gl_Blending = Include.gl.Blending

function framework:Blending(srcMode, dstMode, decorations)
	local blending = {}

	local cachedDecorationCount
	function blending:NeedsRedrawForDrawer(drawer)
		if #self.decorations ~= cachedDecorationCount then return true end
        for i = 1, cachedDecorationCount do
            if i ~= self.decorations[i]._blending_cachedDrawIndex or self.decorations[i]:NeedsRedrawForDrawer(drawer) then
                return true
            end
        end
	end

	function blending:Draw(...)
		gl_Blending(srcMode, dstMode)
		for i=1, #decorations do
			decorations[i]:Draw(...)
		end
		gl_Blending(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
	end

	return blending
end