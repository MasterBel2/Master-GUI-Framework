function framework:Box(child)
	local box = { child = child }

    local cachedChild
    function box:NeedsLayout()
        return cachedChild ~= self.child
    end
    function box:Layout(....)
        cachedChild = child
        return cachedChild:Layout(...)
    end
    function box:LayoutChildren()
        return self, self.child:LayoutChildren()
    end
    function box:Position(...)
        return cachedChild:Position(...)
    end

    return box
end
