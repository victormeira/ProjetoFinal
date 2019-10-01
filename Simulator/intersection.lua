local class = require("middleclass")
local redis  = require 'redis'
local json   = require 'json'
local socket = require 'socket'
require("vehicle")
require("grid")

Intersection = class('intersection')

local function stringIsEmpty(s)
    return s == nil or s == ''
  end

function getRedisKeyString (id, attribute)
	return id .. ":" .. attribute
end

function Intersection:initialize (middlePosX, middlePosY, surroundingBlockSize, flowXDirection, flowYDirection, id, nextXAxisId, nextYAxisId)

    -- Setting up redis client
    client = redis.connect('127.0.0.1', 6379)

    self.middlePosX = middlePosX
    self.middlePosY = middlePosY

    self.middlePosXGrid, self.middlePosYGrid = getGridIndex(middlePosX, middlePosY)
    self.nextChange = -1
    self.id = id
    self.lightDrawingRadius = 10

    -- creates a "box" of the surrouding crosswalks
    self.Crosswalks = {}
    self.Crosswalks.xAxis = {}
    self.Crosswalks.xAxis.sameAxisPos =  math.floor(self.middlePosXGrid - (flowXDirection * surroundingBlockSize/2)) -- if 1, crossing is on the left
    self.Crosswalks.xAxis.lowerLimit = math.floor(self.middlePosYGrid - surroundingBlockSize/2)
    self.Crosswalks.xAxis.upperLimit = math.ceil(self.middlePosYGrid + surroundingBlockSize/2)
    self.Crosswalks.xAxis.lightColor = "green"
    self.Crosswalks.xAxis.drawPositionX = (self.Crosswalks.xAxis.sameAxisPos - 1) * 10 
    self.Crosswalks.xAxis.drawPositionY = (self.Crosswalks.xAxis.upperLimit - 1) * 10
    if(stringIsEmpty(nextXAxisId)) then
        self.Crosswalks.xAxis.interestedIntersectionId = ""
    else
        self.Crosswalks.xAxis.interestedIntersectionId = nextXAxisId .. "xAxis"
    end
    print(self.Crosswalks.xAxis.interestedIntersectionId)
    client:set(getRedisKeyString(id .. "xAxis", "color"), "green")

    self.Crosswalks.yAxis = {}
    self.Crosswalks.yAxis.sameAxisPos =  math.floor(self.middlePosYGrid - (flowYDirection * surroundingBlockSize/2)) -- if 1, crossing is on the left
    self.Crosswalks.yAxis.lowerLimit = math.floor(self.middlePosXGrid - surroundingBlockSize/2)
    self.Crosswalks.yAxis.upperLimit = math.ceil(self.middlePosXGrid + surroundingBlockSize/2)
    self.Crosswalks.yAxis.lightColor = "red"
    self.Crosswalks.yAxis.drawPositionY = (self.Crosswalks.yAxis.sameAxisPos - 1) * 10 
    self.Crosswalks.yAxis.drawPositionX = (self.Crosswalks.yAxis.upperLimit - 1) * 10
    if(stringIsEmpty(nextYAxisId)) then
        self.Crosswalks.yAxis.interestedIntersectionId = ""
    else
        self.Crosswalks.yAxis.interestedIntersectionId = nextYAxisId .. "yAxis"
    end
    print(self.Crosswalks.yAxis.interestedIntersectionId)
    client:set(getRedisKeyString(id .. "yAxis", "color"), "red")

    local currentXColor = self.Crosswalks.xAxis.lightColor
    local currentYColor = self.Crosswalks.yAxis.lightColor

    if(currentXColor == "red") then
        self:setCrosswalkBlocks("x", true) -- closing the crosswalk
    elseif (currentYColor == "red") then
        self:setCrosswalkBlocks("y", true) -- closing the crosswalk
    end

    --sets up possible places where car can turn (corners from lower to upper)
    -- for i = self.lowerLimit
    



end

