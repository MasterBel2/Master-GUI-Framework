local max = Include.math.max
local floor = Include.math.floor

-- Elements that take all available height (or an unbounded function of it) will likely not size correctly. 
-- Instead, use `framework:VerticalHungryStack`.
-- (N.B. Unbounded components at the end of the stack will always size correctly. An example of a component with
-- unbounded height is one that returns `availableWidth, availableHeight` from its `Layout` method.)
function framework:VerticalStack(contents, spacing, xAnchor)
	local verticalStack = { members = contents, xAnchor = xAnchor, spacing = spacing }

	local maxWidth

	function verticalStack:Layout(availableWidth, availableHeight)

		local members = self.members
		local memberCount = #members
		
		if memberCount == 0 then
			return 0, 0
		end

		local elapsedDistance = 0
	 	maxWidth = 0
		local spacing = self.spacing()
		
		for i = 1, memberCount do
			local member = members[memberCount - (i - 1)]
			local memberWidth, memberHeight = member:Layout(availableWidth, availableHeight - elapsedDistance)
			member.vStackCachedY = elapsedDistance
			member.vStackCachedWidth = memberWidth
			elapsedDistance = elapsedDistance + memberHeight + spacing
			maxWidth = max(maxWidth, memberWidth)
		end

		return maxWidth, elapsedDistance - spacing
	end

	function verticalStack:Draw(x, y)
		local members = self.members
		local xAnchor = self.xAnchor

		for i = 1, #members do 
			local member = members[i]
			member:Draw(x + floor((maxWidth - member.vStackCachedWidth) * xAnchor), y + member.vStackCachedY)
		end
	end

	return verticalStack
end