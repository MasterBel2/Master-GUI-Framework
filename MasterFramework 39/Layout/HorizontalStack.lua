local floor = Include.math.floor
local max = Include.math.max

-- Elements that take all available width (or an unbounded function of it) will likely not size correctly. 
-- Instead, use `framework:HorizontalHungryStack`.
-- (N.B. Unbounded components at the end of the stack will always size correctly. An example of an component with
-- unbounded width is one that returns `availableWidth, availableHeight` from its `Layout` method.)
function framework:HorizontalStack(_members, spacing, yAnchor)
	local horizontalStack = { members = _members, yAnchor = yAnchor or 0.5, spacing = spacing }

	-- for _, member in pairs(members) do
	-- 	if member ~= nil then
	-- 		insert(horizontalStack.members, member)
	-- 	end
	-- end

	local maxHeight

	local cachedYAnchor
	local cachedMemberCount
	function horizontalStack:NeedsLayout()
		local members = self.members
		if #members ~= cachedMemberCount or cachedYAnchor ~= self.yAnchor then 
			return true
		end
		for i = 1, cachedMemberCount do
			if i ~= members[i].hStackCachedIndex or members[i]:NeedsLayout() then
				return true
			end
		end
	end

	function horizontalStack:Layout(availableWidth, availableHeight)

		local members = self.members
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
			member.hStackCachedIndex = i
			member.hStackCachedX = elapsedDistance
			member.hStackCachedHeight = memberHeight
			elapsedDistance = elapsedDistance + memberWidth + spacing
			maxHeight = max(memberHeight, maxHeight)
		end
		
		return elapsedDistance - spacing, maxHeight
	end

	function horizontalStack:Position(x, y)
		local members = self.members
		cachedYAnchor = self.yAnchor

		for i = 1, cachedMemberCount do
			local member = members[i]
			member:Position(x + member.hStackCachedX, y + floor((maxHeight - member.hStackCachedHeight) * cachedYAnchor))
		end
	end
	
	return horizontalStack
end