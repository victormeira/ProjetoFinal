local socket = require 'socket'
local redis = require 'redis'

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

--setting up both intersections
local intersection1Configuration = "{\"IntersectionId\":\"001\",\"AreaId\":\"001\",\"NeighboringIds\":[\"002\"],\"Configuration\":{\"South\":{\"In\":{\"Sensors\":[{\"Type\":\"speed\",\"id\":\"ca9c4bcc\"},{\"Type\":\"induction\",\"id\":\"06e410a2\"},{\"Type\":\"presence\",\"id\":\"b7db1540\"}],\"TrafficLight\":true,\"Crosswalk\":true,\"Lanes\":2},\"Out\":null},\"North\":{\"In\":null,\"Out\":{\"Sensors\":[],\"TrafficLight\":false,\"Crosswalk\":false,\"Lanes\":2}},\"East\":{\"In\":null,\"Out\":{\"Sensors\":[],\"TrafficLight\":false,\"Crosswalk\":false,\"Lanes\":2}},\"West\":{\"In\":{\"Sensors\":[{\"Type\":\"speed\",\"id\":\"b3b27c73\"},{\"Type\":\"induction\",\"id\":\"8ef48e99\"},{\"Type\":\"presence\",\"id\":\"2fe4ce51\"}],\"TrafficLight\":true,\"Crosswalk\":true,\"Lanes\":2},\"Out\":null}}}"
local intersection2Configuration = "{\"IntersectionId\":\"002\",\"AreaId\":\"001\",\"NeighboringIds\":[\"001\"],\"Configuration\":{\"South\":{\"In\":null,\"Out\":{\"Sensors\":[],\"TrafficLight\":false,\"Crosswalk\":false,\"Lanes\":2}},\"North\":{\"In\":{\"Sensors\":[{\"Type\":\"speed\",\"id\":\"943284ef\"},{\"Type\":\"induction\",\"id\":\"9aee84ef\"},{\"Type\":\"presence\",\"id\":\"98efd84ef\"}],\"TrafficLight\":true,\"Crosswalk\":true,\"Lanes\":2},\"Out\":null},\"East\":{\"In\":null,\"Out\":{\"Sensors\":[],\"TrafficLight\":false,\"Crosswalk\":false,\"Lanes\":2}},\"West\":{\"In\":{\"Sensors\":[{\"Type\":\"speed\",\"id\":\"b3b37c73\"},{\"Type\":\"induction\",\"id\":\"8ef77e99\"},{\"Type\":\"presence\",\"id\":\"32fece51\"}],\"TrafficLight\":true,\"Crosswalk\":true,\"Lanes\":2},\"Out\":null}}}"

client:set("configuration:001", intersection1Configuration)
client:set("configuration:002", intersection2Configuration)

print("Intersections Configured with success")

