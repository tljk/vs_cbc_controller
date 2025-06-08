local function getWorldspacePosition()
    local worldspacePosition = ship.getWorldspacePosition()
    return vector.new(worldspacePosition.x, worldspacePosition.y, worldspacePosition.z)
end

local function getShipyardPosition()
    local shipyardPosition = ship.getShipyardPosition()
    return vector.new(shipyardPosition.x, shipyardPosition.y, shipyardPosition.z)
end

local function getSize()
    local size = ship.getSize()
    return vector.new(size.x, size.y, size.z)
end

local function getScale()
    local scale = ship.getScale()
    return vector.new(scale.x, scale.y, scale.z)
end

local function getQuaternion()
    local quaternion = ship.getQuaternion()
    return {
        w = quaternion.w,
        x = quaternion.x,
        y = quaternion.y,
        z = quaternion.z
    }
end

local function quaternionMultiply(q1, q2)
    return {
        w = q1.w * q2.w - q1.x * q2.x - q1.y * q2.y - q1.z * q2.z,
        x = q1.w * q2.x + q1.x * q2.w + q1.y * q2.z - q1.z * q2.y,
        y = q1.w * q2.y - q1.x * q2.z + q1.y * q2.w + q1.z * q2.x,
        z = q1.w * q2.z + q1.x * q2.y - q1.y * q2.x + q1.z * q2.w
    }
end

local function quaternionConjugate(q)
    return {
        w = q.w,
        x = -q.x,
        y = -q.y,
        z = -q.z
    }
end

local function quaternionRotate(q, v) -- world to ship
    local qConjugate = quaternionConjugate(q)
    local qV = {w = 0, x = v.x, y = v.y, z = v.z}
    local qResult = quaternionMultiply(quaternionMultiply(qConjugate, qV), q)
    return vector.new(qResult.x, qResult.y, qResult.z)
end

local function quaternionRotateInvert(q, v) -- ship to world
    local qConjugate = quaternionConjugate(q)
    local qV = {w = 0, x = v.x, y = v.y, z = v.z}
    local qResult = quaternionMultiply(quaternionMultiply(q, qV), qConjugate)
    return vector.new(qResult.x, qResult.y, qResult.z)
end

local function quaternionToAxisAngle(q)
    local theta = 2 * math.acos(q.w)
    local sinTheta = math.sqrt(math.max(0, 1 - q.w * q.w))
    local axis = vector.new(q.x / sinTheta, q.y / sinTheta, q.z / sinTheta)
    if sinTheta < 1e-8 then
        return vector.new(0, 0, 0), 0
    end
    return axis, theta
end

return {
    getName = ship.getName,
    getId = ship.getId,
    getWorldspacePosition = getWorldspacePosition,
    getShipyardPosition = getShipyardPosition,
    getSize = getSize,
    getScale = getScale,
    getQuaternion = getQuaternion,
    quaternionMultiply = quaternionMultiply,
    quaternionConjugate = quaternionConjugate,
    quaternionRotate = quaternionRotate,
    quaternionRotateInvert = quaternionRotateInvert,
    quaternionMultiply = quaternionMultiply,
    quaternionToAxisAngle = quaternionToAxisAngle,
}