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
	compatabilityVersion = 3,
	scaleFactor = 0,
	events = { mousePress = "mousePress", mouseWheel = "mouseWheel", mouseOver = "mouseOver" } -- mouseMove = "mouseMove", mouseRelease = "mouseRelease" (Handled differently to other events – see dragListeners)
}

if not WG.MasterFramework then WG.MasterFramework = {} end

WG.MasterFramework[framework.compatabilityVersion] = framework

------------------------------------------------------------------------------------------------------------
-- Internal Access
------------------------------------------------------------------------------------------------------------

local hasCheckedElementBelowMouse = false

local events = framework.events

local elements = {}
local elementsByLayer
local elementCount = 0

local keyElement
local elementBelowMouse

local activeElement

-- A drag listener must assign itself to the index of the button that was pressed, and must implement the 
-- functions MouseRelease(x, y) and MouseMove(x, y, dx, dy). Listeners will be removed automatically on 
-- mouse release
local dragListeners = {}

local conflicts = 0

-- Adds an element to be drawn.
--
-- Parameters:
--  - body: A component as specified in the "Basic Components" section of this file.
function framework:InsertElement(body, preferredKey, deselectAction)
	local key

	-- Create element

	local function nullFunction() end

	local element = { body = body, primaryFrame = nil, tooltips = {}, baseResponders = {}, deselect = deselectAction or function() end}
	for _,event in pairs(events) do
		element.baseResponders[event] = { responders = {}, action = nullFunction }
	end

	-- Create key

	if elements[preferredKey] == nil then
		key = preferredKey
	else
		conflicts = conflicts + 1
		key = preferredKey..conflicts
		Spring.Echo("Key " .. preferredKey .. " has already been taken! Assigning key " .. key .. " instead.")
	end

	elements[key] = element
	return key
end

function framework:RemoveElement(key) 
	if key ~= nil then
		elements[key] = nil 
	else
		Spring.Echo("[Master GUI Framework] Could not remove element: Key is nill!")
	end
end

------------------------------------------------------------------------------------------------------------
-- Includes
------------------------------------------------------------------------------------------------------------

local insert = table.insert

local ceil = math.ceil
local cos = math.cos
local floor = math.floor
local max = math.max
local pi = math.pi
local sin = math.sin
local sqrt = math.sqrt

-- Set in widget:Initialize
local viewportWidth = 0
local viewportHeight = 0

local gl_BeginEnd = gl.BeginEnd
local gl_CallList = gl.CallList
local gl_Color = gl.Color
local gl_CreateList = gl.CreateList
local gl_LineWidth = gl.LineWidth
local gl_LoadFont = gl.LoadFont
local gl_DeleteList = gl.DeleteList
local gl_DeleteFont = gl.DeleteFont
local gl_PushMatrix = gl.PushMatrix
local gl_PopMatrix = gl.PopMatrix
local gl_Rect = gl.Rect
local gl_TexCoord = gl.TexCoord
local gl_TexRect = gl.TexRect
local gl_Text = gl.Text
local gl_Texture = gl.Texture
local gl_Translate = gl.Translate
local gl_Vertex = gl.Vertex

local GL_LINE_LOOP = GL.LINE_LOOP
local GL_POLYGON = GL.POLYGON

------------------------------------------------------------------------------------------------------------
-- Helper Methods
------------------------------------------------------------------------------------------------------------

local function PointIsInRect(x, y, rectX, rectY, rectWidth, rectHeight)
	return x >= rectX and y >= rectY and x <= rectX + rectWidth and y <= rectY + rectHeight
end

------------------------------------------------------------------------------------------------------------
-- Drawing
------------------------------------------------------------------------------------------------------------

local sinThetaCache = {}
local function newSinTheta(cornerRadius)
	local halfPi = pi/2/cornerRadius
	local sinTheta = {}
	for i = 1, cornerRadius do
		insert(sinTheta, sin(halfPi * i) * cornerRadius)
	end
	sinThetaCache[cornerRadius] = sinTheta
	return sinTheta
