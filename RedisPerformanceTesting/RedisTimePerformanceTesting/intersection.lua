local redis = require 'redis'
local socket = require 'socket'

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

charset = {}  do -- [0-9a-zA-Z]
  for c = 48, 57  do table.insert(charset, string.char(c)) end
  for c = 65, 90  do table.insert(charset, string.char(c)) end
  for c = 97, 122 do table.insert(charset, string.char(c)) end
end

function randomString(length)
  local str = ""
  for i = 1, length + 1 do
    str = str .. charset[math.random(1, #charset)]
  end
  return str
end

function generateRandomString()
  math.randomseed(os.clock()^5)
  return randomString(math.random(1, 100))
end

local myId = arg[1]
local totalInts = tonumber(arg[2])

-- Setting up client
client = redis.connect('ec2-3-136-97-159.us-east-2.compute.amazonaws.com', 6379)

-- Testing connection
local testResponse = client:get("ack")
if not testResponse == "ack" then
  print("Connection failed! Try again!")
  return;
end
print("Connected to REDIS Server correctly!")

local nextLogTime = 0
local averageLogTime = 0
local countLogTime = 0
local nextaggregateTime = 0
local averageaggregateTime = 0
local countaggregateTime = 0
local nextActiveTime = 0
local averageActiveTime = 0
local countActiveTime = 0
local nextSyncSetTime = 0
local averageSyncSetTime = 0
local countSyncSetTime = 0
local nextSyncGetTime = 0
local averageSyncGetTime = 0
local countSyncGetTime = 0
local nextSetValues = 0

while true do

  local logTimeElapsed = 0
  local aggregateTimeElapsed = 0
  local activeTimeElapsed = 0
  local syncSetTimeElapsed = 0
  local syncGetTimeElapsed = 0

  local beforeAction = 0
  local currentTime = socket.gettime()

  if(currentTime > nextLogTime) then
    beforeAction = socket.gettime()
    --send to log queue
    client:lpush("logQ", generateRandomString())
    logTimeElapsed = socket.gettime() - beforeAction

    averageLogTime = (averageLogTime*countLogTime + logTimeElapsed)/(countLogTime + 1)
    countLogTime = countLogTime + 1

    nextLogTime = socket.gettime() + 1
  end

  if(currentTime > nextaggregateTime) then
    beforeAction = socket.gettime()
    client:get(joinTwoStrings(myId,"aggregate", ":"))
    aggregateTimeElapsed = socket.gettime() - beforeAction

    averageaggregateTime = (averageaggregateTime*countaggregateTime + aggregateTimeElapsed)/(countaggregateTime + 1)
    countaggregateTime = countaggregateTime + 1

    nextaggregateTime = socket.gettime() + 6
  end

  if(currentTime > nextActiveTime) then
    beforeAction = socket.gettime()
    client:lpush("activeSpots", myId);
    activeTimeElapsed = socket.gettime() - beforeAction

    averageActiveTime = (averageActiveTime*countActiveTime + activeTimeElapsed)/(countActiveTime + 1)
    countActiveTime = countActiveTime + 1
    
    nextActiveTime = socket.gettime() + 30
  end

  if(currentTime > nextSyncSetTime) then
    beforeAction = socket.gettime()
    client:set(joinTwoStrings(myId,"sync", ":"), generateRandomString())
    syncSetTimeElapsed = socket.gettime() - beforeAction

    averageSyncSetTime = (averageSyncSetTime*countSyncSetTime + syncSetTimeElapsed)/(countSyncSetTime + 1)
    countSyncSetTime = countSyncSetTime + 0.

    nextSyncSetTime = socket.gettime() + 0.1
  end

  if(currentTime > nextSyncGetTime) then

    for i = 1, math.random(1, 5) do
      beforeAction = socket.gettime()
      local syncString = client:get(joinTwoStrings(math.random(1, totalInts + 1),"sync", ":"))
      syncGetTimeElapsed = socket.gettime() - beforeAction
  
      averageSyncGetTime = (averageSyncGetTime*countSyncGetTime + syncGetTimeElapsed)/(countSyncGetTime + 1)
      countSyncGetTime = countSyncGetTime + 0.1

      nextSyncGetTime = socket.gettime() + 0.1
    end
  end

  if(currentTime > nextSetValues) then
    client:set(joinTwoStrings(myId,"values", ":"), averageLogTime .. "\t" .. averageaggregateTime .. "\t" .. averageActiveTime .. "\t" .. averageSyncSetTime .. "\t" .. averageSyncGetTime)
    nextSetValues = socket.gettime() + 10
  end

end
