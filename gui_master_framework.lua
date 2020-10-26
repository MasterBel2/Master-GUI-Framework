------------------------------------------------------------------------------------------------------------
-- Metadata
------------------------------------------------------------------------------------------------------------
function widget:GetInfo()
	return {
		version = "Initial Test",
		name = "MasterBel2's GUI Framework",
		desc = "A GUI framework for the SpringRTS Engine",
		author = "MasterBel2",
		date = "October 2020",
		license = "GNU GPL, v2 or later",
		layer = 0,
		enabled = true
	}
end

------------------------------------------------------------------------------------------------------------
-- Global Access
------------------------------------------------------------------------------------------------------------

local framework = {
	compatabilityVersion = 0,
	scaleFactor = 0,
	views = {}
}

if not WG.MasterFramework then WG.MasterFramework = {} end

WG.MasterFramework[framework.compatabilityVersion] = framework

------------------------------------------------------------------------------------------------------------
-- Framework
------------------------------------------------------------------------------------------------------------

local pointPool = {}
function framework:Point(x, y)
	local point = table.remove(pointPool) or { x = 0, y = 0 }
	point.x = x
	point.y = y
	return point
end
function framework:FreePoint(point) table.insert(pointPool, point) end

-- Size requires the same data as a point
framework.Size = framework.Point
framework.FreeSize = framework.FreePoint

local paddingPool = {}
function framework:Padding(left, top, right, bottom)
	local padding = table.remove(paddingPool) or { top = 0, right = 0, bottom = 0, left = 0 }
	padding.top = top
	padding.right = right
	padding.bottom = bottom
	padding.left = left
	return padding
end
function framework:FreePadding(padding) table.insert(paddingPool, padding) end

local borderPool = {}
function framework:Border(width, color)
	local border = table.remove(borderPool) or { width = 0, color = {} }
	border.width = width
	border.color = color
	return border
end
function framework:FreeBorder(border) table.insert(borderPool, border) end

local colorPool = {}
function framework:Color(r, g, b, a)
	local color = table.remove(colorPool) or { r = 0, g = 0, b = 0, a = 0 }
	color.r = r
	color.g = g
	color.b = b
	color.a = a
	return color
end
function framework:FreeColor(color) table.insert(colorPool, color) end

local textPool = {}
function framework:Text(string, color)
	local text = table.remove(textPool) or { r = 0, g = 0, b = 0, a = 0 }
	text.string = string
	text.color = color
	return text
end
function framework:FreeText(text) table.insert(textPool, text) end

local viewPool = {}
function framework:View(padding, subviews, border, cornerRadius, backgroundColor, text, image)
	local view = table.remove(viewPool) or { 
		needsRedraw = true, cachedSize = { x = 0, y = 0 }, cachedAbsolutePosition = { x = 0, y = 0 }, glList = nil,
		index = 0, parent = nil,
		padding = {}, subviews = {}, border = {}, cornerRadius = 0, backgroundColor = {}, text = {}, image = "" 
	}
	view.padding = padding
	view.subviews = subviews
	view.border = border
	view.cornerRadius = cornerRadius
	view.backgroundColor = backgroundColor
	view.text = text
	view.image = image

	for index,subview in pairs(subviews) do
		subview.index = index
		subview.parent = view
	end

	return view
end

function framework:InvalidateView(view)
	view.needsRedraw = true
	if view.parent then
		framework:InvalidateView(view.parent)
	end
end

function framework:RemoveView(view)
	table.remove(parent.subviews, view.index)
	framework.FreePoint(view.bottomLeftPoint)
	framework.FreePadding(view.padding)
	framework.FreeBorder(view.border)
	framework.FreeText(view.text)
	framework.FreeImage(view.image)

	for _,subview in pairs(subviews) do
		subview.index = 0
		subview.parent = nil
	end

	table.insert(viewPool, view)
end

------------------------------------------------------------------------------------------------------------
-- GL Functions
------------------------------------------------------------------------------------------------------------

local gl_DeleteList = gl.DeleteList
local gl_CreateList = gl.CreateList
local gl_CallList = gl.CallList
local GL_POLYGON = GL.POLYGON
local gl_Color = gl.Color
local gl_Texture = gl.Texture
local gl_BeginEnd = gl.BeginEnd
local gl_Rect = gl.Rect
local gl_Vertex = gl.Vertex
local gl_Shape = gl.Shape

