function framework:Tooltip(rect, description)
	local tooltip = self:Responder(rect, events.tooltip, function(tooltip)
		return tooltip.description
	end)

	tooltip.description = description

	return tooltip
end