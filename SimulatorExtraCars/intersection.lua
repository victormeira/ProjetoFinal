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
    self.Crosswalks.xAxis.reaffirmClosedCrosswalk = false
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
    self.Crosswalks.yAxis.reaffirmClosedCrosswalk = false
    print(self.Crosswalks.yAxis.interestedIntersectionId)
    client:set(getRedisKeyString(id .. "yAxis", "color"), "red")

    local currentXColor = self.Crosswalks.xAxis.lightColor
    local currentYColor = self.Crosswalks.yAxis.lightColor

    if(currentXColor == "red") then
        self:setCrosswalkBlocks("x", true) -- closing the crosswalk
        self.Crosswalks.xAxis.reaffirmClosedCrosswalk = true
    elseif (currentYColor == "red") then
        self:setCrosswalkBlocks("y", true) -- closing the crosswalk
        self.Crosswalks.yAxis.reaffirmClosedCrosswalk = true
    end

    --sets up possible places where car can turn (corners from lower to upper 
    local cornerturnX = self.middlePosXGrid - math.floor(flowXDirection * (surroundingBlockSize - 7)/2)
    local cornerturnY = self.middlePosYGrid + math.floor(flowYDirection * (surroundingBlockSize - 7)/2)

    for i = self.middlePosXGrid - flowXDirection, cornerturnX, -1 * flowXDirection do
        for j = self.middlePosYGrid + flowYDirection, cornerturnY, flowYDirection do
            local gridVal = math.rad(90)
            if flowYDirection == -1 then
                gridVal = math.rad(270)
            end
            print(i, j, gridVal)
            setTurnGridValue(i, j, gridVal)
        end
    end

    cornerturnX = self.middlePosXGrid + math.floor(flowXDirection * (surroundingBlockSize - 7)/2)
    cornerturnY = self.middlePosYGrid - math.floor(flowYDirection * (surroundingBlockSize - 7)/2)

    for i = self.middlePosXGrid + flowXDirection , cornerturnX, flowXDirection do
        for j = self.middlePosYGrid - flowYDirection, cornerturnY, -1 * flowYDirection do
            local gridVal = math.rad(0)
            if flowXDirection == -1 then
                gridVal = math.rad(180)
            end
            print(i, j, gridVal)
            setTurnGridValue(i, j, gridVal)
        end
    end

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
        self.Crosswalks.xAxis.reaffirmClosedCrosswalk = false;
        for i = self.Crosswalks.xAxis.lowerLimit, self.Crosswalks.xAxis.upperLimit do
            --print("setting " .. self.Crosswalks.xAxis.sameAxisPos .."," .. i .. " to " .. tostring(value))
            if(getPositionGridValue(self.Crosswalks.xAxis.sameAxisPos, i) and value == true) then
                self.Crosswalks.xAxis.reaffirmClosedCrosswalk = true;
            end
            setPositionGridValue(self.Crosswalks.xAxis.sameAxisPos, i, value)
        end
    else
        self.Crosswalks.yAxis.reaffirmClosedCrosswalk = false;
        for i = self.Crosswalks.yAxis.lowerLimit, self.Crosswalks.yAxis.upperLimit do
            --print("setting " .. i .."," .. self.Crosswalks.yAxis.sameAxisPos .. " to " .. tostring(value))
            if(getPositionGridValue(i, self.Crosswalks.yAxis.sameAxisPos) and value == true) then
                self.Crosswalks.yAxis.reaffirmClosedCrosswalk = true;
                --print("should reaffirm y")
            end
            setPositionGridValue(i, self.Crosswalks.yAxis.sameAxisPos, value)
        end
    end
end

function Intersection:reaffirmClosedCrosswalk()
    if(self.Crosswalks.xAxis.reaffirmClosedCrosswalk) then
        --print("reaffirming x")
        self:setCrosswalkBlocks("x", true)
    end
    if (self.Crosswalks.yAxis.reaffirmClosedCrosswalk) then
        --print("reaffirming y")
        self:setCrosswalkBlocks("y", true)
    end
end

function Intersection:fillInEmptyGridBlocks(axis, value)
    if axis == "x" then
        for i = self.Crosswalks.xAxis.lowerLimit, self.Crosswalks.xAxis.upperLimit do
            
            -- if empty gridPos means we can reaffirm it now
            if(not getPositionGridValue(self.Crosswalks.xAxis.sameAxisPos, i)) then
                self.Crosswalks.xAxis.reaffirmClosedCrosswalk = false;
                setPositionGridValue(self.Crosswalks.xAxis.sameAxisPos, i, value)
            end
        end
    else
        for i = self.Crosswalks.yAxis.lowerLimit, self.Crosswalks.yAxis.upperLimit do

            -- if empty gridPos means we can reaffirm it now
            if(not getPositionGridValue(i, self.Crosswalks.yAxis.sameAxisPos)) then
                print("falsing!")
                self.Crosswalks.yAxis.reaffirmClosedCrosswalk = false;
            end
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
        --self.nextChange = os.time() + 3
        self.Crosswalks.xAxis.reaffirmClosedCrosswalk = true
        --print("HERE4")
    elseif (currentYColor == "green") then
        self.Crosswalks.yAxis.lightColor = "yellow"
        client:set(getRedisKeyString(self.id .. "yAxis", "color"), "green")
        self:setCrosswalkBlocks("y", true) -- closing the crosswalk
        --self.nextChange = os.time() + 3
        self.Crosswalks.yAxis.reaffirmClosedCrosswalk = true
        --print("HERE3")
    elseif (currentXColor == "yellow") then
        self.Crosswalks.xAxis.lightColor = "red"
        self.Crosswalks.yAxis.lightColor = "green"
        client:set(getRedisKeyString(self.id .. "xAxis", "color"), "red")
        client:set(getRedisKeyString(self.id .. "yAxis", "color"), "green")
        self:setCrosswalkBlocks("y", false) -- opening the crosswalk
        self.Crosswalks.yAxis.reaffirmClosedCrosswalk = false
        --print("HERE", self.Crosswalks.xAxis.lightColor)
    elseif (currentYColor == "yellow") then
        self.Crosswalks.yAxis.lightColor = "red"
        self.Crosswalks.xAxis.lightColor = "green"
        client:set(getRedisKeyString(self.id .. "xAxis", "color"), "green")
        client:set(getRedisKeyString(self.id .. "yAxis", "color"), "red")
        self:setCrosswalkBlocks("x", false) -- opening the crosswalk
        self.Crosswalks.xAxis.reaffirmClosedCrosswalk = false
        --print("HERE2")
    end
end

function strIsEqual (s1, s2)
    return s1 == s2
end

function Intersection:checkForColorChange()

    for k,v in pairs(self.Crosswalks) do 
        local currentColorInRedis = client:get(getRedisKeyString(self.id..k, "color"))

        if(not strIsEqual(v.lightColor, currentColorInRedis)) then
            --print("I should change!")
            self:orderColorChange()
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