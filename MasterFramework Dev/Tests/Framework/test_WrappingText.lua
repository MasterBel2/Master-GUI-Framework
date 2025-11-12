return {
    targetFileName = "LuaUI/Widgets/gui_master_framework_dev.lua",
    test_default = function(widget)
        widget.Spring.GetViewGeometry = function() return 500, 10000 end

        widget:Initialize()
        local framework = widget.WG["MasterFramework Dev"]
        
        local testText = framework:WrappingText(VFS.LoadFile("LuaUI/MasterFramework Dev/Tests/TestResources/code_example.lua"))
        function testText:ColoredString()
            return VFS.LoadFile("LuaUI/MasterFramework Dev/Tests/TestResources/code_example_colored.lua")
        end

        local key, element = framework:InsertElement(framework:PrimaryFrame(testText))
    end,
    test_displayIndexToRawIndex = function(widget)
        widget.Spring.GetViewGeometry = function() return 500, 10000 end

        widget:Initialize()
        local framework = widget.WG["MasterFramework Dev"]
        
        local testText = framework:WrappingText(VFS.LoadFile("LuaUI/MasterFramework Dev/Tests/TestResources/code_example.lua"))
        function testText:ColoredString()
            return VFS.LoadFile("LuaUI/MasterFramework Dev/Tests/TestResources/code_example_colored.lua")
        end

        local key, element = framework:InsertElement(framework:PrimaryFrame(testText))

        for i = 1, 1000 do
            testText:DisplayIndexToRawIndex(testText:GetDisplayString():len())
        end
    end,
}