local class = require("middleclass")
local socket = require("socket")
require("grid")

Vehicle = class('Vehicle')

function Vehicle:initialize (posX, posY, initSpeedX, initSpeedY, rotation, spriteImgFile, startingPositionId)
    self.posX = posX
    self.posY = posY
    self.speedX = initSpeedX
    self.speedY = initSpeedY
    self.rotation = rotation
    self.sprite = nil
    self.spriteH = 10
    self.spriteW = 10
    self.hasAppearedInScreen = false
    self.firstTimeInScreen = 0
    self.lastTimeInScreen = 0
    self.color = {
        math.random( 0,255) / 255,
        math.random( 0,255) / 255,
        math.random( 0,255) / 255,
    }
    self.numberOfTurns = 0
    self.startingPositionId = startingPositionId
end

function Vehicle:moveAStep(dt)

    local nextX = self.posX + math.cos(self.rotation) * self.speedX * dt
    local nextY = self.posY + math.sin(self.rotation) * self.speedY * dt

    --get middle grid Indx -> goes from 4 behind to 4 in front
    local nextXIndx, nextYIndx = getGridIndex(nextX, nextY)
    local currXIndx, currYIndx = getGridIndex(self.posX, self.posY)

    -- checks if I can move to next grid position by checking if I have changed gridIndex
    if not(nextXIndx == currXIndx and nextYIndx == currYIndx) then

        if checkIfCanAdvance(nextXIndx, nextYIndx, 1, self.rotation)  then
            return true
        else
            -- print("changing grid pos")
            -- change grid positions
            updateGridWithCarStep(nextXIndx, nextYIndx, 1, self.rotation)
        end 

        local shouldTurnRotation = shouldTurn(nextXIndx, nextYIndx, 1, self.rotation) 
        if shouldTurnRotation ~= 5 and shouldTurnRotation ~= self.rotation then
            --cleanup the grid
            cleanUpCarGrid(nextXIndx, nextYIndx, 1, self.rotation)        
            self.rotation = shouldTurnRotation
            occupyCarGrid(nextXIndx, nextYIndx, 1, self.rotation)  
            self.numberOfTurns = self.numberOfTurns + 1
        end
    end

    -- if is currently in screen
    if( (self.posX > 0 - self.spriteH/2) and (self.posX < 1000 + self.spriteH/2) and (self.posY > 0 - self.spriteH/2) and (self.posY < 650 + self.spriteH/2)) then
        if(not self.hasAppearedInScreen) then
            self.hasAppearedInScreen = true
            self.firstTimeInScreen = socket.gettime()
        end
    else
        -- returns that object has left the screen
        if(self.hasAppearedInScreen) then
            cleanUpCarGrid(nextXIndx, nextYIndx, 1, self.rotation)
            cleanUpGridBorders()
            self.lastTimeInScreen = socket.gettime()
            return false
        end
    end

    self.posX = nextX
    self.posY = nextY


    return true
end

function Vehicle:draw()
    love.graphics.setColor(self.color[1], self.color[2], self.color[3])
    love.graphics.circle("fill", self.posX, self.posY, 3, 30)
end

function Vehicle:statistics()
    return self.lastTimeInScreen - self.firstTimeInScreen .. "\t" .. self.numberOfTurns .. "\t" .. self.startingPositionId
end

function shouldTurn(indxX, indxY, blocks, direction)
    local val = getTurnGridValue(indxX, indxY)
    if val ~= 5 then
        local randInt = math.random(0,10)
        if randInt == 1 then
            return val
        end
    end
    return 5
end

function checkIfCanAdvance(indxX, indxY, blocks, direction)
    local boolVal = getPositionGridValue(indxX, indxY)

    return boolVal
end

function updateGridWithCarStep(indxX, indxY, blocks, direction)
    -- indx - blocks leaves, and indx+blocks is true

    setPositionGridValue(indxX - math.cos(direction)*1, indxY - math.sin(direction)*1, false)
    setPositionGridValue(indxX, indxY, true)
end

function cleanUpCarGrid(indxX, indxY, blocks, direction)
    --clean up all used blocks
    setPositionGridValue(indxX, indxY, false)
    setPositionGridValue(indxX - math.cos(direction)*1, indxY - math.sin(direction)*1, false)
    setPositionGridValue(indxX - math.cos(direction)*2, indxY - math.sin(direction)*2, false)
    setPositionGridValue(indxX + math.cos(direction)*1, indxY + math.sin(direction)*1, false)
    setPositionGridValue(indxX + math.cos(direction)*2, indxY + math.sin(direction)*2, false)

end

function occupyCarGrid(indxX, indxY, blocks, direction)
    --clean up all used blocks
    --setPositionGridValue(indxX - math.cos(direction)*1, indxY - math.sin(direction)*1, true)
    setPositionGridValue(indxX, indxY, true)
end
