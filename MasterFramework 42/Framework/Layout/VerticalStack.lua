local max = Include.math.max
local floor = Include.math.floor
local table_joinArrays = Include.table.joinArrays
local unpack = Include.unpack

-- Elements that take all available height (or an unbounded function of it) will likely not size correctly. 
-- Instead, use `framework:VerticalHungryStack`.
-- (N.B. Unbounded components at the end of the stack will always size correctly. An example of a component with
-- unbounded height is one that returns `availableWidth, availableHeight` from its `Layout` method.)
function framework:VerticalStack(_members, spacing, xAnchor)
	local verticalStack = Component(true, false)

	local maxWidth

	local cachedMemberCount

	local members = {}

	function verticalStack:GetMembers()
		local membersCopy = {}
		for i = 1, #members do 
			membersCopy[i] = members[i]
		end
		return members
	end

	function verticalStack:SetMembers(newMembers)
		self:NeedsLayout()
		for i = #newMembers + 1, #members do
			members[i] = nil
		end
		for i = 1, #newMembers do
			members[i] = newMembers[i]
		end
	end

	verticalStack:SetMembers(_members)

	function verticalStack:SetXAnchor(newXAnchor)
		if newXAnchor ~= xAnchor then
			self:NeedsPosition()
			xAnchor = newXAnchor
		end
	end

	function verticalStack:Layout(availableWidth, availableHeight)
		self:RegisterDrawingGroup()

		cachedMemberCount = #members
		if cachedMemberCount == 0 then
			return 0, 0
		end

		local elapsedDistance = 0
	 	maxWidth = 0
		local spacing = spacing()
		
		for i = 1, cachedMemberCount do
			local member = members[cachedMemberCount - (i - 1)]
			local memberWidth, memberHeight = member:Layout(availableWidth, availableHeight - elapsedDistance)
			member.vStackCachedY = elapsedDistance
			member.vStackCachedWidth = memberWidth
			elapsedDistance = elapsedDistance + memberHeight + spacing
			maxWidth = max(maxWidth, memberWidth)
		end

		return maxWidth, elapsedDistance - spacing
	end

	function verticalStack:Position(x, y)
		for i = 1, cachedMemberCount do
			local member = members[i]
			member:Position(x + floor((maxWidth - member.vStackCachedWidth) * xAnchor), y + member.vStackCachedY)
		end
	end

	return verticalStack
end