end
local function DrawRoundedRect(width, height, cornerRadius, drawFunction, shouldSquareBottomLeft, shouldSquareBottomRight, shouldSquareTopRight, shouldSquareTopLeft)
	local centerTopY = height - cornerRadius
	local centerRightX = width - cornerRadius
	
	local sinTheta = sinThetaCache[cornerRadius] or newSinTheta(cornerRadius)
	
	local pastEnd = cornerRadius + 1

	-- Bottom left
	if shouldSquareBottomLeft then
		drawFunction(0, 0)
	else
		for i = 1, cornerRadius do
			drawFunction(cornerRadius - sinTheta[pastEnd-i], cornerRadius - sinTheta[i])
		end
	end

	-- Bottom right
	if shouldSquareBottomRight then
		drawFunction(width, 0)
	else
		for i = 1, cornerRadius do
			drawFunction(centerRightX + sinTheta[i], cornerRadius - sinTheta[pastEnd-i])
		end
	end

	-- Top right
	if shouldSquareTopRight then
		drawFunction(width, height)
	else
		for i = 1, cornerRadius do
			drawFunction(centerRightX + sinTheta[pastEnd-i], centerTopY + sinTheta[i])
		end
	end

	-- Top left
	if shouldSquareTopLeft then
		drawFunction(0, height)
	else
		for i = 1, cornerRadius do
			drawFunction(cornerRadius - sinTheta[i], centerTopY + sinTheta[pastEnd-i])
		end
	end
end

local function DrawRectVertices(width, height, drawFunction)
	drawFunction(0, 0)
	drawFunction(width, 0)
	drawFunction(width, height)
	drawFunction(0, height)
end


local function DrawRect(rect, drawFunction, x, y)
	drawFunction(x, y, x + rect.width, y + rect.height)
end

------------------------------------------------------------------------------------------------------------
-- Decorations
------------------------------------------------------------------------------------------------------------

-- Colors counterclockwise from bottom left
function framework:Gradient(color1, color2, color3, color4)
	local gradient = { color1 = color1, color2 = color2, color3 = color3, color4 = color4 }

	function gradient:Draw(rect, x, y)
		local width = rect.width
		local height = rect.height
		local cornerRadius = rect.cornerRadius or 0

		local color1 = self.color1; local color2 = self.color2; local color3 = self.color3; local color4 = self.color4; 
		local color1r = color1.r; local color1g = color1.g; local color1b = color1.b; local color1a = color1.a
		local color2r = color2.r; local color2g = color2.g; local color2b = color2.b; local color2a = color2.a
		local color3r = color3.r; local color3g = color3.g; local color3b = color3.b; local color3a = color3.a
		local color4r = color4.r; local color4g = color4.g; local color4b = color4.b; local color4a = color4.a

		local function drawRoundedRectVertex(xOffset, yOffset)
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
		local function drawRectVertecies()
			gl_Color(color1r, color1g, color1b, color1a)
			gl_Vertex(x, y)
			gl_Color(color2r, color2g, color2b, color2a)
			gl_Vertex(x + width, y)
			gl_Color(color3r, color3g, color3b, color3a)
			gl_Vertex(x + width, y + height)
			gl_Color(color4r, color4g, color4b, color4a)
			gl_Vertex(x, y + height)
		end

		if cornerRadius > 0 then
			local beyondLeft = x <= 0
			local belowBottom = y <= 0
			local beyondRight = (x + width) >= viewportWidth
			local beyondTop = (y + height) >= viewportHeight

			gl_BeginEnd(GL_POLYGON, DrawRoundedRect, width, height, cornerRadius, drawRoundedRectVertex, belowBottom or beyondLeft, beyondRight or belowBottom, beyondRight or beyondTop, beyondLeft or beyondTop)
		else
			gl_BeginEnd(GL_QUADS, drawRectVertecies)
		end
	end
	return gradient
end

-- Colors from left to right
function framework:HorizontalGradient(color1, color2) return framework:Gradient(color1, color2, color2, color1) end
-- Colors from bottom to top
function framework:VerticalGradient(color1, color2) return framework:Gradient(color1, color1, color2, color2) end

