local class = require("middleclass")
require("vehicle")
require("grid")

Intersection = class('intersection')

function Intersection:initialize (middlePosX, middlePosY, surroundingBlockSize, flowXDirection, flowYDirection, id)

    self.middlePosX = middlePosX
    self.middlePosY = middlePosY

    self.middlePosXGrid, self.middlePosYGrid = getGridIndex(middlePosX, middlePosY)
    print(self.middlePosXGrid, self.middlePosYGrid)
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

    self.Crosswalks.yAxis = {}
    self.Crosswalks.yAxis.sameAxisPos =  math.floor(self.middlePosYGrid - (flowYDirection * surroundingBlockSize/2)) -- if 1, crossing is on the left
    self.Crosswalks.yAxis.lowerLimit = math.floor(self.middlePosXGrid - surroundingBlockSize/2)
    self.Crosswalks.yAxis.upperLimit = math.ceil(self.middlePosXGrid + surroundingBlockSize/2)
    self.Crosswalks.yAxis.lightColor = "red"
    self.Crosswalks.yAxis.drawPositionY = (self.Crosswalks.yAxis.sameAxisPos - 1) * 10 
    self.Crosswalks.yAxis.drawPositionX = (self.Crosswalks.yAxis.upperLimit - 1) * 10

    local currentXColor = self.Crosswalks.xAxis.lightColor
    local currentYColor = self.Crosswalks.yAxis.lightColor

    if(currentXColor == "red") then
        self:setCrosswalkBlocks("x", true) -- closing the crosswalk
    elseif (currentYColor == "red") then
        self:setCrosswalkBlocks("y", true) -- closing the crosswalk
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
        for i = self.Crosswalks.xAxis.lowerLimit, self.Crosswalks.xAxis.upperLimit do
            print("setting " .. self.Crosswalks.xAxis.sameAxisPos .."," .. i .. " to " .. tostring(value))
            setGridValue(self.Crosswalks.xAxis.sameAxisPos, i, value)
        end
    else
        for i = self.Crosswalks.yAxis.lowerLimit, self.Crosswalks.yAxis.upperLimit do
            print("setting " .. i .."," .. self.Crosswalks.yAxis.sameAxisPos .. " to " .. tostring(value))
            setGridValue(i, self.Crosswalks.yAxis.sameAxisPos, value)
        end
    end
end

function Intersection:orderColorChange()

    local currentXColor = self.Crosswalks.xAxis.lightColor
    local currentYColor = self.Crosswalks.yAxis.lightColor

    if(currentXColor == "green") then
        self.Crosswalks.xAxis.lightColor = "yellow"
        self:setCrosswalkBlocks("x", true) -- closing the crosswalk
        self.nextChange = os.time() + 3
    elseif (currentYColor == "green") then
        self.Crosswalks.yAxis.lightColor = "yellow"
        self:setCrosswalkBlocks("y", true) -- closing the crosswalk
        self.nextChange = os.time() + 3
    elseif (currentXColor == "yellow") then
        self.Crosswalks.xAxis.lightColor = "red"
        self.Crosswalks.yAxis.lightColor = "green"
        self:setCrosswalkBlocks("y", false) -- opening the crosswalk
    elseif (currentYColor == "yellow") then
        self.Crosswalks.yAxis.lightColor = "red"
        self.Crosswalks.xAxis.lightColor = "green"
        self:setCrosswalkBlocks("x", false) -- closing the crosswalk
    end
end

function Intersection:checkForColorChange()
    if(self.nextChange > 0 and os.time() > self.nextChange) then
        self:orderColorChange()
        self.nextChange = -1
    end
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