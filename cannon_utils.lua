local cannons = {peripheral.find("cbc_cannon_mount")}
if settings.get("CHEAT_CANNON_MOUNT") == nil then
    settings.set("CHEAT_CANNON_MOUNT", true)
    settings.save()
end

local function getPositions()
    local positions = {}
    for _, cannon in pairs(cannons) do
        table.insert(positions, vector.new(cannon.getX(), cannon.getY(), cannon.getZ()))
    end
    return positions
end

local function getPitches()
    local pitches = {}
    for _, cannon in pairs(cannons) do
        table.insert(pitches, cannon.getPitch())
    end
    return pitches
end

local function getYaws()
    local yaws = {}
    for _, cannon in pairs(cannons) do
        table.insert(yaws, cannon.getYaw())
    end
    return yaws
end

local function setPitches(pitches)
    for i, cannon in pairs(cannons) do
        cannon.setPitch(pitches[i])
    end
end

local function setYaws(yaws)
    for i, cannon in pairs(cannons) do
        cannon.setYaw(yaws[i])
    end
end

local function assemble()
    for _, cannon in pairs(cannons) do
        if not cannon.isRunning() then
            if not cannon.assemble() then
                return false
            end
        end
    end
    return true
end

local function disassemble()
    for _, cannon in pairs(cannons) do
        if cannon.isRunning() then
            if not cannon.disassemble() then
                return false
            end
        end
    end
    return true
end

local function fire()
    for _, cannon in pairs(cannons) do
        cannon.fire()
    end
end

return {
    cannons = cannons,
    getPositions = getPositions,
    getPitches = getPitches,
    getYaws = getYaws,
    setPitches = settings.get("CHEAT_CANNON_MOUNT") and setPitches or nil,
    setYaws = settings.get("CHEAT_CANNON_MOUNT") and setYaws or nil,
    assemble = assemble,
    disassemble = disassemble,
    fire = fire,
}