------------------------------------------------------------------------------------------------------------
-- Metadata
------------------------------------------------------------------------------------------------------------

-- https://github.com/MasterBel2/Master-GUI-Framework

function widget:GetInfo()
	return {
		version = "0.1",
		name = "MasterBel2's GUI Framework",
		desc = "A GUI framework for the SpringRTS Engine",
		author = "MasterBel2",
		date = "October 2020",
		license = "GNU GPL, v2 or later",
		layer = 0,
		enabled = true,
	}
end

------------------------------------------------------------------------------------------------------------
-- Global Access
------------------------------------------------------------------------------------------------------------

local framework = {
	compatabilityVersion = 1,
	scaleFactor = 0,
	elements = {}
}

if not WG.MasterFramework then WG.MasterFramework = {} end

WG.MasterFramework[framework.compatabilityVersion] = framework

------------------------------------------------------------------------------------------------------------
-- Includes
------------------------------------------------------------------------------------------------------------

local max = math.max
local sqrt = math.sqrt

-- Set in widget:Initialize
local viewportWidth = 0
local viewportHeight = 0

local gl_BeginEnd = gl.BeginEnd
local gl_CallList = gl.CallList
local gl_Color = gl.Color
local gl_CreateList = gl.CreateList
local gl_LoadFont = gl.LoadFont
local gl_DeleteList = gl.DeleteList
local gl_DeleteFont = gl.DeleteFont
local gl_Rect = gl.Rect
local gl_TexCoord = gl.TexCoord
local gl_TexRect = gl.TexRect
local gl_Text = gl.Text
local gl_Texture = gl.Texture
local gl_Vertex = gl.Vertex

local GL_POLYGON = GL.POLYGON

------------------------------------------------------------------------------------------------------------
-- Drawing
------------------------------------------------------------------------------------------------------------

local function DrawRoundedRect(rect, drawFunction, shouldRoundBottomLeft, shouldRoundBottomRight, shouldRoundTopRight, shouldRoundTopLeft)
	local cornerRadius = rect.cornerRadius

	local radiusSquared = cornerRadius * cornerRadius

	local centerBottomY = cornerRadius
	local centerTopY = rect.height - cornerRadius
	local centerRightX = rect.width - cornerRadius
	local centerLeftX = cornerRadius

	local function vertexPosition(x) return sqrt(radiusSquared - (x * x)) end

	-- Bottom left
	if shouldRoundBottomLeft or false then
		drawFunction(0, 0)
	else
		for x = -cornerRadius, 0 do
			drawFunction(centerLeftX + x, centerBottomY - vertexPosition(x))
		end
	end

	-- Bottom right
	if shouldRoundBottomRight or false then
		drawFunction(rect.width, 0)
	else
		for x = 0, cornerRadius do
			drawFunction(centerRightX + x, centerBottomY - vertexPosition(x))
		end
	end

	-- Top right
	if shouldRoundTopRight or false then
		drawFunction(rect.width, rect.height)
	else
		for x = -cornerRadius, 0 do
			drawFunction(centerRightX - x, centerTopY + vertexPosition(x))
		end
	end

	-- Top left
	if shouldRoundTopLeft or false then
		drawFunction(0, rect.height)
	else
		for x = 0, cornerRadius do
			drawFunction(centerLeftX - x, centerTopY + vertexPosition(x))
		end
	end 
end


local function DrawRect(rect, drawFunction, x, y)
	drawFunction(x, y, rect.width, rect.height)
end

local function DrawDecorations(target, x, y)
	for _,decoration in pairs(target.decorations) do
		decoration:Draw(target, x, y)
	end
end

------------------------------------------------------------------------------------------------------------
-- Basic components
------------------------------------------------------------------------------------------------------------

-- A component of fixed size.
function framework:Rect(width, height, cornerRadius, decorations)
	local rect = { width = width, height = height, cornerRadius = cornerRadius or 0, decorations = decorations or {} }

	function rect:Draw(x, y) DrawDecorations(rect, x, y) end

	function rect:Layout(availableWidth, availableHeight) end

	return rect
end

-- Draws a color in a rect.
function framework:Color(r, g, b, a)
	local color = { r = r, g = g, b = b, a = a }
	
	function color:Draw(rect, x, y)
		gl_Color(color.r, color.g, color.b, color.a)
		if (rect.cornerRadius or 0) > 0 then
			gl_BeginEnd(GL_POLYGON, DrawRoundedRect, rect, function(xOffset, yOffset) gl_Vertex(x + xOffset, y + yOffset) end, 
				x <= 0 or y <= 0, x + rect.width >= viewportWidth or y <= 0, x + rect.width >= viewportWidth or y + rect.height >= viewportHeight, x == 0 or y + rect.height >= viewportHeight)
		else
			DrawRect(rect, gl_Rect, x, y)
		end
	end

	return color
