local redis  = require 'redis'
local json   = require 'json'
local socket = require 'socket'

local INTERVAL = 60

local function stringIsEmpty(s)
    return s == nil or s == ''
end

function getRedisKeyString (id, attribute)
	return id .. ":" .. attribute
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
local nextColorChangeTime = socket.gettime()

print("here2!")


while true do

    -- look for neighbor changes
    for i, neighbor in ipairs(myNeighbors) do

        if neighbor.direction == "in" then
            local neighborSyncString = client:get(getRedisKeyString(neighbor.nodeId, "sync"))
            if not stringIsEmpty(neighborSyncString) then
                local neighborSync = json.decode(neighborSyncString)

                if neighborSync.currentColor == "green" then
                  nextColorChangeTime = neighborSync.nextColorChangeTime + 5;
                  myCurrentColor = "green"
                elseif neighborSync.currentColor == "red" then
                  nextColorChangeTime = neighborSync.nextColorChangeTime;
                  myCurrentColor = "red"
                end

            end
        end      
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
      print(myCurrentColor .. "-" .. getRedisKeyString(myNodeId .. "xAxis", "color"))
    elseif(myCurrentColor == "red") then
      client:set(getRedisKeyString(myNodeId .. "xAxis", "color") , "red")
      client:set(getRedisKeyString(myNodeId .. "yAxis", "color") , "green")
      print(myCurrentColor.. "-" .. getRedisKeyString(myNodeId .. "xAxis", "color"))
    elseif(myCurrentColor == "yellow") then
      client:set(getRedisKeyString(myNodeId .. "xAxis", "color"), "yellow")
      --client:set(getRedisKeyString(myNodeId .. "xAxis", "color"), "yellow")
    end

    --print("Im here")

    -- sends currentState object to redis queue
    --client:lpush(getRedisKeyString(myNodeId,"currentState"), json.encode(myCurrentState))

    socket.sleep(0.2)
end