-- Draws a color in a rect.
function framework:Color(r, g, b, a)
	local color = { r = r, g = g, b = b, a = a }

	function color:Set()
		gl_Color(self.r, self.g, self.b, self.a)
	end
	
	function color:Draw(rect, x, y)
		self:Set()
		local cornerRadius = rect.cornerRadius or 0

		local function drawRoundedRectVertex(xOffset, yOffset)
			gl_Vertex(x + xOffset, y + yOffset)
		end

		if cornerRadius > 0 then
			local width = rect.width
			local height = rect.height

			local beyondLeft = x <= 0
			local belowBottom = y <= 0
			local beyondRight = (x + width) >= viewportWidth
			local beyondTop = (y + height) >= viewportHeight

			gl_BeginEnd(GL_POLYGON, DrawRoundedRect, width, height, cornerRadius, drawRoundedRectVertex, 
				belowBottom or beyondLeft, beyondRight or belowBottom, beyondRight or beyondTop, beyondLeft or beyondTop)
		else
			DrawRect(rect, gl_Rect, x, y)
		end
	end

	return color
end

-- Draws a border around an object. NOTE: DOES NOT CURRENTLY WORK PROPERLY
function framework:Stroke(width, color, inside)
	local stroke = { width = width, color = color, inside = inside or false }

	-- Only used for the draw function, so we don't need to worry about this being used by multiple strokes.
	local firstX
	local firstY
	local cachedX 
	local cachedY
	local cachedWidth
	local cachedHeight
	local cachedCornerRadius

	local function strokePixel(xOffset, yOffset)
		gl_Vertex(cachedX + xOffset, cachedY + yOffset)
	end

	function stroke:Draw(rect, x, y)
		local strokeWidth = self.width

		color:Set()
		gl_LineWidth(strokeWidth)
		
		-- Ceil and floor here prevent half-pixels
		local halfStroke = strokeWidth / 2
		if inside then
			cachedX = floor(x + halfStroke)
			cachedY = floor(y + halfStroke)
			cachedWidth = ceil(rect.width - strokeWidth)
			cachedHeight = ceil(rect.height - strokeWidth)
			cachedCornerRadius = ceil(max(0, (rect.cornerRadius or 0) - halfStroke))
		else
			cachedX = floor(x - halfStroke)
			cachedY = floor(y - halfStroke)
			cachedWidth = ceil(rect.width + strokeWidth)
			cachedHeight = ceil(rect.height + strokeWidth)
			cachedCornerRadius = ceil(max(0, (rect.cornerRadius or 0) + halfStroke))
		end

		if cachedCornerRadius > 0 then
			gl_BeginEnd(GL_LINE_LOOP, DrawRoundedRect, cachedWidth, cachedHeight, cachedCornerRadius, strokePixel, 
				x <= 0 or y <= 0, x + cachedWidth >= viewportWidth or y <= 0, x + cachedWidth >= viewportWidth or y + cachedHeight >= viewportHeight, x == 0 or y + cachedHeight >= viewportHeight)
		else
			gl_BeginEnd(GL_LINE_LOOP, DrawRectVertices, cachedWidth, cachedHeight, strokePixel)
		end
	end

	return stroke
end

-- Draws an image in a rect. The image is immutable, that is you cannot change the file.
function framework:Image(fileName, tintColor)
	local image = { fileName = fileName, tintColor = tintColor or framework.color.white }

	function image:Draw(rect, x, y)
		self.tintColor:Set()
		gl_Texture(self.fileName)

		local width = rect.width
		local height = rect.height

		local function drawRoundedRectVertex(xOffset, yOffset)
			gl_TexCoord(xOffset / width, yOffset / height)
			gl_Vertex(x + xOffset, y + yOffset)
		end
		
		if rect.cornerRadius > 0 then
			gl_BeginEnd(GL_POLYGON, DrawRoundedRect, width, height, rect.cornerRadius, drawRoundedRectVertex)
		else
			DrawRect(rect, gl_TexRect, x, y)
		end
		gl_Texture(false)
	end

	return image
