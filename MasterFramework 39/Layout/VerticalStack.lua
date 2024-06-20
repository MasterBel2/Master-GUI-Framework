local max = Include.math.max
local floor = Include.math.floor
local table_joinArrays = Include.table.joinArrays
local unpack = Include.unpack

-- Elements that take all available height (or an unbounded function of it) will likely not size correctly. 
-- Instead, use `framework:VerticalHungryStack`.
-- (N.B. Unbounded components at the end of the stack will always size correctly. An example of a component with
-- unbounded height is one that returns `availableWidth, availableHeight` from its `Layout` method.)
function framework:VerticalStack(contents, spacing, xAnchor)
	local verticalStack = { members = contents, xAnchor = xAnchor, spacing = spacing }

	local maxWidth

	local cachedXAnchor
	local cachedMemberCount

	function verticalStack:LayoutChildren()
		local layoutChildren = {}
		for i = 1, #self.members do
			layoutChildren[i] = { self.members[i]:LayoutChildren() }
		end

		return self, unpack(table_joinArrays(layoutChildren))
	end

	function verticalStack:NeedsLayout()
		local members = self.members
		if #members ~= cachedMemberCount or cachedXAnchor ~= self.xAnchor then 
			return true
		end
		for i = 1, cachedMemberCount do
			local member = members[cachedMemberCount - (i - 1)]
			if i ~= member.vStackCachedIndex then
				return true
			end
		end
	end

	function verticalStack:Layout(availableWidth, availableHeight)

		local members = self.members
		cachedMemberCount = #members
		
		if cachedMemberCount == 0 then
			return 0, 0
		end

		local elapsedDistance = 0
	 	maxWidth = 0
		local spacing = self.spacing()
		
		for i = 1, cachedMemberCount do
			local member = members[cachedMemberCount - (i - 1)]
			local memberWidth, memberHeight = member:Layout(availableWidth, availableHeight - elapsedDistance)
			member.vStackCachedIndex = i
			member.vStackCachedY = elapsedDistance
			member.vStackCachedWidth = memberWidth
			elapsedDistance = elapsedDistance + memberHeight + spacing
			maxWidth = max(maxWidth, memberWidth)
		end

		return maxWidth, elapsedDistance - spacing
	end

	function verticalStack:Position(x, y)
		local members = self.members
		cachedXAnchor = self.xAnchor

		for i = 1, cachedMemberCount do
			local member = members[i]
			member:Position(x + floor((maxWidth - member.vStackCachedWidth) * cachedXAnchor), y + member.vStackCachedY)
		end
	end

	return verticalStack
end