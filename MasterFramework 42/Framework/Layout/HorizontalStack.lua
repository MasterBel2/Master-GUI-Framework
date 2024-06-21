local floor = Include.math.floor
local max = Include.math.max
local table_joinArrays = Include.table.joinArrays
local unpack = Include.unpack

-- Elements that take all available width (or an unbounded function of it) will likely not size correctly. 
-- Instead, use `framework:HorizontalHungryStack`.
-- (N.B. Unbounded components at the end of the stack will always size correctly. An example of an component with
-- unbounded width is one that returns `availableWidth, availableHeight` from its `Layout` method.)
function framework:HorizontalStack(_members, spacing, yAnchor)
	local horizontalStack = { yAnchor = yAnchor or 0.5, spacing = spacing }

	local members = {}
	local membersUpdated

	function horizontalStack:GetMembers()
		local membersCopy = {}
		for i = 1, #members do 
			membersCopy[i] = members[i]
		end
		return members
	end
	function horizontalStack:SetMembers(newMembers)
		membersUpdated = true
		for i = #newMembers, #members do
			members[i] = nil
		end
		for i = 1, #newMembers do
			members[i] = newMembers[i]
		end
	end

	horizontalStack:SetMembers(_members)

	local maxHeight

	function horizontalStack:LayoutChildren()
		local layoutChildren = {}
		for i = 1, #members do
			layoutChildren[i] = { members[i]:LayoutChildren() }
		end

		return self, unpack(table_joinArrays(layoutChildren))
	end

	local cachedYAnchor
	local cachedMemberCount
	function horizontalStack:NeedsLayout()
		return membersUpdated or cachedYAnchor ~= self.yAnchor
	end

	function horizontalStack:Layout(availableWidth, availableHeight)
		membersUpdated = false
		cachedMemberCount = #members

		if cachedMemberCount == 0 then
			return 0, 0
		end

		local elapsedDistance = 0
		maxHeight = 0

		local spacing = self.spacing()

		for i = 1, cachedMemberCount do
			local member = members[i]
			local memberWidth, memberHeight = member:Layout(availableWidth - elapsedDistance, availableHeight)
			member.hStackCachedX = elapsedDistance
			member.hStackCachedHeight = memberHeight
			elapsedDistance = elapsedDistance + memberWidth + spacing
			maxHeight = max(memberHeight, maxHeight)
		end
		
		return elapsedDistance - spacing, maxHeight
	end

	function horizontalStack:Position(x, y)
		cachedYAnchor = self.yAnchor

		for i = 1, cachedMemberCount do
			local member = members[i]
			member:Position(x + member.hStackCachedX, y + floor((maxHeight - member.hStackCachedHeight) * cachedYAnchor))
		end
	end
	
	return horizontalStack
end