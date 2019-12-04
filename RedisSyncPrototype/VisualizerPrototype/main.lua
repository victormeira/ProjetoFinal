require "arrow"
local json  = require "json"
local redis = require 'redis'

function love.load()

	-- connect to redis server
	client = redis.connect('127.0.0.1', 6379)

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
		node.colorRadius   	 = 55
		node.outlineRadius 	 = 62.5
		node.posX			 = ((30 + node.outlineRadius*2) * (i % 4)) + (30 + node.outlineRadius) 
		node.posY			 = ((30 + node.outlineRadius*2) * math.floor( i / 4 )) + (30 + node.outlineRadius)
		node.currentColor    = "green"
		node.nextColorChange = -1
		node.name			 = "Node " .. tostring(i + 1)
		node.neighbors 		 = {}

		table.insert(nodes, node)

		-- reset currentState values
		client:del(getRedisKeyString(i + 1,"currentState"))
	end

	love.graphics.setLineWidth(4)

	-- setting starting window
	love.graphics.setBackgroundColor(237/255, 233/255, 240/255)
	love.window.setMode(650, 650)
	love.window.setTitle("Project Visualizer")

end

function stringIsEmpty(s)
    return s == nil or s == ''
end

function getRedisKeyString (id, attribute)
	return id .. ":" .. attribute
end

function love.keypressed(key, scancode, isrepeat)
	if key == "space" then

		-- sending configuration data to redis
		for id, node in ipairs(nodes) do
			local neighborJson = json.encode(node.neighbors)			
			client:set(getRedisKeyString(id, "configuration"), neighborJson)
		end

		-- starting each intersection as a separate lua process
		for id, node in ipairs(nodes) do
			local cmd = "lua intersection.lua " .. tostring(id) .. " &"
			os.execute(cmd)
		end

		currentState = "simulation"

	elseif key=="escape" then
		os.execute("pkill -f lua")
		love.event.quit()
	end
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
				elseif 	currentState == "simulation" then
					client:set(getRedisKeyString(i,"order"), "change")
				end

			end
		end
	end
 end

function love.update(dt)
	-- poll each node queue for current State
	for id, node in ipairs(nodes) do
		local nodeStateString = client:lpop(getRedisKeyString(id, "currentState"))

		if not stringIsEmpty(nodeStateString) then
			local nodeState = json.decode(nodeStateString)
			node.currentColor = nodeState.color
		end
		
	end

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

	love.graphics.setColor(37/255, 48/255, 49/255)
	-- draw node connections first so they are behind the nodes
	for _, node in ipairs(nodes) do
		for __, neighbor in ipairs(node.neighbors) do
			love.graphics.print(neighbor.nodeId,    node.posX - 17, node.posY + 10)
			love.graphics.print(neighbor.direction, node.posX - 17, node.posY + 20)
						
			if neighbor.direction == "in" then
				--drawing arrow to from neighbor node to current node
				local lineAngle = angleBetweenNodes(node, nodes[neighbor.nodeId])
				local arrowX, arrowY = getBorderPointForNodes(node, lineAngle)
				drawArrow(nodes[neighbor.nodeId].posX, nodes[neighbor.nodeId].posY, arrowX, arrowY, 22 , .5)
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
end