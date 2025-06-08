local trajectory = peripheral.find("ballistic_accelerator")
local defaults = {
    GRAVITY = 0.05,
    DRAG = 0.01,
    GRAVITY_MULTIPLIER = 1.0,
    DRAG_MULTIPLIER = 1.0,
    MAX_DELTA_T_ERROR = 1.0,
    MAX_STEPS = 1000000,
    NUM_INTERATIONS = 5,
    NUM_ELEMENTS = 20,
    CHECK_IMPOSSIBLE = true
}
for key, value in pairs(defaults) do
    if settings.get(key) == nil then
        settings.set(key, value)
        settings.save()
    end
end

local function calculatePitch(position, target, speed, length)
    return trajectory.calculatePitch(
        position, 
        target, 
        speed, 
        length, 
        -90, 
        90, 
        settings.get("GRAVITY"), 
        1 - trajectory.getDrag(settings.get("DRAG"), settings.get("DRAG_MULTIPLIER")), 
        settings.get("MAX_DELTA_T_ERROR"), 
        settings.get("MAX_STEPS"), 
        settings.get("NUM_INTERATIONS"), 
        settings.get("NUM_ELEMENTS"), 
        settings.get("CHECK_IMPOSSIBLE")
    )
end

return {
    trajectory = trajectory,
    calculatePitch = calculatePitch
}