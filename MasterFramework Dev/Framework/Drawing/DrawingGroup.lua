local Internal = Internal
local table_insert = Include.table.insert
local insert = Include.table.insert
local tostring = Include.tostring
local pairs = Include.pairs
local next = Include.next
local os_clock = Include.os.clock
local gl_DeleteList = Include.gl.DeleteList
local gl_CreateList = Include.gl.CreateList
local gl_CallList = Include.gl.CallList
local gl_Translate = Include.gl.Translate
local clear = Include.clear

DRAWING_GROUP_PASS = {
    LAYOUT = 1,
    POSITION = 2,
    DRAW = 3
}

local DRAWING_GROUP_PASS_LAYOUT = DRAWING_GROUP_PASS.LAYOUT
local DRAWING_GROUP_PASS_POSITION = DRAWING_GROUP_PASS.POSITION
local DRAWING_GROUP_PASS_DRAW = DRAWING_GROUP_PASS.DRAW

--[[
    `DrawingGroup` is a component that collects any child component that wishes to draw, and instructs them when to perform their draw.

    By default, `DrawingGroup` compiles a drawList, which can be expensive for interfaces that update too frequently! 
    See parameter `disableDrawList` and property `drawingGroup.disableDrawList` to disable.
    All draw lists may be disabled with the debug mode `disableDrawList`; see `framework.SetDebugMode()` for more detail.

    Parameters:
     - `body`: The root component for the interface to be managed by the `DrawingGroup`.
     - `disableDrawList`: Disables drawList compilation, and instead performs a full draw every draw frame. 

    Properties:
     - `drawingGroup.disableDrawList`: A boolean (or nil) value indicating whether the `drawingGroup` should compile re-usable draw lists. 
                                       For components that update too frequently, this can be a performance cost rather than a performance gain.
     - `drawingGroup.drawers`: A table of `Drawer`s  that drew in the most recent draw pass. 
                               When the drawing group is using draw lists and one of these updates, the drawing group will perform a new draw pass.
                               This table is keyed by the `Drawer`s, and the values are unused (other than ensuring the key remains valid).
     - `drawingGroup.layoutComponents`: A table of `Component`s that laid out in the most recent layout/position passses.
                                        When one of these updates, the drawing group will perform a new layout and/or position pass.
                                        This table is keyed by the `Dimension`s, and the values are unused (other than ensuring the key remains valid).
     - `drawingGroup.childDrawingGroups`: An array of `DrawingGroup`s contained in the component hierarchy to be drawn after the end of the draw pass.
                                          These are drawn separately to avoid nesting draw lists.
     - `drawingGroup.drawTargets`: An array of components implementing `component:Draw()` to be drawn in the draw pass.
                                   Contents of this array are added by the descendent component tree during `drawingGroup:Position(x, y)`

    Methods:
     - `drawingGroup:NeedsLayoutUpdate()`: Returns whether the drawingGroup or its children require a new layout pass.
      - `drawingGroup:NeedsPositionUpdate()`: Returns whether the drawingGroup or its children require a new positioning pass.
]]
function framework:DrawingGroup(body, disableDrawList)
    local drawingGroup = {}

    drawingGroup.disableDrawList = disableDrawList or Internal.debugMode.disableDrawList

    drawingGroup.drawers = {}
    drawingGroup.drawTargets = {}
    drawingGroup.childDrawingGroups = {}
    drawingGroup.layoutComponents = {}
    drawingGroup.continuouslyUpdatingDrawers = {}

    local element
    local parentDrawingGroup
    local parentX, parentY = 0, 0
    local absoluteX, absoluteY = 0, 0

    local responderCache = {}
    drawingGroup.responderCache = responderCache

    for _, event in pairs(events) do
		responderCache[event] = framework:Responder(body, event, function() end)
        body = responderCache[event]
	end

    local textGroup = framework:TextGroup(body, name)
    local drawList
    local redrawFunc
    
    local cachedWidth, cachedHeight
    local cachedAvailableWidth, cachedAvailableHeight
    function drawingGroup:Layout(availableWidth, availableHeight)
        element = Internal.activeElement
        parentDrawingGroup = activeDrawingGroup
        if parentDrawingGroup then
            parentDrawingGroup.childDrawingGroups[#parentDrawingGroup.childDrawingGroups + 1] = self
        end

        if availableWidth ~= cachedAvailableWidth or availableHeight ~= cachedAvailableHeight then
            cachedAvailableWidth = availableWidth
            cachedAvailableHeight = availableHeight

            self:UpdateLayout(true)
        end

        return cachedWidth, cachedHeight
    end

    function drawingGroup:UpdateLayout(calledByParent)
        element.groupsNeedingLayout[self] = nil

        self.layoutComponents = {}
        self.childDrawingGroups = {}
        self.childGeometryTargets = {}

        element.groupsNeedingPosition[self] = true

        local previousDrawingGroup = activeDrawingGroup
        activeDrawingGroup = self
        self.pass = DRAWING_GROUP_PASS_LAYOUT
        local newWidth, newHeight = textGroup:Layout(cachedAvailableWidth, cachedAvailableHeight)
        self.pass = nil
        activeDrawingGroup = previousDrawingGroup
        if newWidth ~= cachedWidth or newHeight ~= cachedHeight then
            cachedWidth = newWidth
            cachedHeight = newHeight
            if parentDrawingGroup and not calledByParent then
                parentDrawingGroup:UpdateLayout()
            end
        end
    end

    local cachedX, cachedY
    function drawingGroup:UpdatePosition()
        element.groupsNeedingPosition[self] = nil

        element.requestedRedraws[redrawFunc] = true
        self.drawTargets = {}

        local previousDrawingGroup = activeDrawingGroup
        activeDrawingGroup = self
        self.pass = DRAWING_GROUP_PASS_POSITION
        textGroup:Position(0, 0)
        self.pass = nil

        activeDrawingGroup = previousDrawingGroup
    end
    
    function drawingGroup:Position(x, y)
        cachedX = x
        cachedY = y
        absoluteX = x + parentX
        absoluteY = y + parentY

        if element.groupsNeedingPosition[self] then
            self:UpdatePosition()
        end

        local childDrawingGroups = self.childDrawingGroups
        for i = 1, #childDrawingGroups do
            childDrawingGroups[i]:SetParentGroupPosition(absoluteX, absoluteY)
        end
        local childGeometryTargets = self.childGeometryTargets
        for i = 1, #childGeometryTargets do
            childGeometryTargets[i]:SetParentGroupPosition(absoluteX, absoluteY)
        end

        for _, event in pairs(events) do
			local parentResponder = Internal.activeResponders[event]
            if parentResponder then
    			local childrenOfParentResponder = parentResponder.responders
                childrenOfParentResponder[#childrenOfParentResponder + 1] = responderCache[event]
                responderCache[event].parent = parentResponder
            end
		end
    end

    function drawingGroup:SetParentGroupPosition(x, y)
        if parentX == x and parentY == y then return end 
        parentX = x
        parentY = y

        absoluteX = cachedX + x
        absoluteY = cachedY + y

        local childDrawingGroups = self.childDrawingGroups
        for i = 1, #childDrawingGroups do
            childDrawingGroups[i]:SetParentGroupPosition(absoluteX, absoluteY)
        end
        local childGeometryTargets = self.childGeometryTargets
        for i = 1, #childGeometryTargets do
            childGeometryTargets[i]:SetParentGroupPosition(absoluteX, absoluteY)
        end
    end
    function drawingGroup:AbsolutePosition()
        return absoluteX, absoluteY
    end

    local function _Draw(self)
        local previousDrawingGroup = activeDrawingGroup
        activeDrawingGroup = self
        self.drawers = {}
        local drawTargets = self.drawTargets
        for i = 1, #drawTargets do
            drawTargets[i]:Draw(self)
        end
        activeDrawingGroup = previousDrawingGroup
    end

    redrawFunc = function()
        gl_DeleteList(drawList)
        self.pass = DRAWING_GROUP_PASS_DRAW
        drawList = gl_CreateList(_Draw, drawingGroup)
        self.pass = nil
    end

    function drawingGroup:Draw()
        local previousDrawingGroup = activeDrawingGroup
        activeDrawingGroup = self
        self.pass = DRAWING_GROUP_PASS_DRAW
        
        if (absoluteX ~= 0) or (absoluteY ~= 0) then
            gl_Translate(absoluteX, absoluteY, 0)
        end

        if self.disableDrawList or next(self.continuouslyUpdatingDrawers) then
            _Draw(self)

            for drawer, _ in pairs(self.continuouslyUpdatingDrawers) do
                if not self.drawers[drawer] then
                    self.continuouslyUpdatingDrawers[drawer] = nil
                end
            end
        else
            gl_CallList(drawList)
        end
        if (absoluteX ~= 0) or (absoluteY ~= 0) then
            gl_Translate(-absoluteX, -absoluteY, 0)
        end
        
        local childDrawingGroups = self.childDrawingGroups
        for i = 1, #childDrawingGroups do
            childDrawingGroups[i]:Draw()
        end
        
        self.pass = nil
        activeDrawingGroup = previousDrawingGroup
    end

    function drawingGroup:CachedSize()
        return cachedWidth, cachedHeight
    end

    function drawingGroup:LayoutUpdated(layoutComponent)
        if self.layoutComponents[layoutComponent] then
            element.groupsNeedingLayout[self] = true
            return true
        end
    end

    function drawingGroup:PositionsUpdated(layoutComponent)
        if self.layoutComponents[layoutComponent] then
            element.groupsNeedingPosition[self] = true
            return true
        end
    end

    function drawingGroup:DrawerUpdated(drawer)
        if self.drawers[drawer] and not (self.disableDrawList or next(self.continuouslyUpdatingDrawers)) then
            element.requestedRedraws[redrawFunc] = true
            return true
        end
    end

    -- Signals to the drawing group that it should not compile draw lists for the time being.
    -- 
    -- Use this when the component is frequently updating, to avoid unnecessary performance penalty.
    function drawingGroup:DrawerWillContinuouslyUpdate(drawer)
        if self.drawers[drawer] then
            self.continuouslyUpdatingDrawers[drawer] = true
            return true
        end
    end

    -- Signals to the drawing group that this component no longer requires avoidance of draw lists.
    -- 
    -- Use this when the component is no longer frequently updating, to avoid unnecessary performance penalty.
    -- Note that if any drawer is continuously updating, every drawer in the drawing group will draw every frame. 
    -- If some drawers are known to update less frequently, consider wrapping them in a separate drawing group.
    function drawingGroup:DrawerWillNotContinuouslyUpdate(drawer)
        if self.drawers[drawer] then
            self.continuouslyUpdatingDrawers[drawer] = nil
            if not (self.disableDrawList or next(self.continuouslyUpdatingDrawers)) then
                element.requestedRedraws[redrawFunc] = true
            end
            return true
        end
    end

    return drawingGroup
end