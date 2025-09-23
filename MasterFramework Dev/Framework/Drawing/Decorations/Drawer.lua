local pairs = Include.pairs

--[[
	`Drawer` provides essential methods for drawing components & decorations that need to notify their `DrawingGroup` of necessary updates.
	Drawers that do not update have no use for these methods.

	Note that components and decorations both make use of these methods, even though components will almost always only have a maximum of one registered `DrawingGroup`.

	Methods:
	 - `drawer:RegisterDrawingGroup()`: Adds `self` to the current `DrawingGroup`'s list of updatable drawers, so that `DrawingGroup` may inform `self` of when it no longer needs to provide updates.
	                                    This may be called in `drawer:Layout()`, `drawer:Position()`, or `drawer:Draw()` - whichever is most useful. 
										This does NOT add `self` to the `DrawingGroup`'s list of drawTargets;
	 - `drawer:NeedsRedraw()`: Informs all registered `DrawingGroup`s that the drawer has been updated and requires a redraw. 
	                           This also checks whether the drawer is still registered with the `DrawingGroup`s, and removes any `DrawingGroup`s that the drawer is no longer a member of.
]]
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

--[[
	`Component` provides essential methods for drawing components & decorations that need to notify their `DrawingGroup` of necessary updates.
	Components that do not update have no use for these methods.

	Note that components and decorations both make use of these methods, even though components will almost always only have a maximum of one registered `DrawingGroup`, and decorations may have many registered `DrawingGroup`s.

	Parameters:
	 - `hasLayout`: A boolean value indicating whether the component performs any updatable layout. 
	 - `draws`: A boolean value indicating whether the component performs any updatable drawing. 
	            When true, the returned component will suport the same interface provided by `Drawer`.

	Methods:
	 - `component:RegisterDrawingGroup()`: Adds `self` to the current `DrawingGroup`'s list of updatable drawers, so that `DrawingGroup` may inform `self` of when it no longer needs to provide updates.
	                                       This may be called in `component:Layout()`, `component:Position()`, or `component:Draw()` - whichever is most useful. 
										   This does NOT add `self` to the `DrawingGroup`'s list of drawTargets;
     - `component:NeedsLayout()`: Informs all registered `DrawingGroup`s that the component's layout has been updated and requires a relayout. 
	                              This also checks whether the component is still registered with the `DrawingGroup`s, and removes any `DrawingGroup`s that the component is no longer a member of.
	 - `component:NeedsPosition()`: Informs all registered `DrawingGroup`s that the component's positioning has been updated and requires a reposition. 
	                                This also checks whether the component is still registered with the `DrawingGroup`s, and removes any `DrawingGroup`s that the component is no longer a member of.
	 - `component:NeedsRedraw()`: Informs all registered `DrawingGroup`s that the component's drawing has been updated and requires a redraw. 
	                              This also checks whether the component is still registered with the `DrawingGroup`s, and removes any `DrawingGroup`s that the component is no longer a member of.
]]
function Component(hasLayout, draws)
	local component = {}
	local continuouslyUpdating = false
	local drawingGroup

	function component:RegisterDrawingGroup()
		if not activeDrawingGroup then return end

		if draws then
			activeDrawingGroup.drawers[self] = true
			
			if continuouslyUpdating then
				activeDrawingGroup:DrawerWillContinuouslyUpdate(self)
			-- else
			-- 	activeDrawingGroup:DrawerWillNotContinuouslyUpdate(self)
			end
		end

		if hasLayout then
			activeDrawingGroup.layoutComponents[self] = true
		end

		drawingGroup = activeDrawingGroup
	end

	function component:RegisteredDrawingGroup()
		return drawingGroup
	end

	if hasLayout then
		function component:NeedsLayout()
			if drawingGroup and not drawingGroup:LayoutUpdated(self) then
				drawingGroup = nil
			end
		end
		function component:NeedsPosition()
			if drawingGroup and not drawingGroup:PositionsUpdated(self) then
				drawingGroup = nil
			end
		end
	end

	if draws then
		function component:NeedsRedraw()
			if drawingGroup and not drawingGroup:DrawerUpdated(self) then
				drawingGroup = nil
			end
		end

		-- Signals to the drawing group that it should not compile draw lists for the time being.
		-- 
		-- Use this when the component is frequently updating, to avoid unnecessary performance penalty.
		function component:EnableContinuousRedrawing()
			if not continuouslyUpdating then
				continuouslyUpdating = true

				if drawingGroup and not drawingGroup:DrawerWillContinuouslyUpdate(self) then
					drawingGroup = nil
				end
			end
		end

		-- Signals to the drawing group that this component no longer requires avoidance of draw lists.
		-- 
		-- Use this when the component is no longer frequently updating, to avoid unnecessary performance penalty.
		function component:DisableContinuousRedrawing()
			if continuouslyUpdating then
				continuouslyUpdating = false

				if drawingGroup and not drawingGroup:DrawerWillNotContinuouslyUpdate(self) then
					drawingGroup = nil
				end
			end
		end
	end

	return component
end