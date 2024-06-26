local max = Include.math.max

-- Allows auto-sizing of a component with unbounded height between two components with bounded width.
-- 
-- The above and below components provided MUST be of bounded height, otherwise this component will not size correctly.
-- An example of an unbounded component is one that returns `availableWidth, availableHeight` from its `Layout(availableWidth, availableHeight)` method.
function framework:VerticalHungryStack(viewAbove, hungryView, viewBelow, xAnchor)
    local stack = {}

    local widthAbove, heightAbove
    local widthBelow, heightBelow
    local hungryWidth, hungryHeight

    local maxWidth

    function stack:Layout(availableWidth, availableHeight)
        widthAbove, heightAbove = viewAbove:Layout(availableWidth, availableHeight)
        widthBelow, heightBelow = viewBelow:Layout(availableWidth, availableHeight - heightAbove)
        hungryWidth, hungryHeight = hungryView:Layout(availableWidth, availableHeight - heightAbove - heightBelow)

        hungryHeight = max(hungryHeight, 0)

        maxWidth = max(widthAbove, widthBelow, hungryWidth)

        return maxWidth, hungryHeight + heightAbove + heightBelow
    end
    function stack:Position(x, y)
        viewBelow:Position(x + (maxWidth - widthBelow) * xAnchor, y)
        hungryView:Position(x + (maxWidth - hungryWidth) * xAnchor, y + heightBelow)
        viewAbove:Position(x + (maxWidth - widthAbove) * xAnchor, y + heightBelow + hungryHeight)
    end 

    return stack
end