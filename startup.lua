print("CC Cannon Controller")
local defaults = { 
    MOUNT_OFFSET = 2.5, -- from cannon to mount
    CANNON_OFFSET = 0.5, -- from cannon block to cannon center
    CANNON_SPEED = 8, -- initial speed per tick
    CANNON_LENGTH = 10.5,
    HIGH_TRAJECTORY = false,
    PITCH_MIN = -30,
    PITCH_MAX = 60,
    YAW_MIN = 0,
    YAW_MAX = 360,
    TICK_RATE = 0.05
}
for key, value in pairs(defaults) do
    if settings.get(key) == nil then
        settings.set(key, value)
        settings.save()
    end
end

local targetPosition = nil
local currentYaws = nil
local currentPitches = nil
local targetYaws = nil
local targetPitches = nil
local gearshiftMappings = nil
local gearshiftUnits = nil
local pitchDelta = 0
local yawDelta = 0
local assembled = false
local firing = false

function logging(message)
    print(os.date("%y/%m/%d %T") .. ": " .. message)
end

function vectorToArray(vector)
    return {vector.x, vector.y, vector.z}
end

function arrayToVector(array)
    return vector.new(array[1], array[2], array[3])
end

local function redstoneEventlLoop()
    while true do
        os.pullEvent("redstone")
        local states = redstone_utils.getSides()

        if states.top and states.bottom then
            pitchDelta = 0
            logging("Reset Pitch Delta")
        elseif states.top then
            pitchDelta = pitchDelta + 0.1
            logging("Pitch Delta: " .. pitchDelta)
        elseif states.bottom then
            pitchDelta = pitchDelta - 0.1
            logging("Pitch Delta: " .. pitchDelta)
        end
        if states.left and states.right then
            yawDelta = 0
            logging("Reset Yaw Delta")
        elseif states.left then
            yawDelta = yawDelta - 0.1
            logging("Yaw Delta: " .. yawDelta)
        elseif states.right then
            yawDelta = yawDelta + 0.1
            logging("Yaw Delta: " .. yawDelta)
        end
        firing = states.front
        if states.back then
            if assembled then
                if not cannon_utils.disassemble() then
                    logging("Failed to disassemble cannon")
                    return
                end
            else
                if not cannon_utils.assemble() then
                    logging("Failed to assemble cannon")
                    return
                end
            end
            assembled = not assembled
        end
    end
end

local function shipControlLoop()
    while true do
        shipyardPosition = ship_utils.getShipyardPosition()
        worldSpacePosition = ship_utils.getWorldspacePosition()

        sleep(settings.get("TICK_RATE"))
    end
end

local function goggleControlLoop()
    while true do
        local result = goggle_utils.getTargetPosition()
        if result then
            targetPosition = result
        end

        sleep(settings.get("TICK_RATE"))
    end
end

local function fireControlLoop()
    while true do
        if cannon_utils and assembled and firing then 
            cannon_utils.fire()
        end
        
        sleep(settings.get("TICK_RATE"))
    end
end