end

------------------------------------------------------------------------------------------------------------
-- Basic Components
------------------------------------------------------------------------------------------------------------

local nextID = 0
function framework:PrimaryFrame(body)
	local primaryFrame = { body = body, width = 0, height = 0, cachedX = 0, cachedY = 0 }

	function primaryFrame:Layout(availableWidth, availableHeight)
		self.body:Layout(availableWidth, availableHeight)
		self.width = body.width
		self.height = body.height
	end

	function primaryFrame:Draw(x, y)
		self.body:Draw(x, y)
		activeElement.primaryFrame = self
		self.cachedX = x
		self.cachedY = y
	end

	return primaryFrame
end

-- A component of fixed size.
function framework:Rect(width, height, cornerRadius, decorations)
	local rect = { width = width, height = height, cornerRadius = cornerRadius or 0, decorations = decorations or {} }

	function rect:Draw(x, y)
		local decorations = self.decorations
		for i = 1, #decorations do
			decorations[i]:Draw(self, x, y)
		end
	end

	function rect:Layout() end

	return rect
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

framework.defaultFont = framework:Font("LuaUI/Fonts/FreeSansBold.otf", 12)
framework.color = {
	white = framework:Color(1, 1, 1, 1),
	red = framework:Color(1, 0, 0, 1),
	green = framework:Color(0, 1, 0, 1),
	blue = framework:Color(0, 1, 0, 1)
}

-- Auto-sizing text
function framework:Text(string, color, constantWidth, constantHeight, font)
	local text = { width = 0, height = 0, string = string, color = color or framework.color.white, constantWidth = constantWidth, font = font or framework.defaultFont }

	function text:Layout(availableHeight, availableWidth)
		local font = self.font; local fontSize = font.size; local glFont = font.glFont
		local string = self.string
		self.width = constantWidth or (glFont:GetTextWidth(self.string) * fontSize)
		self.height = constantHeight or (glFont:GetTextHeight(self.string) * fontSize)
	end

	function text:Draw(x, y)
		self.color:Set()
		gl_Text(self.string, x, y, self.font.size, "")
	end

	return text
end

function framework:DeleteFont(font)
	fonts[font.key] = nil
	gl_DeleteFont(font.glFont)
end

------------------------------------------------------------------------------------------------------------
-- User Interaction
------------------------------------------------------------------------------------------------------------

-- NOTE: Rasterizers are compatible with Responders IF AND ONLY IF the rasterizer DOES NOT APPLY TRANSLATION

function framework:MousePressResponder(rect, downAction, moveAction, releaseAction)
	local responder = self:Responder(rect, events.mousePress, nil)
	local function action(x, y, button)
		responder.button = button
		dragListeners[button] = responder
		return downAction(x, y, button)
	end
	responder.action = action

	function responder:MouseMove(x, y, dx, dy)
		moveAction(x, y, dx, dy)
	end
	function responder:MouseRelease(x, y)
		dragListener[self.button] = nil
		releaseAction(x, y)
	end

	return responder
end

local responderID = 0
local activeResponders = {}
for _, event in pairs(events) do
	activeResponders[event] = {}
end
function framework:Responder(rect, event, action)
	local responder = { rect = rect, action = action, width = 0, height = 0, cachedX = 0, cachedY = 0, responders = {} }
	local id = responderID -- immutable, and will be captured by the functions. Don't need to store it in the table
	-- Event is similarly immutable, so we don't need to store that in the table either.
	responderID = responderID + 1

	function responder:Layout(...)
		local rect = self.rect
		rect:Layout(...)
		self.width = rect.width
		self.height = rect.height
	end

	function responder:Draw(x, y)
		-- Parent keep track of the order of responders, and use that to decide who gets the interactions first
		local previousActiveResponder = activeResponders[event]
		insert(previousActiveResponder.responders, 1, self)
		self.parent = previousActiveResponder

		activeResponders[event] = self
		self.responders = {}
		self.rect:Draw(x, y)
		activeResponders[event] = previousActiveResponder

		-- Spring.Echo(x .. ", " .. y .. ", " .. self.width .. ", " .. self.height)
		
		self.cachedX = x
		self.cachedY = y
	end

	return responder
