function framework:CheckBox(scale, action)
    local checkbox = {}
    local dimension = framework:Dimension(scale)
    local radius = framework:Dimension(scale / 2)
    
    local checked = false

    local highlightColor = framework.color.hoverColor
    local unhighlightedColor = framework.stroke.defaultBorder

    local rect = framework:Rect(dimension, dimension, radius, { unhihlightedColor })
    
    local body = framework:MouseOverChangeResponder(
        framework:MousePressResponder(
            rect,
            function(self, x, y, button)
                highlightColor = framework.color.pressColor
                rect.decorations[1] = highlightColor
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
            rect.decorations[1] = (isInside and highlightColor) or unhighlightedColor
        end
    )
     
    function checkbox:Position(...)
        body:Position(...)
    end
    function checkbox:Layout(...)
        return body:Layout(...)
    end

    function checkbox:SetChecked(newChecked)
        checked = newChecked
        unhighlightedColor = (checked and framework.color.selectedColor) or framework.stroke.defaultBorder
        rect.decorations[1] = (isInside and highlightColor) or unhighlightedColor
    end

    checkbox:SetChecked(checked)
    return checkbox
end