local floor = Include.math.floor
local max = Include.math.max

function framework:StackInPlace(contents, xAnchor, yAnchor)
	local stackInPlace = { members = contents, xAnchor = xAnchor, yAnchor = yAnchor, type = "StackInPlace" }

	local maxWidth
	local maxHeight

	function stackInPlace:Layout(availableWidth, availableHeight)

		maxWidth = 0
		maxHeight = 0

		local members = self.members
		local memberCount = #members

		for i = 1, memberCount do 
			local member = members[i]
			local memberWidth, memberHeight = member:Layout(availableWidth, availableHeight)

			maxWidth = max(maxWidth, memberWidth)
			maxHeight = max(maxHeight, memberHeight)

			member.stackInPlaceCachedWidth = memberWidth
			member.stackInPlaceCachedHeight = memberHeight
		end

		return maxWidth, maxHeight
	end

	function stackInPlace:Draw(x, y)
		local members = self.members
		local xAnchor = self.xAnchor
		local yAnchor = self.yAnchor

		for i = 1, #members do
			local member = members[i]
			member:Draw(x + floor((maxWidth - member.stackInPlaceCachedWidth) * xAnchor), y + floor((maxHeight - member.stackInPlaceCachedHeight) * yAnchor))
		end
	end
	return stackInPlace
end