local WG = Include.WG
local FlowUIExtensions = {}
framework.FlowUIExtensions = FlowUIExtensions

function FlowUIExtensions:Element()
    local element = {}

    function element:NeedsRedrawForDrawer()
        return false
    end

    function element:Draw(rect, x, y, width, height)
        WG.FlowUI.Draw.Element(x, y, x + width, y + height)
    end

    return element
end