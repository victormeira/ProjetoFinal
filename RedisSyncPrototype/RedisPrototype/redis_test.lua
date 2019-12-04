local redis = require 'redis'
local client = redis.connect('127.0.0.1', 6379)
local response = client:get("testing")

channels = {"t1", "t2"}

spots = client:lrange("activeSpots", 0, -1)
client:publish("t1", "TEST")

for k,v in pairs(spots) do
  print(k, v)
end

for msg, abort in client:pubsub({ subscribe = channels }) do
    if msg.kind == 'subscribe' then
        print('Subscribed to channel '..msg.channel)
    elseif msg.kind == 'message' then
        if msg.channel == 'control_channel' then
            if msg.payload == 'quit_loop' then
                print('Aborting pubsub loop...')
                abort()
            else
                print('Received an unrecognized command: '..msg.payload)
            end
        else
            print('Received the following message from '..msg.channel.."\n  "..msg.payload.."\n")
        end
    end
end
