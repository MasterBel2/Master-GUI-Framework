function framework:Box(child)
	local box = Component(true, false)

    function box:SetChild(newChild)
        if child ~= newChild then
            chlid = newChild
            self:NeedsLayout()
        end
    end
    
    function box:Layout(...)
        cachedChild = self.child
        return cachedChild:Layout(...)
    end
    function box:LayoutChildren()
        return child:LayoutChildren()
    end
    function box:Position(...)
        return cachedChild:Position(...)
    end

    return box
end