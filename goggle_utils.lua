local gogglePort = peripheral.find("goggle_link_port")
 if settings.get("MAX_DISTANCE") == nil then
    settings.set("MAX_DISTANCE", 1000)
    settings.save()
end

local function getTargetPosition()
    local positions = {}
    for _, goggle in pairs(gogglePort.getConnected()) do
        if goggle["type"] == "range_goggles" then
            local result = goggle.raycast(settings.get("MAX_DISTANCE"))
            if result["hit_pos"] then
                local targetPosition = result["hit_pos"]
                table.insert(positions, vector.new(targetPosition[1], targetPosition[2], targetPosition[3]))
            end
        end
    end

    local position = vector.new(0, 0, 0)
    if #positions > 0 then
        for _, pos in pairs(positions) do
            position = position + pos
        end
        return position / #positions
    else
        return false
    end
end

return {
    gogglePort = gogglePort,
    getTargetPosition = getTargetPosition,
}