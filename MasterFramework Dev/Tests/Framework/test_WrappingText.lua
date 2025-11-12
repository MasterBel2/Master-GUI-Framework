return {
    targetFileName = "LuaUI/Widgets/gui_master_framework_dev.lua",
    test_default = function(widget)
        widget:Initialize()
        local framework = widget.WG["MasterFramework Dev"]
        
        local testText = framework:WrappingText(string.rep(string.rep("a", 19) .. "\n", 1000))

        local key, element = framework:InsertElement(framework:PrimaryFrame(testText))

        widget:DrawScreen()
    end,
    test_displayIndexToRawIndex = function(widget)
        widget:Initialize()
        local framework = widget.WG["MasterFramework Dev"]
        
        local testText = framework:WrappingText(string.rep(string.rep("a", 19) .. "\n", 1000))

        local key, element = framework:InsertElement(framework:PrimaryFrame(testText))

        widget:DrawScreen()

        for i = 1, 100000 do
            testText:DisplayIndexToRawIndex(testText:GetDisplayString():len())
        end
    end,
}