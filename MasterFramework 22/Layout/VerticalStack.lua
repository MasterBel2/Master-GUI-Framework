local max = Include.math.max
local floor = Include.math.floor

function framework:VerticalStack(contents, spacing, xAnchor)
	local verticalStack = { members = contents, xAnchor = xAnchor, spacing = spacing, type = "VerticalStack" }

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

		if availableHeight < (elapsedDistance - spacing) then -- if we go oversize, see if we can convince things to tighten up (this can create some rendering issues combined with ScrollContainers & ResizableMovableFrame, a better solution is needed)
			local offset = elapsedDistance - spacing - availableHeight
			elapsedDistance = 0
			maxWidth = 0

			for i = 1, memberCount do
				local member = members[memberCount - (i - 1)]
				local memberWidth, memberHeight = member:Layout(availableWidth, availableHeight - elapsedDistance - offset)
				member.vStackCachedY = elapsedDistance
				member.vStackCachedWidth = memberWidth
				elapsedDistance = elapsedDistance + memberHeight + spacing
				maxWidth = max(maxWidth, memberWidth)
			end
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