local max = Include.math.max
local floor = Include.math.floor
local table_joinArrays = Include.table.joinArrays
local unpack = Include.unpack

-- Elements that take all available height (or an unbounded function of it) will likely not size correctly. 
-- Instead, use `framework:VerticalHungryStack`.
-- (N.B. Unbounded components at the end of the stack will always size correctly. An example of a component with
-- unbounded height is one that returns `availableWidth, availableHeight` from its `Layout` method.)
function framework:VerticalStack(_members, spacing, xAnchor)
	local verticalStack = { xAnchor = xAnchor, spacing = spacing }

	local maxWidth

	local cachedXAnchor
	local cachedMemberCount

	local members = {}
	local membersUpdated

	function verticalStack:GetMembers()
		local membersCopy = {}
		for i = 1, #members do 
			membersCopy[i] = members[i]
		end
		return members
	end
	function verticalStack:SetMembers(newMembers)
		membersUpdated = true
		for i = #newMembers + 1, #members do
			members[i] = nil
		end
		for i = 1, #newMembers do
			members[i] = newMembers[i]
		end
	end

	verticalStack:SetMembers(_members)

	function verticalStack:LayoutChildren()
		local layoutChildren = {}
		for i = 1, #members do
			layoutChildren[i] = { members[i]:LayoutChildren() }
		end

		return self, unpack(table_joinArrays(layoutChildren))
	end

	function verticalStack:NeedsLayout()
		return membersUpdated or cachedXAnchor ~= self.xAnchor
	end

	function verticalStack:Layout(availableWidth, availableHeight)
		membersUpdated = false

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
			member.vStackCachedY = elapsedDistance
			member.vStackCachedWidth = memberWidth
			elapsedDistance = elapsedDistance + memberHeight + spacing
			maxWidth = max(maxWidth, memberWidth)
		end

		return maxWidth, elapsedDistance - spacing
	end

	function verticalStack:Position(x, y)
		cachedXAnchor = self.xAnchor

		for i = 1, cachedMemberCount do
			local member = members[i]
			member:Position(x + floor((maxWidth - member.vStackCachedWidth) * cachedXAnchor), y + member.vStackCachedY)
		end
	end

	return verticalStack
end