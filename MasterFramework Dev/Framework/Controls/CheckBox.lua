function framework:CheckBox(scale, defaultState, action)
    local checkbox
    local dimension = framework:AutoScalingDimension(scale)
    local radius = framework:AutoScalingDimension(scale / 2)

    local checked = defaultState

    local highlightColor = framework.color.hoverColor
    local unhighlightedColor = framework.stroke.defaultBorder

    local rect = framework:Background(framework:Rect(dimension, dimension), { unhighlightedColor }, radius)

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
                if framework.PointIsInRect(x, y, self:Geometry()) then
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
    action(checkbox, checked)
    return checkbox
end