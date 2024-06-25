--[[
    Button is an interactive, pressable button with a customisable action.

    Read-only properties:
    - visual: The child component shown within the interactive interface of the button.
    - background: The component that draws the button's background decorations, which indicate interaction.

    Read/write properties:
    - action: The action to be performed when the button is pressed. 
              The action will be called on mouse release, if the cursor is still inside the button's bounds.
]]
function framework:Button(visual, action)
    local button = { visual = visual, action = action }
    local background = framework:Background(visual, emptyTable, framework:AutoScalingDimension(3))

    local responder = framework:MouseOverChangeResponder(
        framework:MousePressResponder(
            cell,
            function(self, x, y, button)
                if button ~= 1 then return false end
                if framework.PointIsInRect(x, y, self:Geometry()) then
                    cell:SetDecorations(framework.buttonStyles.selectedBackgroundDecorations)
                else
                    cell:SetDecorations(framework.buttonStyles.defaultBackgroundDecorations)
                end
                return true
            end,
            function(self, x, y, dx, dy)
                if framework.PointIsInRect(x, y, self:Geometry()) then
                    cell:SetDecorations(framework.buttonStyles.selectedBackgroundDecorations)
                else
                    cell:SetDecorations(framework.buttonStyles.defaultBackgroundDecorations)
                end
            end, 
            function(self, x, y)
                if framework.PointIsInRect(x, y, self:Geometry()) then
                    cell:SetDecorations(framework.buttonStyles.hoverBackgroundDecorations)
                    button.action(button)
                else
                    cell:SetDecorations(framework.buttonStyles.unhighlightedBackgroundDecorations)
                end
            end
        ),
        function(isInside)
            cell:SetDecorations((isInside and framework.buttonStyles.hoverBackgroundDecorations) or framework.buttonStyles.unhighlightedBackgroundDecorations)
        end
    )

    function button:Layout(...)
        return responder:Layout(...)
    end
    function button:Position(...)
        responder:Position(...)
    end

    button.background = background

    return button
end