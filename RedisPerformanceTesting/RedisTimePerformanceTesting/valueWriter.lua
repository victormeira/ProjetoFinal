local redis = require 'redis'
local socket = require 'socket'

local function stringIsEmpty(s)
  return s == nil or s == ''
end


function joinTwoStrings(str1, str2, delimiter)
  return str1 .. delimiter .. str2
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

local totalInts = tonumber(arg[1])
local outputTimesFiles = io.open("testOutputs/redis_times_".. arg[1] ..".txt", "a")
io.output(outputTimesFiles)

io.write("---- New test begins\n")
io.write("averageLogTime\taverageOrderTime\taverageActiveTime\n")
io.write(client:get("manager:values") .. "\n")

io.write("averageLogTime\taverageOrderTime\taverageActiveTime\taverageSyncSetTime\taverageSyncGetTime\n")

for i = 1, totalInts do
  local vals = client:get( i .. ":values")
  io.write(vals .. "\n")
end

