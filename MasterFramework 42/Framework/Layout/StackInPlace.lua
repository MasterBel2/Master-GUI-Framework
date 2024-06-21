local floor = Include.math.floor
local max = Include.math.max
local table_joinArrays = Include.table.joinArrays
local unpack = Include.unpack

function framework:StackInPlace(_members, xAnchor, yAnchor)
	local stackInPlace = { xAnchor = xAnchor, yAnchor = yAnchor, type = "StackInPlace" }

	local maxWidth
	local maxHeight

	local cachedXAnchor
	local cachedYAnchor

	local members = {}
	local membersUpdated

	function stackInPlace:GetMembers()
		local membersCopy = {}
		for i = 1, #members do 
			membersCopy[i] = members[i]
		end
		return members
	end
	function stackInPlace:SetMembers(newMembers)
		membersUpdated = true
		for i = #newMembers, #members do
			members[i] = nil
		end
		for i = 1, #newMembers do
			members[i] = newMembers[i]
		end
	end

	stackInPlace:SetMembers(_members)

	function stackInPlace:LayoutChildren()
		local layoutChildren = {}
		for i = 1, #members do
			local member = members[i]
			layoutChildren[i] = { member:LayoutChildren() }
		end

		return self, unpack(table_joinArrays(layoutChildren))
	end

	local cachedMemberCount
	function stackInPlace:NeedsLayout()
		return membersUpdated or cachedXAnchor ~= self.xAnchor or cachedYAnchor ~= self.yAnchor
	end

	function stackInPlace:Layout(availableWidth, availableHeight)
		membersUpdated = false
		
		maxWidth = 0
		maxHeight = 0

		cachedMemberCount = #members

		for i = 1, cachedMemberCount do 
			local member = members[i]
			local memberWidth, memberHeight = member:Layout(availableWidth, availableHeight)

			maxWidth = max(maxWidth, memberWidth)
			maxHeight = max(maxHeight, memberHeight)

			member.stackInPlaceCachedWidth = memberWidth
			member.stackInPlaceCachedHeight = memberHeight
		end

		return maxWidth, maxHeight
	end

	function stackInPlace:Position(x, y)
		cachedXAnchor = self.xAnchor
		cachedYAnchor = self.yAnchor

		for i = 1, cachedMemberCount do
			local member = members[i]
			member:Position(x + (maxWidth - member.stackInPlaceCachedWidth) * cachedXAnchor, y + (maxHeight - member.stackInPlaceCachedHeight) * cachedYAnchor)
		end
	end
	return stackInPlace
end