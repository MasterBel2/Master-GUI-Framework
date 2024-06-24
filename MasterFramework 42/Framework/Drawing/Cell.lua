local table_insert = Include.table.insert

--[[
    A component used to draw decorations of a desired size around a fixed-size child, that does not directly wrap the child as `framework:MarginAroundRect` would.
    
    Set `cell.overrideWidth` or `cell.overrideHeight` to a non-nil number to customise layout.
    `framework:Cell` is a valid Geometry Target.

    Parameters:
    - `body`: the child component of the cell.
    - `decorations`: an array of decorations that implement `decoration:Draw(rect, x, y, width, height)` that will be called in-order to draw the cell's background.
    - `cornerRadius`: a function returning a number whose result will be used to determine the corner radius for the decorations drawn.

    Properties:
    - `decorations`: an array of decorations that implement `decoration:Draw(rect, x, y, width, height)` that will be called in-order to draw the cell's background.
    - `cornerRadius`: a function returning a number whose result will be used to determine the corner radius for the decorations drawn.
]]
function framework:Cell(body, decorations, cornerRadius)
    local cell = Component(true, false)

    body = framework:Background(body, decorations, cornerRadius) -- TODO: legacy integration of Background

    local overrideWidth
    local overrideHeight

    function cell:SetOverrideDimensions(newOverrideWidth, newOverrideHeight)
        if newOverrideWidth ~= overrideWidth or newOverrideHeight ~= overrideHeight then
            overrideWidth = newOverrideWidth
            overrideHeight = newOverrideHeight
            self:NeedsLayout()
        end
    end

    function cell:Layout(availableWidth, availableHeight)
        self:RegisterDrawingGroup()
        local width, height = body:Layout(availableWidth, availableHeight)
        return overrideWidth or width, overrideHeight or height
    end

    function cell:Position(x, y)
        body:Position(x, y)
    end

    return cell
end