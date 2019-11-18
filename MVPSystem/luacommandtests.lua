local redis = require 'redis'
local client = redis.connect('127.0.0.1', 6379)

function joinTwoStrings(str1, str2, delimiter)
  return str1 .. delimiter .. str2
end

local r = client:get(joinTwoStrings("0001","history", ":"))

print(r)

res = client:subscribe("s", callback)

print(res)

for i,v in ipairs(res) do print(i,v) end

print("subscribed to s")


function callback (msg)
  print(msg)
end
