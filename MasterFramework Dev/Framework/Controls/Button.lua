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
    local background = framework:Background(visual, buttonStyles.defaultBackgroundDecorations, framework:AutoScalingDimension(3))

    local responder = framework:MouseOverChangeResponder(
        framework:MousePressResponder(
            background,
            function(self, x, y, button)
                if button ~= 1 then return false end
                if self:ContainsAbsolutePoint(x, y) then
                    background:SetDecorations(buttonStyles.selectedBackgroundDecorations)
                else
                    background:SetDecorations(buttonStyles.defaultBackgroundDecorations)
                end
                return true
            end,
            function(self, x, y, dx, dy)
                if self:ContainsAbsolutePoint(x, y) then
                    background:SetDecorations(buttonStyles.selectedBackgroundDecorations)
                else
                    background:SetDecorations(buttonStyles.defaultBackgroundDecorations)
                end
            end, 
            function(self, x, y)
                if self:ContainsAbsolutePoint(x, y) then
                    background:SetDecorations(buttonStyles.hoverBackgroundDecorations)
                    button.action(button)
                else
                    background:SetDecorations(buttonStyles.defaultBackgroundDecorations)
                end
            end
        ),
        function(isInside)
            background:SetDecorations((isInside and buttonStyles.hoverBackgroundDecorations) or buttonStyles.defaultBackgroundDecorations)
        end
    )

    function button:Layout(...)
        return responder:Layout(...)
    end
    function button:Position(...)
        responder:Position(...)
    end

    return button
end