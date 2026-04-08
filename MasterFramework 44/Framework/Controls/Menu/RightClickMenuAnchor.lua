--[[
    A `framework:MenuAnchor` that reveals a menu on right-click.

    Parameters:
    - `wrappedRect`: the component for which the menu is being provided. 
                     This component will be laid out and drawn by `RightClickMenuAnchor`.
    - `options`: The options provided in the menu.
    - `tag`: A string that will be included in the menu's key, for debugging purposes.

    `framework:RightClickMenuAnchor` also provides all the methods and properties of `framework:MousePressResponder`.
]]
function framework:RightClickMenuAnchor(wrappedRect, options, menuTag)
    local xOffset, yOffset
    local anchor = framework:MenuAnchor(
        wrappedRect, 
        options, 
        function(anchorX, anchorY, anchorWidth, anchorHeight, menu)
            return xOffset - 5, framework.viewportHeight - yOffset - menu.topMargin()
        end,
        "Right-Click Menu for " .. menuTag
    )

    return framework:MousePressResponder(
        anchor,
        function(responder, x, y, button)
            if button == 3 then
                xOffset = x
                yOffset = y
                anchor:ShowMenu()
            end
        end,
        function() end,
        function() end
    )
end