------------------------------------------------------------------------------------------------------------
-- Values
------------------------------------------------------------------------------------------------------------

local screenSize = framework:Size(0, 0)
local screenOrigin = framework:Point(0, 0)

------------------------------------------------------------------------------------------------------------
-- Local Operations
------------------------------------------------------------------------------------------------------------

local sqrt = math.sqrt

local function DrawRectRound(bottomLeftPoint, size, cornerRadius)
	local radiusSquared = cornerRadius * cornerRadius

	local centerBottomY = bottomLeftPoint.y + cornerRadius
	local centerTopY = bottomLeftPoint.y + size.y - cornerRadius
	local centerRightX = bottomLeftPoint.x + size.x - cornerRadius
	local centerLeftX = bottomLeftPoint.x + cornerRadius

	local function vertexPosition(x) return sqrt(radiusSquared - (x * x)) end

	for x = -cornerRadius, 0 do
		gl_Vertex(centerLeftX + x, centerBottomY - vertexPosition(x))
	end
	for x = 0, cornerRadius do
		gl_Vertex(centerRightX + x, centerBottomY - vertexPosition(x))
	end
	for x = -cornerRadius, 0 do
		gl_Vertex(centerRightX - x, centerTopY + vertexPosition(x))
	end
	for x = 0, cornerRadius do
		gl_Vertex(centerLeftX - x, centerTopY + vertexPosition(x))
	end
end

local max = math.max
local function PrepareToDraw(view, availableBottomLeft, shouldAutomaticallyInvalidate)
	-- Only recalculate if necessary. Subview changes are chained up through their parents, so if they need a redraw, view.needsRedraw will already be true.
	if (view.needsRedraw or shouldAutomaticallyInvalidate) then
		view.needsRedraw = false
		local padding = view.padding
		local size = view.cachedSize

		-- Layout subviews so we can calculate this view's size.

		local nextSubviewBottomLeft = framework:Point(availableBottomLeft.x + padding.left, availableBottomLeft.y)
		local maxSubviewHeight = 0
		for _, subview in pairs(view.subviews) do
			PrepareToDraw(subview, nextSubviewBottomLeft, false)
			maxSubviewHeight = max(maxSubviewHeight, subview.cachedSize.y)
			nextSubviewBottomLeft.x = nextSubviewBottomLeft.x + subview.cachedSize.x
		end

		size.x = nextSubviewBottomLeft.x + padding.right
		size.y = maxSubviewHeight + padding.top + padding.bottom

		framework:FreePoint(nextSubviewBottomLeft)

		-- Create draw list

		gl_DeleteList(view.glList)
		view.glList = gl_CreateList(function()
			local color = view.backgroundColor
			if color ~= nil then
				gl_Color(color.r, color.g, color.b, color.a)
			elseif view.image ~= nil then
				gl_Texture(view.image)
			else
				return
			end
			if view.cornerRadius > 0 then
				-- Spring.Echo("Drawing")
				-- gl_BeginEnd(GL.QUAD_STRIP, DrawRectRound, absolutePosition, size, view.cornerRadius)
				gl_BeginEnd(GL_POLYGON, DrawRectRound, availableBottomLeft, size, view.cornerRadius)
			else
				gl_Rect(availableBottomLeft.x, availableBottomLeft.y, availableBottomLeft.x + size.x, availableBottomLeft.y + size.y)
			end
			-- Reset because someone might forget to set it
			gl_Color(1, 1, 1, 1)
		end)
	end
end

local function Draw(view)
	gl_CallList(view.glList)
	for _, subview in pairs(view.subviews) do
		Draw(subview)
	end
end

------------------------------------------------------------------------------------------------------------
-- Callins
------------------------------------------------------------------------------------------------------------

function widget:DrawScreen()
	for _,view in pairs(framework.views) do
		PrepareToDraw(view, screenOrigin, false)
		Draw(view)
	end
end

function widget:ViewResize(viewSizeX, viewSizeY)
	if screenSize.x ~= viewSizeX or screenSize.y ~= viewSizeY then
		screenSize.x = viewSizeX
		screenSize.y = viewSizeY

		for _, view in pairs(framework.views) do
			view.needsRedraw = true
		end
	end
end
