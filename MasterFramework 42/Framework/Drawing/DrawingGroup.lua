local Internal = Internal
local table_insert = Include.table.insert
local ipairs = Include.ipairs

function framework:DrawingGroup(body, name)
    local drawingGroup = { drawTargets = {} }
    local textGroup = framework:TextGroup(body, name)

    function drawingGroup:LayoutChildren()
        return textGroup:LayoutChildren()
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

    local cachedDrawCount

    function drawingGroup:Draw()
        for i = 1, #drawTargets in ipairs(self.drawTargets) do
            local drawTarget = drawTargets[i]
            drawTarget:Draw()
        end
        cachedDrawCount = #self.drawTargets
    end

    function drawingGroup:SetBody(newBody)
        textGroup:SetBody(newBody)
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