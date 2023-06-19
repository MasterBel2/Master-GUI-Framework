local max = Include.math.max

-- Allows auto-sizing of a component with unbounded width between two components with bounded width.
-- 
-- The left and right components provided MUST be of bounded width, otherwise this component will not size correctly.
-- An example of an unbounded component is one that returns `availableWidth, availableHeight` from its `Layout(availableWidth, availableHeight)` method.
function framework:HorizontalHungryStack(viewLeft, hungryView, viewRight, yAnchor)
    local stack = {}

    local widthLeft, heightLeft
    local widthRight, heightRight
    local hungryWidth, hungryHeight

    local maxHeight

    function stack:Layout(availableWidth, availableHeight)
        widthLeft, heightLeft = viewLeft:Layout(availableWidth, availableHeight)
        widthRight, heightRight = viewRight:Layout(availableWidth - widthLeft, availableHeight)
        hungryWidth, hungryHeight = hungryView:Layout(availableWidth - widthLeft - widthRight, availableHeight)

        maxHeight = max(heightRight, heightLeft, hungryHeight)

        return hungryWidth + widthLeft + widthRight, maxHeight
    end
    function stack:Draw(x, y)
        viewLeft:Draw(x, y + (maxHeight - heightLeft) * yAnchor)
        hungryView:Draw(x + widthLeft, y + (maxHeight - hungryHeight) * yAnchor)
        viewRight:Draw(x + widthLeft + hungryWidth, y + (maxHeight - heightRight) * yAnchor)
    end

    return stack
end