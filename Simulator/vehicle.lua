local class = require("middleclass")
Vehicle = class('Vehicle')

--[x][y] matrix saying car is contained there
--40 x 26
local positionGrid = {}
for i = 1,40 do
    positionGrid[i] = {}
    for j = 1,26 do
        positionGrid[i][j] = false
    end
end

function setGridValue(x,y,val)
    positionGrid[x][y] = val
end

function getGridValue(x,y)
    return positionGrid[x][y]
end

function getGridIndex(x, y)
    local x = math.floor(x/25) + 1
    local y = math.floor(y/25) + 1

    if(x > 26) then
        x = 26
    end
    if(x < 1) then
        x = 1
    end

    if(y > 40) then
        y = 40
    end
    if(y < 1) then
        y = 1
    end

    return x, y
end

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

    local nextXIndx, nextYIndx = getGridIndex(nextX, nextY)
    local currXIndx, currYIndx = getGridIndex(self.posX, self.posY)

    -- checks if I can move to next grid position
    if(not(nextXIndx == currXIndx and nextYIndx == currYIndx)) then
        print("new grid pos")
        print(nextXIndx, nextYIndx)
        print(currXIndx, currYIndx)
        if(getGridValue(nextXIndx, nextYIndx) == true) then
            print("someone in grid!")
            return true
        else
            print("changing grid pos")
            -- change grid positions
            setGridValue(nextXIndx, nextYIndx, true)
            setGridValue(currXIndx, currYIndx, false)
        end
    end

    self.posX = nextX
    self.posY = nextY

    -- if is currently in screen
    if( (self.posX > 0 - self.spriteW) and (self.posX < 1000 + self.spriteW) and (self.posY > 0 - self.spriteH) and (self.posY < 650 + self.spriteH)) then
        if(not self.hasAppearedInScreen) then
            self.hasAppearedInScreen = true
        end
    else
        -- returns that object has left the screen
        if(self.hasAppearedInScreen) then
            print("Vehicle has left!")
            return false
        end
    end


    return true
end

function Vehicle:draw()
    love.graphics.draw(self.sprite, self.posX, self.posY, self.rotation, 0.3, 0.3, self.spriteW / 2, self.spriteH / 2)
end