function Intersection:draw()

    for k,v in pairs(self.Crosswalks) do 
        if(v.lightColor == "red") then
            color = {193/255, 66/255, 66/255, 1}
        elseif (v.lightColor == "yellow") then
            color = {215/255, 215/255, 60/255, 1}       
        else
            color = {63/255, 191/255, 63/255, 1}
        end
        love.graphics.setColor(color)
        love.graphics.circle("fill", v.drawPositionX, v.drawPositionY, self.lightDrawingRadius)
    end

    love.graphics.setColor(1,1,1)
    --love.graphics.circle("fill", self.middlePosX, self.middlePosY, self.lightDrawingRadius)

end

function Intersection:setCrosswalkBlocks(axis, value)
    if axis == "x" then
        for i = self.Crosswalks.xAxis.lowerLimit, self.Crosswalks.xAxis.upperLimit do
            --print("setting " .. self.Crosswalks.xAxis.sameAxisPos .."," .. i .. " to " .. tostring(value))
            setPositionGridValue(self.Crosswalks.xAxis.sameAxisPos, i, value)
        end
    else
        for i = self.Crosswalks.yAxis.lowerLimit, self.Crosswalks.yAxis.upperLimit do
            --print("setting " .. i .."," .. self.Crosswalks.yAxis.sameAxisPos .. " to " .. tostring(value))
            setPositionGridValue(i, self.Crosswalks.yAxis.sameAxisPos, value)
        end
    end
end

function Intersection:orderColorChange()

    local currentXColor = self.Crosswalks.xAxis.lightColor
    local currentYColor = self.Crosswalks.yAxis.lightColor

    if(currentXColor == "green") then
        self.Crosswalks.xAxis.lightColor = "yellow"
        client:set(getRedisKeyString(self.id .. "xAxis", "color"), "yellow")
        self:setCrosswalkBlocks("x", true) -- closing the crosswalk
        self.nextChange = os.time() + 3
        print("HERE4")
    elseif (currentYColor == "green") then
        self.Crosswalks.yAxis.lightColor = "yellow"
        client:set(getRedisKeyString(self.id .. "yAxis", "color"), "green")
        self:setCrosswalkBlocks("y", true) -- closing the crosswalk
        self.nextChange = os.time() + 3
        print("HERE3")
    elseif (currentXColor == "yellow") then
        self.Crosswalks.xAxis.lightColor = "red"
        self.Crosswalks.yAxis.lightColor = "green"
        client:set(getRedisKeyString(self.id .. "xAxis", "color"), "red")
        client:set(getRedisKeyString(self.id .. "yAxis", "color"), "green")
        self:setCrosswalkBlocks("y", false) -- opening the crosswalk
        print("HERE", self.Crosswalks.xAxis.lightColor)
    elseif (currentYColor == "yellow") then
        self.Crosswalks.yAxis.lightColor = "red"
        self.Crosswalks.xAxis.lightColor = "green"
        client:set(getRedisKeyString(self.id .. "xAxis", "color"), "green")
        client:set(getRedisKeyString(self.id .. "yAxis", "color"), "red")
        self:setCrosswalkBlocks("x", false) -- closing the crosswalk
        print("HERE2")
    end
end

function strIsEqual (s1, s2)
    return s1 == s2
end

function Intersection:checkForColorChange()
    if(self.nextChange > 0 and os.time() > self.nextChange) then
        self:orderColorChange()
        self.nextChange = -1
    elseif(self.nextChange < 0) then
        for k,v in pairs(self.Crosswalks) do 
            if not stringIsEmpty(v.interestedIntersectionId) then
                local interestedIntersectionColor = client:get(getRedisKeyString(v.interestedIntersectionId, "color"))
                if (not stringIsEmpty(interestedIntersectionColor) and
                    not strIsEqual(interestedIntersectionColor, v.lightColor) and not strIsEqual(v.lightColor, "yellow")) then
                    print("I should change!")
                    self:orderColorChange()
                end
            end
        end
    end

    --TODO: Analyze better which case you should be given your interested intersection color
end

function Intersection:mouseIsAbove(mouseX, mouseY)
    for k,v in pairs(self.Crosswalks) do 
        local dFromCenter = math.sqrt(math.pow(mouseX - v.drawPositionX, 2) + math.pow(mouseY - v.drawPositionY, 2))
        if dFromCenter < self.lightDrawingRadius then
            return true
        end
    end
    return false
end

function Intersection:isClosedToPass()
    if(self.color == "red") then
        return true
    elseif (self.color == "yellow") then
        return true      
    else
        return false
    end
end