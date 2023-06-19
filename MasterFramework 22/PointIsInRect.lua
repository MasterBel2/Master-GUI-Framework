function PointIsInRect(x, y, rectX, rectY, rectWidth, rectHeight)
	return x >= rectX and y >= rectY and x <= rectX + rectWidth and y <= rectY + rectHeight
end