local floor = Include.math.floor
local max = Include.math.max

function framework:HorizontalStack(_members, spacing, yAnchor)
	local horizontalStack = { members = _members, yAnchor = yAnchor or 0.5, spacing = spacing, type = "HorizontalStack" }

	-- for _, member in pairs(members) do
	-- 	if member ~= nil then
	-- 		insert(horizontalStack.members, member)
	-- 	end
	-- end

	local maxHeight

	function horizontalStack:Layout(availableWidth, availableHeight)

		local members = self.members
		local memberCount = #members

		if memberCount == 0 then
			return 0, 0
		end

		local elapsedDistance = 0
		maxHeight = 0

		local spacing = self.spacing()

		for i = 1, memberCount do
			local member = members[i]
			local memberWidth, memberHeight = member:Layout(availableWidth - elapsedDistance, availableHeight)
			member.hStackCachedX = elapsedDistance
			member.hStackCachedHeight = memberHeight
			elapsedDistance = elapsedDistance + memberWidth + spacing
			maxHeight = max(memberHeight, maxHeight)
		end

		if availableWidth < (elapsedDistance - spacing) then -- if we go oversize, see if we can convince things to tighten up (this can create some rendering issues combined with ScrollContainers & ResizableMovableFrame, a better solution is needed)
			local offset = elapsedDistance - spacing - availableWidth
			elapsedDistance = 0
			maxHeight = 0

			for i = 1, memberCount do
				local member = members[i]
				local memberWidth, memberHeight = member:Layout(availableWidth - elapsedDistance - offset, availableHeight)
				member.hStackCachedX = elapsedDistance
				member.hStackCachedHeight = memberHeight
				elapsedDistance = elapsedDistance + memberWidth + spacing
				maxHeight = max(maxHeight, memberHeight)
			end
		end
		
		return elapsedDistance - spacing, maxHeight
	end

	function horizontalStack:Draw(x, y)
		local members = self.members
		local yAnchor = self.yAnchor

		for i = 1, #members do
			local member = members[i]
			member:Draw(x + member.hStackCachedX, y + floor((maxHeight - member.hStackCachedHeight) * yAnchor))
		end
	end
	
	return horizontalStack
end