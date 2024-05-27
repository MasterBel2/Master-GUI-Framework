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

    Methods:
    - `Size()`: Returns the overridden width & height of the cell, or the width/height of the child if the dimension had not been overridden. 
    - `CachedPosition()`: Returns the position last provided in `cell:Draw(x, y)`.
    - `Geometry()`: Returns the cached position and size.
]]
function framework:Cell(body, decorations, cornerRadius)
    local cell = { cornerRadius = cornerRadius, decorations = decorations }

    local width, height
    local cachedX, cachedY
    function cell:Layout(availableWidth, availableHeight)
        width, height = body:Layout(availableWidth, availableHeight)
        return width, height
    end

    function cell:Size()
        return self.overrideWidth or width, self.overrideHeight or height
    end
    function cell:CachedPosition()
        return cachedX, cachedY
    end
    function cell:Geometry()
        return cachedX, cachedY, self.overrideWidth or width, self.overrideHeight or height
    end

    function cell:Position(x, y)
        cachedX = x
        cachedY = y
        table_insert(activeDrawingGroup.drawTargets, self)
        body:Position(x, y)
    end

    function cell:Draw()
        for i = 1, #self.decorations do
            self.decorations[i]:Draw(self, cachedX, cachedY, self.overrideWidth or width, self.overrideHeight or height)
        end
    end

    return cell
end