local function steerControlLoop()
    while true do
        if gearshift_utils and not gearshift_utils.isRunning(gearshiftMappings) then
            if targetYaws and targetPitches and currentYaws and currentPitches and gearshiftUnits and gearshiftMappings then
                local angles = {}
                for i = 1, #cannon_utils.cannons do
                    angles[i] = targetYaws[i] - currentYaws[i]
                    angles[i + #cannon_utils.cannons] = targetPitches[i] - currentPitches[i]
                end
                gearshift_utils.rotateAll(angles, gearshiftUnits, gearshiftMappings)
            end
        end

        sleep(settings.get("TICK_RATE"))
    end
end

local function cannonControlLoop()
    local offset = vector.new(settings.get("CANNON_OFFSET"), settings.get("MOUNT_OFFSET"), settings.get("CANNON_OFFSET"))
    positions = cannon_utils.getPositions()
    while true do
        currentYaws = cannon_utils.getYaws()
        currentPitches = cannon_utils.getPitches()

        if targetPosition then
            local yaws = {}
            local pitches = {}

            if ship_utils then         
                for i, position in ipairs(positions) do
                    local rotatedTarget = ship_utils.quaternionRotate(ship_utils.getQuaternion(), targetPosition - worldSpacePosition)
                    local delta = rotatedTarget - (position + offset - shipyardPosition)

                    yaws[i] = (360 -(math.atan2(delta.x, delta.z) * 180 / math.pi)) % 360
                    pitches[i] = math.atan2(delta.y, math.sqrt(delta.x * delta.x + delta.z * delta.z)) * 180 / math.pi

                    if trajectory_utils then
                        local results = trajectory_utils.calculatePitch(vectorToArray(position + offset - shipyardPosition), vectorToArray(rotatedTarget), settings.get("CANNON_SPEED"), settings.get("CANNON_LENGTH"))

                        local result
                        if settings.get("HIGH_TRAJECTORY") then
                            result = results[1]
                        else
                            result = results[2]
                        end

                        if result[1] ~= -1 or result[2] ~= -1 or result[3] ~= -1 then
                            local deltaPitch = (result[2] - pitches[i]) / 180 * math.pi
                            local rotatedGravity = ship_utils.quaternionRotate(ship_utils.getQuaternion(), vector.new(0, 1, 0))
                            local normal = delta:cross(rotatedGravity):normalize()
                            local quaternion = {
                                w = math.cos(deltaPitch / 2),
                                x = normal.x * math.sin(deltaPitch / 2),
                                y = normal.y * math.sin(deltaPitch / 2),
                                z = normal.z * math.sin(deltaPitch / 2)
                            }
                            local rotatedDelta = ship_utils.quaternionRotateInvert(quaternion, delta)

                            yaws[i] = (360 - (math.atan2(rotatedDelta.x, rotatedDelta.z) * 180 / math.pi)) % 360
                            pitches[i] = math.atan2(rotatedDelta.y, math.sqrt(rotatedDelta.x * rotatedDelta.x + rotatedDelta.z * rotatedDelta.z)) * 180 / math.pi
                        end
                    end
                end
            else
                for i, position in ipairs(positions) do
                    local delta = targetPosition - (position + offset)

                    yaws[i] = (360 - (math.atan2(delta.x, delta.z) * 180 / math.pi)) % 360
                    pitches[i] = math.atan2(delta.y, math.sqrt(delta.x * delta.x + delta.z * delta.z)) * 180 / math.pi

                    if trajectory_utils then
                        local results = trajectory_utils.calculatePitch(vectorToArray(position + offset), vectorToArray(targetPosition), settings.get("CANNON_SPEED"), settings.get("CANNON_LENGTH"))

                        local result
                        if settings.get("HIGH_TRAJECTORY") then
                            result = results[1]
                        else
                            result = results[2]
                        end

                        if result[1] ~= -1 or result[2] ~= -1 or result[3] ~= -1 then
                            pitches[i] = result[2]
                        else
                            logging("No valid trajectory found")
                        end
                    end
                end
            end

            for i, position in ipairs(positions) do
                yaws[i] = yaws[i] + yawDelta
                pitches[i] = pitches[i] + pitchDelta
                
                if pitches[i] > settings.get("PITCH_MAX") then
                    pitches[i] = settings.get("PITCH_MAX")
                    logging("Max Pitch reached")
                elseif pitches[i] < settings.get("PITCH_MIN") then
                    pitches[i] = settings.get("PITCH_MIN")
                    logging("Min Pitch reached")
                end

                if yaws[i] > settings.get("YAW_MAX") then
                    yaws[i] = settings.get("YAW_MAX")
                    logging("Max Yaw reached")
                elseif yaws[i] < settings.get("YAW_MIN") then
                    yaws[i] = settings.get("YAW_MIN")
                    logging("Min Yaw reached")
                end
            end

            targetYaws = yaws
            targetPitches = pitches
            if cannon_utils.setYaws then
                cannon_utils.setYaws(targetYaws)
            end
            if cannon_utils.setPitches then
                cannon_utils.setPitches(targetPitches)
            end
        end

        sleep(settings.get("TICK_RATE"))
    end
end

local controlLoops = {}
if ship then
    ship_utils = require("ship_utils")
    logging("Found Ship: " .. ship_utils.getName())
    table.insert(controlLoops, shipControlLoop)
end

if peripheral.find("redstone_relay") then
    redstone_utils = require("redstone_utils")
    logging("Found Redstone Relay: " .. #redstone_utils.relays)
    table.insert(controlLoops, redstoneEventlLoop)
    table.insert(controlLoops, fireControlLoop)
end

if peripheral.find("goggle_link_port") then
    goggle_utils = require("goggle_utils")
    logging("Found Goggle: " .. #goggle_utils.gogglePort.getConnected())
    table.insert(controlLoops, goggleControlLoop)
end

if peripheral.find("ballistic_accelerator") then
    trajectory_utils = require("trajectory_utils")
    logging("Found Trajectory Calculator")
end

if peripheral.find("cbc_cannon_mount") then
    cannon_utils = require("cannon_utils")
    logging("Found Cannon: " .. #cannon_utils.cannons)
    if not cannon_utils.assemble() then
        logging("Failed to assemble cannon")
        return
    end
    assembled = true

    table.insert(controlLoops, cannonControlLoop)
else
    logging("No cannon found")
    return
end

if peripheral.find("Create_SequencedGearshift") then
    gearshift_utils = require("gearshift_utils")
    logging("Found Gearshift: " .. #gearshift_utils.gearshifts)

    gearshiftMappings = {}
    gearshiftUnits = {}

    for i, gearshift in ipairs(gearshift_utils.gearshifts) do
        local angles = {}
        for i = 1, #cannon_utils.cannons do
            angles[i] = cannon_utils.getYaws()[i]
            angles[i + #cannon_utils.cannons] = cannon_utils.getPitches()[i]
        end
        
        gearshift.rotate(1, 1)
        for i = 1, 1/settings.get("TICK_RATE") do
            if not gearshift.isRunning() then
                break
            end
            sleep(settings.get("TICK_RATE"))
        end

        local newAngles = {}
        for i = 1, #cannon_utils.cannons do
            newAngles[i] = cannon_utils.getYaws()[i]
            newAngles[i + #cannon_utils.cannons] = cannon_utils.getPitches()[i]
        end
        for j = 1, #angles do
            if angles[j] ~= newAngles[j] then
                gearshiftMappings[j] = i
                gearshiftUnits[j] = newAngles[j] - angles[j]
                logging("Found gearshift mapping: " .. j .. " -> " .. i .. " with unit: " .. gearshiftUnits[j])
            end
        end
    end

    table.insert(controlLoops, steerControlLoop)
end

local ok, error = pcall(function()
    parallel.waitForAny(table.unpack(controlLoops))
end)
if not ok then
    logging(error)
end
if not cannon_utils.disassemble() then
    logging("Failed to disassemble cannon")
    return
end