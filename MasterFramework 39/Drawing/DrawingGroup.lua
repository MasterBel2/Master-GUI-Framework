local Internal = Internal
local table_insert = Include.table.insert
local ipairs = Include.ipairs

function framework:DrawingGroup(body, name)
    local drawingGroup = { drawTargets = {} }
    local textGroup = framework:TextGroup(body, name)

    function drawingGroup:NeedsLayout()
        return textGroup:NeedsLayout()
    end

    function drawingGroup:Layout(availableWidth, availableHeight)
        return textGroup:Layout(availableWidth, availableHeight)
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
        for _, drawTarget in ipairs(self.drawTargets) do
            drawTarget:Draw()
        end
    end

    function drawingGroup:SetBody(newBody)
        textGroup:SetBody(newBody)
    end

    return drawingGroup
end