end

local tooltipID = 0
local activeTooltip
function framework:Tooltip(rect, description)
	local tooltip = { rect = rect, description = description, width = 0, height = 0, cachedX = 0, cachedY = 0, tooltips = {} }
	local id = tooltipID -- like for responder, this is immutable so doesn't need to be stored in the table
	tooltipID = tooltipID + 1

	function tooltip:Layout(...)
		rect:Layout(...)
		self.width = rect.width
		self.height = rect.height
	end
	function tooltip:Draw(x, y)
		local previousActiveTooltip = activeTooltip
		local parent = self.parent
		if previousActiveTooltip ~= parent then
			if parent then
				parent.tooltips[id] = nil
			end
			previousActiveTooltip.tooltips[id] = self
			self.parent = previousActiveTooltip
		end
		activeTooltip = self

		self.rect:Draw(x, y)
		activeTooltip = previousActiveTooltip
		self.cachedX = x
		self.cachedY = y
	end
	return tooltip
end

------------------------------------------------------------------------------------------------------------
-- Positioning
------------------------------------------------------------------------------------------------------------

framework.xAnchor = { left = 0, center = 0.5, right = 1 }
framework.yAnchor = { bottom = 0, center = 0.5, top = 1 }

-- Positions a rect relative to another rect, with no impact on the layout of the original rect.
function framework:RectAnchor(rectToAnchorTo, anchoredRect, xAnchor, yAnchor)
	local rectAnchor = { rectToAnchorTo = rectToAnchorTo, anchoredRect = anchoredRect, xAnchor = xAnchor, yAnchor = yAnchor }

	function rectAnchor:Layout(availableWidth, availableHeight)
		local rectToAnchorTo = self.rectToAnchorTo
		rectToAnchorTo:Layout(availableWidth, availableHeight)
		self.anchoredRect:Layout(availableWidth, availableHeight)

		self.width = rectToAnchorTo.width
		self.height = rectToAnchorTo.height
	end

	function rectAnchor:Draw(x, y)
		local rectToAnchorTo = self.rectToAnchorTo
		local anchoredRect = self.anchoredRect
		rectToAnchorTo:Draw(x, y)
		anchoredRect:Draw(x + (rectToAnchorTo.width - anchoredRect.width) * self.xAnchor, y + (rectToAnchorTo.height - anchoredRect.height) * self.yAnchor)
	end
	return rectAnchor
end

function framework:ConstantOffsetAnchor(rectToAnchorTo, anchoredRect, xOffset, yOffset)
	local anchor = { rectToAnchorTo = rectToAnchorTo, anchoredRect = anchoredRect, xOffset = xOffset, yOffset = yOffset }

	function anchor:Layout(availableWidth, availableHeight)
		local rectToAnchorTo = self.rectToAnchorTo
		rectToAnchorTo:Layout(availableWidth, availableHeight)
		self.anchoredRect:Layout(availableWidth, availableHeight)
		
		self.width = rectToAnchorTo.width
		self.height = rectToAnchorTo.height
	end

	function anchor:Draw(x, y)
		local rectToAnchorTo = self.rectToAnchorTo
		local anchoredRect = self.anchoredRect
		rectToAnchorTo:Draw(x, y)
		anchoredRect:Draw(x + self.xOffset, y + self.yOffset)
	end
	return anchor
end

