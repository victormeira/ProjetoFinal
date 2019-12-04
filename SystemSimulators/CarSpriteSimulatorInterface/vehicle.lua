local class = require("middleclass")
require("grid")

Vehicle = class('Vehicle')

function Vehicle:initialize (posX, posY, initSpeedX, initSpeedY, rotation, spriteImgFile)
    self.posX = posX
    self.posY = posY
    self.speedX = initSpeedX
    self.speedY = initSpeedY
    self.rotation = rotation
    self.sprite = love.graphics.newImage(spriteImgFile)
    self.spriteH = self.sprite:getHeight()
    self.spriteW = self.sprite:getWidth()
    self.hasAppearedInScreen = false
end

function Vehicle:moveAStep(dt)

    local nextX = self.posX + math.cos(self.rotation) * self.speedX * dt
    local nextY = self.posY + math.sin(self.rotation) * self.speedY * dt

    --get middle grid Indx -> goes from 4 behind to 4 in front
    local nextXIndx, nextYIndx = getGridIndex(nextX, nextY)
    local currXIndx, currYIndx = getGridIndex(self.posX, self.posY)

    -- checks if I can move to next grid position by checking if I have changed gridIndex
    if not(nextXIndx == currXIndx and nextYIndx == currYIndx) then

        local shouldTurnRotation = shouldTurn(nextXIndx, nextYIndx, 4, self.rotation) 
        if shouldTurnRotation ~= 5 and shouldTurnRotation ~= self.rotation then
            print("Someone turned rotation:" .. shouldTurnRotation)
            --cleanup the grid
            cleanUpCarGrid(nextXIndx, nextYIndx, 4, self.rotation)        
            self.rotation = shouldTurnRotation

            occupyCarGrid(nextXIndx, nextYIndx, 2, self.rotation)  
        end

        if checkIfCanAdvance(nextXIndx, nextYIndx, 4, self.rotation)  then
            -- print("someone in grid!")
            return true
        else
            -- print("changing grid pos")
            -- change grid positions
            updateGridWithCarStep(nextXIndx, nextYIndx, 4, self.rotation)
        end 
    end

    -- if is currently in screen
    if( (self.posX > 0 - self.spriteH/2) and (self.posX < 1000 + self.spriteH/2) and (self.posY > 0 - self.spriteH/2) and (self.posY < 650 + self.spriteH/2)) then
        if(not self.hasAppearedInScreen) then
            self.hasAppearedInScreen = true
        end
    else
        -- returns that object has left the screen
        if(self.hasAppearedInScreen) then
            print("Vehicle has left!")
            cleanUpCarGrid(nextXIndx, nextYIndx, 4, self.rotation)
            return false
        end
    end

    self.posX = nextX
    self.posY = nextY


    return true
end

function Vehicle:draw()
    love.graphics.draw(self.sprite, self.posX, self.posY, self.rotation, 0.3, 0.3, self.spriteW / 2, self.spriteH / 2)

    if showGrid then
        for i = 1,100 do
            for j = 1,65 do
                local xVal = (i - 1) * 10
                local yVal = (j - 1) * 10
                love.graphics.setColor(0,0,0)
                love.graphics.print(i .. "," .. j, xVal, yVal)
                love.graphics.setColor(1,1,1)
                love.graphics.rectangle("fill", xVal, yVal, 5, 5)
            end
        end
    end
end

function shouldTurn(indxX, indxY, blocks, direction)
    -- gets the midVal for the turn
    local val = getTurnGridValue(indxX + math.cos(direction)*(-2) , indxY + math.sin(direction)*(-2))
    if val ~= 5 then
        --print("Someone could turn")
        local randInt = math.random(0,20)
        if randInt == 1 then
            return val
        end
    end
    return 5
end

function checkIfCanAdvance(indxX, indxY, blocks, direction)
    local boolVal = getPositionGridValue(indxX + math.cos(direction)*blocks, indxY + math.sin(direction)*blocks)

    return boolVal
end

function updateGridWithCarStep(indxX, indxY, blocks, direction)
    -- indx - blocks leaves, and indx+blocks is true

    setPositionGridValue(indxX - math.cos(direction)*blocks, indxY - math.sin(direction)*blocks, false)
    setPositionGridValue(indxX + math.cos(direction)*blocks, indxY + math.sin(direction)*blocks, true)
end

function cleanUpCarGrid(indxX, indxY, blocks, direction)
    --clean up all used blocks
    for i=0, blocks do
        setPositionGridValue(indxX - math.cos(direction)*i, indxY - math.sin(direction)*i, false)
        setPositionGridValue(indxX + math.cos(direction)*i, indxY + math.sin(direction)*i, false)
    end
end

function occupyCarGrid(indxX, indxY, blocks, direction)
    --clean up all used blocks
    for i=0, blocks do
        setPositionGridValue(indxX - math.cos(direction)*i, indxY - math.sin(direction)*i, true)
        setPositionGridValue(indxX + math.cos(direction)*i, indxY + math.sin(direction)*i, true)
    end
end
