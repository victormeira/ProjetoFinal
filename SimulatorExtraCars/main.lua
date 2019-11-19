require("vehicle")
require("intersection")
require("grid")

local json  = require "json"
local redis = require 'redis'

local testType = "300CARS1TO10-TIME"

function addCarsToRoad(carsList, n)
	local spawnedPositions = {}
	local maxSize = table.getn(possibleStartingPositions)
	if(n > maxSize) then
		return
	end

	for i=1, maxSize do
		spawnedPositions[i] = false
	end

	local maxCarsInRoad = 300
	local numCarsInRoad = table.getn(carsList)
	
	-- over max num of cars
	if(numCarsInRoad >= maxCarsInRoad) then
		return
	end
	
	-- add until maxCars only
	if(numCarsInRoad + n >= maxCarsInRoad) then
		n = maxCarsInRoad - numCarsInRoad
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
		{-120, 295, math.rad(0)},
		{-120, 305, math.rad(0)},
		{-120, 315, math.rad(0)},
		{-120, 325, math.rad(0)},	
		{-120, 335, math.rad(0)},
		{-120, 345, math.rad(0)},	
		{-120, 355, math.rad(0)},	
		{215, -120, math.rad(90)},		
		{225, -120, math.rad(90)},		
		{235, -120, math.rad(90)},		
		{245, -120, math.rad(90)},		
		{265, -120, math.rad(90)},		
		{275, -120, math.rad(90)},
		{285, -120, math.rad(90)},		
		{750, 800, math.rad(270)},
		{760, 800, math.rad(270)},
		{770, 800, math.rad(270)},
		{780, 800, math.rad(270)},
		{790, 800, math.rad(270)},
		{800, 800, math.rad(270)},
		{810, 800, math.rad(270)},
		{820, 800, math.rad(270)},
		{830, 800, math.rad(270)},
	}
	math.randomseed(os.time())
	carsList = {}
	addCarsToRoad(carsList, 15)

	intersectionsTable = {}
	intersectionsTable[1] = Intersection:new(255, 325, 15, 1, 1, "1", "2", "")
	intersectionsTable[2] = Intersection:new(790, 325, 15, 1, -1, "2", "", "")

	-- setting starting window
	love.graphics.setBackgroundColor(237/255, 233/255, 240/255)
	love.window.setMode(1000, 650)
	love.window.setTitle("Project Simulator")
	roadBackground = love.graphics.newImage('intersectionbackground.png')

	outputTimesFiles = io.open("vehicle_times".. testType ..".txt", "a")
	io.output(outputTimesFiles)

	io.write("---- New test begins")

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
			
			io.write(v:totalTimeInScreen() .. "\n")
            --print("Vehicle has left!")			
			table.remove(carsList, k)
			addCarsToRoad(carsList, math.random(1, 10))
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
	drawGridIndices()
end