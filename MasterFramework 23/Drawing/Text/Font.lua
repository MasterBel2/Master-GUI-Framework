local Internal = Internal
Internal.fonts = {}

local ceil = Include.math.ceil
local gl_LoadFont = Include.gl.LoadFont

local function round(number)
	return ceil(number - 0.5)
end

-- https://springrts.com/wiki/Lua_Fonts
function framework:Font(fileName, size, outlineWidth, outlineWeight)
	local key = fileName.."s"..(size or "default").."o"..(outlineWidth or "default").."os"..(outlineWeight or "default")
	local font = Internal.fonts[key]
	local scale

	LogDrawCall("Font (Load)")

	if font == nil then
		font = {
			key = key,
			fileName = fileName,
			outlineWidth = outlineWidth,
			outlineWeight = outlineWeight
		}

		function font:ScaledSize()
			return size * scale
		end

		function font:Scale(newScale)
			if self.glFont then gl_DeleteFont(self.glFont) end
			self.glFont = gl_LoadFont(fileName, round(size * newScale), round((outlineWidth or 0) * newScale), outlineWeight)
			scale = newScale
		end
		-- -- During framework initialisation, `combinedScaleFactor` might not be present. That's perfectly fine, we'll get a value before we need it.
		-- if combinedScaleFactor then 
		-- 	font:Scale(combinedScaleFactor)
		-- end

		Internal.fonts[key] = font
	end

	return font
end

function framework:DeleteFont(font)
	LogDrawCall("Font (Delete)")
	Internal.fonts[font.key] = nil
	gl_DeleteFont(font.glFont)
end