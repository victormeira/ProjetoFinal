--[x][y] matrix saying car is contained there
--100 x 65

function initializeGrid()
    positionGrid = {}
    turnGrid = {}
    for i = 1,100 do
        positionGrid[i] = {}
        turnGrid[i] = {}
        for j = 1,65 do
            positionGrid[i][j] = false
            turnGrid[i][j] = false
        end
    end
end

function setTurnGridValue(x,y,val)
    if(x >= 1 and x <= 100 and y >= 1 and y <= 65) then
        turnGrid[x][y] = val
    end
end

function getTurnGridValue(x,y)
    if(x >= 1 and x <= 100 and y >= 1 and y <= 65) then
        return turnGrid[x][y]
    end
    return false
end

function setPositionGridValue(x,y,val)
    if(x >= 1 and x <= 100 and y >= 1 and y <= 65) then
        positionGrid[x][y] = val
    end
end

function getPositionGridValue(x,y)
    if(x >= 1 and x <= 100 and y >= 1 and y <= 65) then
        return positionGrid[x][y]
    end
    return false
end

function getGridIndex(x, y)
    local x = math.floor(x/10) + 1
    local y = math.floor(y/10) + 1

    if(x > 100) then
        x = 100
    end
    if(x < 1) then
        x = 1
    end

    if(y > 65) then
        y = 65
    end
    if(y < 1) then
        y = 1
    end

    return x, y
end

function drawGridIndices()
    for i = 1,10 do
        for j = 1,7 do
            local xVal = (i - 1) * 100
            local yVal = (j - 1) * 100
            love.graphics.setColor(1,1,1)
            love.graphics.rectangle("fill", xVal, yVal, 40, 40)
            love.graphics.setColor(0,0,0)
            love.graphics.print(i*10 .. "," .. j*10, xVal, yVal)
        end
    end
end
