local relays = {peripheral.find("redstone_relay")} 
local sides = {"top", "bottom", "left", "right", "front", "back"}

local function getSides()
    local states = {}
    for _, side in pairs(sides) do
        states[side] = false
        for _, relay in pairs(relays) do
            if relay.getInput(side) then
                states[side] = true
                break
            end
        end
    end
    return states
end

return {
    relays = relays,
    getSides = getSides,
}