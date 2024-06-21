function framework:Button(visual, action)
    local defaultMargin = framework.dimension.defaultMargin
    local button = { visual = visual }
    local cell = framework:Background(visual, {}, framework:AutoScalingDimension(3))

    local highlightColor = framework.color.hoverColor
    button.action = action

    local responder = framework:MouseOverChangeResponder(
        framework:MousePressResponder(
            cell,
            function(self, x, y, button)
                if button ~= 1 then return false end
                if framework.PointIsInRect(x, y, self:Geometry()) then
                    cell.decorations = { [1] = framework.color.pressColor }
                else
                    cell.decorations = {}
                end
                return true
            end,
            function(self, x, y, dx, dy)
                if framework.PointIsInRect(x, y, self:Geometry()) then
                    cell.decorations = { [1] = framework.color.pressColor }
                else
                    cell.decorations = {}
                end
            end, 
            function(self, x, y)
                if framework.PointIsInRect(x, y, self:Geometry()) then
                    cell.decorations[1] = highlightColor
                    button.action(button)
                else
                    cell.decorations = {}
                end
            end
        ),
        function(isInside)
            cell.decorations[1] = (isInside and highlightColor) or unhighlightedColor
        end
    )

    function button:LayoutChildren()
        return cell:LayoutChildren()
    end

    function button:Layout(...)
        return responder:Layout(...)
    end
    function button:Position(...)
        responder:Position(...)
    end

    button.visual = visual
    button.action = action
    button.cell = cell

    return button
end