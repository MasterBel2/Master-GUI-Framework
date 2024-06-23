local floor = Include.math.floor
local max = Include.math.max
local table_joinArrays = Include.table.joinArrays
local unpack = Include.unpack

function framework:StackInPlace(_members, xAnchor, yAnchor)
	local stackInPlace = Component(true, false)

	local maxWidth
	local maxHeight

	local members = {}
	local cachedMemberCount

	function stackInPlace:GetMembers()
		local membersCopy = {}
		for i = 1, #members do 
			membersCopy[i] = members[i]
		end
		return members
	end
	function stackInPlace:SetMembers(newMembers)
		self:NeedsLayout()
		for i = #newMembers + 1, #members do
			members[i] = nil
		end
		for i = 1, #newMembers do
			members[i] = newMembers[i]
		end
	end

	stackInPlace:SetMembers(_members)

	function stackInPlace:SetAnchors(newXAnchor, newYAnchor)
		if newXAnchor ~= xAnchor or newYAnchor ~= yAnchor then
			xAnchor = newXAnchor
			yAnchor = newYAnchor
			self:NeedsPosition()
		end
	end

	function stackInPlace:LayoutChildren()
		local layoutChildren = {}
		for i = 1, #members do
			local member = members[i]
			layoutChildren[i] = { member:LayoutChildren() }
		end

		return unpack(table_joinArrays(layoutChildren))
	end

	function stackInPlace:Layout(availableWidth, availableHeight)
		self:RegisterDrawingGroup()
		
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
		for i = 1, cachedMemberCount do
			local member = members[i]
			member:Position(x + (maxWidth - member.stackInPlaceCachedWidth) * xAnchor, y + (maxHeight - member.stackInPlaceCachedHeight) * yAnchor)
		end
	end
	return stackInPlace
end