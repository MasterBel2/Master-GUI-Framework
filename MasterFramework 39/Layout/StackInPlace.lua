local floor = Include.math.floor
local max = Include.math.max

function framework:StackInPlace(contents, xAnchor, yAnchor)
	local stackInPlace = { members = contents, xAnchor = xAnchor, yAnchor = yAnchor, type = "StackInPlace" }

	local maxWidth
	local maxHeight

	local cachedXAnchor
	local cachedYAnchor

	local cachedMemberCount
	function stackInPlace:NeedsLayout()
		local members = self.members
		if #members ~= cachedMemberCount or cachedXAnchor ~= self.xAnchor or cachedYAnchor ~= self.yAnchor then
			return true
		end
		for i = 1, cachedMemberCount do
			if i ~= self.members[i].stackInPlaceCachedIndex or self.members[i]:NeedsLayout() then
				return true
			end
		end
	end

	function stackInPlace:Layout(availableWidth, availableHeight)

		maxWidth = 0
		maxHeight = 0

		local members = self.members
		cachedMemberCount = #members

		for i = 1, cachedMemberCount do 
			local member = members[i]
			local memberWidth, memberHeight = member:Layout(availableWidth, availableHeight)

			maxWidth = max(maxWidth, memberWidth)
			maxHeight = max(maxHeight, memberHeight)

			member.stackInPlaceCachedIndex = i
			member.stackInPlaceCachedWidth = memberWidth
			member.stackInPlaceCachedHeight = memberHeight
		end

		return maxWidth, maxHeight
	end

	function stackInPlace:Position(x, y)
		local members = self.members
		cachedXAnchor = self.xAnchor
		cachedYAnchor = self.yAnchor

		for i = 1, cachedMemberCount do
			local member = members[i]
			member:Position(x + (maxWidth - member.stackInPlaceCachedWidth) * cachedXAnchor, y + (maxHeight - member.stackInPlaceCachedHeight) * cachedYAnchor)
		end
	end
	return stackInPlace
end