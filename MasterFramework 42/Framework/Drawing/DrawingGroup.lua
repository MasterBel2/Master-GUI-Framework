local Internal = Internal
local table_insert = Include.table.insert
local pairs = Include.pairs

function framework:DrawingGroup(body, name)
    local drawingGroup = Drawer()

    drawingGroup.childNeedsLayout = true
    drawingGroup.needsRedraw = true

    drawingGroup.dimensions = {}
    drawingGroup.drawers = {}
    drawingGroup.drawTargets = {}
    drawingGroup.layoutComponents = {}

    local textGroup = framework:TextGroup(body, name)

    function drawingGroup:LayoutChildren()
        return self, textGroup:LayoutChildren()
    end

    function drawingGroup:NeedsLayout()
        if self.childNeedsLayout then return true end
        for dimension, _ in pairs(self.dimensions) do
            if dimension.ValueHasChanged() then
                return true
            end
        end
    end

    function drawingGroup:Layout(availableWidth, availableHeight)
        self.childNeedsLayout = false
        self.dimensions = {}
        self.layoutComponents = {}
        local previousDrawingGroup = activeDrawingGroup
        activeDrawingGroup = self
        local width, height = textGroup:Layout(availableWidth, availableHeight)
        activeDrawingGroup = previousDrawingGroup
        return width, height
    end
    
    function drawingGroup:Position(x, y)
        self.drawTargets = {}
        local previousDrawingGroup = activeDrawingGroup
        if previousDrawingGroup then
            table_insert(previousDrawingGroup.drawTargets, self)
        end
        activeDrawingGroup = self
        textGroup:Position(x, y)
        activeDrawingGroup = previousDrawingGroup
    end

    function drawingGroup:Draw()
        self:RegisterDrawingGroup()
        self.needsRedraw = false
        self.drawers = {}
        local previousDrawingGroup = activeDrawingGroup
        activeDrawingGroup = self
        local drawTargets = self.drawTargets
        for i = 1, #drawTargets do
            drawTargets[i]:Draw(self)
        end
        activeDrawingGroup = previousDrawingGroup
    end

    function drawingGroup:DrawerUpdated(drawer)
        if self.drawers[drawer] then
            self.needsRedraw = true
            self:NeedsRedraw()
            return true
        end
    end

    function drawingGroup:LayoutUpdated(layoutComponent)
        if self.layoutComponents[layoutComponent] then
            self.childNeedsLayout = true
            return true
        end
    end

    return drawingGroup
end