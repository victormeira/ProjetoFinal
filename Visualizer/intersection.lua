local redis  = require 'redis'
local json   = require 'json'
local socket = require 'socket'

local function stringIsEmpty(s)
    return s == nil or s == ''
  end

function getRedisKeyString (id, attribute)
	return id .. ":" .. attribute
end

function changeMyColor (currentColor)
    local nextColor         = ""
    local nextColorChange   = -1

    if currentColor == "red" then
        nextColor = "green"
    elseif currentColor == "yellow" then
        nextColor = "red"
    elseif currentColor == "green" then
        nextColor = "yellow"
        nextColorChange = os.time() + 2
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

while true do

    -- if a color change has been requested, change and empty the value
    local orderColorChange = client:get(getRedisKeyString (myNodeId, "order"))
    if not stringIsEmpty(orderColorChange) then
        client:set(getRedisKeyString (myNodeId, "order"), "")
        myCurrentColor, myNextColorChange = changeMyColor(myCurrentColor)
        --print("Received Order")
    end

    -- look for neighbor changes
    for i, neighbor in ipairs(myNeighbors) do

        if neighbor.direction == "in" then
            local neighborSyncString = client:get(getRedisKeyString(neighbor.nodeId, "sync"))
            if not stringIsEmpty(neighborSyncString) then
                local neighborSync = json.decode(neighborSyncString)
                if neighborSync.currentColor ~= myCurrentColor and myNextColorChange < 0 then
                    myNextColorChange = os.time() + 3
                    --print("Color Change detected")
                end
            end
        end      
    end

    -- updates color if needed
    if os.time() == myNextColorChange then
        myCurrentColor, myNextColorChange = changeMyColor(myCurrentColor)
    end

    -- builds sync obj to set
    local mySync = {}
    mySync.currentColor    = myCurrentColor
    mySync.nextColorChange = myNextColorChange

    -- set sync val in redis
    client:set(getRedisKeyString(myNodeId, "sync"), json.encode(mySync))

    -- builds currentState object for sending to redis
    local myCurrentState = {}
    myCurrentState.color = myCurrentColor

    -- sends currentState object to redis queue
    client:lpush(getRedisKeyString(myNodeId,"currentState"), json.encode(myCurrentState))

    socket.sleep(0.2)
end


