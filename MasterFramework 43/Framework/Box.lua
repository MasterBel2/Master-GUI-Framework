--[[
    Box is a component that does not modify layout other than to allow you to swith its child. 
    Since most compoments will not allow you to modify their child, provide `Box` as a component's 
    child to allow you to modify the view hierarchy.

    Call `box:SetChild(newChild)` to update `Box`'s child.
]]
function framework:Box(child)
	local box = Component(true, false)

    function box:SetChild(newChild)
        if child ~= newChild then
            child = newChild
            self:NeedsLayout()
        end
    end
    
    function box:Layout(...)
        self:RegisterDrawingGroup()
        return child:Layout(...)
    end
    function box:Position(...)
        return child:Position(...)
    end

    return box
end