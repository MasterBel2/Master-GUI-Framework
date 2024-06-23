local pairs = Include.pairs

function Drawer()
	local drawingGroups = {}
	return {
		RegisterDrawingGroup = function(self)
			if not activeDrawingGroup then return end
			activeDrawingGroup.drawers[self] = true
			drawingGroups[activeDrawingGroup] = true
		end,
		NeedsRedraw = function(self)
			for drawingGroup, _ in pairs(drawingGroups) do
				if not drawingGroup:DrawerUpdated(self) then
					drawingGroups[drawingGroup] = nil
				end
			end
		end
	}
end

function Component(hasLayout, draws)
	local drawingGroups = {}

	local component = {}

	function component:RegisterDrawingGroup()
		if not activeDrawingGroup then return end
		if draws then
			activeDrawingGroup.drawers[self] = true
		end
		if hasLayout then
			activeDrawingGroup.layoutComponents[self] = true
		end
		drawingGroups[activeDrawingGroup] = true
	end

	if hasLayout then
		function component:NeedsLayout()
			for drawingGroup, _ in pairs(drawingGroups) do
				if not drawingGroup:LayoutUpdated(self) then
					drawingGroups[drawingGroup] = nil
				end
			end
		end
		function component:NeedsPosition()
			for drawingGroup, _ in pairs(drawingGroups) do
				if not drawingGroup:PositionsUpdated(self) then
					drawingGroups[drawingGroup] = nil
				end
			end
		end
	end

	if draws then
		function component:NeedsRedraw()
			for drawingGroup, _ in pairs(drawingGroups) do
				if not drawingGroup:DrawerUpdated(self) then
					drawingGroups[drawingGroup] = nil
				end
			end
		end
	end

	return component
end