function framework:MarginAroundRect(rect, left, top, right, bottom, decorations, cornerRadius, shouldRasterize)
	local margin = { width = 0, height = 0, rect = rect, left = left, top = top, right = right, bottom = bottom, decorations = decorations or {}, cornerRadius = cornerRadius or 0, 
		shouldRasterize = shouldRasterize or false, shouldInvalidateRasterizer = true
	}
	if shouldRasterize then
		margin.rasterizableRect = framework:Rect(0, 0, cornerRadius, decorations)
		margin.rasterizer = framework:Rasterizer(margin.rasterizableRect)
	end
	
	function margin:Layout(availableWidth, availableHeight)
		local horizontal = self.left + self.right -- May be more performant to do left right top bottom – not sure though
		local vertical = self.top + self.bottom
		local rect = self.rect

		rect:Layout(availableWidth - horizontal, availableHeight - vertical)
		self.width = rect.width + horizontal
		self.height = rect.height + vertical
	end

	function margin:Draw(x, y)
		if margin.shouldRasterize then
			if margin.shouldInvalidateRasterizer then
				self.rasterizableRect.width = self.width
				self.rasterizableRect.height = self.height
				self.rasterizableRect.cornerRadius = self.cornerRadius
				self.rasterizableRect.decorations = self.decorations
				self.rasterizer.invalidated = self.shouldInvalidateRasterizer
				margin.shouldInvalidateRasterizer = false
			end
			self.rasterizer:Draw(x, y)
		else
			local decorations = margin.decorations
			for i = 1, #decorations do
				decorations[i]:Draw(margin, x, y)
			end
		end

		self.rect:Draw(x + self.left, y + self.bottom)
	end

	return margin
end

function framework:FrameOfReference(xAnchor, yAnchor, body)
	local frame = { xAnchor = xAnchor, yAnchor = yAnchor, body = body, width = 0, height = 0, availableWidth = 0, availableHeight = 0 }

	function frame:Layout(availableWidth, availableHeight)
		self.body:Layout(availableWidth, availableHeight)
		self.width = availableWidth
		self.height = availableHeight
	end

	function frame:Draw(x, y)
		local body = self.body
		body:Draw(x + (self.width - body.width) * self.xAnchor, y + (self.height - body.height) * self.yAnchor)
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
		local spacing = self.spacing
		local members = self.members
		local memberCount = #members
		
		for i = 1, memberCount do 
			local member = members[i]
			member:Layout(availableWidth, availableHeight - elapsedDistance)
			member.vStackCachedY = elapsedDistance
			elapsedDistance = elapsedDistance + member.height + spacing
			maxWidth = max(maxWidth, member.width)
		end

		local xAnchor = self.xAnchor

		for i = 1, memberCount do 
			local member = members[i]
			member.vStackCachedX = (maxWidth - member.width) * xAnchor
		end

		self.width = maxWidth

		if memberCount == 0 then 
			self.height = elapsedDistance 
		else
			self.height = elapsedDistance - spacing
		end
	end

	function verticalStack:Draw(x, y)
		local members = self.members
		for i = 1, #members do 
			local member = members[i]
			member:Draw(x + member.vStackCachedX, y + member.vStackCachedY)
		end
	end
	return verticalStack
end

function framework:StackInPlace(contents, xAnchor, yAnchor)
	local stackInPlace = { members = contents, height = 0, width = 0, xAnchor = xAnchor, yAnchor = yAnchor }

	function stackInPlace:Layout(availableWidth, availableHeight)
		local maxWidth = 0
		local maxHeight = 0
		local members = self.members
		local memberCount = #members

		for i = 1, memberCount do 
			local member = members[i]
			member:Layout(availableWidth, availableHeight)
			maxWidth = max(maxWidth, member.width)
			maxHeight = max(maxHeight, member.height)
		end

		local xAnchor = self.xAnchor
		local yAnchor = self.yAnchor

		for i = 1, memberCount do 
			local member = members[i]
			member.stackInPlaceCachedX = (maxWidth - member.width) * xAnchor
			member.stackInPlaceCachedY = (maxHeight - member.height) * yAnchor
		end

		self.width = maxWidth
		self.height = maxHeight
	end

	function stackInPlace:Draw(x, y)
		local members = self.members
		for i = 1, #members do 
			local member = members[i]
			member:Draw(x + member.stackInPlaceCachedX, y + member.stackInPlaceCachedY)
		end
	end
	return stackInPlace
