local Internal = Internal
local table_insert = Include.table.insert
local insert = Include.table.insert
local tostring = Include.tostring
local pairs = Include.pairs
local os_clock = Include.os.clock
local gl_DeleteList = Include.gl.DeleteList
local gl_CreateList = Include.gl.CreateList
local gl_CallList = Include.gl.CallList
local clear = Include.clear

--[[
    `DrawingGroup` is a component that collects any child component that wishes to draw, and instructs them when to perform their draw.

    By default, `DrawingGroup` compiles a drawList, which can be expensive for interfaces that update too frequently! 
    See parameter `disableDrawList` and property `drawingGroup.disableDrawList` to disable.
    All draw lists may be disabled with the debug mode `disableDrawList`; see `framework.SetDebugMode()` for more detail.

    Parameters:
     - `body`: The root component for the interface to be managed by the `DrawingGroup`.
     - `disableDrawList`: Disables drawList compilation, and instead performs a full draw every draw frame. 

    Properties:
     - `drawingGroup.needsRedraw`: A boolean value indicating whether a new draw pass is needed; this may be set to true (but not false!) by a child.

     - `drawingGroup.disableDrawList`: A boolean (or nil) value indicating whether the `drawingGroup` should compile re-usable draw lists. 
                                       For components that update too frequently, this can be a performance cost rather than a performance gain.

     - `drawingGroup.dimensions`: A table of `Dimension`s that were used in the most recent layout/position/draw passes.
                                  When one of these updates, the drawing group will perform a new layout, position, and draw pass.
                                  This table is keyed by the `Dimension`s, and the values are unused (other than ensuring the key remains valid). 
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

    drawingGroup.needsRedraw = true
    drawingGroup.disableDrawList = disableDrawList or Internal.debugMode.disableDrawList

    drawingGroup.dimensions = {}
    drawingGroup.drawers = {}
    drawingGroup.drawTargets = {}
    drawingGroup.childDrawingGroups = {}
    drawingGroup.layoutComponents = {}

    local element
    local parentDrawingGroup

    local responderCache = {}
    drawingGroup.responderCache = responderCache

    for _, event in pairs(events) do
		responderCache[event] = framework:Responder(body, event, function() end)
        body = responderCache[event]
	end

    local textGroup = framework:TextGroup(body, name)
    local drawList

    -- debug
    local framesRedrawnInARow = 0

    function drawingGroup:DimensionNeedsLayoutUpdate()
        for dimension, _ in pairs(drawingGroup.dimensions) do
            if dimension.ValueHasChanged() then
                return true
            end
        end
    end

    local cachedWidth, cachedHeight
    local cachedAvailableWidth, cachedAvailableHeight
    function drawingGroup:Layout(availableWidth, availableHeight)
        element = Internal.activeElement
        parentDrawingGroup = activeDrawingGroup
        if parentDrawingGroup then
            parentDrawingGroup.childDrawingGroups[#parentDrawingGroup.childDrawingGroups + 1] = self
        end

        if self:DimensionNeedsLayoutUpdate() or availableWidth ~= cachedAvailableWidth or availableHeight ~= cachedAvailableHeight then
            cachedAvailableWidth = availableWidth
            cachedAvailableHeight = availableHeight

            self:UpdateLayout(true)
        end

        return cachedWidth, cachedHeight
    end

    function drawingGroup:UpdateLayout(calledByParent)
        element.groupsNeedingLayout[self] = nil
        self.needsRedraw = true
        self.dimensions = {}
        self.layoutComponents = {}
        self.childDrawingGroups = {}

        element.groupsNeedingPosition[self] = true

        local previousDrawingGroup = activeDrawingGroup
        activeDrawingGroup = self
        local newWidth, newHeight = textGroup:Layout(cachedAvailableWidth, cachedAvailableHeight)
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

        self.needsRedraw = true
        self.drawTargets = {}

        local previousDrawingGroup = activeDrawingGroup
        activeDrawingGroup = self
        textGroup:Position(cachedX, cachedY)

        activeDrawingGroup = previousDrawingGroup
    end
    
    function drawingGroup:Position(x, y)
        if cachedX ~= x or cachedY ~= y then
            
            cachedX = x
            cachedY = y
            
            self:UpdatePosition()
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

    local function _Draw(self)
        local drawTargets = self.drawTargets
        for i = 1, #drawTargets do
            drawTargets[i]:Draw(self)
        end
    end

    function drawingGroup:Draw()
        local previousDrawingGroup = activeDrawingGroup
        activeDrawingGroup = self

        if self.disableDrawList then
            self.drawers = {}
            self.needsRedraw = false

            _Draw(self)

            local childDrawingGroups = self.childDrawingGroups
            for i = 1, #childDrawingGroups do
                childDrawingGroups[i]:Draw()
            end
        else 
            if self.needsRedraw then
                self.drawers = {}
                self.needsRedraw = false

                -- if Internal.debugMode.general then
                --     Log("Recompiling drawlist for (" .. self._debugUniqueIdentifier .. ") " .. self._debugTypeIdentifier .. "(" .. os_clock() .. ")" .. tostring(not drawList) .. ", " .. tostring(self.needsRedraw))
                --     recalculatingRasterizer = true
                --     if framesRedrawnInARow > 0 then
                --         Log("Recompiling drawlist for (" .. self._debugUniqueIdentifier .. ") " .. self._debugTypeIdentifier ..  " " .. framesRedrawnInARow .. " frame(s) in a row")
                --     end
                -- end

                gl_DeleteList(drawList)
                drawList = gl_CreateList(_Draw, self)
                
                -- framesRedrawnInARow = framesRedrawnInARow + 1
            -- else
                -- framesRedrawnInARow = 0
            end

            gl_CallList(drawList)

            local childDrawingGroups = self.childDrawingGroups
            for i = 1, #childDrawingGroups do
                childDrawingGroups[i]:Draw()
            end
        end

        activeDrawingGroup = previousDrawingGroup
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
        if self.drawers[drawer] then
            self.needsRedraw = true
            return true
        end
    end

    return drawingGroup
end