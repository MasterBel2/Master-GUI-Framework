local Internal = Internal
local table_insert = Include.table.insert
local ipairs = Include.ipairs

function framework:DrawingGroup(body, name)
    local drawingGroup = { drawTargets = {} }
    local textGroup = framework:TextGroup(body, name)

    function drawingGroup:LayoutChildren()
        return self, textGroup:LayoutChildren()
    end

    function drawingGroup:NeedsLayout()
        for dimension, _ in pairs(self.dimensions) do
            if dimension.ValueHasChanged() then
                return true
            end
        end
    end

    function drawingGroup:Layout(availableWidth, availableHeight)
        self.dimensions = {}
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
        local drawTargets = self.drawTargets
        for i = 1, #drawTargets do
            drawTargets[i]:Draw()
        end
    end

    function drawingGroup:NeedsRedraw()
        local drawTargets = self.drawTargets

        for i = 1, #drawTargets do
            local drawTarget = drawTargets[i]
            if drawTarget:NeedsRedraw() then return true end
        end
    end

    return drawingGroup
end