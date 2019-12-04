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

-- Setting up client
client = redis.connect('127.0.0.1', 6379)

-- Testing connection
local testResponse = client:get("ack")
if not testResponse == "ack" then
  print("Connection failed! Try again!")
  return;
end
print("Connected to REDIS Server correctly!")

--Get every active node
activeNodes = client:lrange("activeSpots", 0, -1)
local weightUpdateLists = {}

for i, nodeId in ipairs(activeNodes) do
  print("Found node with id:" .. nodeId)
  table.insert(weightUpdateLists, joinTwoStrings(nodeId, "updates", ":"))
end

--TODO: Active Node updating
local averageWeights = {}

while true do
  for i, listId in ipairs(weightUpdateLists) do
    local weightString = tonumber(client:rpop(listId))

    if not stringIsEmpty(weightString) then
      local weight = tonumber(weightString)
      local nodeId = splitLine(listId, ":")[1]

      print("Received " .. weight .. " from node " .. nodeId)

      -- TODO: Better average taking
      averageWeights[nodeId] = weight + 1

      -- Set back to history value
      client:set(joinTwoStrings(nodeId, "history", ":"), averageWeights[nodeId])
    end
  end
end
