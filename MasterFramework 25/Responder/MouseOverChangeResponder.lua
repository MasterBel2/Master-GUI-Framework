function framework:MouseOverChangeResponder(rect, changeAction)
	return self:MouseOverResponder(
		rect,
		function() return true end,
		function() 
			changeAction(true)
		end,
		function() 
			changeAction(false) 
		end
	)
end