end

-- Draws an image in a rect.
function framework:Image(fileName)
	local image = { fileName = fileName }

	function image:Draw(rect, x, y)
		gl_Texture(image.fileName)
		if frame.cornerRadius > 0 then
			DrawRoundedRect(rect, function(xOffset, yOffset)
				gl_TexCoord(xOffset / rect.width, yOffset / rect.height)
				gl_Vertex(x + xOffset, y + yOffset)
			end)
		else
			DrawRect(rect, gl_TexRect, x, y)
		end
	end

	return image
end

------------------------------------------------------------------------------------------------------------
-- Text
------------------------------------------------------------------------------------------------------------

local fonts = {}

function framework:Font(fileName, size, outline, outlineStrength)
	local key = fileName.."s"..(size or "default").."o"..(outline or "default").."os"..(outlineStrength or "default")
	local font = fonts[key]

	if font == nil then
		font = {
			glFont = gl_LoadFont(fileName, size, outline, outlineStrength),
			key = key,
			fileName = fileName,
			size = size,
			outline = outline,
			outlineStrength = outlineStrength
		}

		fonts[key] = font
	end

	return font
end

local defaultFont = framework:Font("LuaUI/Fonts/FreeSansBold.otf", 44)
framework.color = {
	white = framework:Color(1, 1, 1, 1)
}

-- Auto-sizing text
function framework:Text(string, color, font)
	local text = { width = 0, height = 0, string = string, color = color or framework.color.white, font = font or defaultFont }

	function text:Layout(availableHeight, availableWidth)
		local font = self.font
		width = font.glFont:GetTextWidth(self.string) * font.size
		height = font.glFont:GetTextWidth(self.string) * font.size
	end

	function text:Draw(x, y)
		gl_Color(self.color)
		gl_Text(self.string, x, y, self.font.size, "")
	end

	return text
end

function framework:DeleteFont(font)
	fonts[font.key] = nil
	gl_DeleteFont(font.glFont)
end

------------------------------------------------------------------------------------------------------------
-- Interaction
------------------------------------------------------------------------------------------------------------

framework.interactions = { mouseUp = 0, mouseDown = 1, scrollUp = 2, scrollDown = 3, mouseEnter = 4, mouse }
framework.responders = {}

for _,interaction in pairs(framework.interactions) do
	framework.responders[interaction] = {}
end

function framework:Responder(rect, interaction, action)
	-- Don't add to the responders array yet.
	-- But as an example I will just now.
	table.insert(responders[interaction], { action, rect })

	-- Or maybe it's okay …
end

------------------------------------------------------------------------------------------------------------
-- Positioning
------------------------------------------------------------------------------------------------------------

framework.xAnchor = { left = 0, center = 0.5, right = 1 }
framework.yAnchor = { bottom = 0, center = 0.5, top = 1 }

function framework:MarginAroundRect(rect, left, top, right, bottom, decorations, cornerRadius)
	local margin = { width = 0, height = 0, rect = rect, left = left, top = top, right = right, bottom = bottom, decorations = decorations or {}, cornerRadius = cornerRadius or 0, }
	
	function margin:Layout(availableWidth, availableHeight)
		local horizontal = margin.left + margin.right -- May be more performant to do left right top bottom – not sure though
		local vertical = margin.top + margin.bottom

		rect:Layout(availableWidth - horizontal, availableHeight - vertical)
		margin.width = rect.width + horizontal
		margin.height = rect.height + horizontal
	end

	function margin:Draw(x, y)
		DrawDecorations(margin, x, y)
		margin.rect:Draw(x + margin.left, y + margin.bottom)
	end

	return margin
end

function framework:FrameOfReference(xAnchor, yAnchor, body)
	local frame = { xAnchor = xAnchor, yAnchor = yAnchor, body = body, width = 0, height = 0 }

	function frame:Layout(availableWidth, availableHeight)
		body:Layout(availableWidth, availableHeight)
		frame.width = availableWidth
		frame.height = availableHeight
	end

	function frame:Draw(x, y)
		local xAnchor = frame.xAnchor
		local yAnchor = frame.yAnchor
		body:Draw(frame.width * xAnchor - body.width * xAnchor, frame.height * yAnchor - body.height * yAnchor)
	end

	return frame
end

------------------------------------------------------------------------------------------------------------
-- Grouping
------------------------------------------------------------------------------------------------------------

