return {
    targetFileName = "LuaUI/Widgets/gui_master_framework_dev.lua",
    --[[
        Verifies the fix for a bug where Dimension wasn't correctly registering itself
        to provide updates to its drawing groups.
    ]]
    test_dimension_update = function(widget)
        widget:Initialize()
        local framework = widget.WG["MasterFramework Dev"]
        
        local TestDimension = function(x) return framework:Dimension(function(x) return x end, x) end
        local testDimension1 = TestDimension(1)
        local testDimension2 = TestDimension(2)

        local key, element = framework:InsertElement(framework:PrimaryFrame(framework:Rect(testDimension1, testDimension2)))

        testDimension1.Update(3)
        widget:DrawScreen()

        if element.drawingGroup:CachedSize() ~= 3 then
            error("Dimension update is not reflected in drawing group's size")
        end
    end
}