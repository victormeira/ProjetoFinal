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
local nextOrderTime = 0
local averageOrderTime = 0
local countOrderTime = 0
local nextActiveTime = 0
local averageActiveTime = 0
local countActiveTime = 0

local nextSetValues = 0

local activeIds = {}

while true do

  local logTimeElapsed = 0
  local orderTimeElapsed = 0
  local activeTimeElapsed = 0

  local beforeAction = 0
  local currentTime = socket.gettime()

  if(currentTime > nextActiveTime) then
    beforeAction = socket.gettime()
    local id = client:rpop("activeSpots");
    while not stringIsEmpty(id) do
      activeIds[id] = id
      id = client:rpop("activeSpots");
    end
    activeTimeElapsed = socket.gettime() - beforeAction

    averageActiveTime = (averageActiveTime*countActiveTime + activeTimeElapsed)/(countActiveTime + 1)
    countActiveTime = countActiveTime + 1
    
    nextActiveTime = socket.gettime() + 60
  end

  beforeAction = socket.gettime()
  local log = client:rpop("logQ");
  while not stringIsEmpty(log) do
    log = client:rpop("logQ");
  end
  logTimeElapsed = socket.gettime() - beforeAction

  averageLogTime = (averageLogTime*countLogTime + logTimeElapsed)/(countLogTime + 1)
  countLogTime = countLogTime + 1

  if(currentTime > nextOrderTime) then

    beforeAction = socket.gettime()
    client:set(joinTwoStrings(math.random(1, #activeIds + 1), "order", ":"), generateRandomString())
    orderTimeElapsed = socket.gettime() - beforeAction

    averageOrderTime = (averageOrderTime*countOrderTime + orderTimeElapsed)/(countOrderTime + 1)
    countOrderTime = countOrderTime + 1

    nextOrderTime = socket.gettime() + 2
  end

  if(currentTime > nextSetValues) then
    client:set("manager:values", averageLogTime .. "\t" .. averageOrderTime .. "\t" .. averageActiveTime)
    nextSetValues = socket.gettime() + 10
  end

end
