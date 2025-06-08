local gearshifts = {peripheral.find("Create_SequencedGearshift")}
if settings.get("MAX_ERROR_RATE") == nil then
    settings.set("MAX_ERROR_RATE", 1)
    settings.save()
end

local function rotateAll(angles, units, mappings)
    if not mappings then
        mappings = {}
        for i = 1, #angles do
            mappings[i] = i
        end
    end

    for j, i in pairs(mappings) do
        if angles[j] > 180 then
            angles[j] = angles[j] - 360
        elseif angles[j] < -180 then
            angles[j] = angles[j] + 360
        end

        if i and math.abs(angles[j]) > math.abs(units[j]) * settings.get("MAX_ERROR_RATE") then
            local gearshift = gearshifts[i]
            local direction = angles[j] * units[j] > 0 and 1 or -1
            gearshift.rotate(angles[j] / units[j], direction)
        end
    end
end

local function isRunning(mappings)
    if not mappings then
        mappings = {}
        for i = 1, #angles do
            mappings[i] = i
        end
    end

    for j, i in pairs(mappings) do
        if i and gearshifts[i].isRunning() then
            return true
        end
    end
    return false
end

return {
    gearshifts = gearshifts,
    rotateAll = rotateAll,
    isRunning = isRunning,
}