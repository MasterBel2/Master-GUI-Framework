-- An alias for `framework:WrappingText` that sets `maxLines = 1`.
--
-- functions:
-- - `text:GetString()` : an alias for `wrappingText:GetRawString()`
function framework:Text(string, color, font, watch)
	local text = self:WrappingText(string, color, font, 1)
	function text:GetString() return self:GetRawString() end
	return text
end