end

function framework:HorizontalStack(members, spacing, yAnchor)
	local horizontalStack = { yAnchor = yAnchor or 0.5, spacing = spacing or 0, members = members, height = 0, width = 0 }

	function horizontalStack:Layout(availableWidth, availableHeight)
		local elapsedDistance = 0
		local maxHeight = 0
		local spacing = self.spacing
		local members = self.members
		local memberCount = #members

		for i = 1, memberCount do 
			local member = members[i]
			member:Layout(availableWidth - elapsedDistance, availableHeight)
			member.hStackCachedX = elapsedDistance	
			elapsedDistance = elapsedDistance + member.width + spacing
			maxHeight = max(member.height, maxHeight)
		end

		local yAnchor = self.yAnchor
		for i = 1, memberCount do
			local member = members[i]
			member.hStackCachedY = (maxHeight - member.height) * yAnchor
		end

		if memberCount == 0 then
			self.width = elapsedDistance 
		else
			self.width = elapsedDistance - spacing
		end
		
		self.height = maxHeight
	end

	function horizontalStack:Draw(x, y)
		local members = self.members
		for i = 1, #members do
			local member = members[i]
			member:Draw(x + member.hStackCachedX, y + member.hStackCachedY)
		end
	end
	
	return horizontalStack
end

------------------------------------------------------------------------------------------------------------
-- Performance
------------------------------------------------------------------------------------------------------------

-- NOTE: Translation is NOT COMPATIBLE WITH RESPONDERS
local emptyTable = {}
function framework:Rasterizer(body)
	local rasterizer = { body = body, invalidated = true, width = 0, height = 0,
		activeResponderCache = {}
	}

	for _, event in pairs(events) do 
		rasterizer.activeResponderCache[event] = { responders = {} }
	end

	function rasterizer:Layout(availableWidth, availableHeight)
		if rasterizer.invalidated then
			local body = self.body
			body:Layout(availableWidth, availableHeight)
			self.width = body.width
			self.height = body.height
		end
	end

	local function draw(body, x, y)
		body:Draw(x, y)
	end

	function rasterizer:Draw(x, y)
		local activeResponderCache = self.activeResponderCache

		if self.invalidated or not self.drawList then

			for _, event in pairs(events) do 
				activeResponderCache[event].responders = {}
			end

			local previousResponders = activeResponders
			activeResponders = activeResponderCache

			self.invalidated = false
			gl_DeleteList(self.drawList)
			self.drawList = gl_CreateList(draw, rasterizer.body, x, y)

			activeResponders = previousResponders
		end
		-- self.body:Draw(x, y) -- For debugging purposes.
		for _, event in pairs(events) do
			local activeResponder = activeResponders[event]
			local activeResponderResponders = activeResponder.responders
			for _, responder in pairs(activeResponderCache[event].responders or emptyTable) do
				if responder.action == nil then
					Spring.Echo("nil action!")
				end
				insert(activeResponderResponders, responder)
				responder.parent = activeResponder
			end
		end
		gl_CallList(self.drawList)
	end

	return rasterizer
end

------------------------------------------------------------------------------------------------------------
-- System events
------------------------------------------------------------------------------------------------------------

function widget:Initialize()
	local viewSizeX,viewSizeY = Spring.GetViewGeometry()
	viewportWidth = viewSizeX
	viewportHeight = viewSizeY
end

function widget:DrawScreen()
	hasCheckedElementBelowMouse = false
	elementBelowMouse = nil
	for key,element in pairs(elements) do
		activeElement = element
		activeTooltip = element
		activeResponders = element.baseResponders
		for _,responder in pairs(activeResponders) do
			responder.responders = {}
		end
		element.body:Layout(viewportWidth, viewportHeight)
		element.body:Draw(0, 0)
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

------------------------------------------------------------------------------------------------------------
-- Tooltips
------------------------------------------------------------------------------------------------------------

