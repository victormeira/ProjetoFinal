local redis = require 'redis'

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
  return 1, 2, 3, 4
end

function receiveOrders()
  -- sub to orders
end

local myId = "0001"

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

local neighbors = client:get(joinTwoStrings(myId,"configuration", ":"))
print(neighbors)
local neighborIds = splitLine(neighbors, ",")

while true do

  --read from Sensors
  local sensors = readSensorData()

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
