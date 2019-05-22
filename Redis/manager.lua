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

function readFromLogStacks ()
  for i, nodeId in ipairs(activeNodes) do
    -- left pop guarantees we are getting the most recent one
    local logObj = client:lpop(joinTwoStrings(nodeId, "currentLog", ":"))

    if not stringIsEmpty(logObj) then
      print("Got from node " .. nodeId .. " queue weight of: " .. logObj)
    end

  end
end


function manageOrders ()
  local order = client:lpop("orders")

  if stringIsEmpty(order) then
    return
  end

  local orderObj = splitLine(order, ",")

  local nodeId = orderObj[1]
  local order  = orderObj[2]

  print("Sending order " .. order .. " to node " .. nodeId)

  client:publish(joinTwoStrings(nodeId, "order", ":"), order)

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

for i, nodeId in ipairs(activeNodes) do
  print("Found node with id:" .. nodeId)
end

--TODO: Active Node updating

while true do
  readFromLogStacks()
  manageOrders()
end
