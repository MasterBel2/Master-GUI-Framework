function framework:CheckBox(scale, action)
    local checkbox
    local dimension = framework:AutoScalingDimension(scale)
    local radius = framework:AutoScalingDimension(scale / 2)
    
    local checked = false

    local highlightColor = framework.color.hoverColor
    local unhighlightedColor = framework.stroke.defaultBorder

    local rect = framework:Background(framework:Rect(dimension, dimension), { unhihlightedColor }, radius)
    
    checkbox = framework:MouseOverChangeResponder(
        framework:MousePressResponder(
            rect,
            function(self, x, y, button)
                highlightColor = framework.color.pressColor
                rect:SetDecorations({ highlightColor })
                return true
            end,
            function(self, x, y, dx, dy)
            end,
            function(self, x, y)
                highlightColor = framework.color.hoverColor
                if self:ContainsAbsolutePoint(x, y) then
                    checkbox:SetChecked(not checked)
                    action(checkbox, checked)
                end
            end
        ),
        function(isInside)
            rect:SetDecorations({ (isInside and highlightColor) or unhighlightedColor })
        end
    )

    function checkbox:SetChecked(newChecked)
        checked = newChecked
        unhighlightedColor = (checked and framework.color.selectedColor) or framework.stroke.defaultBorder
        rect:SetDecorations({ (isInside and highlightColor) or unhighlightedColor })
    end

    checkbox:SetChecked(checked)
    return checkbox
end