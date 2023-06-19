function framework:Button(visual, action)
    local defaultMargin = framework.dimension.defaultMargin
    local button = { visual = visual }
    local margin = framework:MarginAroundRect(visual, defaultMargin, defaultMargin, defaultMargin, defaultMargin, {}, marginDimension, false)

    local highlightColor = framework.color.hoverColor
    button.action = action

    local responder = framework:MouseOverChangeResponder(
        framework:MousePressResponder(
            margin,
            function(self, x, y, button)
                if button ~= 1 then return false end
                if framework.PointIsInRect(x, y, self:Geometry()) then
                    margin.decorations = { [1] = framework.color.pressColor }
                else
                    margin.decorations = {}
                end
                return true
            end,
            function(self, x, y, dx, dy)
                if framework.PointIsInRect(x, y, self:Geometry()) then
                    margin.decorations = { [1] = framework.color.pressColor }
                else
                    margin.decorations = {}
                end
            end, 
            function(self, x, y)
                if framework.PointIsInRect(x, y, self:Geometry()) then
                    margin.decorations[1] = highlightColor
                    button.action(button)
                else
                    margin.decorations = {}
                end
            end
        ),
        function(isInside)
            margin.decorations[1] = (isInside and highlightColor) or unhighlightedColor
        end
    )

    function button:Layout(...)
        return responder:Layout(...)
    end
    function button:Draw(...)
        responder:Draw(...)
    end

    button.margin = margin

    return button
end