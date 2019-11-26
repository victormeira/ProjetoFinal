require("vehicle")
require("intersection")
require("grid")

local json  = require "json"
local redis = require 'redis'
local socket = require 'socket'

local testType = "50CARS_N"

function addCarsToRoad(carsList, n)
	local spawnedPositions = {}
	local maxSize = table.getn(possibleStartingPositions)
	if(n > maxSize) then
		return
	end

	for i=1, maxSize do
		spawnedPositions[i] = false
	end

	local maxCarsInRoad = 50
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
		local vehi = Vehicle:new(startingVars[1], startingVars[2], math.random(50,120), math.random(50,120), startingVars[3], 'bluecar.png', startingVars[4])
		table.insert(carsList, vehi)
	end
end

function love.load()

	initializeGrid()

	math.randomseed(os.time())

	local listIndex = 1

	possibleStartingPositions = {}
	for i = 1, 9 do
		table.insert( possibleStartingPositions, {-120, 285 + (i-1)*10 , math.rad(0), "1"})
		table.insert( possibleStartingPositions, {215 + (i-1)*10, -120, math.rad(90), "2"})
		table.insert( possibleStartingPositions, {750 + (i-1)*10, 800, math.rad(270), "3"})
	end

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

	outputTimesFiles = io.open("testOutputs/vehicle_times".. testType ..".txt", "a")
	io.output(outputTimesFiles)

	io.write("---- New test begins\n")

	intersectionPositionsForCounting = {
		{"1xAxis", 0  , 160, 280, 370},
		{"1yAxis", 210, 295, 0  , 230},
		{"2xAxis", 300, 690, 280, 370},
		{"2yAxis", 740, 840, 440, 650}
	}
	carCounterStopWatch = socket.gettime() + 10
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
			time = os.date("*t")
			timeString = ("%02d:%02d:%02d"):format(time.hour, time.min, time.sec)
			io.write(timeString .. "\t" .. v:statistics() .. "\n")
            --print("Vehicle has left!")			
			table.remove(carsList, k)
			addCarsToRoad(carsList, math.random(5, 15))
		end
	end
	for k,v in pairs(intersectionsTable) do
		v:checkForColorChange()
		v:reaffirmClosedCrosswalk()
	end

	if carCounterStopWatch > socket.gettime() then
		for k,v in pairs(intersectionPositionsForCounting) do
			local carAmount = getNumberOfCars(v[2], v[3], v[4], v[5])
			client:set(v[1]..":carCount", carAmount)
		end
		carCounterStopWatch = socket.gettime() + 5
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