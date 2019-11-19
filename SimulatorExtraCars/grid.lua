--[x][y] matrix saying car is contained there
--110 x -5

local LOWER_X_INDX = -20
local LOWER_Y_INDX = -10
local HIGHER_X_INDX = 120
local HIGHER_Y_INDX = 80

function initializeGrid()
    positionGrid = {}
    turnGrid = {}
    for i = LOWER_X_INDX,HIGHER_X_INDX do
        positionGrid[i] = {}
        turnGrid[i] = {}
        for j = LOWER_Y_INDX,HIGHER_Y_INDX do
            positionGrid[i][j] = false
            turnGrid[i][j] = 5
        end
    end
end

function setTurnGridValue(x,y,val)
    if(x >= LOWER_X_INDX and x <= HIGHER_X_INDX and y >= LOWER_Y_INDX and y <= HIGHER_Y_INDX) then
        turnGrid[x][y] = val
    end
end

function getTurnGridValue(x,y)
    if(x >= LOWER_X_INDX and x <= HIGHER_X_INDX and y >= LOWER_Y_INDX and y <= HIGHER_Y_INDX) then
        return turnGrid[x][y]
    end
    return 5
end

function setPositionGridValue(x,y,val)
    if(x >= LOWER_X_INDX and x <= HIGHER_X_INDX and y >= LOWER_Y_INDX and y <= HIGHER_Y_INDX) then
        positionGrid[x][y] = val
    end
end

function getPositionGridValue(x,y)
    if(x >= LOWER_X_INDX and x <= HIGHER_X_INDX and y >= LOWER_Y_INDX and y <= HIGHER_Y_INDX)  then
        return positionGrid[x][y]
    end
    return false
end

function getGridIndex(x, y)
    local x = math.floor(x/10) + 1
    local y = math.floor(y/10) + 1

    if(x > HIGHER_X_INDX) then
        x = HIGHER_X_INDX
    end
    if(x < LOWER_X_INDX) then
        x = 10
    end

    if(y > HIGHER_Y_INDX) then
        y = HIGHER_Y_INDX
    end
    if(y < LOWER_X_INDX) then
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
            elseif(getTurnGridValue(i,j) ~= 5) then
                love.graphics.setColor(0,0,1)           
            else
                love.graphics.setColor(0,1,0)
            end
            love.graphics.circle("fill", xVal, yVal, 1)
            
            --love.graphics.print(i*10 .. "," .. j*10, xVal, yVal)
        end
    end
end

function cleanUpGridBorders()
    --print("Cleaning up!!")
    for i = LOWER_X_INDX, 0 do
        for j = LOWER_Y_INDX, HIGHER_Y_INDX do
            setPositionGridValue(i, j, false)
        end
    end

    for i = 100,  HIGHER_X_INDX do
        for j = LOWER_Y_INDX, HIGHER_Y_INDX do
            setPositionGridValue(i, j, false)
        end
    end


    for i = LOWER_Y_INDX, 0 do
        for j = LOWER_X_INDX, HIGHER_X_INDX do
            setPositionGridValue(j, i, false)
        end
    end

    for i = 65, HIGHER_Y_INDX do
        for j = LOWER_X_INDX, HIGHER_X_INDX do
            setPositionGridValue(j, i, false)
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

function drawGridBlocks(showGrid)
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
