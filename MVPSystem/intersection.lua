local socket = require 'socket'
local redis = require 'redis'
local uuid = require 'uuid'
      uuid.seed()

local function stringIsEmpty(s)
  return s == nil or s == ''
end

function splitLine(s, delimiter)
    local result = {}
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end
    return result
end

function joinTwoStrings(str1, str2, delimiter)
  return str1 .. delimiter .. str2
end

function readSensorData()
  return 1, 2, 3
end

function receiveOrders()
  -- sub to orders
end

function checkIfTimeIsUp(expectedTime)
  local nowTime = socket.getTime()

  if(nowTime < expectedTime) then
    return true
  end

  return false
end

function buildLogObject()
  -- building log object
end

-- adding intersectionHeuristic
local intHeu = loadfile("intersectionHeuristic.lua")
intHeu()

--local myId = uuid()
local myId = arg[1]

-- Setting up client
client = redis.connect('127.0.0.1', 6379)

-- Testing connection
local testResponse = client:get("ack")
if not testResponse == "ack" then
  print("Connection failed! Try again!")
  return;
end
print("Connected to REDIS Server correctly!")


--broadcast that its active
client:lpush("activeSpots", myId);
local nextActivePushTime = socket.getTime() + 6000

local neighbors = client:get(joinTwoStrings(myId,"configuration", ":"))
print(neighbors)
local neighborIds = splitLine(neighbors, ",")

currentState = "red"
nextSwitch = socket.getTime() + 60

while true do

  --broadcast this node is active every 10 min
  if(checkIfTimeIsUp(nextActivePushTime)) then
    nextActivePushTime = socket.getTime() + 6000
    client:lpush("activeSpots", myId);
  end

  --read from Sensors
  local stoppedCars, passedCars, numberOfPedestrians = readSensorData()

  -- read from Historic Data
  local history = client:get(joinTwoStrings(myId,"history", ":"))

  -- read from orders
  local orders = receiveOrders()

  -- read sync from neighbors
  local syncTime = 1
  for i, nodeId in ipairs(neighborIds) do
    syncTime = client:get(joinTwoStrings(nodeId,"sync", ":"))
    print("Got sync " .. syncTime .. " from node " .. nodeId)
  end

  -- CALCULATION OF NEW VARIABLES
  local weight = tonumber(history) + 1

  -- update current Log
  client:lpush(joinTwoStrings(myId, "currentLog", ":"), weight)

  -- update sync object
  client:set(joinTwoStrings(myId,"sync", ":"), weight)

  -- update updates for agregator
  client:lpush(joinTwoStrings(myId, "updates", ":"),weight)

end
