local imap = Include.table.imap

--[[
    A variant of `framework:VerticalStack` that wraps each of its elements in an equal-sized `framework:Cell`.

    Methods:
    - `SetMembers(newMembers)`: takes an array of components, wraps each of them in a `framework:Cell`, and stores the resulting array in its `members` property.
    - `_Layout()`: `VerticalStack`'s layout method. Do not call this directly.

    `framework:CelledVerticalStack` also provides all the methods and properties of `framework:VerticalStack`.
]]
function framework:CelledVerticalStack(contents, spacing)
    local celledStack = framework:VerticalStack({}, spacing, 0)

    local _SetMembers = celledStack.SetMembers
    function celledStack:SetMembers(newMembers)
        _SetMembers(self, imap(newMembers, function(_, member)
            return framework:Cell(member, {}, framework:AutoScalingDimension(0))
        end))
    end

    celledStack:SetMembers(contents)

    celledStack._Layout = celledStack.Layout
    function celledStack:Layout(availableWidth, availableHeight)
        local width, height = self:_Layout(availableWidth, availableHeight)
        local members = self:GetMembers()
        for i = 1, #members do
            members[i].overrideWidth = width
        end
        return width, height
    end

    return celledStack
end