local table_insert = Include.table.insert
local table_mergeInPlace = Include.table.mergeInPlace

--[[
    `Background` is a component used to draw decorations around a child.
    
    Notes:
     - `Background` is a non-overriding extension of `Drawer` and `GeometryTarget`.

    Parameters:
     - `body`: the child component of the cell.
     - `decorations`: an array of decorations that implement `decoration:Draw(rect, x, y, width, height)` that will be called in-order to draw the cell's background.
     - `cornerRadius`: a function returning a number whose result will be used to determine the corner radius for the decorations drawn. This may be nil.

    Read/write properties:
     - `cornerRadius`: a function returning a number whose result will be used to determine the corner radius for the decorations drawn.

    Methods:
     - `background:SetDecorations(newDecorations)`: copies the array contents of `newDecorations` to be the new set of decorations drawn.
]]
function framework:Background(body, _decorations, cornerRadius)
    local background = table.mergeInPlace(Component(false, true), framework:GeometryTarget(body))
    background.cornerRadius = cornerRadius or framework:AutoScalingDimension(0)
    local decorations = {}

    function background:SetDecorations(newDecorations)
        self:NeedsRedraw()
        for i = #newDecorations + 1, #decorations do
            decorations[i] = nil
        end
        for i = 1, #newDecorations do
            decorations[i] = newDecorations[i]
        end
    end
    background:SetDecorations(_decorations)

    local _Position = background.Position
    function background:Position(x, y)
        table_insert(activeDrawingGroup.drawTargets, self)
        _Position(self, x, y)
    end

    function background:Draw()
        self:RegisterDrawingGroup()
        local x, y = self:CachedPositionRemainingInLocalContext()
        local width, height = self:Size()

        for i = 1, #decorations do
            decorations[i]:Draw(self, x, y, width, height)
        end
    end

    return background
end 