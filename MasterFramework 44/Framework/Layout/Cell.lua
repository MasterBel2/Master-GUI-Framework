local table_insert = Include.table.insert

--[[
    `Cell` is used to override the size alotted to an interface, e.g. for a table with equal-sized cells in each column. 
    See `CelledVerticalStack` for an example use.

    Parameters:
     - `child`: the interface to be displayed in the cell.

    Methods:
     - `cell:SetOverrideDimensions(newOverrideWidth, newOverrideHeight)`: Set a size to be maintained by the cell.
                                                                          If either value is nil, the value returned by the child's layout method will be used instead.
]]
function framework:Cell(child)
    local cell = Component(true, false)

    local overrideWidth, overrideHeight
    local width, height

    function cell:SetOverrideDimensions(newOverrideWidth, newOverrideHeight)
        if newOverrideWidth ~= overrideWidth or newOverrideHeight ~= overrideHeight then
            overrideWidth = newOverrideWidth
            overrideHeight = newOverrideHeight
            self:NeedsLayout()
        end
    end

    function cell:Size()
        return overrideWidth or width, overrideHeight or height
    end

    function cell:Layout(availableWidth, availableHeight)
        self:RegisterDrawingGroup()
        width, height = child:Layout(availableWidth, availableHeight)
        return overrideWidth or width, overrideHeight or height
    end

    function cell:Position(x, y)
        child:Position(x, y)
    end

    return cell
end