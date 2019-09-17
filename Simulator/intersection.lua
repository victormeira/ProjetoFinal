local class = require("middleclass")
require("vehicle")
Intersection = class('intersection')

function Intersection:initialize (middlePosX, middlePosY, surroundingBlockSize, flowXDirection, flowYDirection, id)

    self.middlePosXGrid, self.middlePosYGrid = getGridIndex(middlePosX, middlePosY)
    self.nextChange = -1
    self.id = id
    self.lightDrawingRadius = 10

    -- creates a "box" of the surrouding crosswalks
    self.Crosswalks = {}
    self.Crosswalks.xAxis = {}
    self.Crosswalks.xAxis.sameAxisPos =  self.middlePosXGrid - (flowXDirection * surroundingBlockSize/2) -- if 1, crossing is on the left
    self.Crosswalks.xAxis.lowerLimit = self.middlePosYGrid - surroundingBlockSize/2
    self.Crosswalks.xAxis.upperLimit = self.middlePosYGrid + surroundingBlockSize/2
    self.Crosswalks.xAxis.lightColor = "green"
    self.Crosswalks.xAxis.drawPositionX = (self.Crosswalks.xAxis.sameAxisPos - 1) * 10 
    self.Crosswalks.xAxis.drawPositionY = (self.Crosswalks.xAxis.upperLimit - 1) * 10


    self.Crosswalks.yAxis = {}
    self.Crosswalks.yAxis.sameAxisPos =  self.middlePosYGrid - (flowYDirection * surroundingBlockSize/2) -- if 1, crossing is on the left
    self.Crosswalks.yAxis.lowerLimit = self.middlePosXGrid - surroundingBlockSize/2
    self.Crosswalks.yAxis.upperLimit = self.middlePosXGrid + surroundingBlockSize/2
    self.Crosswalks.yAxis.lightColor = "red"
    self.Crosswalks.yAxis.drawPositionY = (self.Crosswalks.yAxis.sameAxisPos - 1) * 10 
    self.Crosswalks.yAxis.drawPositionX = (self.Crosswalks.yAxis.upperLimit - 1) * 10

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
end

-- TODO: 
--      Add color change ordering                           -> adding extra delay between changes (if one is green, turn to yellow and keep other; 
--                                                                                                  if yellow, turn to red and other to green)
--      Fix is mouseAbove function                          -> should iterate through crosswalks looking at drawing positions
--      Add light closing "trueing" the crosswalk blocks    -> go through upper and lower limit at sameAxisPos and true those blocks


function Intersection:orderColorChange()
    currentColor = self.color
    if currentColor == "red" then
        self.color = "green"
    elseif currentColor == "yellow" then
        self.color = "red"
    elseif currentColor == "green" then
        self.color = "yellow"
        self.nextChange = os.time() + 2
    end
end

function Intersection:checkForColorChange()
    if(self.nextChange > 0 and os.time() > self.nextChange) then
        self:orderColorChange()
        self.nextChange = -1
    end
end

function Intersection:mouseIsAbove(mouseX, mouseY)
    local dFromCenter = math.sqrt(math.pow(mouseX - self.posX, 2) + math.pow(mouseY - self.posY, 2))
    print(dFromCenter)
	return dFromCenter < self.radius
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