--[x][y] matrix saying car is contained there
--110 x -5

function initializeGrid()
    positionGrid = {}
    turnGrid = {}
    for i = -10,110 do
        positionGrid[i] = {}
        turnGrid[i] = {}
        for j = -5,70 do
            positionGrid[i][j] = false
            turnGrid[i][j] = 5
        end
    end
end

function setTurnGridValue(x,y,val)
    if(x >= -10 and x <= 110 and y >= -5 and y <= 70) then
        turnGrid[x][y] = val
    end
end

function getTurnGridValue(x,y)
    if(x >= -10 and x <= 110 and y >= -5 and y <= 70) then
        return turnGrid[x][y]
    end
    return 5
end

function setPositionGridValue(x,y,val)
    if(x >= -10 and x <= 110 and y >= -5 and y <= 70) then
        positionGrid[x][y] = val
    end
end

function getPositionGridValue(x,y)
    if(x >= -10 and x <= 110 and y >= -5 and y <= 70)  then
        return positionGrid[x][y]
    end
    return false
end

function getGridIndex(x, y)
    local x = math.floor(x/10) + 1
    local y = math.floor(y/10) + 1

    if(x > 110) then
        x = 110
    end
    if(x < -10) then
        x = 10
    end

    if(y > 70) then
        y = 70
    end
    if(y < -10) then
        y = 10
    end

    return x, y
end

function drawGridIndices()
    for i = 1,100 do
        for j = 1,65 do
            local xVal = (i - 1) * 10
            local yVal = (j - 1) * 10

            if(getPositionGridValue(i,j)) then
                love.graphics.setColor(1,0,0)           
            else
                love.graphics.setColor(0,1,0)
            end
            love.graphics.circle("fill", xVal, yVal, 1)
            
            --love.graphics.print(i*10 .. "," .. j*10, xVal, yVal)
        end
    end
end


function drawTurnBlocksIndices()
    for i = 1,100 do
        for j = 1, 65 do         
            if turnGrid[i][j] ~= 5 then
                local xVal = (i - 1) * 10
                local yVal = (j - 1) * 10
                love.graphics.setColor(122/255,24/255,220/255)
                love.graphics.rectangle("fill", xVal, yVal, 5, 5)
                love.graphics.setColor(0,0,0)
                -- love.graphics.print(i .. "," .. j*10, xVal, yVal)
            end
        end
    end
end
