require("vehicle")
require("intersection")
require("grid")

local json  = require "json"
local redis = require 'redis'

function addCarsToRoad(carsList, n)
	local spawnedPositions = {}
	local maxSize = table.getn(possibleStartingPositions)
	if(n > maxSize) then
		return
	end

	for i=1, maxSize do
		spawnedPositions[i] = false
	end

	for i=1, n do
		local randInt = math.random(maxSize)

		while spawnedPositions[randInt] do
			randInt = math.random(maxSize)
		end

		spawnedPositions[randInt] = true
		local startingVars = possibleStartingPositions[randInt]
		local vehi = Vehicle:new(startingVars[1], startingVars[2], math.random(50,120), math.random(50,120), startingVars[3], 'bluecar.png')
		table.insert(carsList, vehi)
	end
end

function love.load()

	initializeGrid()

	math.randomseed(os.time())
	possibleStartingPositions = {
		{-120, 305, math.rad(0)},
		{-120, 345, math.rad(0)},	
		{235, -120, math.rad(90)},		
		{275, -120, math.rad(90)},
		{770, 800, math.rad(270)},
		{810, 800, math.rad(270)},	
	}

	math.randomseed(os.time())
	carsList = {}
	addCarsToRoad(carsList, 3)

	intersectionsTable = {}
	intersectionsTable[1] = Intersection:new(255, 325, 15, 1, 1, "1", "2", "")
	intersectionsTable[2] = Intersection:new(790, 325, 15, 1, -1, "2", "", "")

	-- setting starting window
	love.graphics.setBackgroundColor(237/255, 233/255, 240/255)
	love.window.setMode(1000, 650)
	love.window.setTitle("Project Simulator")
	roadBackground = love.graphics.newImage('intersectionbackground.png')

end

function love.keypressed(key, scancode, isrepeat)

end

function love.mousepressed(x, y, button, istouch)
	if button == 1 then 
		for k, v in pairs(intersectionsTable) do
			if v:mouseIsAbove(x, y) then
				print("Pressed")
				v:orderColorChange()
			end
		end
	end
end

function love.update(dt)
	for k, v in pairs(carsList) do
		-- if object is no longer in screen
		if(not v:moveAStep(dt)) then
			table.remove(carsList, k)
			addCarsToRoad(carsList, math.random(3, 5))
		end
	end
	for k,v in pairs(intersectionsTable) do
		v:checkForColorChange()
		v:reaffirmClosedCrosswalk()
	end
end

function drawBackgroundRoad()
	love.graphics.setColor(1,1,1)
	local sx = love.graphics.getWidth() / roadBackground:getWidth()
	local sy = love.graphics.getHeight() / roadBackground:getHeight()
	love.graphics.draw(roadBackground, 0, 0, 0, sx, sy)
end

function love.draw()
	drawBackgroundRoad()
	--drawTurnBlocksIndices()
	for k, v in pairs(carsList) do
		v:draw()
	end
	for k,v in pairs(intersectionsTable) do
		v:draw()
	end
	--drawGridIndices()
end