function framework:VerticalStack(contents, spacing, xAnchor)
	local verticalStack = { members = contents, height = 0, width = 0, xAnchor = xAnchor, spacing = spacing}

	function verticalStack:Layout(availableWidth, availableHeight)
		local elapsedDistance = 0
		local maxWidth = 0
		local members = verticalStack.members
		
		for _, member in pairs(members) do
			member:Layout(availableWidth, availableHeight - elapsedDistance)
			member.vStackCachedY = elapsedDistance
			elapsedDistance = elapsedDistance + member.height + verticalStack.spacing
			maxWidth = max(maxWidth, member.width)
		end

		for _, member in pairs(members) do
			member.vStackCachedX = maxWidth * verticalStack.xAnchor - member.width * verticalStack.xAnchor
		end

		verticalStack.width = maxWidth

		if #members == 0 then 
			verticalStack.height = elapsedDistance 
		else
			 verticalStack.height = elapsedDistance - verticalStack.spacing
		end
	end

	function verticalStack:Draw(x, y)
		for _, member in pairs(verticalStack.members) do
			member:Draw(x + member.vStackCachedX, y + member.vStackCachedY)
		end
	end
	return verticalStack
end

function framework:StackInPlace(contents, xAnchor, yAnchor)
	local stackInPlace = { members = contents, height = 0, width = 0, xAnchor = xAnchor, yAnchor = yAnchor, invalidated = true }

	function stackInPlace:Layout(availableWidth, availableHeight)
		local maxWidth = 0
		local maxHeight = 0
		local members = stackInPlace.members

		for _, member in pairs(members) do
			member:Layout(availableWidth, availableHeight)
			maxWidth = max(maxWidth, member.width)
			maxHeight = max(maxHeight, member.height)
		end

		local xAnchor = stackInPlace.xAnchor
		local yAnchor = stackInPlace.yAnchor

		for _, member in pairs(members) do
			member.stackInPlaceCachedX = maxWidth * xAnchor - member.width * xAnchor
			member.stackInPlaceCachedY = maxHeight * yAnchor - member.height * yAnchor
		end

		stackInPlace.width = maxWidth
		stackInPlace.height = maxHeight
		stackInPlace.invalidated = false
	end

	function stackInPlace:Draw(x, y)
		for _, member in pairs(stackInPlace.members) do
			member:Draw(x + member.stackInPlaceCachedX, y + member.stackInPlaceCachedY)
		end
	end
	return stackInPlace
end

function framework:HorizontalStack(members, spacing, yAnchor)
	local horizontalStack = { yAnchor = yAnchor, spacing = spacing, members = members, height = 0, width = 0 }

	function horizontalStack:Layout(availableWidth, availableHeight)
		local elapsedDistance = 0
		local maxHeight = 0
		local members = horizontalStack.members

		for _, member in pairs(members) do
			member:Layout(availableWidth - elapsedDistance, availableHeight)
			member.hStackCachedX = elapsedDistance
			elapsedDistance = elapsedDistance + member.width + horizontalStack.spacing
			maxHeight = max(member.height, maxHeight)
		end

		for _, member in pairs(members) do
			member.hStackCachedY = maxHeight * horizontalStack.yAnchor - member.height * horizontalStack.yAnchor
		end

		if #members == 0 then 
			horizontalStack.width = elapsedDistance 
		else
			 horizontalStack.width = elapsedDistance - horizontalStack.spacing
		end
		
		horizontalStack.height = maxHeight
	end

	function horizontalStack:Draw(x, y)
		for _, member in pairs(horizontalStack.members) do
			member:Draw(x + member.hStackCachedX, y + member.hStackCachedY)
		end
	end
	
	return horizontalStack
end

------------------------------------------------------------------------------------------------------------
-- Framework
------------------------------------------------------------------------------------------------------------

function framework:Rasterizer(body)
	local rasterizer = { body = body, invalidated = true, width = 0, height = 0 }

	function rasterizer:Layout(availableWidth, availableHeight)
		if rasterizer.invalidated then
			body:Layout(availableWidth, availableHeight)
			rasterizer.width = body.width
			rasterizer.height = body.height
		end
	end

	function rasterizer:Draw(x, y)
		if rasterizer.invalidated then
			rasterizer.invalidated = false
			gl_DeleteList(rasterizer.drawList)
			rasterizer.drawList = gl_CreateList(function() rasterizer.body:Draw(x, y) end)
		end
		gl_CallList(rasterizer.drawList)
	end

	return rasterizer
end

------------------------------------------------------------------------------------------------------------
-- Callins
------------------------------------------------------------------------------------------------------------

function widget:Initialize()
	local viewSizeX,viewSizeY = Spring.GetViewGeometry()
	viewportWidth = viewSizeX
	viewportHeight = viewSizeY
end

function widget:DrawScreen()
	for _,element in pairs(framework.elements) do
		element:Layout(viewportWidth, viewportHeight)
		element:Draw(0, 0)
	end
	viewportDidChange = false
end

function widget:ViewResize(viewSizeX, viewSizeY)
	if viewportWidth ~= viewSizeX or viewportHeight ~= viewSizeY then
		viewportWidth = viewSizeX
		viewportHeight = viewSizeY
		viewportDidChange = true
	end
end