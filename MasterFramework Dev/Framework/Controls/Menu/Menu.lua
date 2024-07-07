local imap = Include.table.imap

--[[
    A floating, auto-hiding menu displaying a list of options.
    
    Parameters:
    - options: an array of menu items - one of either a button, a submenu, or a non-interactive title. E.g.
    ```
    options = {
        [1] = { title = "...", action = function(option, index, menu, anchor) end, enabled = true }, -- Button
        [2] = { title = "...", subOptions = { ... } }, -- Submenu
        [2] = { title = "..." }, -- Section title
        ...
    }
    ```
    - anchor: a component that determines whether the menu should show or not. 
      This menu will tell that anchor to stay alive if one of our submenus has focus, via `anchor:ShowMenu()`.
      For the default implementation, see `framework:MenuAnchor`

    Methods:
    - `SetOptions(newOptions)`: Updates the options displayed in the menu.

    Properties:
    - `mouseIsOver`: (read-only) indicates whether the mouse is above the menu. 
                     `true` when mouse is over, `nil` or `false` when mouse is not over the menu.
    - `leftMargin`: (read-only) the `framework:Dimension()` providing the left margin of the menu.
    - `topMargin`: (read-only) the `framework:Dimension()` providing the top margin of the menu.
    - `rightMargin`: (read-only) the `framework:Dimension()` providing the right margin of the menu.
    - `bottomMargin`: (read-only) the `framework:Dimension()` providing the bottom margin of the menu.

    Menu also inherits all properties and methods from `framework:AbsoluteOffsetFromTopLeft`.
]]
function framework:Menu(options, anchor)
    local menu

    local titleColor = framework:Color(0.7, 0.7, 0.7, 1)
    local celledStack

    local optionElements = {}

    celledStack = framework:CelledVerticalStack(optionElements, framework:AutoScalingDimension(0))

    local menuItemAtCoordinates
    local highlightedMenuItem

    local menuOptions = framework:MouseOverResponder(
        framework:MousePressResponder(
            celledStack,
            function(responder, x, y, button)
                local _, index = menuItemAtCoordinates(x, y)
                if button == 1 and index then
                    if options[index].action then
                        options[index]:action(index, menu, anchor)
                    end
                end
                return true
            end,
            function(responder, x, y, dx, dy, button) end,
            function(responder, x, y, button) end
        ),
        function(responder, x, y)
            local menuItem, index = menuItemAtCoordinates(x, y)

            if menuItem ~= highlightedMenuItem and highlightedMenuItem then
                highlightedMenuItem:SetDecorations({})
            end
            if menuItem then
                if options[index].subOptions or options[index].action then
                    menuItem:SetDecorations({ framework.color.hoverColor })
                end
                
                if options[index].subOptions then
                    optionElements[index]:ShowMenu()
                end
            end

            highlightedMenuItem = menuItem
        end,
        function(responder) end,
        function(responder)
            if highlightedMenuItem then
                highlightedMenuItem = nil
                highlightedMenuItem:SetDecorations({})
            end
        end
    )

    menuItemAtCoordinates = function(x, y)
        local responderX, responderY = menuOptions:CachedPosition()
        local stackMembers = celledStack:GetMembers()
        for i = 1, #stackMembers do
            local member = stackMembers[i]
            if framework.PointIsInRect(x, y, responderX, responderY + member.vStackCachedY, member:Size()) then
                return member, i
            end
        end
    end
    
    local leftMargin = framework:AutoScalingDimension(0)
    local topMargin = framework:AutoScalingDimension(8)
    local rightMargin = leftMargin
    local bottomMargin = topMargin

    local body = framework:MouseOverChangeResponder(
        framework:Background(
            framework:MarginAroundRect(
                menuOptions,
                leftMargin,
                topMargin,
                rightMargin,
                bottomMargin
            ),
            { framework:Color(0, 0, 0, 0.7) },
            framework:AutoScalingDimension(5)
        ),
        function(isOver)
            menu.mouseIsOver = isOver
        end
    )

    menu = framework:AbsoluteOffsetFromTopLeft(
        framework:PrimaryFrame(
            body
        ),
        0, 0
    )

    menu.leftMargin = leftMargin
    menu.topMargin = topMargin
    menu.rightMargin = rightMargin
    menu.bottomMargin = bottomMargin

    function menu:SetOptions(newOptions)
        optionElements = imap(options, function(index, option)
            local component
            if option.action then -- enabled is ignored for now
                component = framework:Text(option.title)
            elseif option.subOptions then
                component = framework:MenuAnchor(
                    framework:Text(option.title),
                    option.subOptions,
                    function(anchorX, anchorY, anchorWidth, anchorHeight, submenu)
                        anchor:ShowMenu()
                        local cellX, cellY, cellWidth, cellHeight = celledStack:GetMembers()[index]:Geometry()
                        return cellX + cellWidth, framework.viewportHeight - cellY - cellHeight - submenu.topMargin()
                    end,
                    option.title
                )
            else -- title only
                component = framework:Text(option.title, titleColor)
            end

            return framework:MarginAroundRect(
                component,
                framework:AutoScalingDimension(8),
                framework:AutoScalingDimension(1),
                framework:AutoScalingDimension(8),
                framework:AutoScalingDimension(1)
            )
        end)

        celledStack:SetMembers(optionElements)
    end

    menu:SetOptions(options)

    return menu
end