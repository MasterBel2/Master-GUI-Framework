local imap = Include.table.imap
--[[
    A `framework:MenuAnchor` that displays a text field with content configurable by options displayed in a dropdown menu.

    (Left-click to show menu.)

    Parameters:
    - `options`: an array of strings, which will be displayed to the user.
    - `selectAction`: a function to call when an new option is selected.

    Methods:
    - `GetSelectedIndex()`: Returns the index of the selected option.
    - `SelectIndex(n)`: Selects the option at the given index.
    - `SetOptions(newOptions)`: Updates the options shown in the dropdown menu.

    `framework:MultiOptionBox` also inherits all methods and properties from `framework:MousePressResponder`.
]]
function framework:MultiOptionBox(options, selectAction)
    local selectedIndex = 1
    local text = framework:Text(options[selectedIndex])
    local box

    local function internalSelectAction(option, index, _, anchor)
        box:SelectIndex(index)
        anchor:HideMenu()
    end

    local xOffset, yOffset
    local anchor = framework:MenuAnchor(
        text,
        {},
        function(anchorX, anchorY, anchorWidth, anchorHeight, menu)
            return anchorX - framework:Dimension(8)(), framework.viewportHeight - anchorY - anchorHeight - menu.topMargin() - framework:Dimension(1)()
        end,
        "Menu for MultiOptionBox"
    )

    box = framework:MousePressResponder(
        anchor,
        function(responder, x, y, button)
            if button == 1 then
                local responderX, responderY = responder:CachedPosition()
                xOffset = x - responderX
                yOffset = y - responderY
                anchor:ShowMenu()
            end
            return true
        end,
        function() end,
        function() end
    )

    function box:GetSelectedIndex()
        return selectedIndex
    end

    function box:SelectIndex(n)
        selectedIndex = n
        local title = options[n]
        text:SetString(title)
        selectAction(box, n, title)
    end

    function box:SetOptions(newOptions)
        options = newOptions
        anchor:SetMenuOptions(imap(options, function(index, option)
            return {
                title = option, 
                action = internalSelectAction
            }
        end))
    end

    box:SetOptions(options)

    return box
end