local redis  = require 'redis'
local json   = require 'json'
local socket = require 'socket'

local INTERVAL = 30
local LAGBEHIND = 0
local CLOSED_BY_OPEN_PROPORTION = 2
local USE_CAR_AMOUNT = false

local function stringIsEmpty(s)
    return s == nil or s == ''
end

function getRedisKeyString (id, attribute)
	return id .. ":" .. attribute
end

function carAmountFunction (x, y, currentColor)

    -- we add 1 to avoid divisions by zero
    local openAmount, closedAmount
    if currentColor == "green" then
        openAmount = x + 1
        closedAmount = y + 1
    elseif currentColor == "red" then
        openAmount = y + 1
        closedAmount = x + 1
    else
        return 0
    end

    local unbalanceProportion = closedAmount/openAmount

    if unbalanceProportion > 5*CLOSED_BY_OPEN_PROPORTION then
        return -0.25
    elseif unbalanceProportion > 4*CLOSED_BY_OPEN_PROPORTION then
        return -0.2
    elseif unbalanceProportion > 3*CLOSED_BY_OPEN_PROPORTION then
        return -0.15
    elseif unbalanceProportion > 2*CLOSED_BY_OPEN_PROPORTION then
        return -0.1
    elseif unbalanceProportion > CLOSED_BY_OPEN_PROPORTION then
        return -0.05
    elseif unbalanceProportion < 1/(5*CLOSED_BY_OPEN_PROPORTION) then
        return 0.25
    elseif unbalanceProportion < 1/(4*CLOSED_BY_OPEN_PROPORTION) then
        return 0.2
    elseif unbalanceProportion < 1/(3*CLOSED_BY_OPEN_PROPORTION) then
        return 0.15
    elseif unbalanceProportion < 1/(2*CLOSED_BY_OPEN_PROPORTION) then
        return 0.1
    elseif unbalanceProportion < 1/(CLOSED_BY_OPEN_PROPORTION) then
        return 0.05
    else
        return 0
    end

    return 0
end

function changeMyColor (currentColor)
    local nextColor         = ""
    local nextColorChange   = -1

    print("changed color!")

    nextColorChange = socket.gettime() + INTERVAL
    if currentColor == "red" then
        nextColor = "green"
    elseif currentColor == "yellow" then
        nextColor = "red"
    elseif currentColor == "green" then
        nextColor = "yellow"
        nextColorChange = socket.gettime() + 2
    end

    return nextColor, nextColorChange
end

local myNodeId = arg[1]

-- Setting up client
client = redis.connect('127.0.0.1', 6379)

-- broadcast that its active
client:lpush("activeNodes", myNodeId);

-- setting up initial values and neighbors
local myNeighbors = {}
local neiString = client:get(getRedisKeyString(myNodeId, "configuration"))

if not stringIsEmpty(neiString) then
    myNeighbors = json.decode(neiString)
end

local myNextColorChange = -1
local myCurrentColor    = "green"
local myLastColor = "red"
local nextColorChangeTime = socket.gettime()
local nextSecondPrint = socket.gettime()

while true do

    local xAmountOfCars = client:get(getRedisKeyString(myNodeId.. "xAxis", "carCount"))
    local yAmountOfCars = client:get(getRedisKeyString(myNodeId.. "yAxis", "carCount"))

    -- look for neighbor changes
    for i, neighbor in ipairs(myNeighbors) do

        if neighbor.direction == "in" then
            local neighborSyncString = client:get(getRedisKeyString(neighbor.nodeId, "sync"))
            if not stringIsEmpty(neighborSyncString) then
                local neighborSync = json.decode(neighborSyncString)
                local carAmountProp = carAmountFunction(xAmountOfCars, yAmountOfCars, myCurrentColor)

                if neighborSync.currentColor == "green" then
                  nextColorChangeTime = neighborSync.nextColorChangeTime + LAGBEHIND
                  myCurrentColor = "green"
                elseif neighborSync.currentColor == "red" then
                  nextColorChangeTime = neighborSync.nextColorChangeTime
                  myCurrentColor = "red"
                end

            end
        end      
    end

    if USE_CAR_AMOUNT then
        nextColorChangeTime = nextColorChangeTime + carAmountFunction(xAmountOfCars, yAmountOfCars, myCurrentColor)
    end

    -- print seconds left
    if socket.gettime() > nextSecondPrint then
        print("Seconds left to color change: " .. nextColorChangeTime - socket.gettime())
        nextSecondPrint = socket.gettime() + 1;
    end

    -- updates color if needed
    if socket.gettime() > nextColorChangeTime then
        myCurrentColor, nextColorChangeTime = changeMyColor(myCurrentColor)
    end

    -- builds sync obj to set
    local mySync = {}
    mySync.currentColor    = myCurrentColor
    mySync.nextColorChangeTime = nextColorChangeTime

    -- set sync val in redis
    client:set(getRedisKeyString(myNodeId, "sync"), json.encode(mySync))

    -- builds currentState object for sending to redis
    if(myCurrentColor == "green") then
      client:set(getRedisKeyString(myNodeId .. "xAxis", "color"), "green")
      client:set(getRedisKeyString(myNodeId .. "yAxis", "color"), "red")
      --print(myCurrentColor .. "-" .. getRedisKeyString(myNodeId .. "xAxis", "color"))
    elseif(myCurrentColor == "red") then
      client:set(getRedisKeyString(myNodeId .. "xAxis", "color") , "red")
      if(nextColorChangeTime - 2 < socket.gettime()) then
        client:set(getRedisKeyString(myNodeId .. "yAxis", "color") , "yellow")
      else
        client:set(getRedisKeyString(myNodeId .. "yAxis", "color") , "green")
      end
      --print(myCurrentColor.. "-" .. getRedisKeyString(myNodeId .. "xAxis", "color"))
    elseif(myCurrentColor == "yellow") then
      client:set(getRedisKeyString(myNodeId .. "xAxis", "color"), "yellow")
      --client:set(getRedisKeyString(myNodeId .. "xAxis", "color"), "yellow")
    end

    myLastColor = myCurrentColor

    socket.sleep(0.2)
end
