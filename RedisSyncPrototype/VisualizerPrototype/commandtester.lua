nodes = {}

for i = 1, 16 do
    local node = {}
    node.colorRadius   	= 55
    node.outlineRadius 	= 62.5
    node.posX			= (30 + node.outlineRadius) * ((i % 4) + 1)
    node.posY			= (30 + node.outlineRadius) * (math.floor( i / 4 ) + 1)
    node.currentColor   = "red"
    node.name			= "Node " .. tostring(i)
    table.insert(nodes, node)
end

for i, v in ipairs(nodes) do
    print(v.name)
    print(v.posX .. "-" .. v.posY)
end