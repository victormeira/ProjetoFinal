require "arrow"

function love.load()

	-- load initial state
	-- can be either configuration or simulation
	currentState = "configuration"

	-- load auxNodes for configuration
	auxStartNode  = -1
	auxEndNode	  = -1

	-- load nodes
	nodes = {}

	for i = 0, 15 do
		local node = {}
		node.colorRadius   	= 55
		node.outlineRadius 	= 62.5
		node.posX			= ((30 + node.outlineRadius*2) * (i % 4)) + (30 + node.outlineRadius) 
		node.posY			= ((30 + node.outlineRadius*2) * math.floor( i / 4 )) + (30 + node.outlineRadius)
		node.currentColor   = "green"
		node.name			= "Node " .. tostring(i + 1)
		node.neighbors 		= {}

		table.insert(nodes, node)
	end

	love.graphics.setLineWidth(4)

	-- setting starting window
	love.graphics.setBackgroundColor(237/255, 233/255, 240/255)
	love.window.setMode(650, 650)
	love.window.setTitle("Project Visualizer")

end

function mouseIsOverThisNode(node, mouseX, mouseY)
	local dFromCenter = math.sqrt(math.pow(mouseX - node.posX, 2) + math.pow(mouseY - node.posY, 2))
	return dFromCenter < node.outlineRadius
end

function love.mousepressed(x, y, button, istouch)
	if button == 1 then 
		for i, v in ipairs(nodes) do
			if mouseIsOverThisNode(v, x, y) then

				-- in configuration a click binds nodes
				if 	currentState == "configuration" then
					if auxStartNode < 0 then
						auxStartNode = i

					elseif auxEndNode < 0 then
						auxEndNode = i

						local neighborIn = {}
						neighborIn.nodeId 	 = auxStartNode
						neighborIn.direction = "in"

						local neighborOut = {}
						neighborOut.nodeId 	  = auxEndNode
						neighborOut.direction = "out"

						table.insert(nodes[auxEndNode].neighbors,   neighborIn)
						table.insert(nodes[auxStartNode].neighbors, neighborOut)

						auxStartNode = -1
						auxEndNode   = -1
					end
					
				-- in simulation a click changes node color
				elseif 	currentState == "simulation"	then
					v.currentColor = "red"
				end

			end
		end
	end
 end

function love.update(dt)

end

function angleBetweenNodes(nodeIn, nodeOut)
	local deltaX = nodeIn.posX - nodeOut.posX 
	local deltaY = nodeIn.posY - nodeOut.posY 

	local rotation = -1 * math.atan2(deltaX, deltaY)
	rotation = math.rad(math.deg(rotation) + 180)

	return rotation
end

function getBorderPointForNodes(node, rotation)
	rotation = rotation - math.rad(90)

	local extX = node.posX - math.cos(rotation) * node.outlineRadius
	local extY = node.posY - math.sin(rotation) * node.outlineRadius

	return extX, extY
end

function love.draw()

	-- draw node connections first so they are behind the nodes
	for _, node in ipairs(nodes) do
		for __, neighbor in ipairs(node.neighbors) do
			love.graphics.print(neighbor.nodeId,    node.posX - 17, node.posY + 10)
			love.graphics.print(neighbor.direction, node.posX - 17, node.posY + 20)
						
			if neighbor.direction == "in" then
				-- draw line
				--love.graphics.arrow(nodes[neighbor.nodeId].posX, nodes[neighbor.nodeId].posY, node.posX, node.posY, 22 , .5)

				-- draw arrow tip
				-- angle is arcsin(opposite/adjacent)
				local lineAngle = angleBetweenNodes(node, nodes[neighbor.nodeId])
				local arrowX, arrowY = getBorderPointForNodes(node, lineAngle)

				love.graphics.arrow(nodes[neighbor.nodeId].posX, nodes[neighbor.nodeId].posY, arrowX, arrowY, 22 , .5)
				--love.graphics.polygon("fill", triX, triY, triX - 15, triY - 15, triX + 15, triY - 15)
			end
		end
	end

	for _, node in ipairs(nodes) do
		--outlining node
		love.graphics.setColor(37/255, 48/255, 49/255)
		love.graphics.circle("fill", node.posX, node.posY, node.outlineRadius)

		--filling with color
		if 		node.currentColor == "red" 		then love.graphics.setColor(219/255,  76/255,  64/255)
		elseif	node.currentColor == "yellow" 	then love.graphics.setColor(240/255, 201/255, 135/255)
		elseif	node.currentColor == "green" 	then love.graphics.setColor(137/255, 189/255, 158/255)
		end
		love.graphics.circle("fill", node.posX, node.posY, node.colorRadius)

		-- writing node number
		love.graphics.setColor(37/255, 48/255, 49/255)
		love.graphics.print(node.name , node.posX - 17, node.posY - 40)
	end

	love.graphics.setColor(37/255, 48/255, 49/255)

end