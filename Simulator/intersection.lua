local class = require("middleclass")
Intersection = class('intersection')

function Intersection:initialize (posX, posY, id)
    self.posX = posX
    self.posY = posY
    self.color = "red"
    self.nextColor = "green"
    self.nextChange = -1
    self.id = id
    self.radius = 10
end

function Intersection:draw()
    if(self.color == "red") then
        color = {193/255, 66/255, 66/255, 1}
    elseif (self.color == "yellow") then
        color = {215/255, 215/255, 60/255, 1}       
    else
        color = {63/255, 191/255, 63/255, 1}
    end
    love.graphics.setColor(color)
    love.graphics.circle("fill", self.posX, self.posY, self.radius)
    love.graphics.setColor(1,1,1)
end

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