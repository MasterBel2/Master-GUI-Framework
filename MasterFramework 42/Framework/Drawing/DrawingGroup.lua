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

function framework:Rasterizer(body)
    local rasterizer = self:DrawingGroup(body)
    rasterizer.noRasterizer = false
    return rasterizer
end

function framework:DrawingGroup(body)
    local drawingGroup = {}

    drawingGroup.childNeedsLayout = true
    drawingGroup.childNeedsPosition = true
    drawingGroup.needsRedraw = true

    drawingGroup.noRasterizer = true

    drawingGroup.dimensions = {}
    drawingGroup.drawers = {}
    drawingGroup.drawTargets = {}
    drawingGroup.childDrawingGroups = {}
    drawingGroup.layoutComponents = {}

    local activeResponderCache = {}

    for _, event in pairs(events) do
		activeResponderCache[event] = { responders = {} }
	end

    local textGroup = framework:TextGroup(body, name)
    local drawList

    -- debug
    local framesRedrawnInARow = 0

    function drawingGroup:NeedsLayout()
        if self.childNeedsLayout then return true end
        for dimension, _ in pairs(self.dimensions) do
            if dimension.ValueHasChanged() then
                return true
            end
        end
        local childDrawingGroups = drawingGroup.childDrawingGroups
        for i = 1, #childDrawingGroups do
            if childDrawingGroups[i]:NeedsLayout() then
                return true
            end
        end
    end

    local cachedWidth, cachedHeight
    local cachedAvailableWidth, cachedAvailableHeight
    function drawingGroup:Layout(availableWidth, availableHeight)
        local previousDrawingGroup = activeDrawingGroup
        if previousDrawingGroup then
            previousDrawingGroup.childDrawingGroups[#previousDrawingGroup.childDrawingGroups + 1] = self
        end

        if self:NeedsLayout() or availableWidth ~= cachedAvailableWidth or availableHeight ~= cachedAvailableHeight then
            self.childNeedsLayout = false
            self.childNeedsPosition = true
            self.needsRedraw = true
            self.dimensions = {}
            self.layoutComponents = {}
            self.childDrawingGroups = {}

            cachedAvailableWidth = availableWidth
            cachedAvailableHeight = availableHeight

            activeDrawingGroup = self
            cachedWidth, cachedHeight = textGroup:Layout(availableWidth, availableHeight)
            activeDrawingGroup = previousDrawingGroup
        end

        return cachedWidth, cachedHeight
    end
    
    local cachedX, cachedY
    function drawingGroup:Position(x, y)
        if self.childNeedsPosition or cachedX ~= x or cachedY ~= y then
            self.childNeedsPosition = false
            self.needsRedraw = true
            self.drawTargets = {}

            cachedX = x
            cachedY = y

            -- Cache responders that won't be drawn
			for _, event in pairs(events) do
				clear(activeResponderCache[event].responders)
			end

            local previousDrawingGroup = activeDrawingGroup
            activeDrawingGroup = self

            local previousResponders = Internal.activeResponders
			Internal.activeResponders = activeResponderCache

            textGroup:Position(x, y)

            Internal.activeResponders = previousResponders
            activeDrawingGroup = previousDrawingGroup
        end

        for _, event in pairs(events) do
			local parentResponder = Internal.activeResponders[event]
			local childrenOfParentResponder = parentResponder.responders
			
			local cachedResponders = activeResponderCache[event].responders

			for index = 1, #cachedResponders do
				local cachedResponder = cachedResponders[index]
                childrenOfParentResponder[#childrenOfParentResponder + 1] = cachedResponder
				cachedResponder.parent = parentResponder
			end
		end
    end

    local function _Draw(self)
        self.drawers = {}
        local previousDrawingGroup = activeDrawingGroup
        activeDrawingGroup = self
        local drawTargets = self.drawTargets
        for i = 1, #drawTargets do
            drawTargets[i]:Draw(self)
        end
        local childDrawingGroups = self.childDrawingGroups
        for i = 1, #childDrawingGroups do
            childDrawingGroups[i]:Draw()
        end
        activeDrawingGroup = previousDrawingGroup
    end

    function drawingGroup:Draw()
        if self.noRasterizer then
            self.needsRedraw = false
            _Draw(self)
        else 
            if self.needsRedraw then
                -- if Internal.debugMode.general then
                --     Log("Recompiling drawlist for (" .. self._debugUniqueIdentifier .. ") " .. self._debugTypeIdentifier .. "(" .. os_clock() .. ")" .. tostring(not drawList) .. ", " .. tostring(self.needsRedraw))
                --     recalculatingRasterizer = true
                --     if framesRedrawnInARow > 0 then
                --         Log("Recompiling drawlist for (" .. self._debugUniqueIdentifier .. ") " .. self._debugTypeIdentifier ..  " " .. framesRedrawnInARow .. " frame(s) in a row")
                --     end
                -- end
                self.needsRedraw = false

                gl_DeleteList(drawList)
                drawList = gl_CreateList(_Draw, self)
                
                -- framesRedrawnInARow = framesRedrawnInARow + 1
            -- else
                -- framesRedrawnInARow = 0
            end

            gl_CallList(drawList)
        end
    end

    function drawingGroup:LayoutUpdated(layoutComponent)
        if self.layoutComponents[layoutComponent] then
            self.childNeedsLayout = true
            return true
        end
    end

    function drawingGroup:PositionsUpdated(layoutComponent)
        if self.layoutComponents[layoutComponent] then
            self.childNeedsPosition = true
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