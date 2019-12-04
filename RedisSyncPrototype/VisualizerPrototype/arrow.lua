function drawArrow(x1, y1, x2, y2, arrlen, angle)
	love.graphics.line(x1, y1, x2, y2)
	local a = math.atan2(y1 - y2, x1 - x2)
	love.graphics.polygon('fill', x2, y2, x2 + arrlen * math.cos(a + angle), y2 + arrlen * math.sin(a + angle), x2 + arrlen * math.cos(a - angle), y2 + arrlen * math.sin(a - angle))
end

