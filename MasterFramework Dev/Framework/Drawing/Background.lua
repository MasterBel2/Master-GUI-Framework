local table_insert = Include.table.insert

--[[
    `Background` is a component used to draw decorations around a child.
    
    Notes: 
     - `Background` is a valid geometry target.
     - `Background` is a non-overriding extension of `Drawer`.

    Parameters:
     - `body`: the child component of the cell.
     - `decorations`: an array of decorations that implement `decoration:Draw(rect, x, y, width, height)` that will be called in-order to draw the cell's background.
     - `cornerRadius`: a function returning a number whose result will be used to determine the corner radius for the decorations drawn. This may be nil.

    Read/write properties:
     - `cornerRadius`: a function returning a number whose result will be used to determine the corner radius for the decorations drawn.

    Methods:
     - `background.CachedPosition()`: Returns the position last provided in `cell:Draw(x, y)`.
     - `background.Geometry()`: Returns the cached position and size.
     - `background.Size()`: Returns the overridden width & height of the cell, or the width/height of the child if the dimension had not been overridden. 
     - `background:SetDecorations(newDecorations)`: copies the array contents of `newDecorations` to be the new set of decorations drawn.
]]
function framework:Background(body, _decorations, cornerRadius)
    local background = Drawer()
    background.cornerRadius = cornerRadius or framework:AutoScalingDimension(0)
    local decorations = {}

    local width, height
    local cachedX, cachedY

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

    function background:Layout(availableWidth, availableHeight)
        width, height = body:Layout(availableWidth, availableHeight)
        return width, height
    end

    function background:Size()
        return width, height
    end
    function background:CachedPosition()
        return cachedX, cachedY
    end
    function background:Geometry()
        return cachedX, cachedY, width, height
    end

    function background:Position(x, y)
        cachedX = x
        cachedY = y
        table_insert(activeDrawingGroup.drawTargets, self)
        body:Position(x, y)
    end

    function background:Draw()
        self:RegisterDrawingGroup()
        
        for i = 1, #decorations do
            decorations[i]:Draw(self, cachedX, cachedY, width, height)
        end
    end

    return background
end 