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
    local cell = {}

    body = framework:Background(body, decorations, cornerRadius)

    local width, height
    local cachedOverrideWidth
    local cachedOverrideHeight

    function cell:LayoutChildren()
        return self, body:LayoutChildren()
    end

    function cell:NeedsLayout()
        return cachedOverrideWidth ~= self.overrideWidth or cachedOverrideHeight ~= self.overrideHeight
    end

    function cell:Layout(availableWidth, availableHeight)
        local width, height = body:Layout(availableWidth, availableHeight)
        cachedOverrideWidth = self.overrideWidth
        cachedOverrideHeight = self.overrideHeight
        return cachedOverrideWidth or width, cachedOverrideHeight or height
    end

    function cell:Position(x, y)
        body:Position(x, y)
    end

    return cell
end