local function FindTooltip(x, y, tooltips)
	for _,tooltip in pairs(tooltips) do
		if PointIsInRect(x, y, tooltip.cachedX, tooltip.cachedY, tooltip.width, tooltip.height) then
			local child = FindTooltip(x, y, tooltip.tooltips)
			return child or tooltip
		end
	end
	return nil
end

function widget:GetTooltip(x, y)
	-- IsAbove is called before GetTooltip, so we can use the element found by that.
	local tooltip = FindTooltip(x, y, elementBelowMouse.tooltips)
	if not tooltip then return nil end

	return tooltip.description
	
end
function widget:TweakGetTooltip(x, y)
end

------------------------------------------------------------------------------------------------------------
-- Keyboard Events
------------------------------------------------------------------------------------------------------------

function widget:KeyPress(key, mods, isRepeat, label, unicode) end
function widget:KeyRelease(key, mods, label, unicode) end

------------------------------------------------------------------------------------------------------------
-- Mouse Events
------------------------------------------------------------------------------------------------------------

local function CheckElementUnderMouse(x, y)
	if not hasCheckedElementBelowMouse then
		for _, element in pairs(elements) do
			local primaryFrame = element.primaryFrame
			if primaryFrame ~= nil then -- Check for pre-initialised elements.
				if PointIsInRect(x, y, primaryFrame.cachedX, primaryFrame.cachedY, primaryFrame.width, primaryFrame.height) then 
					elementBelowMouse = element
					return true
				end
			end
		end
	end

	return elementBelowMouse ~= nil
end

local function Event(responder, ...)
	if responder.action(...) then
		return true
	else
		local parent = responder.parent
		if parent ~= nil then
			return Event(parent, ...)
		else
			return false
		end
	end
end

local function SearchDownResponderTree(responder, x, y, ...)
	for _,responder in pairs(responder.responders) do
		if PointIsInRect(x, y, responder.cachedX, responder.cachedY, responder.width, responder.height) then
			if SearchDownResponderTree(responder, x, y, ...) then
				return true
			else
				return Event(responder, x, y, ...)
			end
		end
	end
	return false
end

local function FindResponder(event, x, y, ...)
	return SearchDownResponderTree(elementBelowMouse.baseResponders[event], x, y, ...)
end

-- Normal mode

local mousePressEvent = events.mousePress
function widget:MousePress(x, y, button)
	if not CheckElementUnderMouse(x, y) then
		for _, element in pairs(elements) do
			element.deselect()
		end
		return false
	end
	local a = FindResponder(mousePressEvent, x, y, button)
	return a
end

function widget:MouseMove(x, y, dx, dy, button)
	local dragListener = dragListeners[button]
	if dragListener ~= nil then
		dragListener:MouseMove(x, y, dx, dy)
	end
end

function widget:MouseRelease(x, y, button) 
	local dragListener = dragListeners[button]
	if dragListener then
		dragListener:MouseRelease(x, y)
		dragListeners[button] = nil
	end
	return false
end

local mouseWheelEvent = events.mouseWheel
function widget:MouseWheel(up, value)
	if elementBelowMouse then
		local frame = elementBelowMouse.primaryFrame
		return FindResponder(mouseWheelEvent, frame.cachedX, frame.cachedY)
	else
		return false 
	end
end

local mouseOverEvent = events.mouseOver
function widget:IsAbove(x, y)
	local isAbove = CheckElementUnderMouse(x, y)
	if isAbove then FindResponder(mouseOverEvent, x, y) end
	return isAbove
end

-- Tweak mode 

function widget:TweakMousePress(x, y, button) end
function widget:TweakMouseMove(x, y, dx, dy, button) end
function widget:TweakMouseRelease(x, y, button) end
function widget:TweakMouseWheel(up, value) end
function widget:TweakIsAbove(x, y) return widget:IsAbove(x, y) end

------------------------------------------------------------------------------------------------------------
-- Joystick events
------------------------------------------------------------------------------------------------------------

-- function widget:JoyAxis(axis,value) end
-- function widget:JoyHat(hat, value) end
-- function widget:JoyButtonDown(button, state) end
-- function widget:JoyButtonUp(button, state) end