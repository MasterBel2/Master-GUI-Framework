function widget:GetInfo()
    return {
        name = "MasterFramework FlowUI Extensions",
        description = "Integrates FlowUI drawing to assist in matching default styles",
        layer = -math.huge -- Run Initialise after MasterFramework file has loaded, but before any widget uses it
    }
end

local requiredFrameworkVersion = 18

function widget:Initialize()
    local MasterFramework = WG.MasterFramework[requiredFrameworkVersion]
    if MasterFramework and WG.FlowUI.Draw then
        local FlowUIExtensions = {}
        MasterFramework.FlowUIExtensions = FlowUIExtensions

        function FlowUIExtensions:Element()
            local element = {}

            function element:Draw(rect, x, y, width, height)
                WG.FlowUI.Draw.Element(x, y, x + width, y + height)
            end

            return element
        end

    end
end